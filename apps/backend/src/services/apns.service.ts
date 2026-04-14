// src/services/apns.service.ts
// Apple Push Notification Service - sends push directly to Apple (free, self-hosted)
import jwt from 'jsonwebtoken';
import fs from 'fs';
import path from 'path';
import { logger } from '../config/logger.js';
import prisma from '../config/database.js';

const APNS_KEY_ID = '62FTDWJU7B';
const APNS_TEAM_ID = 'P6W2TQ4XXF';
const APNS_BUNDLE_ID = 'com.frogio.santajuana';
// Use sandbox for development profiles, production for App Store
const APNS_HOST = 'api.sandbox.push.apple.com';

let apnsKey: string | null = null;
let apnsToken: string | null = null;
let apnsTokenExpiry = 0;

function loadKey(): string {
  if (apnsKey) return apnsKey;
  const keyPath = path.resolve('/app/AuthKey_62FTDWJU7B.p8');
  const altPath = path.resolve('./AuthKey_62FTDWJU7B.p8');

  if (fs.existsSync(keyPath)) {
    apnsKey = fs.readFileSync(keyPath, 'utf8');
  } else if (fs.existsSync(altPath)) {
    apnsKey = fs.readFileSync(altPath, 'utf8');
  } else {
    throw new Error('APNs key file not found');
  }
  return apnsKey;
}

function getToken(): string {
  const now = Math.floor(Date.now() / 1000);
  if (apnsToken && now < apnsTokenExpiry - 60) {
    return apnsToken;
  }

  const key = loadKey();
  apnsToken = jwt.sign(
    { iss: APNS_TEAM_ID, iat: now },
    key,
    { algorithm: 'ES256', keyid: APNS_KEY_ID, header: { alg: 'ES256', kid: APNS_KEY_ID } }
  );
  apnsTokenExpiry = now + 3600; // 1 hour
  return apnsToken;
}

export async function sendAPNsPush(
  deviceToken: string,
  title: string,
  body: string,
  data?: Record<string, any>,
  sound: string = 'default',
): Promise<boolean> {
  try {
    const token = getToken();
    const payload = {
      aps: {
        alert: { title, body },
        sound,
        badge: 1,
        'interruption-level': 'time-sensitive',
        'relevance-score': 1.0,
      },
      ...data,
    };

    const response = await fetch(
      `https://${APNS_HOST}/3/device/${deviceToken}`,
      {
        method: 'POST',
        headers: {
          'authorization': `bearer ${token}`,
          'apns-topic': APNS_BUNDLE_ID,
          'apns-push-type': 'alert',
          'apns-priority': '10',
          'apns-expiration': '0',
          'content-type': 'application/json',
        },
        body: JSON.stringify(payload),
      }
    );

    if (response.status === 200) {
      logger.info(`APNs push sent to ${deviceToken.substring(0, 8)}...`);
      return true;
    } else {
      const error = await response.text();
      logger.error(`APNs push failed (${response.status}): ${error}`);
      return false;
    }
  } catch (e) {
    logger.error(`APNs push error: ${e}`);
    return false;
  }
}

/// Send push to all inspectors/admins with iOS devices
export async function sendPanicPushToInspectors(
  tenantId: string,
  title: string,
  body: string,
  data?: Record<string, any>,
): Promise<void> {
  try {
    // Get all iOS device tokens for inspectors/admins
    const tokens = await prisma.$queryRawUnsafe<any[]>(
      `SELECT dt.device_token, dt.platform
       FROM "${tenantId}".device_tokens dt
       JOIN "${tenantId}".users u ON dt.user_id = u.id
       WHERE u.role IN ('inspector', 'admin')
       AND dt.platform = 'ios'
       AND dt.is_active = true`
    );

    if (tokens.length === 0) {
      logger.info('No iOS inspector tokens found for push');
      return;
    }

    logger.info(`Sending APNs push to ${tokens.length} inspector devices`);

    // Send to all devices in parallel
    const results = await Promise.allSettled(
      tokens.map(t => sendAPNsPush(t.device_token, title, body, data))
    );

    const success = results.filter(r => r.status === 'fulfilled' && r.value).length;
    logger.info(`APNs: ${success}/${tokens.length} pushes sent successfully`);
  } catch (e) {
    logger.error(`Error sending panic push: ${e}`);
  }
}

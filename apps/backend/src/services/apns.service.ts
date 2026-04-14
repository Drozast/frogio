// src/services/apns.service.ts
// Apple Push Notification Service via HTTP/2
import http2 from 'node:http2';
import jwt from 'jsonwebtoken';
import fs from 'fs';
import path from 'path';
import { logger } from '../config/logger.js';
import prisma from '../config/database.js';

const APNS_KEY_ID = '62FTDWJU7B';
const APNS_TEAM_ID = 'P6W2TQ4XXF';
const APNS_BUNDLE_ID = 'com.frogio.santajuana';
const APNS_HOST = 'api.sandbox.push.apple.com';

let apnsKey: string | null = null;
let apnsToken: string | null = null;
let apnsTokenExpiry = 0;

function loadKey(): string {
  if (apnsKey) return apnsKey;
  const paths = [
    path.resolve('/app/AuthKey_62FTDWJU7B.p8'),
    path.resolve('./AuthKey_62FTDWJU7B.p8'),
  ];
  for (const p of paths) {
    if (fs.existsSync(p)) {
      apnsKey = fs.readFileSync(p, 'utf8');
      logger.info(`APNs key loaded from ${p}`);
      return apnsKey;
    }
  }
  throw new Error('APNs key file not found');
}

function getToken(): string {
  const now = Math.floor(Date.now() / 1000);
  if (apnsToken && now < apnsTokenExpiry - 60) return apnsToken;

  const key = loadKey();
  apnsToken = jwt.sign({ iss: APNS_TEAM_ID, iat: now }, key, {
    algorithm: 'ES256',
    header: { alg: 'ES256', kid: APNS_KEY_ID },
  });
  apnsTokenExpiry = now + 3500;
  return apnsToken;
}

function sendHTTP2Push(deviceToken: string, payload: object): Promise<boolean> {
  return new Promise((resolve) => {
    try {
      const client = http2.connect(`https://${APNS_HOST}`);

      client.on('error', (err) => {
        logger.error(`APNs HTTP/2 connection error: ${err.message}`);
        resolve(false);
      });

      const token = getToken();
      const body = JSON.stringify(payload);

      const req = client.request({
        ':method': 'POST',
        ':path': `/3/device/${deviceToken}`,
        'authorization': `bearer ${token}`,
        'apns-topic': APNS_BUNDLE_ID,
        'apns-push-type': 'alert',
        'apns-priority': '10',
        'apns-expiration': '0',
        'content-type': 'application/json',
        'content-length': Buffer.byteLength(body),
      });

      let responseData = '';
      let statusCode = 0;

      req.on('response', (headers) => {
        statusCode = headers[':status'] as number;
      });

      req.on('data', (chunk) => {
        responseData += chunk;
      });

      req.on('end', () => {
        client.close();
        if (statusCode === 200) {
          logger.info(`APNs push sent to ${deviceToken.substring(0, 8)}...`);
          resolve(true);
        } else {
          logger.error(`APNs push failed (${statusCode}): ${responseData}`);
          resolve(false);
        }
      });

      req.on('error', (err) => {
        logger.error(`APNs request error: ${err.message}`);
        client.close();
        resolve(false);
      });

      req.write(body);
      req.end();
    } catch (e) {
      logger.error(`APNs push exception: ${e}`);
      resolve(false);
    }
  });
}

export async function sendAPNsPush(
  deviceToken: string,
  title: string,
  body: string,
  data?: Record<string, any>,
): Promise<boolean> {
  const payload = {
    aps: {
      alert: { title, body },
      sound: 'default',
      badge: 1,
      'interruption-level': 'time-sensitive',
    },
    ...(data || {}),
  };
  return sendHTTP2Push(deviceToken, payload);
}

export async function sendPanicPushToInspectors(
  tenantId: string,
  title: string,
  body: string,
  data?: Record<string, any>,
): Promise<void> {
  try {
    const tokens = await prisma.$queryRawUnsafe<any[]>(
      `SELECT dt.device_token
       FROM "${tenantId}".device_tokens dt
       JOIN "${tenantId}".users u ON dt.user_id = u.id
       WHERE u.role IN ('inspector', 'admin')
       AND dt.platform = 'ios'
       AND dt.is_active = true`
    );

    if (tokens.length === 0) {
      logger.info('No iOS inspector tokens for push');
      return;
    }

    logger.info(`Sending APNs push to ${tokens.length} iOS devices`);

    const results = await Promise.allSettled(
      tokens.map(t => sendAPNsPush(t.device_token, title, body, data))
    );

    const success = results.filter(r => r.status === 'fulfilled' && r.value).length;
    logger.info(`APNs: ${success}/${tokens.length} sent`);
  } catch (e) {
    logger.error(`Error sending panic push: ${e}`);
  }
}

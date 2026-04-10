import nodemailer from 'nodemailer';
import { env } from '../config/env.js';
import { logger } from '../config/logger.js';

class EmailService {
  private transporter: nodemailer.Transporter | null = null;
  private isConfigured = false;

  constructor() {
    this.initialize();
  }

  private initialize() {
    if (env.SMTP_HOST && env.SMTP_USER && env.SMTP_PASSWORD) {
      try {
        this.transporter = nodemailer.createTransport({
          host: env.SMTP_HOST,
          port: env.SMTP_PORT,
          secure: env.SMTP_SECURE,
          auth: {
            user: env.SMTP_USER,
            pass: env.SMTP_PASSWORD,
          },
        });
        this.isConfigured = true;
        logger.info('Email service configured');
      } catch (error) {
        logger.warn('Email service failed to initialize:', error);
      }
    } else {
      logger.info('Email service not configured (SMTP vars missing)');
    }
  }

  async sendEmail(to: string, subject: string, html: string, text?: string): Promise<boolean> {
    if (!this.isConfigured || !this.transporter) {
      logger.warn(`Email not sent (not configured): to=${to}, subject=${subject}`);
      return false;
    }

    try {
      await this.transporter.sendMail({
        from: env.SMTP_FROM || `FROGIO <${env.SMTP_USER}>`,
        to,
        subject,
        html,
        text: text || html.replace(/<[^>]*>/g, ''),
      });
      logger.info(`Email sent to ${to}: ${subject}`);
      return true;
    } catch (error) {
      logger.error(`Failed to send email to ${to}:`, error);
      return false;
    }
  }

  async sendPasswordReset(email: string, resetToken: string, _tenantId: string): Promise<boolean> {
    const resetUrl = `${env.API_URL}/reset-password?token=${resetToken}`;

    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
      </head>
      <body style="font-family: 'Helvetica Neue', Arial, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5;">
        <div style="max-width: 560px; margin: 40px auto; background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.08);">
          <div style="background: linear-gradient(135deg, #0D3B1E, #1B5E20, #2E7D32); padding: 32px; text-align: center;">
            <h1 style="color: white; margin: 0; font-size: 28px; letter-spacing: 2px;">FROGIO</h1>
            <p style="color: rgba(255,255,255,0.7); margin: 8px 0 0; font-size: 12px; letter-spacing: 1px;">SISTEMA DE GESTION MUNICIPAL</p>
          </div>
          <div style="padding: 32px;">
            <h2 style="color: #212121; margin: 0 0 16px; font-size: 20px;">Recuperar Contrasena</h2>
            <p style="color: #757575; line-height: 1.6; margin: 0 0 24px;">
              Recibimos una solicitud para restablecer tu contrasena. Haz clic en el siguiente boton para continuar:
            </p>
            <div style="text-align: center; margin: 32px 0;">
              <a href="${resetUrl}" style="display: inline-block; background: linear-gradient(135deg, #1B5E20, #2E7D32); color: white; text-decoration: none; padding: 14px 32px; border-radius: 12px; font-weight: 600; font-size: 14px;">
                Restablecer Contrasena
              </a>
            </div>
            <p style="color: #9e9e9e; font-size: 13px; line-height: 1.5;">
              Si no solicitaste este cambio, puedes ignorar este correo. El enlace expira en 1 hora.
            </p>
            <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;" />
            <p style="color: #bdbdbd; font-size: 11px; text-align: center;">
              Este correo fue enviado automaticamente por FROGIO. No responder.
            </p>
          </div>
        </div>
      </body>
      </html>
    `;

    return this.sendEmail(email, 'Recuperar Contrasena - FROGIO', html);
  }

  async sendWelcome(email: string, firstName: string): Promise<boolean> {
    const html = `
      <!DOCTYPE html>
      <html>
      <head><meta charset="utf-8"></head>
      <body style="font-family: 'Helvetica Neue', Arial, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5;">
        <div style="max-width: 560px; margin: 40px auto; background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.08);">
          <div style="background: linear-gradient(135deg, #0D3B1E, #1B5E20, #2E7D32); padding: 32px; text-align: center;">
            <h1 style="color: white; margin: 0; font-size: 28px; letter-spacing: 2px;">FROGIO</h1>
          </div>
          <div style="padding: 32px;">
            <h2 style="color: #212121; margin: 0 0 16px;">Bienvenido/a, ${firstName}!</h2>
            <p style="color: #757575; line-height: 1.6;">
              Tu cuenta ha sido creada exitosamente en el Sistema de Gestion Municipal FROGIO.
              Ya puedes acceder al sistema con tu correo y contrasena.
            </p>
          </div>
        </div>
      </body>
      </html>
    `;

    return this.sendEmail(email, 'Bienvenido a FROGIO', html);
  }

  async sendNotification(email: string, title: string, message: string): Promise<boolean> {
    const html = `
      <!DOCTYPE html>
      <html>
      <head><meta charset="utf-8"></head>
      <body style="font-family: 'Helvetica Neue', Arial, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5;">
        <div style="max-width: 560px; margin: 40px auto; background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.08);">
          <div style="background: linear-gradient(135deg, #0D3B1E, #1B5E20, #2E7D32); padding: 24px; text-align: center;">
            <h1 style="color: white; margin: 0; font-size: 24px; letter-spacing: 2px;">FROGIO</h1>
          </div>
          <div style="padding: 32px;">
            <h2 style="color: #212121; margin: 0 0 16px; font-size: 18px;">${title}</h2>
            <p style="color: #757575; line-height: 1.6;">${message}</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return this.sendEmail(email, title, html);
  }
}

export const emailService = new EmailService();

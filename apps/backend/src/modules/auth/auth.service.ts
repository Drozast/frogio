import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import prisma from '../../config/database.js';
import redis from '../../config/redis.js';
import { env } from '../../config/env.js';
import { logger } from '../../config/logger.js';
import type { RegisterDto, LoginDto, AuthResponse, ForgotPasswordDto, ResetPasswordDto } from './auth.types.js';

export class AuthService {
  private readonly JWT_SECRET = env.JWT_SECRET;
  private readonly JWT_REFRESH_SECRET = env.JWT_REFRESH_SECRET;
  private readonly JWT_EXPIRES_IN = env.JWT_EXPIRES_IN;
  private readonly JWT_REFRESH_EXPIRES_IN = env.JWT_REFRESH_EXPIRES_IN;

  async register(data: RegisterDto, tenantId: string): Promise<AuthResponse> {
    // Validate RUT format (basic Chilean RUT validation)
    if (!this.validateRUT(data.rut)) {
      throw new Error('RUT inválido');
    }

    // Check if user already exists
    const existingUser = await prisma.$queryRawUnsafe(
      `SELECT id FROM "${tenantId}".users WHERE email = $1 OR rut = $2 LIMIT 1`,
      data.email,
      data.rut
    );

    if (Array.isArray(existingUser) && existingUser.length > 0) {
      throw new Error('Usuario ya existe con este email o RUT');
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(data.password, 12);

    // Create user
    const [user] = await prisma.$queryRawUnsafe<any[]>(
      `INSERT INTO "${tenantId}".users (email, password_hash, rut, first_name, last_name, phone, role, is_active, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW())
       RETURNING id, email, rut, first_name, last_name, phone, role, is_active, created_at`,
      data.email,
      hashedPassword,
      data.rut,
      data.firstName || '',
      data.lastName || '',
      data.phone || null,
      data.role || 'citizen',
      true
    );

    // Generate tokens
    const tokens = await this.generateTokens(user.id, user.email, user.role, tenantId);

    return {
      user: {
        id: user.id,
        email: user.email,
        rut: user.rut,
        firstName: user.first_name,
        lastName: user.last_name,
        phone: user.phone,
        role: user.role,
        isActive: user.is_active,
      },
      ...tokens,
    };
  }

  async login(data: LoginDto, tenantId: string): Promise<AuthResponse> {
    console.log('🔐 Login attempt:', { email: data.email, tenantId });

    // Find user by email
    const [user] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT id, email, password_hash, rut, first_name, last_name, phone, role, is_active
       FROM "${tenantId}".users
       WHERE email = $1 LIMIT 1`,
      data.email
    );

    console.log('👤 User found:', user ? { email: user.email, hash: user.password_hash?.substring(0, 20) } : 'NO USER');

    if (!user) {
      throw new Error('Credenciales inválidas');
    }

    if (!user.is_active) {
      throw new Error('Usuario inactivo. Contacte al administrador.');
    }

    // Verify password
    console.log('🔑 Comparing password...');
    const isPasswordValid = await bcrypt.compare(data.password, user.password_hash);
    console.log('✅ Password valid:', isPasswordValid);

    if (!isPasswordValid) {
      throw new Error('Credenciales inválidas');
    }

    // Generate tokens
    const tokens = await this.generateTokens(user.id, user.email, user.role, tenantId);

    return {
      user: {
        id: user.id,
        email: user.email,
        rut: user.rut,
        firstName: user.first_name,
        lastName: user.last_name,
        phone: user.phone,
        role: user.role,
        isActive: user.is_active,
      },
      ...tokens,
    };
  }

  async refreshToken(refreshToken: string): Promise<{ accessToken: string; refreshToken: string }> {
    try {
      // Verify refresh token
      const decoded = jwt.verify(refreshToken, this.JWT_REFRESH_SECRET) as {
        userId: string;
        email: string;
        role: string;
        tenantId: string;
      };

      // Check if refresh token is blacklisted (only if redis is available)
      if (redis) {
        const isBlacklisted = await redis.get(`blacklist:${refreshToken}`);
        if (isBlacklisted) {
          throw new Error('Token inválido');
        }
      }

      // Generate new tokens
      return await this.generateTokens(decoded.userId, decoded.email, decoded.role, decoded.tenantId);
    } catch (error) {
      throw new Error('Refresh token inválido o expirado');
    }
  }

  async logout(refreshToken: string): Promise<void> {
    // Add refresh token to blacklist (expires in 7 days) - only if redis is available
    if (redis) {
      await redis.setex(`blacklist:${refreshToken}`, 7 * 24 * 60 * 60, '1');
    }
  }

  private async generateTokens(
    userId: string,
    email: string,
    role: string,
    tenantId: string
  ): Promise<{ accessToken: string; refreshToken: string }> {
    const payload = { userId, email, role, tenantId };

    const accessToken = jwt.sign(payload, this.JWT_SECRET, {
      expiresIn: this.JWT_EXPIRES_IN as string,
    } as jwt.SignOptions);

    const refreshToken = jwt.sign(payload, this.JWT_REFRESH_SECRET, {
      expiresIn: this.JWT_REFRESH_EXPIRES_IN as string,
    } as jwt.SignOptions);

    return { accessToken, refreshToken };
  }

  private validateRUT(rut: string): boolean {
    // Remove dots and hyphen
    const cleanRUT = rut.replace(/\./g, '').replace(/-/g, '');

    // Check format
    if (!/^[0-9]+[0-9Kk]$/.test(cleanRUT)) {
      return false;
    }

    const body = cleanRUT.slice(0, -1);
    const dv = cleanRUT.slice(-1).toLowerCase();

    // Calculate verification digit
    let sum = 0;
    let multiplier = 2;

    for (let i = body.length - 1; i >= 0; i--) {
      sum += parseInt(body[i]) * multiplier;
      multiplier = multiplier === 7 ? 2 : multiplier + 1;
    }

    const calculatedDV = 11 - (sum % 11);
    const expectedDV =
      calculatedDV === 11 ? '0' : calculatedDV === 10 ? 'k' : calculatedDV.toString();

    return dv === expectedDV;
  }

  async forgotPassword(data: ForgotPasswordDto, tenantId: string): Promise<{ message: string }> {
    // Find user by email
    const [user] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT id, email, first_name FROM "${tenantId}".users WHERE email = $1 LIMIT 1`,
      data.email
    );

    // Always return success to prevent email enumeration
    if (!user) {
      logger.info(`Password reset requested for non-existent email: ${data.email}`);
      return { message: 'Si el correo existe, recibirás instrucciones para recuperar tu contraseña' };
    }

    // Generate reset token (valid for 1 hour)
    const resetToken = jwt.sign(
      { userId: user.id, email: user.email, tenantId, type: 'password_reset' },
      this.JWT_SECRET,
      { expiresIn: '1h' }
    );

    // Store token in redis if available (for invalidation)
    if (redis) {
      await redis.setex(`password_reset:${user.id}`, 3600, resetToken);
    }

    // Log the token (in production, this would be sent via email/ntfy)
    logger.info(`Password reset token generated for ${user.email}: ${resetToken.substring(0, 20)}...`);

    // TODO: Send email/notification with reset link
    // For now, we'll use ntfy if configured
    if (env.NTFY_URL) {
      try {
        await fetch(`${env.NTFY_URL}/frogio-password-reset`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            topic: 'frogio-password-reset',
            title: 'Recuperación de Contraseña - FROGIO',
            message: `Se solicitó recuperación de contraseña para: ${user.email}`,
            tags: ['key', 'lock'],
          }),
        });
      } catch (e) {
        logger.warn('Could not send ntfy notification for password reset');
      }
    }

    return { message: 'Si el correo existe, recibirás instrucciones para recuperar tu contraseña' };
  }

  async resetPassword(data: ResetPasswordDto): Promise<{ message: string }> {
    try {
      // Verify token
      const decoded = jwt.verify(data.token, this.JWT_SECRET) as {
        userId: string;
        email: string;
        tenantId: string;
        type: string;
      };

      if (decoded.type !== 'password_reset') {
        throw new Error('Token inválido');
      }

      // Check if token is still valid in redis (if available)
      if (redis) {
        const storedToken = await redis.get(`password_reset:${decoded.userId}`);
        if (!storedToken || storedToken !== data.token) {
          throw new Error('Token expirado o ya utilizado');
        }
      }

      // Hash new password
      const hashedPassword = await bcrypt.hash(data.password, 12);

      // Update password
      await prisma.$queryRawUnsafe(
        `UPDATE "${decoded.tenantId}".users SET password_hash = $1, updated_at = NOW() WHERE id = $2`,
        hashedPassword,
        decoded.userId
      );

      // Invalidate token in redis
      if (redis) {
        await redis.del(`password_reset:${decoded.userId}`);
      }

      logger.info(`Password reset successful for user ${decoded.userId}`);

      return { message: 'Contraseña actualizada exitosamente' };
    } catch (error) {
      if (error instanceof jwt.TokenExpiredError) {
        throw new Error('El enlace de recuperación ha expirado');
      }
      throw new Error('Token de recuperación inválido');
    }
  }
}

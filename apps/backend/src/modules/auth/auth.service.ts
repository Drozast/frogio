import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { prisma } from '../../config/database';
import { redis } from '../../config/redis';
import { env } from '../../config/env';
import type { RegisterDto, LoginDto, AuthResponse } from './auth.types';

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
    // Find user by email
    const [user] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT id, email, password_hash, rut, first_name, last_name, phone, role, is_active
       FROM "${tenantId}".users
       WHERE email = $1 LIMIT 1`,
      data.email
    );

    if (!user) {
      throw new Error('Credenciales inválidas');
    }

    if (!user.is_active) {
      throw new Error('Usuario inactivo. Contacte al administrador.');
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(data.password, user.password_hash);

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

      // Check if refresh token is blacklisted
      const isBlacklisted = await redis.get(`blacklist:${refreshToken}`);
      if (isBlacklisted) {
        throw new Error('Token inválido');
      }

      // Generate new tokens
      return await this.generateTokens(decoded.userId, decoded.email, decoded.role, decoded.tenantId);
    } catch (error) {
      throw new Error('Refresh token inválido o expirado');
    }
  }

  async logout(refreshToken: string): Promise<void> {
    // Add refresh token to blacklist (expires in 7 days)
    await redis.setex(`blacklist:${refreshToken}`, 7 * 24 * 60 * 60, '1');
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
}

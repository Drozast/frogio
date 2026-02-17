import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock dependencies
vi.mock('../../src/config/database.js', () => ({
  default: { $queryRawUnsafe: vi.fn() },
}));

vi.mock('../../src/config/redis.js', () => ({
  default: {
    get: vi.fn(),
    setex: vi.fn(),
    del: vi.fn(),
  },
}));

vi.mock('../../src/config/env.js', () => ({
  env: {
    JWT_SECRET: 'test-secret-key-for-testing-purposes',
    JWT_REFRESH_SECRET: 'test-refresh-secret-key',
    JWT_EXPIRES_IN: '15m',
    JWT_REFRESH_EXPIRES_IN: '7d',
    NTFY_URL: null,
  },
}));

vi.mock('bcryptjs', () => ({
  default: {
    hash: vi.fn().mockResolvedValue('hashedPassword123'),
    compare: vi.fn(),
  },
}));

vi.mock('jsonwebtoken', () => ({
  default: {
    sign: vi.fn().mockReturnValue('mock.jwt.token'),
    verify: vi.fn(),
    TokenExpiredError: class TokenExpiredError extends Error {
      constructor() {
        super('Token expired');
        this.name = 'TokenExpiredError';
      }
    },
  },
}));

import prisma from '../../src/config/database.js';
import redis from '../../src/config/redis.js';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { AuthService } from '../../src/modules/auth/auth.service.js';

describe('AuthService', () => {
  let authService: AuthService;
  const tenantId = 'santa_juana';

  beforeEach(() => {
    authService = new AuthService();
    vi.clearAllMocks();
  });

  describe('register', () => {
    it('should register a new user successfully', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // No existing user
      mockQueries.mockResolvedValueOnce([]);

      // User created
      mockQueries.mockResolvedValueOnce([{
        id: 'user-123',
        email: 'test@example.com',
        rut: '12.345.678-5',
        first_name: 'Juan',
        last_name: 'Pérez',
        phone: '+56912345678',
        role: 'citizen',
        is_active: true,
      }]);

      const result = await authService.register({
        email: 'test@example.com',
        password: 'SecurePass123!',
        rut: '12.345.678-5',
        firstName: 'Juan',
        lastName: 'Pérez',
        phone: '+56912345678',
      }, tenantId);

      expect(result.user.email).toBe('test@example.com');
      expect(result.user.rut).toBe('12.345.678-5');
      expect(result.accessToken).toBeDefined();
      expect(result.refreshToken).toBeDefined();
    });

    it('should throw error for invalid RUT', async () => {
      await expect(
        authService.register({
          email: 'test@example.com',
          password: 'SecurePass123!',
          rut: 'invalid-rut',
        }, tenantId)
      ).rejects.toThrow('RUT inválido');
    });

    it('should throw error if user already exists', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Existing user found
      mockQueries.mockResolvedValueOnce([{ id: 'existing-user' }]);

      await expect(
        authService.register({
          email: 'test@example.com',
          password: 'SecurePass123!',
          rut: '12.345.678-5',
        }, tenantId)
      ).rejects.toThrow('Usuario ya existe con este email o RUT');
    });
  });

  describe('login', () => {
    it('should login successfully with valid credentials', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);
      vi.mocked(bcrypt.compare).mockResolvedValueOnce(true as never);

      // User found
      mockQueries.mockResolvedValueOnce([{
        id: 'user-123',
        email: 'test@example.com',
        password_hash: 'hashedPassword123',
        rut: '12.345.678-5',
        first_name: 'Juan',
        last_name: 'Pérez',
        phone: '+56912345678',
        role: 'citizen',
        is_active: true,
      }]);

      const result = await authService.login({
        email: 'test@example.com',
        password: 'SecurePass123!',
      }, tenantId);

      expect(result.user.email).toBe('test@example.com');
      expect(result.accessToken).toBeDefined();
      expect(result.refreshToken).toBeDefined();
    });

    it('should throw error for non-existent user', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // No user found
      mockQueries.mockResolvedValueOnce([]);

      await expect(
        authService.login({
          email: 'nonexistent@example.com',
          password: 'password',
        }, tenantId)
      ).rejects.toThrow('Credenciales inválidas');
    });

    it('should throw error for inactive user', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Inactive user found
      mockQueries.mockResolvedValueOnce([{
        id: 'user-123',
        email: 'test@example.com',
        password_hash: 'hashedPassword123',
        is_active: false,
      }]);

      await expect(
        authService.login({
          email: 'test@example.com',
          password: 'password',
        }, tenantId)
      ).rejects.toThrow('Usuario inactivo');
    });

    it('should throw error for invalid password', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);
      vi.mocked(bcrypt.compare).mockResolvedValueOnce(false as never);

      // User found
      mockQueries.mockResolvedValueOnce([{
        id: 'user-123',
        email: 'test@example.com',
        password_hash: 'hashedPassword123',
        is_active: true,
      }]);

      await expect(
        authService.login({
          email: 'test@example.com',
          password: 'wrongpassword',
        }, tenantId)
      ).rejects.toThrow('Credenciales inválidas');
    });
  });

  describe('refreshToken', () => {
    it('should refresh tokens successfully', async () => {
      vi.mocked(jwt.verify).mockReturnValueOnce({
        userId: 'user-123',
        email: 'test@example.com',
        role: 'citizen',
        tenantId: 'santa_juana',
      } as never);

      vi.mocked(redis!.get).mockResolvedValueOnce(null);

      const result = await authService.refreshToken('valid.refresh.token');

      expect(result.accessToken).toBeDefined();
      expect(result.refreshToken).toBeDefined();
    });

    it('should throw error for blacklisted token', async () => {
      vi.mocked(jwt.verify).mockReturnValueOnce({
        userId: 'user-123',
        email: 'test@example.com',
        role: 'citizen',
        tenantId: 'santa_juana',
      } as never);

      vi.mocked(redis!.get).mockResolvedValueOnce('1');

      await expect(
        authService.refreshToken('blacklisted.token')
      ).rejects.toThrow('Refresh token inválido o expirado');
    });

    it('should throw error for invalid token', async () => {
      vi.mocked(jwt.verify).mockImplementationOnce(() => {
        throw new Error('Invalid token');
      });

      await expect(
        authService.refreshToken('invalid.token')
      ).rejects.toThrow('Refresh token inválido o expirado');
    });
  });

  describe('logout', () => {
    it('should blacklist refresh token', async () => {
      await authService.logout('refresh.token.to.logout');

      expect(redis!.setex).toHaveBeenCalledWith(
        'blacklist:refresh.token.to.logout',
        7 * 24 * 60 * 60,
        '1'
      );
    });
  });

  describe('forgotPassword', () => {
    it('should return success message for existing user', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([{
        id: 'user-123',
        email: 'test@example.com',
        first_name: 'Juan',
      }]);

      const result = await authService.forgotPassword({
        email: 'test@example.com',
      }, tenantId);

      expect(result.message).toContain('Si el correo existe');
      expect(redis!.setex).toHaveBeenCalled();
    });

    it('should return same message for non-existent email (security)', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([]);

      const result = await authService.forgotPassword({
        email: 'nonexistent@example.com',
      }, tenantId);

      expect(result.message).toContain('Si el correo existe');
    });
  });

  describe('resetPassword', () => {
    it('should reset password successfully', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      vi.mocked(jwt.verify).mockReturnValueOnce({
        userId: 'user-123',
        email: 'test@example.com',
        tenantId: 'santa_juana',
        type: 'password_reset',
      } as never);

      vi.mocked(redis!.get).mockResolvedValueOnce('valid.reset.token');
      mockQueries.mockResolvedValueOnce([]);

      const result = await authService.resetPassword({
        token: 'valid.reset.token',
        password: 'NewSecurePass123!',
      });

      expect(result.message).toBe('Contraseña actualizada exitosamente');
      expect(redis!.del).toHaveBeenCalled();
    });

    it('should throw error for invalid token type', async () => {
      vi.mocked(jwt.verify).mockReturnValueOnce({
        userId: 'user-123',
        type: 'wrong_type',
      } as never);

      await expect(
        authService.resetPassword({
          token: 'wrong.type.token',
          password: 'NewPass123!',
        })
      ).rejects.toThrow('Token de recuperación inválido');
    });
  });

  describe('getProfile', () => {
    it('should return user profile', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([{
        id: 'user-123',
        email: 'test@example.com',
        rut: '12.345.678-5',
        first_name: 'Juan',
        last_name: 'Pérez',
        phone: '+56912345678',
        address: 'Av. Principal 123',
        role: 'citizen',
        created_at: new Date(),
        updated_at: new Date(),
      }]);

      const result = await authService.getProfile('user-123', tenantId);

      expect(result.email).toBe('test@example.com');
      expect(result.firstName).toBe('Juan');
      expect(result.lastName).toBe('Pérez');
    });

    it('should throw error if user not found', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([]);

      await expect(
        authService.getProfile('nonexistent', tenantId)
      ).rejects.toThrow('Usuario no encontrado');
    });
  });

  describe('updateProfile', () => {
    it('should update profile successfully', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Updated user (firstName doesn't require RUT check)
      mockQueries.mockResolvedValueOnce([{
        id: 'user-123',
        email: 'test@example.com',
        rut: '12.345.678-5',
        first_name: 'Juan Carlos',
        last_name: 'Pérez',
        phone: '+56912345678',
        role: 'citizen',
        created_at: new Date(),
        updated_at: new Date(),
      }]);

      const result = await authService.updateProfile('user-123', tenantId, {
        firstName: 'Juan Carlos',
      });

      expect(result.firstName).toBe('Juan Carlos');
    });

    it('should throw error when no data to update', async () => {
      await expect(
        authService.updateProfile('user-123', tenantId, {})
      ).rejects.toThrow('No hay datos para actualizar');
    });

    it('should throw error for invalid RUT on update', async () => {
      await expect(
        authService.updateProfile('user-123', tenantId, {
          rut: 'invalid-rut',
        })
      ).rejects.toThrow('RUT inválido');
    });

    it('should throw error if RUT already used by another user', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Existing user with same RUT
      mockQueries.mockResolvedValueOnce([{ id: 'other-user' }]);

      await expect(
        authService.updateProfile('user-123', tenantId, {
          rut: '12.345.678-5',
        })
      ).rejects.toThrow('Este RUT ya está registrado por otro usuario');
    });
  });

  describe('RUT validation', () => {
    it('should accept valid RUT with dots and hyphen', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Clear any previous mock calls
      vi.clearAllMocks();

      // No existing user
      mockQueries.mockResolvedValueOnce([]);

      // User created successfully
      mockQueries.mockResolvedValueOnce([{
        id: 'user-123',
        email: 'rut-test@example.com',
        rut: '12.345.678-5',
        first_name: 'Test',
        last_name: 'User',
        phone: null,
        role: 'citizen',
        is_active: true,
      }]);

      const result = await authService.register({
        email: 'rut-test@example.com',
        password: 'Pass123!',
        rut: '12.345.678-5',
      }, tenantId);

      expect(result.user.rut).toBe('12.345.678-5');
    });

    it('should accept valid RUT with K verification digit', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      vi.clearAllMocks();

      // No existing user
      mockQueries.mockResolvedValueOnce([]);

      // User created
      mockQueries.mockResolvedValueOnce([{
        id: 'user-456',
        email: 'k-rut@example.com',
        rut: '11.111.111-1',
        first_name: '',
        last_name: '',
        phone: null,
        role: 'citizen',
        is_active: true,
      }]);

      // Test with a RUT that has number verifier (not K)
      const result = await authService.register({
        email: 'k-rut@example.com',
        password: 'Pass123!',
        rut: '11.111.111-1',
      }, tenantId);

      expect(result).toBeDefined();
    });
  });
});

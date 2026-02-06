import bcrypt from 'bcryptjs';
import prisma from '../../config/database.js';
import type { CreateUserDto, UpdateUserDto, UserFilters } from './users.types.js';

export class UsersService {
  async create(data: CreateUserDto, tenantId: string) {
    // Check if user already exists
    const [existing] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT id FROM "${tenantId}".users WHERE email = $1 OR rut = $2 LIMIT 1`,
      data.email,
      data.rut
    );

    if (existing) {
      throw new Error('Ya existe un usuario con este email o RUT');
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(data.password, 12);

    const [user] = await prisma.$queryRawUnsafe<any[]>(
      `INSERT INTO "${tenantId}".users
       (email, password_hash, rut, first_name, last_name, phone, address, role, is_active, email_verified, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, false, NOW(), NOW())
       RETURNING id, email, rut, first_name, last_name, phone, address, role, is_active, email_verified, avatar, created_at, updated_at`,
      data.email,
      hashedPassword,
      data.rut,
      data.firstName || null,
      data.lastName || null,
      data.phone || null,
      data.address || null,
      data.role
    );

    return this.formatUser(user);
  }

  async findAll(tenantId: string, filters?: UserFilters) {
    let query = `SELECT id, email, rut, first_name, last_name, phone, address, role, is_active, email_verified, avatar, created_at, updated_at
                 FROM "${tenantId}".users WHERE 1=1`;

    const params: any[] = [];
    let paramIndex = 1;

    if (filters?.role) {
      query += ` AND role = $${paramIndex}`;
      params.push(filters.role);
      paramIndex++;
    }

    if (filters?.isActive !== undefined) {
      query += ` AND is_active = $${paramIndex}`;
      params.push(filters.isActive);
      paramIndex++;
    }

    if (filters?.search) {
      query += ` AND (
        LOWER(email) LIKE $${paramIndex} OR
        LOWER(first_name) LIKE $${paramIndex} OR
        LOWER(last_name) LIKE $${paramIndex} OR
        rut LIKE $${paramIndex}
      )`;
      params.push(`%${filters.search.toLowerCase()}%`);
      paramIndex++;
    }

    query += ` ORDER BY created_at DESC`;

    const users = await prisma.$queryRawUnsafe<any[]>(query, ...params);
    return users.map(this.formatUser);
  }

  async findById(id: string, tenantId: string) {
    const [user] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT id, email, rut, first_name, last_name, phone, address, role, is_active, email_verified, avatar, created_at, updated_at
       FROM "${tenantId}".users WHERE id = $1::uuid LIMIT 1`,
      id
    );

    if (!user) {
      throw new Error('Usuario no encontrado');
    }

    return this.formatUser(user);
  }

  async update(id: string, data: UpdateUserDto, tenantId: string) {
    const updates: string[] = [];
    const params: any[] = [];
    let paramIndex = 1;

    if (data.firstName !== undefined) {
      updates.push(`first_name = $${paramIndex}`);
      params.push(data.firstName);
      paramIndex++;
    }

    if (data.lastName !== undefined) {
      updates.push(`last_name = $${paramIndex}`);
      params.push(data.lastName);
      paramIndex++;
    }

    if (data.phone !== undefined) {
      updates.push(`phone = $${paramIndex}`);
      params.push(data.phone);
      paramIndex++;
    }

    if (data.address !== undefined) {
      updates.push(`address = $${paramIndex}`);
      params.push(data.address);
      paramIndex++;
    }

    if (data.role !== undefined) {
      updates.push(`role = $${paramIndex}`);
      params.push(data.role);
      paramIndex++;
    }

    if (data.isActive !== undefined) {
      updates.push(`is_active = $${paramIndex}`);
      params.push(data.isActive);
      paramIndex++;
    }

    if (updates.length === 0) {
      throw new Error('No hay datos para actualizar');
    }

    updates.push(`updated_at = NOW()`);
    params.push(id);

    const [updatedUser] = await prisma.$queryRawUnsafe<any[]>(
      `UPDATE "${tenantId}".users
       SET ${updates.join(', ')}
       WHERE id = $${paramIndex}::uuid
       RETURNING id, email, rut, first_name, last_name, phone, address, role, is_active, email_verified, avatar, created_at, updated_at`,
      ...params
    );

    if (!updatedUser) {
      throw new Error('Usuario no encontrado');
    }

    return this.formatUser(updatedUser);
  }

  async toggleStatus(id: string, tenantId: string) {
    const [user] = await prisma.$queryRawUnsafe<any[]>(
      `UPDATE "${tenantId}".users
       SET is_active = NOT is_active, updated_at = NOW()
       WHERE id = $1::uuid
       RETURNING id, email, rut, first_name, last_name, phone, address, role, is_active, email_verified, avatar, created_at, updated_at`,
      id
    );

    if (!user) {
      throw new Error('Usuario no encontrado');
    }

    return this.formatUser(user);
  }

  async delete(id: string, tenantId: string) {
    // Soft delete - just deactivate
    const [user] = await prisma.$queryRawUnsafe<any[]>(
      `UPDATE "${tenantId}".users
       SET is_active = false, updated_at = NOW()
       WHERE id = $1::uuid
       RETURNING id`,
      id
    );

    if (!user) {
      throw new Error('Usuario no encontrado');
    }

    return { message: 'Usuario desactivado exitosamente' };
  }

  async updatePassword(id: string, newPassword: string, tenantId: string) {
    const hashedPassword = await bcrypt.hash(newPassword, 12);

    const [user] = await prisma.$queryRawUnsafe<any[]>(
      `UPDATE "${tenantId}".users
       SET password_hash = $1, updated_at = NOW()
       WHERE id = $2::uuid
       RETURNING id`,
      hashedPassword,
      id
    );

    if (!user) {
      throw new Error('Usuario no encontrado');
    }

    return { message: 'Contraseña actualizada exitosamente' };
  }

  async getStats(tenantId: string) {
    const [stats] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT
        COUNT(*) as total,
        COUNT(*) FILTER (WHERE role = 'citizen') as citizens,
        COUNT(*) FILTER (WHERE role = 'inspector') as inspectors,
        COUNT(*) FILTER (WHERE role = 'admin') as admins,
        COUNT(*) FILTER (WHERE is_active = true) as active,
        COUNT(*) FILTER (WHERE is_active = false) as inactive
       FROM "${tenantId}".users`
    );

    return {
      total: parseInt(stats?.total || '0'),
      citizens: parseInt(stats?.citizens || '0'),
      inspectors: parseInt(stats?.inspectors || '0'),
      admins: parseInt(stats?.admins || '0'),
      active: parseInt(stats?.active || '0'),
      inactive: parseInt(stats?.inactive || '0'),
    };
  }

  private formatUser(user: any) {
    return {
      id: user.id,
      email: user.email,
      rut: user.rut,
      firstName: user.first_name,
      lastName: user.last_name,
      phone: user.phone,
      address: user.address,
      role: user.role,
      isActive: user.is_active,
      emailVerified: user.email_verified,
      avatar: user.avatar,
      createdAt: user.created_at,
      updatedAt: user.updated_at,
    };
  }
}

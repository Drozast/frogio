export interface CreateUserDto {
  email: string;
  password: string;
  rut: string;
  firstName?: string;
  lastName?: string;
  phone?: string;
  address?: string;
  role: 'citizen' | 'inspector' | 'admin';
}

export interface UpdateUserDto {
  firstName?: string;
  lastName?: string;
  phone?: string;
  address?: string;
  role?: 'citizen' | 'inspector' | 'admin';
  isActive?: boolean;
}

export interface UserFilters {
  role?: string;
  isActive?: boolean;
  search?: string;
}

export interface UserResponse {
  id: string;
  email: string;
  rut: string;
  firstName: string | null;
  lastName: string | null;
  phone: string | null;
  address: string | null;
  role: string;
  isActive: boolean;
  emailVerified: boolean;
  avatar: string | null;
  createdAt: Date;
  updatedAt: Date;
}

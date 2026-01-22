export interface RegisterDto {
  email: string;
  password: string;
  rut: string;
  firstName?: string;
  lastName?: string;
  name?: string;
  phone?: string;
  address?: string;
  role?: 'citizen' | 'inspector' | 'admin';
}

export interface LoginDto {
  email: string;
  password: string;
}

export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  user: {
    id: string;
    email: string;
    rut: string;
    firstName?: string;
    lastName?: string;
    phone?: string | null;
    name?: string | null;
    role: string;
    isActive: boolean;
  };
}

export interface JwtPayload {
  userId: string;
  email: string;
  role: string;
  tenantId?: string;
}

export interface ForgotPasswordDto {
  email: string;
}

export interface ResetPasswordDto {
  token: string;
  password: string;
}

export interface UpdateProfileDto {
  firstName?: string;
  lastName?: string;
  rut?: string;
  phoneNumber?: string;
  address?: string;
  profileImageUrl?: string;
  latitude?: number;
  longitude?: number;
  referenceNotes?: string;
  familyMembers?: FamilyMember[];
}

export interface FamilyMember {
  id?: string;
  name: string;
  rut?: string;
  relationship: string;
  phone?: string;
  hasDisability?: boolean;
  disabilityType?: string;
  hasChronicIllness?: boolean;
  illnessType?: string;
  notes?: string;
}

export interface UserProfile {
  id: string;
  email: string;
  rut?: string;
  firstName?: string;
  lastName?: string;
  phoneNumber?: string;
  address?: string;
  profileImageUrl?: string;
  latitude?: number;
  longitude?: number;
  referenceNotes?: string;
  familyMembers?: FamilyMember[];
  role: string;
  createdAt: Date;
  updatedAt?: Date;
}

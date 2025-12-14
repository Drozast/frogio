// ========================================
// FROGIO - Shared TypeScript Types
// ========================================

// User Types
export enum UserRole {
  CITIZEN = 'citizen',
  INSPECTOR = 'inspector',
  ADMIN = 'admin',
  SUPER_ADMIN = 'super_admin',
}

export interface User {
  id: string;
  email: string;
  rut: string;
  name?: string;
  phone?: string;
  address?: string;
  role: UserRole;
  avatar?: string;
  emailVerified: boolean;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

// Report Types
export enum ReportCategory {
  SECURITY = 'security',
  INFRASTRUCTURE = 'infrastructure',
  NOISE = 'noise',
  LIGHTING = 'lighting',
  OTHER = 'other',
}

export enum ReportPriority {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  URGENT = 'urgent',
}

export enum ReportStatus {
  DRAFT = 'draft',
  SUBMITTED = 'submitted',
  REVIEWING = 'reviewing',
  IN_PROGRESS = 'in_progress',
  RESOLVED = 'resolved',
  REJECTED = 'rejected',
  ARCHIVED = 'archived',
}

export interface Report {
  id: string;
  citizenId: string;
  title: string;
  description: string;
  category: ReportCategory;
  priority: ReportPriority;
  status: ReportStatus;
  latitude: number;
  longitude: number;
  address?: string;
  assignedToId?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Attachment {
  id: string;
  reportId: string;
  fileUrl: string;
  fileType: 'image' | 'video';
  fileName: string;
  fileSize?: number;
  uploadedAt: Date;
}

// Infraction Types
export enum PaymentStatus {
  PENDING = 'pending',
  PAID = 'paid',
  OVERDUE = 'overdue',
}

export interface Infraction {
  id: string;
  citationNumber: string;
  inspectorId: string;
  citizenRut: string;
  citizenName: string;
  infractionType: string;
  infractionCode?: string;
  description: string;
  amount: number;
  latitude?: number;
  longitude?: number;
  address?: string;
  vehiclePlate?: string;
  paymentStatus: PaymentStatus;
  paymentDueDate: Date;
  paidAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

// Court Citation Types
export enum CitationStatus {
  PENDING = 'pending',
  NOTIFIED = 'notified',
  ATTENDED = 'attended',
  MISSED = 'missed',
}

export interface CourtCitation {
  id: string;
  citationNumber: string;
  infractionId?: string;
  citizenId?: string;
  citizenRut: string;
  citizenName: string;
  courtDate: Date;
  courtLocation: string;
  reason: string;
  status: CitationStatus;
  notificationSentAt?: Date;
  attendedAt?: Date;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

// Medical Record Types
export enum Relationship {
  SELF = 'self',
  SPOUSE = 'spouse',
  CHILD = 'child',
  PARENT = 'parent',
  OTHER = 'other',
}

export interface MedicalRecord {
  id: string;
  userId: string;
  householdMemberName: string;
  relationship?: Relationship;
  medicalCondition: string;
  medications?: string;
  emergencyContactName?: string;
  emergencyContactPhone?: string;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

// Vehicle Types
export enum VehicleStatus {
  AVAILABLE = 'available',
  IN_USE = 'in_use',
  MAINTENANCE = 'maintenance',
  RETIRED = 'retired',
}

export interface Vehicle {
  id: string;
  plate: string;
  brand: string;
  model: string;
  year: number;
  vehicleType: string;
  status: VehicleStatus;
  createdAt: Date;
  updatedAt: Date;
}

// Tenant Types
export enum SubscriptionType {
  MONTHLY = 'monthly',
  YEARLY = 'yearly',
}

export enum SubscriptionStatus {
  ACTIVE = 'active',
  INACTIVE = 'inactive',
  TRIAL = 'trial',
}

export interface Tenant {
  id: string;
  slug: string;
  name: string;
  subdomain?: string;
  subscriptionType: SubscriptionType;
  subscriptionStatus: SubscriptionStatus;
  subscriptionStart: Date;
  subscriptionEnd?: Date;
  contactName?: string;
  contactEmail?: string;
  contactPhone?: string;
  createdAt: Date;
  updatedAt: Date;
}

// API Response Types
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

// Auth Types
export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  email: string;
  password: string;
  rut: string;
  name?: string;
  phone?: string;
  address?: string;
}

export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  user: User;
}

// Notification Types
export enum NotificationType {
  REPORT_UPDATE = 'report_update',
  ASSIGNMENT = 'assignment',
  CITATION = 'citation',
  PAYMENT = 'payment',
  GENERAL = 'general',
}

export interface Notification {
  id: string;
  userId: string;
  title: string;
  body: string;
  type: NotificationType;
  data?: Record<string, any>;
  read: boolean;
  sentAt: Date;
}

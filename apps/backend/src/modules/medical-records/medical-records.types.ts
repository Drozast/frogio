export interface FamilyMember {
  name: string;
  age: number;
  relationship: string;
  hasChronicCondition?: boolean;
}

export interface CreateMedicalRecordDto {
  householdHeadId: string;
  address: string;
  familyMembers: FamilyMember[];
  chronicConditions?: string[];
  allergies?: string[];
  medications?: string[];
  emergencyContactName?: string;
  emergencyContactPhone?: string;
  notes?: string;
}

export interface UpdateMedicalRecordDto {
  address?: string;
  familyMembers?: FamilyMember[];
  chronicConditions?: string[];
  allergies?: string[];
  medications?: string[];
  emergencyContactName?: string;
  emergencyContactPhone?: string;
  notes?: string;
}

from datetime import date, datetime
from typing import Any

from pydantic import BaseModel, EmailStr, Field

from apps.api.models import AppointmentStatus, EscalationUrgency, UserRole


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserResponse"


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    role: UserRole = UserRole.PATIENT


class UserResponse(BaseModel):
    id: int
    email: str
    full_name: str
    role: UserRole

    model_config = {"from_attributes": True}


class PatientResponse(BaseModel):
    id: int
    first_name: str
    last_name: str
    date_of_birth: date
    phone: str
    email: str
    insurance_provider: str | None = None

    model_config = {"from_attributes": True}


class PatientCreate(BaseModel):
    first_name: str
    last_name: str
    date_of_birth: date
    phone: str
    email: EmailStr
    insurance_provider: str | None = None


class DoctorResponse(BaseModel):
    id: int
    first_name: str
    last_name: str
    specialty: str
    department: str
    working_hours_start: str
    working_hours_end: str

    model_config = {"from_attributes": True}


class AvailabilitySlotResponse(BaseModel):
    id: int
    doctor_id: int
    start_time: datetime
    end_time: datetime
    is_booked: bool
    doctor_name: str | None = None

    model_config = {"from_attributes": True}


class AppointmentResponse(BaseModel):
    id: int
    patient_id: int
    doctor_id: int
    slot_id: int | None
    scheduled_at: datetime
    status: AppointmentStatus
    reason_for_visit: str | None
    notes: str | None
    patient_name: str | None = None
    doctor_name: str | None = None
    has_intake: bool = False

    model_config = {"from_attributes": True}


class AppointmentCreate(BaseModel):
    patient_id: int
    doctor_id: int
    slot_id: int
    reason_for_visit: str | None = None


class AppointmentUpdate(BaseModel):
    status: AppointmentStatus | None = None
    reason_for_visit: str | None = None
    notes: str | None = None


class IntakeFormCreate(BaseModel):
    symptoms_summary: str | None = None
    medications: str | None = None
    allergies: str | None = None
    additional_notes: str | None = None


class IntakeFormResponse(BaseModel):
    id: int
    appointment_id: int
    symptoms_summary: str | None
    medications: str | None
    allergies: str | None
    additional_notes: str | None
    prep_summary: str | None

    model_config = {"from_attributes": True}


class ChatMessage(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    message: str
    session_id: str | None = None
    patient_id: int | None = None


class ChatResponse(BaseModel):
    session_id: str
    message: str
    tool_calls_made: list[str] = Field(default_factory=list)
    escalated: bool = False


class EscalationResponse(BaseModel):
    id: int
    reason: str
    urgency: EscalationUrgency
    resolved: bool
    patient_name: str | None = None
    created_at: datetime

    model_config = {"from_attributes": True}


class DoctorScheduleResponse(BaseModel):
    doctor: DoctorResponse
    date: date
    appointments: list[AppointmentResponse]
    prep_summaries: dict[int, str] = Field(default_factory=dict)


class HospitalInfoResponse(BaseModel):
    name: str
    address: str
    phone: str
    hours: str
    departments: list[str]
    insurance_accepted: list[str]


class AuditLogResponse(BaseModel):
    id: int
    user_id: int | None
    action: str
    resource_type: str
    resource_id: str | None
    details: dict[str, Any] | None
    created_at: datetime

    model_config = {"from_attributes": True}

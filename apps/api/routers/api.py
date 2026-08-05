from datetime import date, datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session, joinedload

from apps.api.auth import authenticate_user, create_access_token, create_user, get_user_by_email
from apps.api.deps import get_client_ip, get_current_user, log_audit, require_roles
from apps.api.database import get_db
from apps.api.models import (
    Appointment,
    AppointmentStatus,
    Doctor,
    Escalation,
    Patient,
    User,
    UserRole,
)
from apps.api.schemas import (
    AppointmentCreate,
    AppointmentResponse,
    AppointmentUpdate,
    DoctorResponse,
    EscalationResponse,
    LoginRequest,
    PatientCreate,
    PatientResponse,
    RegisterRequest,
    TokenResponse,
    UserResponse,
)

router = APIRouter()


def _appointment_response(appointment: Appointment) -> AppointmentResponse:
    return AppointmentResponse(
        id=appointment.id,
        patient_id=appointment.patient_id,
        doctor_id=appointment.doctor_id,
        slot_id=appointment.slot_id,
        scheduled_at=appointment.scheduled_at,
        status=appointment.status,
        reason_for_visit=appointment.reason_for_visit,
        notes=appointment.notes,
        patient_name=f"{appointment.patient.first_name} {appointment.patient.last_name}",
        doctor_name=f"Dr. {appointment.doctor.first_name} {appointment.doctor.last_name}",
        has_intake=appointment.intake_form is not None,
    )


@router.post("/auth/register", response_model=TokenResponse)
def register(payload: RegisterRequest, request: Request, db: Session = Depends(get_db)):
    if get_user_by_email(db, payload.email):
        raise HTTPException(status_code=400, detail="Email already registered")
    user = create_user(db, payload.email, payload.password, payload.full_name, payload.role)
    log_audit(
        db,
        action="user_registered",
        resource_type="user",
        user_id=user.id,
        resource_id=str(user.id),
        details={"role": user.role.value},
        ip_address=get_client_ip(request),
    )
    token = create_access_token({"sub": str(user.id), "role": user.role.value})
    return TokenResponse(access_token=token, user=UserResponse.model_validate(user))


@router.post("/auth/login", response_model=TokenResponse)
def login(payload: LoginRequest, request: Request, db: Session = Depends(get_db)):
    user = authenticate_user(db, payload.email, payload.password)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    log_audit(
        db,
        action="user_login",
        resource_type="user",
        user_id=user.id,
        resource_id=str(user.id),
        ip_address=get_client_ip(request),
    )
    token = create_access_token({"sub": str(user.id), "role": user.role.value})
    return TokenResponse(access_token=token, user=UserResponse.model_validate(user))


@router.get("/auth/me", response_model=UserResponse)
def me(user: User = Depends(get_current_user)):
    return UserResponse.model_validate(user)


@router.get("/patients", response_model=list[PatientResponse])
def list_patients(
    db: Session = Depends(get_db),
    user: User = Depends(require_roles(UserRole.ADMIN, UserRole.RECEPTIONIST, UserRole.DOCTOR)),
):
    return db.query(Patient).order_by(Patient.last_name).all()


@router.post("/patients", response_model=PatientResponse, status_code=201)
def create_patient(
    payload: PatientCreate,
    request: Request,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles(UserRole.ADMIN, UserRole.RECEPTIONIST)),
):
    patient = Patient(**payload.model_dump())
    db.add(patient)
    db.commit()
    db.refresh(patient)
    log_audit(
        db,
        action="patient_created",
        resource_type="patient",
        user_id=user.id,
        resource_id=str(patient.id),
        ip_address=get_client_ip(request),
    )
    return patient


@router.get("/patients/{patient_id}", response_model=PatientResponse)
def get_patient(
    patient_id: int,
    request: Request,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    from apps.api.security import audit_phi_access

    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    audit_phi_access(db, user, "patient_viewed", "patient", str(patient_id), request)
    return patient


@router.get("/doctors", response_model=list[DoctorResponse])
def list_doctors(db: Session = Depends(get_db)):
    return db.query(Doctor).order_by(Doctor.last_name).all()


@router.get("/doctors/{doctor_id}", response_model=DoctorResponse)
def get_doctor(doctor_id: int, db: Session = Depends(get_db)):
    doctor = db.query(Doctor).filter(Doctor.id == doctor_id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    return doctor


@router.get("/appointments", response_model=list[AppointmentResponse])
def list_appointments(
    patient_id: int | None = None,
    doctor_id: int | None = None,
    status_filter: AppointmentStatus | None = None,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    query = db.query(Appointment).options(
        joinedload(Appointment.patient),
        joinedload(Appointment.doctor),
        joinedload(Appointment.intake_form),
    )
    if patient_id:
        query = query.filter(Appointment.patient_id == patient_id)
    if doctor_id:
        query = query.filter(Appointment.doctor_id == doctor_id)
    if status_filter:
        query = query.filter(Appointment.status == status_filter)
    appointments = query.order_by(Appointment.scheduled_at).all()
    return [_appointment_response(a) for a in appointments]


@router.post("/appointments", response_model=AppointmentResponse, status_code=201)
def create_appointment(
    payload: AppointmentCreate,
    request: Request,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    from apps.api.models import AvailabilitySlot

    slot = db.query(AvailabilitySlot).filter(AvailabilitySlot.id == payload.slot_id).first()
    if not slot:
        raise HTTPException(status_code=404, detail="Slot not found")
    if slot.is_booked:
        raise HTTPException(status_code=400, detail="Slot already booked")
    if slot.doctor_id != payload.doctor_id:
        raise HTTPException(status_code=400, detail="Slot does not belong to doctor")

    appointment = Appointment(
        patient_id=payload.patient_id,
        doctor_id=payload.doctor_id,
        slot_id=payload.slot_id,
        scheduled_at=slot.start_time,
        reason_for_visit=payload.reason_for_visit,
    )
    slot.is_booked = True
    db.add(appointment)
    db.commit()
    db.refresh(appointment)
    appointment = (
        db.query(Appointment)
        .options(
            joinedload(Appointment.patient),
            joinedload(Appointment.doctor),
            joinedload(Appointment.intake_form),
        )
        .filter(Appointment.id == appointment.id)
        .first()
    )
    log_audit(
        db,
        action="appointment_created",
        resource_type="appointment",
        user_id=user.id,
        resource_id=str(appointment.id),
        details={"patient_id": payload.patient_id, "doctor_id": payload.doctor_id},
        ip_address=get_client_ip(request),
    )
    return _appointment_response(appointment)


@router.patch("/appointments/{appointment_id}", response_model=AppointmentResponse)
def update_appointment(
    appointment_id: int,
    payload: AppointmentUpdate,
    request: Request,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles(UserRole.DOCTOR, UserRole.RECEPTIONIST, UserRole.ADMIN)),
):
    appointment = (
        db.query(Appointment)
        .options(
            joinedload(Appointment.patient),
            joinedload(Appointment.doctor),
            joinedload(Appointment.intake_form),
        )
        .filter(Appointment.id == appointment_id)
        .first()
    )
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(appointment, field, value)
    db.commit()
    db.refresh(appointment)
    log_audit(
        db,
        action="appointment_updated",
        resource_type="appointment",
        user_id=user.id,
        resource_id=str(appointment_id),
        details=payload.model_dump(exclude_unset=True),
        ip_address=get_client_ip(request),
    )
    return _appointment_response(appointment)


@router.get("/doctors/{doctor_id}/schedule", response_model=list[AppointmentResponse])
def doctor_schedule(
    doctor_id: int,
    schedule_date: date | None = None,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles(UserRole.DOCTOR, UserRole.RECEPTIONIST, UserRole.ADMIN)),
):
    target_date = schedule_date or date.today()
    start = datetime.combine(target_date, datetime.min.time())
    end = start + timedelta(days=1)
    appointments = (
        db.query(Appointment)
        .options(
            joinedload(Appointment.patient),
            joinedload(Appointment.doctor),
            joinedload(Appointment.intake_form),
        )
        .filter(
            Appointment.doctor_id == doctor_id,
            Appointment.scheduled_at >= start,
            Appointment.scheduled_at < end,
        )
        .order_by(Appointment.scheduled_at)
        .all()
    )
    return [_appointment_response(a) for a in appointments]


@router.get("/escalations", response_model=list[EscalationResponse])
def list_escalations(
    resolved: bool | None = False,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles(UserRole.DOCTOR, UserRole.RECEPTIONIST, UserRole.ADMIN)),
):
    query = db.query(Escalation)
    if resolved is not None:
        query = query.filter(Escalation.resolved == resolved)
    escalations = query.order_by(Escalation.created_at.desc()).all()
    results = []
    for esc in escalations:
        patient_name = None
        if esc.patient_id:
            patient = db.query(Patient).filter(Patient.id == esc.patient_id).first()
            if patient:
                patient_name = f"{patient.first_name} {patient.last_name}"
        results.append(
            EscalationResponse(
                id=esc.id,
                reason=esc.reason,
                urgency=esc.urgency,
                resolved=esc.resolved,
                patient_name=patient_name,
                created_at=esc.created_at,
            )
        )
    return results


@router.patch("/escalations/{escalation_id}/resolve")
def resolve_escalation(
    escalation_id: int,
    request: Request,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles(UserRole.DOCTOR, UserRole.RECEPTIONIST, UserRole.ADMIN)),
):
    escalation = db.query(Escalation).filter(Escalation.id == escalation_id).first()
    if not escalation:
        raise HTTPException(status_code=404, detail="Escalation not found")
    escalation.resolved = True
    escalation.resolved_by = user.id
    db.commit()
    log_audit(
        db,
        action="escalation_resolved",
        resource_type="escalation",
        user_id=user.id,
        resource_id=str(escalation_id),
        ip_address=get_client_ip(request),
    )
    return {"status": "resolved"}

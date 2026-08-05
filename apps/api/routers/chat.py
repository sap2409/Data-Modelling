from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session, joinedload

from apps.api.deps import get_client_ip, get_optional_user, log_audit
from apps.api.database import get_db
from apps.api.models import Appointment, IntakeForm, User
from apps.api.schemas import (
    ChatRequest,
    ChatResponse,
    HospitalInfoResponse,
    IntakeFormCreate,
    IntakeFormResponse,
)
from ai.agent import ReceptionistAgent

router = APIRouter()


HOSPITAL_INFO = HospitalInfoResponse(
    name="CityCare General Hospital",
    address="123 Medical Center Drive, Springfield, IL 62701",
    phone="(555) 123-4567",
    hours="Monday–Friday 8:00 AM – 6:00 PM, Saturday 9:00 AM – 1:00 PM",
    departments=["General Medicine", "Cardiology", "Pediatrics", "Orthopedics", "Dermatology"],
    insurance_accepted=["Blue Cross", "Aetna", "UnitedHealthcare", "Medicare", "Medicaid"],
)


@router.get("/info", response_model=HospitalInfoResponse)
def hospital_info():
    return HOSPITAL_INFO


@router.post("/chat", response_model=ChatResponse)
async def chat(
    payload: ChatRequest,
    request: Request,
    db: Session = Depends(get_db),
    user: User | None = Depends(get_optional_user),
):
    agent = ReceptionistAgent(db)
    result = await agent.handle_message(
        message=payload.message,
        session_id=payload.session_id,
        patient_id=payload.patient_id,
        user=user,
    )
    log_audit(
        db,
        action="chat_message",
        resource_type="conversation",
        user_id=user.id if user else None,
        resource_id=result["session_id"],
        details={
            "tool_calls": result.get("tool_calls_made", []),
            "escalated": result.get("escalated", False),
        },
        ip_address=get_client_ip(request),
    )
    return ChatResponse(**result)


@router.post("/appointments/{appointment_id}/intake", response_model=IntakeFormResponse, status_code=201)
def submit_intake(
    appointment_id: int,
    payload: IntakeFormCreate,
    request: Request,
    db: Session = Depends(get_db),
    user: User | None = Depends(get_optional_user),
):
    appointment = (
        db.query(Appointment)
        .options(joinedload(Appointment.patient), joinedload(Appointment.doctor))
        .filter(Appointment.id == appointment_id)
        .first()
    )
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    if appointment.intake_form:
        raise HTTPException(status_code=400, detail="Intake already submitted")

    prep_summary = _generate_prep_summary(appointment, payload)
    intake = IntakeForm(
        appointment_id=appointment_id,
        symptoms_summary=payload.symptoms_summary,
        medications=payload.medications,
        allergies=payload.allergies,
        additional_notes=payload.additional_notes,
        prep_summary=prep_summary,
    )
    db.add(intake)
    db.commit()
    db.refresh(intake)
    log_audit(
        db,
        action="intake_submitted",
        resource_type="intake_form",
        user_id=user.id if user else None,
        resource_id=str(intake.id),
        details={"appointment_id": appointment_id},
        ip_address=get_client_ip(request),
    )
    return intake


@router.get("/appointments/{appointment_id}/intake", response_model=IntakeFormResponse)
def get_intake(appointment_id: int, db: Session = Depends(get_db)):
    intake = db.query(IntakeForm).filter(IntakeForm.appointment_id == appointment_id).first()
    if not intake:
        raise HTTPException(status_code=404, detail="Intake not found")
    return intake


def _generate_prep_summary(appointment: Appointment, intake: IntakeFormCreate) -> str:
    patient = appointment.patient
    doctor = appointment.doctor
    lines = [
        f"Patient: {patient.first_name} {patient.last_name} (DOB: {patient.date_of_birth})",
        f"Appointment with Dr. {doctor.first_name} {doctor.last_name} ({doctor.specialty})",
        f"Scheduled: {appointment.scheduled_at.strftime('%B %d, %Y at %I:%M %p')}",
        f"Reason for visit: {appointment.reason_for_visit or 'Not specified'}",
    ]
    if intake.symptoms_summary:
        lines.append(f"Symptoms: {intake.symptoms_summary}")
    if intake.medications:
        lines.append(f"Current medications: {intake.medications}")
    if intake.allergies:
        lines.append(f"Allergies: {intake.allergies}")
    if intake.additional_notes:
        lines.append(f"Additional notes: {intake.additional_notes}")
    lines.append("Please review intake details before the visit. This summary is for preparation only.")
    return "\n".join(lines)

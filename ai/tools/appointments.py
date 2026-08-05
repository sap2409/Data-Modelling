from datetime import date, datetime, timedelta
from typing import Any

from sqlalchemy.orm import Session, joinedload

from apps.api.models import (
    Appointment,
    AppointmentStatus,
    AvailabilitySlot,
    Conversation,
    Doctor,
    Escalation,
    EscalationUrgency,
    IntakeForm,
    Patient,
)

TOOL_DEFINITIONS = [
    {
        "type": "function",
        "function": {
            "name": "search_doctors",
            "description": "Search for doctors by name or specialty",
            "parameters": {
                "type": "object",
                "properties": {
                    "name": {"type": "string", "description": "Doctor name (partial match)"},
                    "specialty": {"type": "string", "description": "Medical specialty"},
                },
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "check_availability",
            "description": "Check available appointment slots for a doctor",
            "parameters": {
                "type": "object",
                "properties": {
                    "doctor_id": {"type": "integer", "description": "Doctor ID"},
                    "date_from": {"type": "string", "description": "Start date (YYYY-MM-DD)"},
                    "date_to": {"type": "string", "description": "End date (YYYY-MM-DD), optional"},
                },
                "required": ["doctor_id", "date_from"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "book_appointment",
            "description": "Book an appointment for a patient",
            "parameters": {
                "type": "object",
                "properties": {
                    "patient_id": {"type": "integer"},
                    "doctor_id": {"type": "integer"},
                    "slot_id": {"type": "integer"},
                    "reason_for_visit": {"type": "string"},
                },
                "required": ["patient_id", "doctor_id", "slot_id"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_patient_appointments",
            "description": "Get upcoming appointments for a patient",
            "parameters": {
                "type": "object",
                "properties": {
                    "patient_id": {"type": "integer"},
                },
                "required": ["patient_id"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "find_patient",
            "description": "Find a patient by email or phone",
            "parameters": {
                "type": "object",
                "properties": {
                    "email": {"type": "string"},
                    "phone": {"type": "string"},
                },
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "escalate_to_human",
            "description": "Escalate to a human receptionist or staff member",
            "parameters": {
                "type": "object",
                "properties": {
                    "reason": {"type": "string"},
                    "urgency": {
                        "type": "string",
                        "enum": ["low", "medium", "high", "emergency"],
                    },
                    "patient_id": {"type": "integer"},
                },
                "required": ["reason", "urgency"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_doctor_schedule",
            "description": "Get a doctor's schedule for a given date",
            "parameters": {
                "type": "object",
                "properties": {
                    "doctor_id": {"type": "integer"},
                    "date": {"type": "string", "description": "Date (YYYY-MM-DD)"},
                },
                "required": ["doctor_id"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_patient_prep_summary",
            "description": "Get prep summary for an upcoming appointment",
            "parameters": {
                "type": "object",
                "properties": {
                    "appointment_id": {"type": "integer"},
                },
                "required": ["appointment_id"],
            },
        },
    },
]


class ToolExecutor:
    def __init__(self, db: Session, conversation_id: int | None = None):
        self.db = db
        self.conversation_id = conversation_id
        self.escalated = False

    def execute(self, name: str, arguments: dict[str, Any]) -> str:
        handler = getattr(self, f"_tool_{name}", None)
        if not handler:
            return f"Unknown tool: {name}"
        return handler(**arguments)

    def _tool_search_doctors(self, name: str | None = None, specialty: str | None = None) -> str:
        query = self.db.query(Doctor)
        if name:
            pattern = f"%{name}%"
            query = query.filter(
                (Doctor.first_name.ilike(pattern)) | (Doctor.last_name.ilike(pattern))
            )
        if specialty:
            query = query.filter(Doctor.specialty.ilike(f"%{specialty}%"))
        doctors = query.all()
        if not doctors:
            return "No doctors found matching your criteria."
        lines = []
        for d in doctors:
            lines.append(
                f"ID {d.id}: Dr. {d.first_name} {d.last_name} — {d.specialty} ({d.department})"
            )
        return "\n".join(lines)

    def _tool_check_availability(
        self, doctor_id: int, date_from: str, date_to: str | None = None
    ) -> str:
        start = datetime.strptime(date_from, "%Y-%m-%d")
        end = datetime.strptime(date_to, "%Y-%m-%d") + timedelta(days=1) if date_to else start + timedelta(days=7)
        slots = (
            self.db.query(AvailabilitySlot)
            .filter(
                AvailabilitySlot.doctor_id == doctor_id,
                AvailabilitySlot.is_booked == False,
                AvailabilitySlot.start_time >= start,
                AvailabilitySlot.start_time < end,
            )
            .order_by(AvailabilitySlot.start_time)
            .limit(20)
            .all()
        )
        if not slots:
            return f"No available slots for doctor {doctor_id} in the requested range."
        lines = []
        for s in slots:
            lines.append(
                f"Slot {s.id}: {s.start_time.strftime('%Y-%m-%d %I:%M %p')} - {s.end_time.strftime('%I:%M %p')}"
            )
        return "\n".join(lines)

    def _tool_book_appointment(
        self,
        patient_id: int,
        doctor_id: int,
        slot_id: int,
        reason_for_visit: str | None = None,
    ) -> str:
        slot = self.db.query(AvailabilitySlot).filter(AvailabilitySlot.id == slot_id).first()
        if not slot:
            return "Slot not found."
        if slot.is_booked:
            return "That slot is no longer available. Please choose another."
        if slot.doctor_id != doctor_id:
            return "Slot does not belong to the specified doctor."

        appointment = Appointment(
            patient_id=patient_id,
            doctor_id=doctor_id,
            slot_id=slot_id,
            scheduled_at=slot.start_time,
            reason_for_visit=reason_for_visit,
            status=AppointmentStatus.SCHEDULED,
        )
        slot.is_booked = True
        self.db.add(appointment)
        self.db.commit()
        self.db.refresh(appointment)
        doctor = self.db.query(Doctor).filter(Doctor.id == doctor_id).first()
        return (
            f"Appointment booked! ID: {appointment.id}, "
            f"Dr. {doctor.first_name} {doctor.last_name} on "
            f"{slot.start_time.strftime('%B %d, %Y at %I:%M %p')}. "
            f"Please complete your intake form before the visit."
        )

    def _tool_get_patient_appointments(self, patient_id: int) -> str:
        appointments = (
            self.db.query(Appointment)
            .options(joinedload(Appointment.doctor))
            .filter(
                Appointment.patient_id == patient_id,
                Appointment.status.in_([AppointmentStatus.SCHEDULED, AppointmentStatus.CHECKED_IN]),
                Appointment.scheduled_at >= datetime.utcnow(),
            )
            .order_by(Appointment.scheduled_at)
            .all()
        )
        if not appointments:
            return "No upcoming appointments found."
        lines = []
        for a in appointments:
            lines.append(
                f"ID {a.id}: Dr. {a.doctor.first_name} {a.doctor.last_name} on "
                f"{a.scheduled_at.strftime('%B %d, %Y at %I:%M %p')} — {a.status.value}"
                f"{f' ({a.reason_for_visit})' if a.reason_for_visit else ''}"
            )
        return "\n".join(lines)

    def _tool_find_patient(self, email: str | None = None, phone: str | None = None) -> str:
        query = self.db.query(Patient)
        if email:
            query = query.filter(Patient.email.ilike(email))
        elif phone:
            query = query.filter(Patient.phone.ilike(f"%{phone}%"))
        else:
            return "Please provide email or phone to find patient."
        patient = query.first()
        if not patient:
            return "Patient not found."
        return (
            f"Found patient ID {patient.id}: {patient.first_name} {patient.last_name}, "
            f"DOB {patient.date_of_birth}, phone {patient.phone}"
        )

    def _tool_escalate_to_human(
        self,
        reason: str,
        urgency: str,
        patient_id: int | None = None,
    ) -> str:
        self.escalated = True
        escalation = Escalation(
            conversation_id=self.conversation_id,
            patient_id=patient_id,
            reason=reason,
            urgency=EscalationUrgency(urgency),
        )
        self.db.add(escalation)
        self.db.commit()
        if urgency == "emergency":
            return (
                "EMERGENCY ESCALATION: Please call 911 immediately if this is a life-threatening "
                "emergency. A staff member has been notified and will contact you shortly."
            )
        return f"Your request has been escalated to our staff ({urgency} priority). Someone will assist you shortly."

    def _tool_get_doctor_schedule(self, doctor_id: int, date: str | None = None) -> str:
        target = datetime.strptime(date, "%Y-%m-%d").date() if date else datetime.utcnow().date()
        start = datetime.combine(target, datetime.min.time())
        end = start + timedelta(days=1)
        appointments = (
            self.db.query(Appointment)
            .options(joinedload(Appointment.patient), joinedload(Appointment.intake_form))
            .filter(
                Appointment.doctor_id == doctor_id,
                Appointment.scheduled_at >= start,
                Appointment.scheduled_at < end,
            )
            .order_by(Appointment.scheduled_at)
            .all()
        )
        doctor = self.db.query(Doctor).filter(Doctor.id == doctor_id).first()
        if not doctor:
            return "Doctor not found."
        if not appointments:
            return f"No appointments for Dr. {doctor.last_name} on {target}."
        lines = [f"Schedule for Dr. {doctor.first_name} {doctor.last_name} on {target}:"]
        for a in appointments:
            intake_status = "Intake complete" if a.intake_form else "Intake pending"
            lines.append(
                f"  {a.scheduled_at.strftime('%I:%M %p')} — {a.patient.first_name} {a.patient.last_name} "
                f"({a.reason_for_visit or 'No reason'}) [{intake_status}]"
            )
        return "\n".join(lines)

    def _tool_get_patient_prep_summary(self, appointment_id: int) -> str:
        appointment = (
            self.db.query(Appointment)
            .options(
                joinedload(Appointment.patient),
                joinedload(Appointment.doctor),
                joinedload(Appointment.intake_form),
            )
            .filter(Appointment.id == appointment_id)
            .first()
        )
        if not appointment:
            return "Appointment not found."
        if appointment.intake_form and appointment.intake_form.prep_summary:
            return appointment.intake_form.prep_summary
        patient = appointment.patient
        doctor = appointment.doctor
        return (
            f"Patient: {patient.first_name} {patient.last_name} (DOB: {patient.date_of_birth})\n"
            f"Appointment with Dr. {doctor.first_name} {doctor.last_name} ({doctor.specialty})\n"
            f"Scheduled: {appointment.scheduled_at.strftime('%B %d, %Y at %I:%M %p')}\n"
            f"Reason: {appointment.reason_for_visit or 'Not specified'}\n"
            f"Intake: {'Pending — patient has not submitted intake form' if not appointment.intake_form else 'See intake form'}"
        )

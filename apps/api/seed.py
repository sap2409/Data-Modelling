from datetime import date, datetime, timedelta

from sqlalchemy.orm import Session

from apps.api.auth import create_user, get_password_hash
from apps.api.database import SessionLocal
from apps.api.models import (
    Appointment,
    AppointmentStatus,
    AvailabilitySlot,
    Doctor,
    Patient,
    User,
    UserRole,
)


def seed_database() -> None:
    db = SessionLocal()
    try:
        if db.query(Doctor).count() > 0:
            return
        _seed_users(db)
        _seed_doctors(db)
        _seed_patients(db)
        _seed_slots(db)
        _seed_appointments(db)
        db.commit()
    finally:
        db.close()


def _seed_users(db: Session) -> None:
    users = [
        ("admin@citycare.com", "admin123", "System Admin", UserRole.ADMIN),
        ("reception@citycare.com", "reception123", "Jane Receptionist", UserRole.RECEPTIONIST),
        ("dr.smith@citycare.com", "doctor123", "Dr. James Smith", UserRole.DOCTOR),
        ("dr.patel@citycare.com", "doctor123", "Dr. Priya Patel", UserRole.DOCTOR),
        ("dr.lee@citycare.com", "doctor123", "Dr. Sarah Lee", UserRole.DOCTOR),
        ("alice@email.com", "patient123", "Alice Johnson", UserRole.PATIENT),
        ("bob@email.com", "patient123", "Bob Williams", UserRole.PATIENT),
    ]
    for email, password, name, role in users:
        if not db.query(User).filter(User.email == email).first():
            create_user(db, email, password, name, role)


def _seed_doctors(db: Session) -> None:
    doctors_data = [
        ("James", "Smith", "General Medicine", "Primary Care", "dr.smith@citycare.com"),
        ("Priya", "Patel", "Cardiology", "Heart Center", "dr.patel@citycare.com"),
        ("Sarah", "Lee", "Pediatrics", "Children's Health", "dr.lee@citycare.com"),
    ]
    for first, last, specialty, dept, email in doctors_data:
        user = db.query(User).filter(User.email == email).first()
        doctor = Doctor(
            user_id=user.id if user else None,
            first_name=first,
            last_name=last,
            specialty=specialty,
            department=dept,
        )
        db.add(doctor)
    db.flush()


def _seed_patients(db: Session) -> None:
    patients_data = [
        ("Alice", "Johnson", date(1990, 3, 15), "555-0101", "alice@email.com", "Blue Cross"),
        ("Bob", "Williams", date(1985, 7, 22), "555-0102", "bob@email.com", "Aetna"),
        ("Carol", "Davis", date(1978, 11, 8), "555-0103", "carol@email.com", "Medicare"),
        ("David", "Miller", date(1995, 1, 30), "555-0104", "david@email.com", "UnitedHealthcare"),
        ("Emma", "Wilson", date(2000, 6, 12), "555-0105", "emma@email.com", "Medicaid"),
        ("Frank", "Moore", date(1962, 9, 5), "555-0106", "frank@email.com", "Blue Cross"),
        ("Grace", "Taylor", date(1988, 4, 18), "555-0107", "grace@email.com", "Aetna"),
        ("Henry", "Anderson", date(1975, 12, 25), "555-0108", "henry@email.com", "Medicare"),
        ("Ivy", "Thomas", date(1992, 8, 3), "555-0109", "ivy@email.com", "Blue Cross"),
        ("Jack", "Jackson", date(1980, 2, 14), "555-0110", "jack@email.com", "UnitedHealthcare"),
        ("Karen", "White", date(1998, 10, 7), "555-0111", "karen@email.com", "Aetna"),
        ("Leo", "Harris", date(1955, 5, 20), "555-0112", "leo@email.com", "Medicare"),
        ("Mia", "Martin", date(2005, 3, 9), "555-0113", "mia@email.com", "Medicaid"),
        ("Noah", "Garcia", date(1993, 7, 16), "555-0114", "noah@email.com", "Blue Cross"),
        ("Olivia", "Martinez", date(1987, 11, 28), "555-0115", "olivia@email.com", "Aetna"),
        ("Paul", "Robinson", date(1970, 1, 11), "555-0116", "paul@email.com", "UnitedHealthcare"),
        ("Quinn", "Clark", date(1999, 9, 2), "555-0117", "quinn@email.com", "Blue Cross"),
        ("Rachel", "Lewis", date(1983, 6, 19), "555-0118", "rachel@email.com", "Medicare"),
        ("Sam", "Walker", date(1991, 4, 27), "555-0119", "sam@email.com", "Aetna"),
        ("Tina", "Hall", date(1977, 8, 14), "555-0120", "tina@email.com", "UnitedHealthcare"),
    ]
    for first, last, dob, phone, email, insurance in patients_data:
        user = db.query(User).filter(User.email == email).first()
        patient = Patient(
            user_id=user.id if user else None,
            first_name=first,
            last_name=last,
            date_of_birth=dob,
            phone=phone,
            email=email,
            insurance_provider=insurance,
        )
        db.add(patient)
    db.flush()


def _seed_slots(db: Session) -> None:
    doctors = db.query(Doctor).all()
    base_date = date.today() + timedelta(days=1)
    for day_offset in range(14):
        current_date = base_date + timedelta(days=day_offset)
        if current_date.weekday() >= 6:
            continue
        for doctor in doctors:
            for hour in [9, 10, 11, 14, 15, 16]:
                start = datetime.combine(current_date, datetime.min.time().replace(hour=hour))
                end = start + timedelta(minutes=30)
                slot = AvailabilitySlot(
                    doctor_id=doctor.id,
                    start_time=start,
                    end_time=end,
                    is_booked=False,
                )
                db.add(slot)
    db.flush()


def _seed_appointments(db: Session) -> None:
    patients = db.query(Patient).limit(5).all()
    doctors = db.query(Doctor).all()
    today = date.today()
    for i, patient in enumerate(patients):
        doctor = doctors[i % len(doctors)]
        scheduled = datetime.combine(today, datetime.min.time().replace(hour=9 + i))
        appointment = Appointment(
            patient_id=patient.id,
            doctor_id=doctor.id,
            scheduled_at=scheduled,
            status=AppointmentStatus.SCHEDULED,
            reason_for_visit=["Annual checkup", "Follow-up", "Chest pain evaluation", "Child wellness visit", "Skin rash"][i],
        )
        db.add(appointment)

"""Security utilities for HIPAA-ready hardening path."""

from fastapi import Request
from sqlalchemy.orm import Session

from apps.api.deps import get_client_ip, log_audit
from apps.api.models import User


def audit_phi_access(
    db: Session,
    user: User | None,
    action: str,
    resource_type: str,
    resource_id: str,
    request: Request | None = None,
    details: dict | None = None,
) -> None:
    """Log access to protected health information (PHI)."""
    log_audit(
        db,
        action=action,
        resource_type=resource_type,
        user_id=user.id if user else None,
        resource_id=resource_id,
        details={**(details or {}), "phi_access": True},
        ip_address=get_client_ip(request) if request else None,
    )


HIPAA_HARDENING_CHECKLIST = [
    "Execute BAAs with cloud and LLM vendors before processing real PHI",
    "Enable encryption at rest (database, backups) and in transit (TLS 1.2+)",
    "Implement session timeouts and MFA for staff accounts",
    "Add row-level access controls so patients only see their own data",
    "Enable comprehensive audit logging with tamper-evident storage",
    "Define data retention and secure deletion policies",
    "Conduct regular security risk assessments",
    "Use de-identified or synthetic data in development environments",
    "Restrict LLM prompts to minimum necessary PHI",
    "Implement breach notification procedures",
]

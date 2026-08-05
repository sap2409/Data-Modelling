from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from apps.api.deps import get_client_ip, log_audit, require_roles
from apps.api.database import get_db
from apps.api.models import AuditLog, User, UserRole
from apps.api.schemas import AuditLogResponse

router = APIRouter()


@router.get("/audit-logs", response_model=list[AuditLogResponse])
def list_audit_logs(
    limit: int = 100,
    db: Session = Depends(get_db),
    user: User = Depends(require_roles(UserRole.ADMIN)),
):
    logs = db.query(AuditLog).order_by(AuditLog.created_at.desc()).limit(limit).all()
    return logs

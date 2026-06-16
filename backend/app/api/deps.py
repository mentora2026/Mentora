import uuid

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import decode_token
from app.models import PatientProfile, User
from app.models.enums import UserRole

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="بيانات الاعتماد غير صالحة أو منتهية الصلاحية",
        headers={"WWW-Authenticate": "Bearer"},
    )

    payload = decode_token(token)
    if payload is None or payload.get("type") != "access":
        raise credentials_exception

    user_id = payload.get("sub")
    if user_id is None:
        raise credentials_exception

    try:
        user_uuid = uuid.UUID(user_id)
    except ValueError:
        raise credentials_exception

    user = db.query(User).filter(User.id == user_uuid).first()
    if user is None or not user.is_active:
        raise credentials_exception

    return user


def get_current_patient_profile(
    current_user: User = Depends(get_current_user), db: Session = Depends(get_db)
) -> PatientProfile:
    if current_user.role != UserRole.patient:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="هذا المورد متاح للمرضى فقط",
        )

    profile = db.query(PatientProfile).filter(PatientProfile.user_id == current_user.id).first()
    if profile is None:
        # Auto-create an empty profile on first access after registration
        profile = PatientProfile(user_id=current_user.id)
        db.add(profile)
        db.commit()
        db.refresh(profile)

    return profile


def require_admin(current_user: User = Depends(get_current_user)) -> User:
    if current_user.role not in (UserRole.admin, UserRole.clinical_supervisor):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="هذا المورد متاح للمسؤولين فقط",
        )
    return current_user

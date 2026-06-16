from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.models import PatientProfile, User
from app.models.enums import UserRole
from app.schemas.auth import (
    ChangePasswordRequest,
    RefreshTokenRequest,
    TokenResponse,
    UserCreate,
    UserLogin,
    UserOut,
)

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(payload: UserCreate, db: Session = Depends(get_db)):
    """
    Register a new patient account.

    Always creates a user with role `patient` and an associated (initially
    empty) `patient_profile`. Returns access + refresh tokens immediately -
    no separate login step is needed after registration.

    The client should next call `PUT /patients/me` and
    `POST /patients/me/conditions` to complete onboarding
    (`onboarding_completed` becomes `true` once `disease_duration_months` and
    `activity_level` are set).
    """
    existing = db.query(User).filter(User.email == payload.email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="يوجد حساب مسجل بهذا البريد الإلكتروني من قبل",
        )

    user = User(
        email=payload.email,
        password_hash=hash_password(payload.password),
        full_name=payload.full_name,
        phone_number=payload.phone_number,
        role=UserRole.patient,
    )
    db.add(user)
    db.flush()

    # Every patient gets an associated (initially empty) profile
    profile = PatientProfile(user_id=user.id)
    db.add(profile)
    db.commit()

    access_token = create_access_token(subject=str(user.id), role=user.role.value)
    refresh_token = create_refresh_token(subject=str(user.id))
    return TokenResponse(access_token=access_token, refresh_token=refresh_token)


@router.post("/login", response_model=TokenResponse)
def login(payload: UserLogin, db: Session = Depends(get_db)):
    """
    Log in with email and password. Returns access + refresh tokens.

    Works for all roles (`patient`, `admin`, `clinical_supervisor`) - the
    admin dashboard uses this same endpoint and rejects non-admin tokens
    client-side via `GET /auth/me`.
    """
    user = db.query(User).filter(User.email == payload.email).first()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="البريد الإلكتروني أو كلمة المرور غير صحيحة",
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="تم تعطيل هذا الحساب، يرجى التواصل مع الدعم",
        )

    access_token = create_access_token(subject=str(user.id), role=user.role.value)
    refresh_token = create_refresh_token(subject=str(user.id))
    return TokenResponse(access_token=access_token, refresh_token=refresh_token)


@router.post("/refresh", response_model=TokenResponse)
def refresh(payload: RefreshTokenRequest, db: Session = Depends(get_db)):
    token_data = decode_token(payload.refresh_token)
    if token_data is None or token_data.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="رمز التحديث غير صالح أو منتهي الصلاحية",
        )

    user = db.query(User).filter(User.id == token_data.get("sub")).first()
    if user is None or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="المستخدم غير موجود أو غير مفعل")

    access_token = create_access_token(subject=str(user.id), role=user.role.value)
    new_refresh_token = create_refresh_token(subject=str(user.id))
    return TokenResponse(access_token=access_token, refresh_token=new_refresh_token)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout():
    """
    Stateless JWT logout: the client discards its tokens.
    A token-blacklist (e.g., Redis) can be added later for hard invalidation.
    """
    return None


@router.post("/change-password", status_code=status.HTTP_204_NO_CONTENT)
def change_password(
    payload: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not verify_password(payload.current_password, current_user.password_hash):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="كلمة المرور الحالية غير صحيحة")

    current_user.password_hash = hash_password(payload.new_password)
    db.add(current_user)
    db.commit()
    return None


@router.get("/me", response_model=UserOut)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models import Notification, User, UserDevice
from app.schemas.extras import DeviceRegisterRequest, NotificationOut

router = APIRouter(tags=["Notifications"])


@router.get("/notifications", response_model=list[NotificationOut])
def list_notifications(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(Notification)
        .filter(Notification.user_id == current_user.id)
        .order_by(Notification.created_at.desc())
        .all()
    )


@router.post("/notifications/{notification_id}/read", status_code=status.HTTP_204_NO_CONTENT)
def mark_notification_read(
    notification_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    notification = (
        db.query(Notification)
        .filter(Notification.id == notification_id, Notification.user_id == current_user.id)
        .first()
    )
    if notification is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="الإشعار غير موجود")

    notification.is_read = True
    db.add(notification)
    db.commit()
    return None


@router.delete("/notifications/all", status_code=status.HTTP_204_NO_CONTENT)
def clear_all_notifications(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    db.query(Notification).filter(Notification.user_id == current_user.id).delete()
    db.commit()
    return None


@router.delete("/notifications/{notification_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_notification(
    notification_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    notification = (
        db.query(Notification)
        .filter(Notification.id == notification_id, Notification.user_id == current_user.id)
        .first()
    )
    if notification is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="الإشعار غير موجود")

    db.delete(notification)
    db.commit()
    return None


@router.post("/devices/register", status_code=status.HTTP_204_NO_CONTENT)
def register_device(
    payload: DeviceRegisterRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Check if token already exists
    existing_device = db.query(UserDevice).filter(UserDevice.fcm_token == payload.fcm_token).first()
    
    if existing_device:
        # If the token exists but belongs to a different user, update the user_id
        if existing_device.user_id != current_user.id:
            existing_device.user_id = current_user.id
            db.add(existing_device)
            db.commit()
    else:
        # Create a new device registration
        new_device = UserDevice(
            user_id=current_user.id,
            fcm_token=payload.fcm_token,
            device_type=payload.device_type,
        )
        db.add(new_device)
        db.commit()
        
    return None

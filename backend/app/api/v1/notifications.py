from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models import Notification, User
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


@router.post("/devices/register", status_code=status.HTTP_204_NO_CONTENT)
def register_device(
    payload: DeviceRegisterRequest,
    current_user: User = Depends(get_current_user),
):
    """
    Registers an FCM device token for push notifications.

    NOTE (future step): persist the token (e.g., in a `user_devices` table)
    and wire up the FCM sending service. For Step 2 this endpoint validates
    the request shape and is ready for that integration.
    """
    return None

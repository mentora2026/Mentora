import logging
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from sqlalchemy.orm import Session
from sqlalchemy import create_engine
from app.core.config import settings
from app.models import UserDevice, Notification, User
from app.models.enums import NotificationType, UserRole
from app.core.firebase import send_push_notification
from app.core.database import SessionLocal

logger = logging.getLogger(__name__)

scheduler = AsyncIOScheduler()

def send_notifications_to_patients(title: str, body: str, type: NotificationType):
    """
    Helper function to send a notification to all patients.
    """
    db: Session = SessionLocal()
    try:
        patients = db.query(User).filter(User.role == UserRole.patient).all()
        for patient in patients:
            # Create DB notification
            notif = Notification(
                user_id=patient.id,
                type=type,
                title_ar=title,
                body_ar=body,
            )
            db.add(notif)
            
            # Send Push Notification
            devices = db.query(UserDevice).filter(UserDevice.user_id == patient.id).all()
            for device in devices:
                send_push_notification(
                    token=device.fcm_token,
                    title=title,
                    body=body,
                )
        db.commit()
    except Exception as e:
        logger.error(f"Error sending scheduled notifications: {e}")
        db.rollback()
    finally:
        db.close()

def job_remind_mood():
    """
    Job to remind patients to log their mood.
    Runs 3 times a day.
    """
    logger.info("Running scheduled job: Mood Reminder")
    send_notifications_to_patients(
        title="كيف حالك الآن؟",
        body="يرجى تسجيل حالتك المزاجية الحالية لنطمئن عليك.",
        type=NotificationType.daily_checkin
    )

def job_remind_interview():
    """
    Job to remind patients to have an interview session.
    Runs once a week.
    """
    logger.info("Running scheduled job: Interview Reminder")
    send_notifications_to_patients(
        title="وقت التقييم الأسبوعي",
        body="لقد حان وقت التقييم، تفضل بإجراء محادثة قصيرة معي لنطمئن على صحتك.",
        type=NotificationType.follow_up
    )

def start_scheduler():
    """
    Initializes and starts the APScheduler with predefined jobs.
    """
    # Mood reminder: 9 AM, 2 PM, 8 PM
    scheduler.add_job(
        job_remind_mood,
        CronTrigger(hour="9,14,20", minute="0"),
        id="mood_reminder_job",
        replace_existing=True
    )
    
    # Interview reminder: Every Friday at 10 AM (day_of_week=4 is Friday in APScheduler)
    scheduler.add_job(
        job_remind_interview,
        CronTrigger(day_of_week="fri", hour="10", minute="0"),
        id="interview_reminder_job",
        replace_existing=True
    )
    
    scheduler.start()
    logger.info("APScheduler started successfully.")

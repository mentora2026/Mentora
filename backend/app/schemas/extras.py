import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict

from app.models.enums import (
    ContentType,
    NotificationStatus,
    NotificationType,
    RecommendationCategory,
)


class RecommendationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    category: RecommendationCategory
    title_ar: str
    content_ar: str
    media_url: Optional[str] = None


class PatientRecommendationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    recommendation: RecommendationOut
    delivered_at: datetime
    is_viewed: bool
    is_helpful_feedback: Optional[bool] = None


class RecommendationFeedback(BaseModel):
    is_helpful: bool


class RecommendationCreate(BaseModel):
    category: RecommendationCategory
    chronic_condition_id: Optional[uuid.UUID] = None
    applicable_risk_levels: list[int]
    title_ar: str
    content_ar: str
    media_url: Optional[str] = None


class AdminRecommendationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    category: RecommendationCategory
    chronic_condition_id: Optional[uuid.UUID] = None
    applicable_risk_levels: list[int]
    title_ar: str
    content_ar: str
    media_url: Optional[str] = None
    is_active: bool
    created_at: datetime


class RecommendationUpdate(BaseModel):
    category: Optional[RecommendationCategory] = None
    chronic_condition_id: Optional[uuid.UUID] = None
    applicable_risk_levels: Optional[list[int]] = None
    title_ar: Optional[str] = None
    content_ar: Optional[str] = None
    media_url: Optional[str] = None
    is_active: Optional[bool] = None


class NotificationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    type: NotificationType
    title_ar: str
    body_ar: str
    is_read: bool
    status: NotificationStatus
    created_at: datetime


class DeviceRegisterRequest(BaseModel):
    fcm_token: str
    device_type: Optional[str] = None


class ContentLibraryCreate(BaseModel):
    content_type: ContentType
    key: str
    chronic_condition_id: Optional[uuid.UUID] = None
    title_ar: Optional[str] = None
    body_ar: str
    is_published: bool = True


class ContentLibraryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    content_type: ContentType
    key: str
    title_ar: Optional[str] = None
    body_ar: str
    is_published: bool

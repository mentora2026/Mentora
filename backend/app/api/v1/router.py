from fastapi import APIRouter

from app.api.v1 import (
    admin,
    auth,
    content,
    interviews,
    mood,
    notifications,
    patients,
    recommendations,
    reports,
    risk,
)

api_router = APIRouter()

api_router.include_router(auth.router)
api_router.include_router(patients.router)
api_router.include_router(interviews.router)
api_router.include_router(mood.router)
api_router.include_router(risk.router)
api_router.include_router(recommendations.router)
api_router.include_router(notifications.router)
api_router.include_router(reports.router)
api_router.include_router(admin.router)
api_router.include_router(content.router)

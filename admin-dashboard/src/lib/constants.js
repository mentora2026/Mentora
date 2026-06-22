// Backend API base URL.
//
// During development, the backend runs on http://localhost:8000 (see
// backend/docker-compose.yml). For production, set this via an environment
// variable at build time (Vite exposes import.meta.env.VITE_API_BASE_URL).
export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "http://localhost:8000/api/v1";

export const ENDPOINTS = {
  login: `${API_BASE_URL}/auth/login`,
  me: `${API_BASE_URL}/auth/me`,
  refresh: `${API_BASE_URL}/auth/refresh`,

  adminUsers: `${API_BASE_URL}/admin/users`,
  adminUserStatus: (id) => `${API_BASE_URL}/admin/users/${id}/status`,
  adminPatientDetail: (userId) => `${API_BASE_URL}/admin/users/${userId}/patient-detail`,
  sendDirectRecommendation: (patientProfileId) => `${API_BASE_URL}/admin/patients/${patientProfileId}/send-recommendation`,

  riskMonitoring: `${API_BASE_URL}/admin/risk-monitoring`,
  adminInterviewSession: (id) => `${API_BASE_URL}/admin/interviews/${id}`,

  adminRecommendations: `${API_BASE_URL}/admin/recommendations`,
  adminRecommendation: (id) => `${API_BASE_URL}/admin/recommendations/${id}`,

  adminContentLibrary: `${API_BASE_URL}/admin/content-library`,

  analyticsOverview: `${API_BASE_URL}/admin/analytics/overview`,
  auditLogs: `${API_BASE_URL}/admin/audit-logs`,

  chronicConditions: `${API_BASE_URL}/conditions`,
};

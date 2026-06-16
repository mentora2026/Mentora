import { ENDPOINTS } from "./constants";

const ACCESS_TOKEN_KEY = "admin_access_token";
const REFRESH_TOKEN_KEY = "admin_refresh_token";

export function getAccessToken() {
  return localStorage.getItem(ACCESS_TOKEN_KEY);
}

export function getRefreshToken() {
  return localStorage.getItem(REFRESH_TOKEN_KEY);
}

export function saveTokens({ access_token, refresh_token }) {
  localStorage.setItem(ACCESS_TOKEN_KEY, access_token);
  localStorage.setItem(REFRESH_TOKEN_KEY, refresh_token);
}

export function clearTokens() {
  localStorage.removeItem(ACCESS_TOKEN_KEY);
  localStorage.removeItem(REFRESH_TOKEN_KEY);
}

export class ApiError extends Error {
  constructor(status, messageAr) {
    super(messageAr);
    this.status = status;
    this.messageAr = messageAr;
  }
}

async function parseErrorMessage(response) {
  try {
    const data = await response.json();
    if (typeof data?.detail === "string") return data.detail;
    if (Array.isArray(data?.detail) && data.detail[0]?.msg) return data.detail[0].msg;
  } catch {
    // ignore JSON parse failures
  }
  return "حدث خطأ غير متوقع";
}

async function tryRefreshToken() {
  const refreshToken = getRefreshToken();
  if (!refreshToken) return false;

  try {
    const response = await fetch(ENDPOINTS.refresh, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refresh_token: refreshToken }),
    });
    if (!response.ok) return false;
    const data = await response.json();
    saveTokens(data);
    return true;
  } catch {
    return false;
  }
}

/**
 * Core request helper: attaches JWT, retries once after a token refresh on 401,
 * and throws ApiError with an Arabic message on failure.
 */
export async function apiRequest(url, { method = "GET", body, withAuth = true, isRetry = false } = {}) {
  const headers = { "Content-Type": "application/json" };
  if (withAuth) {
    const token = getAccessToken();
    if (token) headers["Authorization"] = `Bearer ${token}`;
  }

  let response;
  try {
    response = await fetch(url, {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
  } catch {
    throw new ApiError(0, "تعذر الاتصال بالخادم، تحقق من اتصال الإنترنت");
  }

  if (response.status === 401 && withAuth && !isRetry) {
    const refreshed = await tryRefreshToken();
    if (refreshed) {
      return apiRequest(url, { method, body, withAuth, isRetry: true });
    }
    clearTokens();
    throw new ApiError(401, "انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى");
  }

  if (response.status === 204) return null;

  if (!response.ok) {
    const messageAr = await parseErrorMessage(response);
    throw new ApiError(response.status, messageAr);
  }

  const text = await response.text();
  return text ? JSON.parse(text) : null;
}

export const api = {
  get: (url) => apiRequest(url, { method: "GET" }),
  post: (url, body) => apiRequest(url, { method: "POST", body }),
  put: (url, body) => apiRequest(url, { method: "PUT", body }),
  patch: (url, body) => apiRequest(url, { method: "PATCH", body }),
  delete: (url) => apiRequest(url, { method: "DELETE" }),
};

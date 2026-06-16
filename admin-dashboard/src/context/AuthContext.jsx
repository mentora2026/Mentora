import { createContext, useCallback, useContext, useEffect, useState } from "react";
import { api, clearTokens, getAccessToken, saveTokens } from "../lib/api";
import { ENDPOINTS } from "../lib/constants";

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [status, setStatus] = useState("loading"); // loading | authenticated | unauthenticated
  const [error, setError] = useState(null);

  const loadUser = useCallback(async () => {
    if (!getAccessToken()) {
      setStatus("unauthenticated");
      return;
    }
    try {
      const me = await api.get(ENDPOINTS.me);
      if (me.role !== "admin" && me.role !== "clinical_supervisor") {
        clearTokens();
        setError("هذا الحساب لا يملك صلاحية الوصول إلى لوحة التحكم");
        setStatus("unauthenticated");
        return;
      }
      setUser(me);
      setStatus("authenticated");
    } catch {
      clearTokens();
      setStatus("unauthenticated");
    }
  }, []);

  useEffect(() => {
    loadUser();
  }, [loadUser]);

  const login = useCallback(
    async (email, password) => {
      setError(null);
      try {
        const tokens = await api.post(ENDPOINTS.login, { email, password });
        saveTokens(tokens);
        await loadUser();
        return true;
      } catch (err) {
        setError(err.messageAr || "حدث خطأ غير متوقع");
        return false;
      }
    },
    [loadUser]
  );

  const logout = useCallback(() => {
    clearTokens();
    setUser(null);
    setStatus("unauthenticated");
  }, []);

  return (
    <AuthContext.Provider value={{ user, status, error, login, logout }}>{children}</AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}

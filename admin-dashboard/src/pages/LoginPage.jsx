import { useState } from "react";
import { Navigate, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

export default function LoginPage() {
  const { login, status, error } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [submitting, setSubmitting] = useState(false);

  if (status === "authenticated") {
    return <Navigate to="/" replace />;
  }

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    const success = await login(email, password);
    setSubmitting(false);
    if (success) navigate("/");
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-paper px-4">
      <div className="w-full max-w-sm">
        <div className="mb-8 flex flex-col items-center text-center">
          <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-lg bg-teal">
            <svg viewBox="0 0 32 32" className="h-6 w-6" aria-hidden="true">
              <rect x="2" y="6" width="4" height="20" rx="2" fill="#4F8A5B" />
              <rect x="9" y="9" width="4" height="17" rx="2" fill="#8BAA4E" />
              <rect x="16" y="4" width="4" height="22" rx="2" fill="#D4A12C" />
              <rect x="23" y="11" width="4" height="15" rx="2" fill="#C1432E" />
            </svg>
          </div>
          <h1 className="font-display text-2xl text-ink">لوحة تحكم منصة الدعم النفسي</h1>
          <p className="mt-1 text-sm text-sage">دخول فريق الإدارة والمتابعة السريرية</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4 rounded-lg border border-line bg-white p-6">
          <div>
            <label htmlFor="email" className="mb-1.5 block text-sm font-medium text-ink">
              البريد الإلكتروني
            </label>
            <input
              id="email"
              type="email"
              required
              dir="ltr"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full rounded border border-line bg-paper px-3 py-2 text-sm text-ink outline-none transition focus:border-teal"
              placeholder="admin@platform.example"
            />
          </div>
          <div>
            <label htmlFor="password" className="mb-1.5 block text-sm font-medium text-ink">
              كلمة المرور
            </label>
            <input
              id="password"
              type="password"
              required
              dir="ltr"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full rounded border border-line bg-paper px-3 py-2 text-sm text-ink outline-none transition focus:border-teal"
              placeholder="••••••••"
            />
          </div>

          {error && <p className="text-sm text-terracotta">{error}</p>}

          <button
            type="submit"
            disabled={submitting}
            className="w-full rounded bg-teal py-2.5 text-sm font-medium text-paper transition hover:bg-teal-600 disabled:opacity-60"
          >
            {submitting ? "جارِ تسجيل الدخول..." : "تسجيل الدخول"}
          </button>
        </form>

        <p className="mt-6 text-center text-xs text-sage">
          هذه اللوحة مخصصة للمسؤولين والمشرفين السريريين فقط.
        </p>
      </div>
    </div>
  );
}

import { NavLink, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { USER_ROLE_LABELS } from "../lib/format";

const NAV_ITEMS = [
  { to: "/", label: "نظرة عامة", icon: OverviewIcon },
  { to: "/risk-monitoring", label: "مراقبة الخطر", icon: RiskIcon },
  { to: "/users", label: "المستخدمون", icon: UsersIcon },
  { to: "/recommendations", label: "التوصيات", icon: LightbulbIcon },
  { to: "/content-library", label: "المحتوى التعليمي", icon: BookIcon },
  { to: "/audit-logs", label: "سجل التدقيق", icon: AuditIcon },
];

export function AppShell({ children, title, description }) {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  return (
    <div className="flex min-h-screen bg-paper">
      {/* Sidebar - sits on the right in RTL */}
      <aside className="flex w-64 flex-col border-l border-line bg-teal text-paper">
        <div className="flex items-center gap-3 px-6 py-6">
          <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded bg-paper/10">
            <RiskSpineMark />
          </div>
          <div>
            <p className="font-display text-base leading-tight">لوحة التحكم</p>
            <p className="text-[11px] text-paper/60">منصة الدعم النفسي</p>
          </div>
        </div>

        <nav className="flex-1 space-y-1 px-3 py-2">
          {NAV_ITEMS.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === "/"}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded px-3 py-2.5 text-sm transition ${
                  isActive ? "bg-paper/10 text-paper font-medium" : "text-paper/70 hover:bg-paper/5 hover:text-paper"
                }`
              }
            >
              <item.icon className="h-4 w-4 shrink-0" />
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div className="border-t border-paper/10 px-4 py-4">
          <p className="truncate text-sm font-medium">{user?.full_name}</p>
          <p className="text-[11px] text-paper/60">{USER_ROLE_LABELS[user?.role] || user?.role}</p>
          <button
            onClick={handleLogout}
            className="mt-3 w-full rounded border border-paper/20 px-3 py-1.5 text-xs text-paper/80 transition hover:bg-paper/10 hover:text-paper"
          >
            تسجيل الخروج
          </button>
        </div>
      </aside>

      {/* Main content */}
      <div className="flex-1">
        <header className="border-b border-line bg-paper/80 px-8 py-6 backdrop-blur">
          <h1 className="font-display text-2xl text-ink">{title}</h1>
          {description && <p className="mt-1 text-sm text-sage">{description}</p>}
        </header>
        <main className="px-8 py-6">{children}</main>
      </div>
    </div>
  );
}

function RiskSpineMark() {
  return (
    <svg viewBox="0 0 32 32" className="h-5 w-5" aria-hidden="true">
      <rect x="2" y="6" width="4" height="20" rx="2" fill="#4F8A5B" />
      <rect x="9" y="9" width="4" height="17" rx="2" fill="#8BAA4E" />
      <rect x="16" y="4" width="4" height="22" rx="2" fill="#D4A12C" />
      <rect x="23" y="11" width="4" height="15" rx="2" fill="#C1432E" />
    </svg>
  );
}

function OverviewIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" {...props}>
      <rect x="3" y="3" width="7" height="9" rx="1.5" />
      <rect x="14" y="3" width="7" height="5" rx="1.5" />
      <rect x="14" y="12" width="7" height="9" rx="1.5" />
      <rect x="3" y="16" width="7" height="5" rx="1.5" />
    </svg>
  );
}

function RiskIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" {...props}>
      <path d="M12 3v12" strokeLinecap="round" />
      <path d="M5 21h14" strokeLinecap="round" />
      <path d="M5 17l3-5 3 3 3-7 3 5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function UsersIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" {...props}>
      <circle cx="9" cy="8" r="3" />
      <path d="M3 20c0-3 2.7-5 6-5s6 2 6 5" strokeLinecap="round" />
      <circle cx="17" cy="8" r="2.5" />
      <path d="M16 12.5c2.8.4 5 2.3 5 4.5" strokeLinecap="round" />
    </svg>
  );
}

function LightbulbIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" {...props}>
      <path d="M9 18h6" strokeLinecap="round" />
      <path d="M10 21h4" strokeLinecap="round" />
      <path d="M12 3a6 6 0 0 0-3.8 10.6c.5.4.8 1 .8 1.7v.7h6v-.7c0-.6.3-1.3.8-1.7A6 6 0 0 0 12 3Z" strokeLinejoin="round" />
    </svg>
  );
}

function BookIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" {...props}>
      <path d="M4 19.5V5a2 2 0 0 1 2-2h12v15H6a2 2 0 0 0-2 2Z" strokeLinejoin="round" />
      <path d="M6 19.5A2 2 0 0 1 8 18h10" strokeLinecap="round" />
    </svg>
  );
}

function AuditIcon(props) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" {...props}>
      <rect x="4" y="2" width="16" height="20" rx="2" />
      <path d="M8 7h8M8 11h8M8 15h5" strokeLinecap="round" />
    </svg>
  );
}

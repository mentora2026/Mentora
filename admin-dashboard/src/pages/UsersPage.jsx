import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { AppShell } from "../components/AppShell";
import { EmptyState, ErrorState, LoadingState } from "../components/StateViews";
import { api } from "../lib/api";
import { ENDPOINTS } from "../lib/constants";
import { formatDateTime, USER_ROLE_LABELS } from "../lib/format";

export default function UsersPage() {
  const [users, setUsers] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);
  const [updatingId, setUpdatingId] = useState(null);
  const navigate = useNavigate();

  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.get(ENDPOINTS.adminUsers);
      setUsers(data);
    } catch (err) {
      setError(err.messageAr);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const toggleActive = async (user) => {
    setUpdatingId(user.id);
    try {
      const updated = await api.patch(ENDPOINTS.adminUserStatus(user.id), { is_active: !user.is_active });
      setUsers((prev) => prev.map((u) => (u.id === user.id ? updated : u)));
    } catch (err) {
      setError(err.messageAr);
    } finally {
      setUpdatingId(null);
    }
  };

  return (
    <AppShell title="المستخدمون" description="إدارة حسابات المرضى والمسؤولين">
      {loading && <LoadingState />}
      {error && <ErrorState message={error} onRetry={load} />}

      {users && (
        <div className="overflow-hidden rounded-lg border border-line bg-white">
          {users.length === 0 ? (
            <EmptyState title="لا يوجد مستخدمون" />
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-line bg-paper/60 text-right text-xs text-sage">
                  <th className="px-5 py-3 font-medium">الاسم</th>
                  <th className="px-5 py-3 font-medium">البريد الإلكتروني</th>
                  <th className="px-5 py-3 font-medium">الدور</th>
                  <th className="px-5 py-3 font-medium">تاريخ التسجيل</th>
                  <th className="px-5 py-3 font-medium">الحالة</th>
                  <th className="px-5 py-3 font-medium"></th>
                </tr>
              </thead>
              <tbody>
                {users.map((user) => (
                  <tr
                    key={user.id}
                    className={`border-b border-line last:border-0 ${
                      user.role === "patient" ? "cursor-pointer hover:bg-paper/60" : ""
                    }`}
                    onClick={() => user.role === "patient" && navigate(`/users/${user.id}`)}
                  >
                    <td className="px-5 py-3.5 font-medium text-ink">{user.full_name}</td>
                    <td className="px-5 py-3.5 tabular text-sage" dir="ltr">
                      {user.email}
                    </td>
                    <td className="px-5 py-3.5 text-ink">{USER_ROLE_LABELS[user.role] || user.role}</td>
                    <td className="px-5 py-3.5 tabular text-sage">{formatDateTime(user.created_at)}</td>
                    <td className="px-5 py-3.5">
                      <span
                        className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${
                          user.is_active ? "bg-sage-100 text-teal" : "bg-terracotta-50 text-terracotta"
                        }`}
                      >
                        {user.is_active ? "نشط" : "معطل"}
                      </span>
                    </td>
                    <td className="px-5 py-3.5">
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          toggleActive(user);
                        }}
                        disabled={updatingId === user.id}
                        className="rounded border border-line px-3 py-1 text-xs text-ink transition hover:border-teal hover:text-teal disabled:opacity-50"
                      >
                        {user.is_active ? "تعطيل" : "تفعيل"}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </AppShell>
  );
}

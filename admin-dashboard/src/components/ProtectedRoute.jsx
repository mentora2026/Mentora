import { Navigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { LoadingState } from "./StateViews";

export function ProtectedRoute({ children }) {
  const { status } = useAuth();

  if (status === "loading") {
    return (
      <div className="flex min-h-screen items-center justify-center bg-paper">
        <LoadingState />
      </div>
    );
  }

  if (status === "unauthenticated") {
    return <Navigate to="/login" replace />;
  }

  return children;
}

import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { AuthProvider } from "./context/AuthContext";
import { ProtectedRoute } from "./components/ProtectedRoute";

import LoginPage from "./pages/LoginPage";
import OverviewPage from "./pages/OverviewPage";
import RiskMonitoringPage from "./pages/RiskMonitoringPage";
import UsersPage from "./pages/UsersPage";
import PatientDetailPage from "./pages/PatientDetailPage";
import InterviewDetailPage from "./pages/InterviewDetailPage";
import RecommendationsPage from "./pages/RecommendationsPage";
import ContentLibraryPage from "./pages/ContentLibraryPage";
import AuditLogsPage from "./pages/AuditLogsPage";

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<LoginPage />} />

          <Route
            path="/"
            element={
              <ProtectedRoute>
                <OverviewPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/risk-monitoring"
            element={
              <ProtectedRoute>
                <RiskMonitoringPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/users"
            element={
              <ProtectedRoute>
                <UsersPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/users/:userId"
            element={
              <ProtectedRoute>
                <PatientDetailPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/interviews/:sessionId"
            element={
              <ProtectedRoute>
                <InterviewDetailPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/recommendations"
            element={
              <ProtectedRoute>
                <RecommendationsPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/content-library"
            element={
              <ProtectedRoute>
                <ContentLibraryPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/audit-logs"
            element={
              <ProtectedRoute>
                <AuditLogsPage />
              </ProtectedRoute>
            }
          />

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}

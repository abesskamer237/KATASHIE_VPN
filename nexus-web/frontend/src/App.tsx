import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Route, Routes, Navigate } from "react-router-dom";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import { AuthProvider, useAuth } from "@/lib/auth-context";
import LoginPage from "./pages/LoginPage";
import DashboardLayout from "./components/DashboardLayout";
import AdminDashboard from "./pages/AdminDashboard";
import AdminResellers from "./pages/AdminResellers";
import AdminAdmins from "./pages/AdminAdmins";
import AdminProtocols from "./pages/AdminProtocols";
import AdminServer from "./pages/AdminServer";
import AdminAppearance from "./pages/AdminAppearance";
import AdminSettings from "./pages/AdminSettings";
import ResellerDashboard from "./pages/ResellerDashboard";
import ResellerCreateAccount from "./pages/ResellerCreateAccount";
import ResellerAccounts from "./pages/ResellerAccounts";
import NotFound from "./pages/NotFound";

const queryClient = new QueryClient();

function AppRoutes() {
  const { isAuthenticated, user, loading } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (!isAuthenticated) {
    return (
      <Routes>
        <Route path="*" element={<LoginPage />} />
      </Routes>
    );
  }

  const isAdmin = user?.role === 'admin' || user?.role === 'super_admin';

  return (
    <Routes>
      <Route path="/" element={<Navigate to={isAdmin ? '/admin' : '/reseller'} replace />} />
      <Route element={<DashboardLayout />}>
        {/* Admin routes */}
        <Route path="/admin" element={<AdminDashboard />} />
        <Route path="/admin/resellers" element={<AdminResellers />} />
        <Route path="/admin/admins" element={<AdminAdmins />} />
        <Route path="/admin/create" element={<ResellerCreateAccount />} />
        <Route path="/admin/accounts" element={<ResellerAccounts />} />
        <Route path="/admin/protocols" element={<AdminProtocols />} />
        <Route path="/admin/server" element={<AdminServer />} />
        <Route path="/admin/appearance" element={<AdminAppearance />} />
        <Route path="/admin/settings" element={<AdminSettings />} />
        {/* Reseller routes */}
        <Route path="/reseller" element={<ResellerDashboard />} />
        <Route path="/reseller/create" element={<ResellerCreateAccount />} />
        <Route path="/reseller/accounts" element={<ResellerAccounts />} />
      </Route>
      <Route path="*" element={<NotFound />} />
    </Routes>
  );
}

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <AuthProvider>
        <BrowserRouter>
          <AppRoutes />
        </BrowserRouter>
      </AuthProvider>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;

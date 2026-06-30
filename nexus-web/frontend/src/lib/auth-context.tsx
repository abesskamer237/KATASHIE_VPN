import React, { createContext, useContext, useState, useCallback, useEffect } from 'react';
import { api, saveToken, clearToken, hasToken } from './api';

export type UserRole = 'super_admin' | 'admin' | 'reseller';

export interface ProtocolQuota {
  protocolId: string;
  maxAccounts: number;
  usedAccounts: number;
}

export interface AuthUser {
  id: string;
  username: string;
  role: UserRole;
  bouquet?: ProtocolQuota[];
  expiryDate?: string;
  remainingDays?: number;
  remainingSeconds?: number;
  isActive: boolean;
  createdAt?: string;
}

interface AuthContextType {
  user: AuthUser | null;
  login: (username: string, password: string) => Promise<{ success: boolean; error?: string }>;
  logout: () => Promise<void>;
  isAuthenticated: boolean;
  loading: boolean;
  refreshUser: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [loading, setLoading] = useState(true);

  const loadUser = useCallback(async () => {
    if (!hasToken()) {
      setLoading(false);
      return;
    }
    try {
      const { admin } = await api.me();
      let bouquet: ProtocolQuota[] = [];
      if (admin.bouquet) {
        try {
          bouquet = typeof admin.bouquet === 'string' ? JSON.parse(admin.bouquet) : admin.bouquet;
        } catch {}
      }
      setUser({
        id: admin.id,
        username: admin.username,
        role: admin.role as UserRole,
        bouquet,
        expiryDate: admin.expiry_date,
        remainingDays: admin.remaining_days,
        remainingSeconds: admin.remaining_seconds,
        isActive: true,
      });
    } catch {
      clearToken();
      setUser(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadUser();
  }, [loadUser]);

  const login = useCallback(async (username: string, password: string): Promise<{ success: boolean; error?: string }> => {
    try {
      const { token, admin } = await api.login(username, password);
      saveToken(token);
      setUser({
        id: admin.id,
        username: admin.username,
        role: admin.role as UserRole,
        bouquet: [],
        isActive: true,
      });
      // Reload full user info (bouquet, expiry, etc.)
      await loadUser();
      return { success: true };
    } catch (err: any) {
      return { success: false, error: err.message || 'Identifiants invalides' };
    }
  }, [loadUser]);

  const logout = useCallback(async () => {
    try {
      await api.logout();
    } catch {}
    clearToken();
    setUser(null);
  }, []);

  const refreshUser = useCallback(async () => {
    await loadUser();
  }, [loadUser]);

  return (
    <AuthContext.Provider
      value={{
        user,
        login,
        logout,
        isAuthenticated: !!user && !loading,
        loading,
        refreshUser,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}

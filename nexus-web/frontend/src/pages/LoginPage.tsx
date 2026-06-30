import { useState } from 'react';
import { useAuth } from '@/lib/auth-context';
import { Eye, EyeOff, Terminal, Lock, User } from 'lucide-react';

export default function LoginPage() {
  const { login } = useAuth();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    const result = await login(username, password);
    if (!result.success) setError(result.error || 'Identifiants invalides');
    setLoading(false);
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-background p-4 relative overflow-hidden">
      {/* Grid de fond subtil */}
      <div
        className="absolute inset-0 opacity-[0.025] pointer-events-none"
        style={{
          backgroundImage: 'linear-gradient(hsl(var(--primary)) 1px, transparent 1px), linear-gradient(90deg, hsl(var(--primary)) 1px, transparent 1px)',
          backgroundSize: '48px 48px',
        }}
      />
      {/* Orbe bleu discret */}
      <div
        className="absolute top-1/3 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 rounded-full opacity-5 pointer-events-none"
        style={{ background: 'radial-gradient(circle, hsl(var(--primary)) 0%, transparent 70%)' }}
      />

      <div className="relative w-full max-w-sm animate-slide-in">
        <div className="glass-card p-8 border-border relative overflow-hidden">
          {/* Ligne bleue en haut */}
          <div className="absolute top-0 left-0 right-0 h-[2px]" style={{ background: 'var(--gradient-blue)' }} />

          {/* Logo */}
          <div className="flex flex-col items-center mb-8">
            <div
              className="w-16 h-16 rounded-2xl flex items-center justify-center mb-4"
              style={{ background: 'var(--gradient-blue)', boxShadow: 'var(--blue-glow)' }}
            >
              <Terminal className="w-8 h-8 text-white" />
            </div>
            <h1 className="text-xl font-bold text-white tracking-wide">KATASHIE VPN</h1>
            <p className="text-muted-foreground text-xs mt-1 font-mono">Management Panel v2.0</p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Username */}
            <div>
              <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-1.5 block">
                Nom d'utilisateur
              </label>
              <div className="relative">
                <User className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                <input
                  type="text"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  className="input-dark pl-9 font-mono"
                  placeholder="admin"
                  autoComplete="username"
                  required
                />
              </div>
            </div>

            {/* Password */}
            <div>
              <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wider mb-1.5 block">
                Mot de passe
              </label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="input-dark pl-9 pr-10 font-mono"
                  placeholder="••••••••"
                  autoComplete="current-password"
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            {/* Error */}
            {error && (
              <div className="text-destructive text-xs bg-destructive/10 border border-destructive/20 rounded-md px-3 py-2">
                {error}
              </div>
            )}

            {/* Submit */}
            <button type="submit" disabled={loading} className="btn-primary w-full text-sm tracking-wide mt-2">
              {loading ? (
                <span className="flex items-center justify-center gap-2">
                  <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  Connexion en cours...
                </span>
              ) : (
                'SE CONNECTER'
              )}
            </button>
          </form>

          <div className="mt-6 pt-5 border-t border-border">
            <p className="text-[11px] text-muted-foreground text-center">
              Identifiants configurés lors de l'installation{' '}
              <span className="font-mono text-primary">KATASHIE VPN</span>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

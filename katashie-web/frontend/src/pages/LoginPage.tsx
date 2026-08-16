import { useState } from 'react';
import { useAuth } from '@/lib/auth-context';
import { motion } from 'framer-motion';
import { Eye, EyeOff } from 'lucide-react';

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
      {/* Animated background orbs */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <motion.div
          animate={{ x: [0, 100, -50, 0], y: [0, -80, 60, 0], scale: [1, 1.2, 0.9, 1] }}
          transition={{ duration: 20, repeat: Infinity, ease: "easeInOut" }}
          className="absolute top-1/4 left-1/4 w-[500px] h-[500px] rounded-full opacity-20"
          style={{ background: 'radial-gradient(circle, hsl(270 100% 65%) 0%, transparent 70%)' }}
        />
        <motion.div
          animate={{ x: [0, -80, 100, 0], y: [0, 60, -40, 0], scale: [1, 0.8, 1.1, 1] }}
          transition={{ duration: 25, repeat: Infinity, ease: "easeInOut" }}
          className="absolute bottom-1/4 right-1/4 w-[400px] h-[400px] rounded-full opacity-15"
          style={{ background: 'radial-gradient(circle, hsl(320 100% 60%) 0%, transparent 70%)' }}
        />
        {/* Grid lines */}
        <div className="absolute inset-0 opacity-[0.03]"
          style={{ backgroundImage: 'linear-gradient(hsl(270 100% 65%) 1px, transparent 1px), linear-gradient(90deg, hsl(270 100% 65%) 1px, transparent 1px)', backgroundSize: '60px 60px' }}
        />
      </div>

      <motion.div
        initial={{ opacity: 0, y: 30, scale: 0.95 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ duration: 0.6, ease: "easeOut" }}
        className="relative w-full max-w-md"
      >
        <div className="glass-card p-8 relative overflow-hidden">
          {/* Top gradient line */}
          <div className="absolute top-0 left-0 right-0 h-[2px] bg-gradient-primary" />

          {/* Logo */}
          <div className="flex flex-col items-center mb-8">
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ delay: 0.2, type: "spring", stiffness: 200 }}
              className="w-20 h-20 rounded-2xl flex items-center justify-center mb-4 relative"
              style={{ background: 'var(--gradient-primary)' }}
            >
              <span className="text-3xl font-display font-black text-primary-foreground">N</span>
              <div className="absolute inset-0 rounded-2xl animate-glow-pulse" style={{ boxShadow: '0 0 40px rgba(138,43,226,0.4)' }} />
            </motion.div>
            <h1 className="text-2xl font-display font-black text-gradient-primary tracking-wider">KATASHIE VPN</h1>
            <p className="text-muted-foreground text-sm mt-1 font-sans">VPN Management Panel</p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-5">
            <div>
              <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">
                Nom d'utilisateur
              </label>
              <input
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                className="input-dark w-full font-mono"
                placeholder="admin"
                required
              />
            </div>
            <div>
              <label className="text-xs uppercase tracking-widest text-muted-foreground mb-2 block font-semibold">
                Mot de passe
              </label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="input-dark w-full font-mono pr-12"
                  placeholder="••••••••"
                  required
                />
                <button type="button" onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors">
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            {error && (
              <motion.div
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                className="text-destructive text-sm bg-destructive/10 border border-destructive/20 rounded-lg px-4 py-2"
              >
                {error}
              </motion.div>
            )}

            <button type="submit" disabled={loading} className="btn-primary w-full disabled:opacity-50 text-base tracking-wider">
              {loading ? (
                <span className="flex items-center justify-center gap-2">
                  <span className="w-5 h-5 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin" />
                  Connexion...
                </span>
              ) : 'SE CONNECTER'}
            </button>
          </form>

          <div className="mt-6 pt-6 border-t border-border">
            <p className="text-xs text-muted-foreground text-center">
              Identifiants créés via le script d'installation <span className="font-mono text-primary">KATASHIE</span>
            </p>
          </div>
        </div>
      </motion.div>
    </div>
  );
}

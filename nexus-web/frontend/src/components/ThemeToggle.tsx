import { Sun, Moon } from 'lucide-react';
import { useTheme } from '../contexts/ThemeContext';
import { useI18n } from '../contexts/I18nContext';

export default function ThemeToggle() {
  const { theme, toggleTheme } = useTheme();
  const { t } = useI18n();
  return (
    <button
      onClick={toggleTheme}
      className="btn btn-ghost btn-sm"
      title={theme === 'dark' ? t('theme.light') : t('theme.dark')}
      style={{ gap: '0.4rem' }}
    >
      {theme === 'dark' ? <Sun size={16} /> : <Moon size={16} />}
    </button>
  );
}

import { useI18n } from '../contexts/I18nContext';
import type { Language } from '../i18n';

const LANGS: { code: Language; label: string; flag: string }[] = [
  { code: 'fr', label: 'FR', flag: '🇫🇷' },
  { code: 'en', label: 'EN', flag: '🇬🇧' },
  { code: 'ar', label: 'AR', flag: '🇸🇦' },
];

export default function LanguageSwitcher() {
  const { lang, setLang } = useI18n();
  return (
    <div style={{ display: 'flex', gap: '0.25rem' }}>
      {LANGS.map(l => (
        <button
          key={l.code}
          onClick={() => setLang(l.code)}
          className={`btn btn-sm ${lang === l.code ? 'btn-primary' : 'btn-ghost'}`}
          style={{ padding: '0.25rem 0.5rem', fontSize: '0.72rem', minWidth: 0 }}
          title={l.label}
        >
          {l.flag} {l.label}
        </button>
      ))}
    </div>
  );
}

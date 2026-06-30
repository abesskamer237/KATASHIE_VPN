import fr from './fr.json';
import en from './en.json';
import ar from './ar.json';

export type Language = 'fr' | 'en' | 'ar';
export type TranslationKey = string;

const translations: Record<Language, typeof fr> = { fr, en, ar };

export function t(lang: Language, key: string, fallback?: string): string {
  const parts = key.split('.');
  let value: any = translations[lang];
  for (const part of parts) {
    value = value?.[part];
    if (value === undefined) break;
  }
  if (typeof value === 'string') return value;
  // Fallback to French then to key
  let frValue: any = translations.fr;
  for (const part of parts) {
    frValue = frValue?.[part];
    if (frValue === undefined) break;
  }
  return typeof frValue === 'string' ? frValue : (fallback ?? key);
}

export { translations };

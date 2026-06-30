import React, { createContext, useContext, useState } from 'react';
import { Language, t as translate } from '../i18n';

interface I18nContextType {
  lang: Language;
  setLang: (lang: Language) => void;
  t: (key: string, fallback?: string) => string;
}

const I18nContext = createContext<I18nContextType>({
  lang: 'fr',
  setLang: () => {},
  t: (key) => key
});

export function I18nProvider({ children }: { children: React.ReactNode }) {
  const [lang, setLangState] = useState<Language>(() => {
    const stored = localStorage.getItem('katashie-lang') as Language | null;
    if (stored && ['fr', 'en', 'ar'].includes(stored)) return stored;
    const browser = navigator.language.slice(0, 2) as Language;
    return ['fr', 'en', 'ar'].includes(browser) ? browser : 'fr';
  });

  const setLang = (newLang: Language) => {
    setLangState(newLang);
    localStorage.setItem('katashie-lang', newLang);
    document.documentElement.setAttribute('dir', newLang === 'ar' ? 'rtl' : 'ltr');
    document.documentElement.setAttribute('lang', newLang);
  };

  const t = (key: string, fallback?: string) => translate(lang, key, fallback);

  return (
    <I18nContext.Provider value={{ lang, setLang, t }}>
      {children}
    </I18nContext.Provider>
  );
}

export function useI18n() { return useContext(I18nContext); }

import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { interpolate, translations } from '../i18n/translations';

const KEY = 'riyada_admin_locale';
const LocaleContext = createContext(null);

export function LocaleProvider({ children }) {
  const [locale, setLocaleState] = useState(() => {
    const saved = localStorage.getItem(KEY);
    return saved === 'en' ? 'en' : 'ar';
  });

  useEffect(() => {
    localStorage.setItem(KEY, locale);
    document.documentElement.lang = locale === 'ar' ? 'ar' : 'en';
    document.documentElement.dir = locale === 'ar' ? 'rtl' : 'ltr';
  }, [locale]);

  const setLocale = useCallback((next) => {
    setLocaleState(next === 'en' ? 'en' : 'ar');
  }, []);

  const toggleLocale = useCallback(() => {
    setLocaleState((prev) => (prev === 'ar' ? 'en' : 'ar'));
  }, []);

  const t = useCallback((path, vars) => {
    const parts = String(path).split('.');
    let cur = translations[locale];
    for (const p of parts) cur = cur?.[p];
    if (typeof cur !== 'string') {
      let fallback = translations.ar;
      for (const p of parts) fallback = fallback?.[p];
      cur = typeof fallback === 'string' ? fallback : path;
    }
    return vars ? interpolate(cur, vars) : cur;
  }, [locale]);

  const value = useMemo(() => ({
    locale,
    isRtl: locale === 'ar',
    setLocale,
    toggleLocale,
    t,
  }), [locale, setLocale, toggleLocale, t]);

  return <LocaleContext.Provider value={value}>{children}</LocaleContext.Provider>;
}

export function useLocale() {
  const ctx = useContext(LocaleContext);
  if (!ctx) throw new Error('useLocale outside provider');
  return ctx;
}

import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import ar from './locales/ar.json';
import en from './locales/en.json';

const saved = localStorage.getItem('riyada_lang') || 'ar';

i18n.use(initReactI18next).init({
  resources: { ar: { translation: ar }, en: { translation: en } },
  lng: saved,
  fallbackLng: 'ar',
  interpolation: { escapeValue: false },
});

i18n.on('languageChanged', (lng) => {
  localStorage.setItem('riyada_lang', lng);
  document.documentElement.lang = lng;
  document.documentElement.dir = lng === 'ar' ? 'rtl' : 'ltr';
});

document.documentElement.lang = saved;
document.documentElement.dir = saved === 'ar' ? 'rtl' : 'ltr';

export default i18n;

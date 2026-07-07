import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Moon, Sun, Globe, Server, Info } from 'lucide-react';
import Header from '../components/Header';
import Button from '../components/Button';

const THEME_KEY = 'riyada_theme';
const LANG_KEY = 'riyada_lang';

export default function Settings() {
  const navigate = useNavigate();
  const [dark, setDark] = useState(() => localStorage.getItem(THEME_KEY) === 'dark');
  const [lang, setLang] = useState(() => localStorage.getItem(LANG_KEY) || 'ar');

  const toggleTheme = () => {
    const next = !dark;
    setDark(next);
    localStorage.setItem(THEME_KEY, next ? 'dark' : 'light');
    document.documentElement.classList.toggle('dark', next);
  };

  const toggleLang = () => {
    const next = lang === 'ar' ? 'en' : 'ar';
    setLang(next);
    localStorage.setItem(LANG_KEY, next);
    document.documentElement.lang = next;
    document.documentElement.dir = next === 'ar' ? 'rtl' : 'ltr';
  };

  return (
    <div className="app-shell min-h-screen pb-8 animate-fade-in">
      <Header title="الإعدادات" onBack={() => navigate(-1)} />

      <div className="px-5 space-y-4">
        <button type="button" onClick={toggleTheme} className="card w-full flex items-center justify-between p-4">
          <span className="font-semibold flex items-center gap-2">
            {dark ? <Moon className="w-5 h-5" /> : <Sun className="w-5 h-5" />}
            الوضع الليلي
          </span>
          <span className="text-sm text-gray-500">{dark ? 'مُفعّل' : 'غير مُفعّل'}</span>
        </button>

        <button type="button" onClick={toggleLang} className="card w-full flex items-center justify-between p-4">
          <span className="font-semibold flex items-center gap-2">
            <Globe className="w-5 h-5" />
            اللغة
          </span>
          <span className="text-sm text-brand-600 font-bold">{lang === 'ar' ? 'العربية' : 'English'}</span>
        </button>

        <div className="card p-4 flex items-start gap-3">
          <Server className="w-5 h-5 text-brand-600 shrink-0 mt-0.5" />
          <div className="text-right flex-1">
            <p className="font-semibold">الخادم</p>
            <p className="text-sm text-gray-500 mt-1">يتصل تلقائياً بمنفذ 61082 — يمكن تغييره عبر VITE_API_HOST</p>
          </div>
        </div>

        <div className="card p-4 flex items-start gap-3">
          <Info className="w-5 h-5 text-brand-600 shrink-0 mt-0.5" />
          <div className="text-right flex-1">
            <p className="font-semibold">عن التطبيق</p>
            <p className="text-sm text-gray-500 mt-1">رياضة — حجز الملاعب في نينوى · الإصدار 1.0.0</p>
          </div>
        </div>

        <Button variant="outline" onClick={() => navigate('/')}>
          العودة للرئيسية
        </Button>
      </div>
    </div>
  );
}

import { ArrowRight, LogOut, Settings, History, MapPin } from 'lucide-react';

export default function Header({ title, subtitle, onBack, onLogout, onSettings, onHistory, avatar, userName }) {
  return (
    <header className="customer-hero text-white px-5 pt-6 pb-7 sm:px-6 sm:pt-8 sm:pb-8 rounded-b-[2rem] shadow-[0_12px_32px_rgba(0,0,0,0.12)]">
      <div className="flex items-center justify-between mb-5">
        {onBack ? (
          <button
            onClick={onBack}
            aria-label="رجوع"
            className="h-11 w-11 grid place-items-center rounded-2xl border border-white/15 bg-white/5 hover:bg-white/10 transition-colors"
          >
            <ArrowRight className="w-5 h-5" />
          </button>
        ) : (
          <div className="flex items-center gap-2">
            <span className="grid place-items-center w-9 h-9 rounded-xl bg-white/10 border border-white/10 font-black text-green-300">R</span>
            <span className="font-extrabold tracking-wide">RIYADA</span>
          </div>
        )}

        <div className="flex items-center gap-1">
          {onHistory && (
            <button onClick={onHistory} className="h-10 w-10 grid place-items-center rounded-xl hover:bg-white/10 transition-colors" title="سجل الحجوزات" aria-label="سجل الحجوزات">
              <History className="w-5 h-5" />
            </button>
          )}
          {onSettings && (
            <button onClick={onSettings} className="h-10 w-10 grid place-items-center rounded-xl hover:bg-white/10 transition-colors" title="الإعدادات" aria-label="الإعدادات">
              <Settings className="w-5 h-5" />
            </button>
          )}
          {onLogout && (
            <button onClick={onLogout} className="h-10 w-10 grid place-items-center rounded-xl hover:bg-white/10 transition-colors" title="تسجيل الخروج" aria-label="تسجيل الخروج">
              <LogOut className="w-5 h-5" />
            </button>
          )}
        </div>
      </div>

      {(userName || avatar) && (
        <div className="flex items-center gap-3 mb-4">
          {avatar ? (
            <img src={avatar} alt="" className="w-12 h-12 rounded-2xl border border-white/25 object-cover" />
          ) : (
            <div className="w-12 h-12 rounded-2xl bg-white/10 border border-white/15 flex items-center justify-center text-lg font-bold">
              {userName?.[0]}
            </div>
          )}
          <div className="min-w-0">
            <p className="text-white/65 text-sm">مرحباً بعودتك</p>
            <p className="font-bold text-lg truncate">{userName}</p>
          </div>
        </div>
      )}

      {title && <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight leading-tight">{title}</h1>}
      {subtitle && (
        <p className="text-white/70 text-sm mt-2 flex items-center gap-2">
          <MapPin className="w-4 h-4 text-green-300 shrink-0" />
          <span>{subtitle}</span>
        </p>
      )}
    </header>
  );
}

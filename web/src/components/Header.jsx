import { ArrowRight, LogOut, Settings, History } from 'lucide-react';

export default function Header({ title, subtitle, onBack, onLogout, onSettings, onHistory, avatar, userName }) {
  return (
    <div className="gradient-hero text-white px-5 pt-10 pb-6 rounded-b-3xl shadow-float">
      <div className="flex items-center justify-between mb-3">
        {onBack ? (
          <button onClick={onBack} className="p-2 -mr-2 rounded-xl hover:bg-white/10 transition-colors">
            <ArrowRight className="w-6 h-6" />
          </button>
        ) : <div className="w-10" />}

        <div className="flex items-center gap-1">
          {onHistory && (
            <button onClick={onHistory} className="p-2 rounded-xl hover:bg-white/10 transition-colors" title="سجل الحجوزات">
              <History className="w-5 h-5" />
            </button>
          )}
          {onSettings && (
            <button onClick={onSettings} className="p-2 rounded-xl hover:bg-white/10 transition-colors" title="إعدادات">
              <Settings className="w-5 h-5" />
            </button>
          )}
          {onLogout && (
            <button onClick={onLogout} className="p-2 -ml-2 rounded-xl hover:bg-white/10 transition-colors" title="خروج">
              <LogOut className="w-5 h-5" />
            </button>
          )}
        </div>
      </div>

      {(userName || avatar) && (
        <div className="flex items-center gap-3 mb-2">
          {avatar ? (
            <img src={avatar} alt="" className="w-12 h-12 rounded-full border-2 border-white/50 object-cover" />
          ) : (
            <div className="w-12 h-12 rounded-full bg-white/20 flex items-center justify-center text-xl font-bold">
              {userName?.[0]}
            </div>
          )}
          <div>
            <p className="text-white/70 text-sm">مرحباً</p>
            <p className="font-bold text-lg">{userName}</p>
          </div>
        </div>
      )}

      {title && <h1 className="text-2xl font-extrabold">{title}</h1>}
      {subtitle && <p className="text-white/70 text-sm mt-1">{subtitle}</p>}
    </div>
  );
}

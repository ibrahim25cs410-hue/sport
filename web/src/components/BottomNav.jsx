import { Bell, CalendarDays, MapPin } from 'lucide-react';

export default function BottomNav({ active, onChange, badges = {} }) {
  const tabs = [
    { key: 'stadiums', label: 'الملاعب', icon: MapPin },
    { key: 'bookings', label: 'حجوزاتي', icon: CalendarDays },
    { key: 'notifications', label: 'الإشعارات', icon: Bell },
  ];

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 safe-bottom px-3">
      <div className="mx-auto max-w-md rounded-t-2xl border border-b-0 border-[rgb(var(--color-outline))] bg-[rgb(var(--color-surface))]/95 backdrop-blur-xl shadow-[0_-8px_28px_rgba(0,0,0,0.08)]">
        <div className="flex">
          {tabs.map(({ key, label, icon: Icon }) => {
            const selected = active === key;
            return (
              <button
                key={key}
                onClick={() => onChange(key)}
                aria-current={selected ? 'page' : undefined}
                className={`flex-1 flex flex-col items-center justify-center gap-1 py-3 relative transition-colors ${
                  selected ? 'text-[rgb(var(--color-primary))]' : 'text-[rgb(var(--color-on-surface-variant))]'
                }`}
              >
                <div className={`relative grid place-items-center w-10 h-7 rounded-xl transition-colors ${selected ? 'bg-[rgb(var(--color-primary))]/10' : ''}`}>
                  <Icon className={`w-5 h-5 ${selected ? 'stroke-[2.5]' : ''}`} />
                  {badges[key] > 0 && (
                    <span className="absolute -top-1 -right-1 min-w-4 h-4 px-1 bg-red-500 text-white text-[10px] font-bold rounded-full flex items-center justify-center">
                      {badges[key] > 9 ? '9+' : badges[key]}
                    </span>
                  )}
                </div>
                <span className={`text-xs ${selected ? 'font-bold' : 'font-medium'}`}>{label}</span>
                {selected && <span className="absolute top-0 left-1/2 -translate-x-1/2 w-8 h-0.5 bg-[rgb(var(--color-primary))] rounded-full" />}
              </button>
            );
          })}
        </div>
      </div>
    </nav>
  );
}

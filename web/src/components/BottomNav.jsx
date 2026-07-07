import { Bell, Calendar, MapPin } from 'lucide-react';

export default function BottomNav({ active, onChange, badges = {} }) {
  const tabs = [
    { key: 'stadiums', label: 'الملاعب', icon: MapPin },
    { key: 'bookings', label: 'حجوزاتي', icon: Calendar },
    { key: 'notifications', label: 'إشعارات', icon: Bell },
  ];

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 safe-bottom">
      <div className="mx-auto max-w-md bg-white border-t border-gray-100 shadow-[0_-4px_20px_rgba(0,0,0,0.06)]">
        <div className="flex">
          {tabs.map(({ key, label, icon: Icon }) => (
            <button
              key={key}
              onClick={() => onChange(key)}
              className={`flex-1 flex flex-col items-center py-3 relative transition-colors ${
                active === key ? 'text-brand-600' : 'text-gray-400'
              }`}
            >
              <div className="relative">
                <Icon className={`w-6 h-6 ${active === key ? 'stroke-[2.5]' : ''}`} />
                {badges[key] > 0 && (
                  <span className="absolute -top-1.5 -left-1.5 w-4 h-4 bg-red-500 text-white text-[10px] font-bold rounded-full flex items-center justify-center">
                    {badges[key]}
                  </span>
                )}
              </div>
              <span className={`text-xs mt-1 ${active === key ? 'font-bold' : ''}`}>{label}</span>
              {active === key && (
                <div className="absolute top-0 left-1/2 -translate-x-1/2 w-8 h-0.5 bg-brand-600 rounded-full" />
              )}
            </button>
          ))}
        </div>
      </div>
    </nav>
  );
}

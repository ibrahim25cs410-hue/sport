import { Loader2 } from 'lucide-react';

export default function AppLogo({ size = 112, showLabel = true, light = false }) {
  const box = Math.round(size * 0.78);
  return (
    <div className="flex flex-col items-center">
      <div
        className={`rounded-3xl flex items-center justify-center shadow-float border ${
          light
            ? 'bg-white/15 backdrop-blur border-white/20'
            : 'gradient-hero border-brand-200/30'
        }`}
        style={{ width: box, height: box }}
      >
        <svg viewBox="0 0 64 64" className={light ? 'w-14 h-14' : 'w-12 h-12'} aria-hidden>
          <circle cx="32" cy="32" r="28" fill={light ? 'rgba(255,255,255,0.95)' : 'white'} />
          <path
            d="M32 8c13.3 0 24 10.7 24 24S45.3 56 32 56 8 45.3 8 32 18.7 8 32 8zm0 6a18 18 0 100 36 18 18 0 000-36z"
            fill={light ? '#0D4F1C' : '#1565C0'}
            opacity="0.15"
          />
          <path
            d="M32 14l4 12h12l-10 7 4 12-10-8-10 8 4-12-10-7h12z"
            fill={light ? '#FFB300' : '#0D4F1C'}
          />
        </svg>
      </div>
      {showLabel && (
        <h1 className={`font-extrabold mt-4 ${light ? 'text-white text-5xl' : 'text-brand-800 text-3xl'}`}>
          رياضة
        </h1>
      )}
    </div>
  );
}

export function AppLoadingScreen({ message = 'جاري التحميل...' }) {
  return (
    <div className="app-shell flex flex-col items-center justify-center min-h-screen gap-5 animate-fade-in">
      <AppLogo size={120} showLabel={false} />
      <Loader2 className="w-8 h-8 text-brand-600 animate-spin" />
      <p className="text-gray-500 text-sm">{message}</p>
    </div>
  );
}

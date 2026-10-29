import { MapPin, Phone, Clock, ArrowUpLeft } from 'lucide-react';
import { formatMoney } from '../api';
import { StarRatingDisplay } from './StarRating';

export default function StadiumCard({ stadium, onClick }) {
  return (
    <button
      onClick={onClick}
      className="group w-full text-right overflow-hidden rounded-3xl border border-[rgb(var(--color-outline))] bg-[rgb(var(--color-surface))] shadow-[0_4px_18px_rgba(0,0,0,0.045)] hover:shadow-[0_12px_30px_rgba(0,0,0,0.09)] hover:-translate-y-0.5 active:scale-[0.995] transition-all duration-200"
    >
      <div className="flex gap-4 p-3 sm:p-4">
        <div className="relative w-28 h-28 sm:w-32 sm:h-32 rounded-2xl overflow-hidden shrink-0 bg-[rgb(var(--color-surface-variant))]">
          {stadium.image ? (
            <img src={stadium.image} alt="" loading="lazy" className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
          ) : (
            <div className="w-full h-full grid place-items-center customer-hero text-4xl">⚽</div>
          )}
          <span className="absolute bottom-2 right-2 rounded-lg bg-black/65 px-2 py-1 text-[10px] font-bold text-white backdrop-blur">
            نينوى
          </span>
        </div>
        <div className="flex-1 min-w-0 py-1 flex flex-col items-start">
          <div className="flex items-start justify-between gap-2 w-full">
            <span className="grid place-items-center w-8 h-8 rounded-xl text-[rgb(var(--color-on-surface-variant))] bg-[rgb(var(--color-surface-variant))] shrink-0">
              <ArrowUpLeft className="w-4 h-4" />
            </span>
            <h3 className="font-bold text-base sm:text-lg text-[rgb(var(--color-on-surface))] truncate">{stadium.name}</h3>
          </div>
          {stadium.reviewCount > 0 && (
            <div className="mt-1">
              <StarRatingDisplay rating={stadium.averageRating} reviewCount={stadium.reviewCount} size={14} />
            </div>
          )}
          <p className="w-full text-[rgb(var(--color-on-surface-variant))] text-sm flex items-center gap-1.5 mt-2">
            <MapPin className="w-4 h-4 shrink-0 text-[rgb(var(--color-primary))]" />
            <span className="truncate">{stadium.address || 'الموقع غير محدد'}</span>
          </p>
          {stadium.phone && (
            <p className="w-full text-[rgb(var(--color-on-surface-variant))] text-xs flex items-center gap-1.5 mt-1">
              <Phone className="w-3.5 h-3.5 shrink-0" />
              <span className="truncate">{stadium.phone}</span>
            </p>
          )}
          <div className="mt-auto pt-2 w-full flex items-end justify-between gap-2">
            <span className="text-xs text-[rgb(var(--color-on-surface-variant))] flex items-center gap-1">
              <Clock className="w-3.5 h-3.5" /> سعر الساعة
            </span>
            <p className="font-extrabold text-base text-[rgb(var(--color-primary))] whitespace-nowrap">
              {formatMoney(stadium.pricePerHour)}
            </p>
          </div>
        </div>
      </div>
    </button>
  );
}

import { MapPin, Phone, Clock } from 'lucide-react';
import { formatMoney } from '../api';

import { StarRatingDisplay } from './StarRating';

export default function StadiumCard({ stadium, onClick }) {
  return (
    <button
      onClick={onClick}
      className="card w-full text-right hover:shadow-float active:scale-[0.99] transition-all duration-200 group"
    >
      <div className="flex gap-4">
        <div className="w-20 h-20 rounded-2xl gradient-card flex items-center justify-center shrink-0 group-hover:scale-105 transition-transform">
          {stadium.image ? (
            <img src={stadium.image} alt="" className="w-full h-full rounded-2xl object-cover" />
          ) : (
            <span className="text-4xl">⚽</span>
          )}
        </div>
        <div className="flex-1 min-w-0">
          <h3 className="font-bold text-lg text-brand-700 truncate">{stadium.name}</h3>
          {stadium.reviewCount > 0 && (
            <div className="mt-1">
              <StarRatingDisplay rating={stadium.averageRating} reviewCount={stadium.reviewCount} size={14} />
            </div>
          )}
          <p className="text-gray-500 text-sm flex items-center gap-1 mt-1">
            <MapPin className="w-3.5 h-3.5 shrink-0" />
            <span className="truncate">{stadium.address}</span>
          </p>
          <p className="text-gray-500 text-sm flex items-center gap-1">
            <Phone className="w-3.5 h-3.5 shrink-0" />
            <span>{stadium.phone}</span>
          </p>
          <p className="text-brand-600 font-bold text-sm mt-2 flex items-center gap-1">
            <Clock className="w-3.5 h-3.5" />
            {formatMoney(stadium.pricePerHour)} / ساعة
          </p>
        </div>
      </div>
    </button>
  );
}

import { Star } from 'lucide-react';

export function StarRatingDisplay({ rating = 0, reviewCount, size = 16 }) {
  const filled = Math.min(5, Math.max(0, Math.round(rating)));
  return (
    <div className="flex items-center gap-0.5">
      {Array.from({ length: 5 }).map((_, i) => (
        <Star
          key={i}
          className={i < filled ? 'text-amber-400 fill-amber-400' : 'text-gray-300'}
          style={{ width: size, height: size }}
        />
      ))}
      {reviewCount != null && (
        <span className="text-xs text-gray-500 mr-1">
          {rating > 0 ? rating.toFixed(1) : '—'} ({reviewCount})
        </span>
      )}
    </div>
  );
}

export function StarRatingInput({ value, onChange }) {
  return (
    <div className="flex justify-center gap-1">
      {Array.from({ length: 5 }).map((_, i) => {
        const star = i + 1;
        const active = star <= value;
        return (
          <button
            key={star}
            type="button"
            onClick={() => onChange(star)}
            className="p-1"
            aria-label={`${star} نجوم`}
          >
            <Star className={active ? 'w-9 h-9 text-amber-400 fill-amber-400' : 'w-9 h-9 text-gray-300'} />
          </button>
        );
      })}
    </div>
  );
}

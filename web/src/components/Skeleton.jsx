/** Skeleton loaders — بديل spinners لتحميل سلس */
export function Shimmer({ className = '', style = {} }) {
  return (
    <div
      className={`animate-pulse rounded-xl bg-gradient-to-r from-gray-200 via-gray-100 to-gray-200 dark:from-gray-700 dark:via-gray-600 dark:to-gray-700 ${className}`}
      style={style}
    />
  );
}

export function FieldsListSkeleton({ count = 4 }) {
  return (
    <div className="space-y-3 p-4">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="card !p-4 space-y-3">
          <Shimmer className="h-5 w-40" />
          <Shimmer className="h-4 w-full" />
          <Shimmer className="h-4 w-28" />
        </div>
      ))}
    </div>
  );
}

export function ScheduleSkeleton() {
  return (
    <div className="space-y-4">
      <Shimmer className="h-48 w-full rounded-none" />
      <div className="card !p-4 space-y-3 -mt-6 mx-4">
        <Shimmer className="h-6 w-48" />
        <Shimmer className="h-4 w-full" />
        <Shimmer className="h-4 w-32" />
      </div>
      <div className="px-4 flex flex-wrap gap-2">
        {Array.from({ length: 12 }).map((_, i) => (
          <Shimmer key={i} className="h-9 w-24 rounded-full" />
        ))}
      </div>
    </div>
  );
}

export function HistoryListSkeleton() {
  return (
    <div className="space-y-3 p-4">
      <div className="h-24 rounded-2xl animate-pulse bg-gray-200" />
      {Array.from({ length: 4 }).map((_, i) => (
        <div key={i} className="card !p-4 space-y-2">
          <div className="h-5 w-32 animate-pulse bg-gray-200 rounded" />
          <div className="h-4 w-full animate-pulse bg-gray-100 rounded" />
        </div>
      ))}
    </div>
  );
}

export function OwnerDashboardSkeleton() {
  return (
    <div className="space-y-4 p-4">
      <Shimmer className="h-28 w-full rounded-2xl" />
      <div className="grid grid-cols-2 gap-3">
        <Shimmer className="h-20 rounded-xl" />
        <Shimmer className="h-20 rounded-xl" />
      </div>
      {Array.from({ length: 3 }).map((_, i) => (
        <div key={i} className="card !p-4 space-y-3">
          <Shimmer className="h-5 w-36" />
          <Shimmer className="h-4 w-full" />
          <div className="flex gap-2">
            <Shimmer className="h-10 flex-1 rounded-xl" />
            <Shimmer className="h-10 flex-1 rounded-xl" />
          </div>
        </div>
      ))}
    </div>
  );
}

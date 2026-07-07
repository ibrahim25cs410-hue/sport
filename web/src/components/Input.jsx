export default function Input({ label, icon: Icon, ...props }) {
  return (
    <div className="mb-4">
      {label && <label className="block text-sm font-medium text-gray-600 mb-1.5 text-right">{label}</label>}
      <div className="relative">
        {Icon && (
          <Icon className="absolute right-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400 pointer-events-none" />
        )}
        <input
          className={`input-field ${Icon ? 'pr-12' : ''}`}
          dir="rtl"
          {...props}
        />
      </div>
    </div>
  );
}

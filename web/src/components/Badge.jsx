export default function Badge({ status }) {
  const map = {
    pending: { cls: 'bg-amber-100 text-amber-700', label: 'بانتظار الموافقة' },
    approved: { cls: 'bg-green-100 text-green-700', label: 'مؤكد' },
    rejected: { cls: 'bg-red-100 text-red-700', label: 'مرفوض' },
    cancelled: { cls: 'bg-gray-100 text-gray-500', label: 'ملغي' },
  };
  const s = map[status] || map.pending;
  return (
    <span className={`inline-block px-3 py-1 rounded-full text-xs font-bold ${s.cls}`}>
      {s.label}
    </span>
  );
}

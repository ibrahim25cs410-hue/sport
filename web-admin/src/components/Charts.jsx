/** Simple SVG charts — no chart library dependency */

export function BarChart({ data, height = 180, valueKey = 'value', labelKey = 'label', color = '#2d6a3e' }) {
  const max = Math.max(1, ...data.map((d) => Number(d[valueKey]) || 0));
  const barW = 36;
  const gap = 18;
  const padX = 16;
  const padY = 24;
  const width = padX * 2 + data.length * (barW + gap) - gap;
  const innerH = height - padY * 2;

  return (
    <svg viewBox={`0 0 ${width} ${height}`} className="w-full h-auto" role="img" aria-label="مخطط أعمدة">
      {data.map((d, i) => {
        const v = Number(d[valueKey]) || 0;
        const h = (v / max) * innerH;
        const x = padX + i * (barW + gap);
        const y = padY + innerH - h;
        return (
          <g key={d[labelKey] || i}>
            <rect x={x} y={y} width={barW} height={Math.max(h, 2)} rx="8" fill={color} opacity={0.85 + (i % 3) * 0.05} />
            <text x={x + barW / 2} y={height - 6} textAnchor="middle" className="fill-pitch-600" style={{ fontSize: 10 }}>
              {d[labelKey]}
            </text>
            <text x={x + barW / 2} y={y - 6} textAnchor="middle" className="fill-pitch-800" style={{ fontSize: 11, fontWeight: 700 }}>
              {v}
            </text>
          </g>
        );
      })}
    </svg>
  );
}

export function DonutChart({ segments, size = 160, thickness = 22 }) {
  const total = Math.max(1, segments.reduce((s, x) => s + (Number(x.value) || 0), 0));
  const r = (size - thickness) / 2;
  const c = 2 * Math.PI * r;
  let offset = 0;

  return (
    <div className="flex items-center gap-5">
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} className="-rotate-90">
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="#e0efe3" strokeWidth={thickness} />
        {segments.map((seg) => {
          const val = Number(seg.value) || 0;
          const len = (val / total) * c;
          const el = (
            <circle
              key={seg.label}
              cx={size / 2}
              cy={size / 2}
              r={r}
              fill="none"
              stroke={seg.color}
              strokeWidth={thickness}
              strokeDasharray={`${len} ${c - len}`}
              strokeDashoffset={-offset}
              strokeLinecap="butt"
            />
          );
          offset += len;
          return el;
        })}
      </svg>
      <ul className="space-y-2 text-sm">
        {segments.map((seg) => (
          <li key={seg.label} className="flex items-center gap-2">
            <span className="h-2.5 w-2.5 rounded-sm" style={{ background: seg.color }} />
            <span className="text-pitch-700">{seg.label}</span>
            <span className="mr-auto font-bold text-pitch-950">{seg.value}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}

export function ProgressBar({ value, max = 100, label, color = 'bg-pitch-600' }) {
  const pct = Math.min(100, Math.round((Number(value) / Math.max(1, max)) * 100));
  return (
    <div>
      <div className="mb-1.5 flex items-center justify-between text-xs">
        <span className="font-semibold text-pitch-700">{label}</span>
        <span className="font-bold text-pitch-900">{pct}%</span>
      </div>
      <div className="h-2 overflow-hidden rounded-full bg-pitch-100">
        <div className={`h-full rounded-full ${color}`} style={{ width: `${pct}%` }} />
      </div>
    </div>
  );
}

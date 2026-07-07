import { Loader2 } from 'lucide-react';

export default function Button({ children, variant = 'primary', loading, className = '', ...props }) {
  const variants = {
    primary: 'btn-primary',
    secondary: 'btn-secondary',
    danger: 'btn-danger',
  };

  return (
    <button className={`${variants[variant]} ${className} flex items-center justify-center gap-2`} disabled={loading} {...props}>
      {loading && <Loader2 className="w-5 h-5 animate-spin" />}
      {children}
    </button>
  );
}

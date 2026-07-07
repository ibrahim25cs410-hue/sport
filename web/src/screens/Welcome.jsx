import { useNavigate } from 'react-router-dom';
import { User, Building2, LogIn } from 'lucide-react';
import AppLogo from '../components/AppLogo';

export default function Welcome() {
  const navigate = useNavigate();

  return (
    <div className="app-shell min-h-screen flex flex-col animate-fade-in">
      <div className="gradient-hero flex-1 flex flex-col items-center justify-center px-8 pb-12 relative overflow-hidden">
        <div className="absolute inset-0 opacity-10">
          <div className="absolute top-10 right-10 w-40 h-40 rounded-full bg-white blur-3xl" />
          <div className="absolute bottom-20 left-5 w-60 h-60 rounded-full bg-accent blur-3xl" />
        </div>

        <div className="relative z-10 text-center">
          <AppLogo size={140} light />
          <p className="text-white/80 text-lg mt-2 mb-1">احجز ملعبك بسهولة</p>
          <p className="text-accent font-semibold text-sm">محافظة نينوى</p>
        </div>
      </div>

      <div className="bg-white rounded-t-[2rem] -mt-8 relative z-10 px-6 pt-8 pb-10 shadow-float animate-slide-up">
        <p className="text-center text-gray-500 mb-6">اختر نوع حسابك للبدء</p>

        <button
          onClick={() => navigate('/register-user')}
          className="w-full flex items-center gap-4 p-4 mb-3 rounded-2xl border-2 border-brand-100 bg-brand-50 hover:bg-brand-100 active:scale-[0.98] transition-all"
        >
          <div className="w-14 h-14 rounded-2xl gradient-hero flex items-center justify-center shrink-0">
            <User className="w-7 h-7 text-white" />
          </div>
          <div className="text-right flex-1">
            <p className="font-bold text-lg text-brand-700">مستخدم جديد</p>
            <p className="text-gray-500 text-sm">احجز ملعب واستمتع بلعبتك</p>
          </div>
        </button>

        <button
          onClick={() => navigate('/register-owner')}
          className="w-full flex items-center gap-4 p-4 mb-2 rounded-2xl border-2 border-amber-100 bg-amber-50 hover:bg-amber-100 active:scale-[0.98] transition-all"
        >
          <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-amber-500 to-amber-600 flex items-center justify-center shrink-0">
            <Building2 className="w-7 h-7 text-white" />
          </div>
          <div className="text-right flex-1">
            <p className="font-bold text-lg text-amber-700">صاحب ملعب جديد</p>
            <p className="text-gray-500 text-sm">سجّل ملعبك وابدأ باستقبال الحجوزات</p>
          </div>
        </button>

        <button
          onClick={() => navigate('/login')}
          className="w-full flex items-center justify-center gap-2 text-amber-700 font-semibold text-sm py-2 mb-6 hover:bg-amber-50 rounded-xl transition-colors"
        >
          <LogIn className="w-4 h-4" />
          صاحب ملعب ولديك حساب؟ تسجيل الدخول
        </button>

        <button
          onClick={() => navigate('/login')}
          className="w-full flex items-center justify-center gap-2 text-brand-600 font-bold py-3 hover:bg-brand-50 rounded-2xl transition-colors"
        >
          <LogIn className="w-5 h-5" />
          لدي حساب - تسجيل الدخول
        </button>
      </div>
    </div>
  );
}

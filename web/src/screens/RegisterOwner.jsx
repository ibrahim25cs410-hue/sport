import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { User, Mail, Phone, Lock, Building2, MapPin, DollarSign } from 'lucide-react';
import { riyadaRepository } from '../repositories/riyadaRepository';
import { useAuth } from '../context/AuthContext';
import { useSmartToast } from '../context/SmartToastContext';
import Header from '../components/Header';
import Input from '../components/Input';
import Button from '../components/Button';

export default function RegisterOwner() {
  const navigate = useNavigate();
  const { login } = useAuth();
  const { success, smartError } = useSmartToast();
  const [form, setForm] = useState({
    name: '', email: '', phone: '', password: '',
    stadiumName: '', stadiumAddress: '', stadiumPhone: '', pricePerHour: '',
  });
  const [loading, setLoading] = useState(false);

  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value });

  const submit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const result = await riyadaRepository.registerOwner({
        name: form.name, email: form.email, phone: form.phone, password: form.password,
        stadiumName: form.stadiumName, stadiumAddress: form.stadiumAddress,
        stadiumPhone: form.stadiumPhone, pricePerHour: parseInt(form.pricePerHour, 10),
      });
      login(result);
      success('تم إنشاء حساب الملعب بنجاح!');
      navigate('/owner', { replace: true });
    } catch (err) {
      smartError(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="app-shell min-h-screen animate-fade-in pb-8">
      <Header title="تسجيل صاحب ملعب" subtitle="سجّل ملعبك وابدأ باستقبال الحجوزات" onBack={() => navigate('/')} />

      <form onSubmit={submit} className="px-5 py-6">
        <div className="flex items-center gap-2 mb-4">
          <div className="h-px flex-1 bg-brand-200" />
          <span className="text-sm font-bold text-brand-600">معلوماتك الشخصية</span>
          <div className="h-px flex-1 bg-brand-200" />
        </div>

        <Input label="الاسم" icon={User} value={form.name} onChange={set('name')} required />
        <Input label="البريد الإلكتروني" icon={Mail} type="email" value={form.email} onChange={set('email')} required />
        <Input label="رقم الهاتف" icon={Phone} type="tel" value={form.phone} onChange={set('phone')} required />
        <Input label="كلمة المرور" icon={Lock} type="password" value={form.password} onChange={set('password')} required />

        <div className="flex items-center gap-2 mb-4 mt-6">
          <div className="h-px flex-1 bg-amber-200" />
          <span className="text-sm font-bold text-amber-600">معلومات الملعب</span>
          <div className="h-px flex-1 bg-amber-200" />
        </div>

        <Input label="اسم الملعب" icon={Building2} value={form.stadiumName} onChange={set('stadiumName')} required />
        <Input label="عنوان الملعب" icon={MapPin} value={form.stadiumAddress} onChange={set('stadiumAddress')} required />
        <Input label="هاتف الملعب" icon={Phone} type="tel" value={form.stadiumPhone} onChange={set('stadiumPhone')} required />
        <Input label="سعر الساعة (دينار)" icon={DollarSign} type="number" value={form.pricePerHour} onChange={set('pricePerHour')} required />

        <Button type="submit" loading={loading} className="mt-4">إنشاء حساب الملعب</Button>

        <p className="text-center text-gray-500 text-sm mt-6">
          لديك حساب بالفعل؟{' '}
          <button type="button" onClick={() => navigate('/login')} className="text-amber-600 font-bold hover:underline">
            تسجيل الدخول
          </button>
        </p>
      </form>
    </div>
  );
}

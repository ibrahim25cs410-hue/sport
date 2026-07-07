import { useState, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { User, Mail, Phone, Lock, Camera, MapPin } from 'lucide-react';
import { riyadaRepository } from '../repositories/riyadaRepository';
import { useAuth } from '../context/AuthContext';
import { useSmartToast } from '../context/SmartToastContext';
import Header from '../components/Header';
import Input from '../components/Input';
import Button from '../components/Button';

export default function RegisterUser() {
  const navigate = useNavigate();
  const { login } = useAuth();
  const { success, smartError } = useSmartToast();
  const fileRef = useRef();
  const [form, setForm] = useState({ name: '', email: '', phone: '', password: '' });
  const [image, setImage] = useState(null);
  const [loading, setLoading] = useState(false);

  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value });

  const pickImage = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => setImage(reader.result);
    reader.readAsDataURL(file);
  };

  const submit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const phone = form.phone.replace(/\D/g, '');
      console.log('[RegisterUser] إرسال طلب التسجيل...');
      const result = await riyadaRepository.registerUser({ ...form, phone, province: 'نينوى', image });
      console.log('[RegisterUser] نجح التسجيل:', result.user?.email);
      login(result);
      success('تم إنشاء حسابك بنجاح!');
      navigate('/home', { replace: true });
    } catch (err) {
      console.error('[RegisterUser] فشل التسجيل:', err);
      smartError(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="app-shell min-h-screen animate-fade-in pb-8">
      <Header title="تسجيل مستخدم" subtitle="أنشئ حسابك للبدء بالحجز" onBack={() => navigate('/')} />

      <form onSubmit={submit} className="px-5 py-6">
        <div className="flex flex-col items-center mb-6">
          <button type="button" onClick={() => fileRef.current?.click()}
            className="relative w-24 h-24 rounded-full bg-brand-50 border-2 border-dashed border-brand-300 flex items-center justify-center overflow-hidden hover:border-brand-500 transition-colors">
            {image ? (
              <img src={image} alt="" className="w-full h-full object-cover" />
            ) : (
              <Camera className="w-8 h-8 text-brand-400" />
            )}
          </button>
          <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={pickImage} />
          <p className="text-sm text-brand-600 mt-2 font-medium">إضافة صورة شخصية</p>
        </div>

        <Input label="الاسم الكامل" icon={User} value={form.name} onChange={set('name')} placeholder="محمد أحمد" required />
        <Input label="البريد الإلكتروني" icon={Mail} type="email" value={form.email} onChange={set('email')} required />
        <Input label="رقم الهاتف" icon={Phone} type="tel" value={form.phone} onChange={set('phone')} placeholder="07XXXXXXXXX" required />
        <Input label="كلمة المرور" icon={Lock} type="password" value={form.password} onChange={set('password')} required />

        <div className="mb-4">
          <label className="block text-sm font-medium text-gray-600 mb-1.5 text-right">المحافظة</label>
          <div className="input-field flex items-center gap-2 bg-gray-50 text-gray-500">
            <MapPin className="w-5 h-5 text-brand-500" />
            نينوى
          </div>
        </div>

        <Button type="submit" loading={loading}>تسجيل ودخول</Button>
      </form>
    </div>
  );
}

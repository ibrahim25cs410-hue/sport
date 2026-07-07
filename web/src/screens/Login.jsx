import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Mail, Lock } from 'lucide-react';
import { riyadaRepository } from '../repositories/riyadaRepository';
import { useAuth } from '../context/AuthContext';
import { useSmartToast } from '../context/SmartToastContext';
import Header from '../components/Header';
import Input from '../components/Input';
import Button from '../components/Button';

export default function Login() {
  const navigate = useNavigate();
  const { login } = useAuth();
  const { success, smartError } = useSmartToast();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const result = await riyadaRepository.login(email, password);
      login(result);
      success('تم تسجيل الدخول بنجاح');
      navigate(result.user.role === 'admin' ? '/admin' : result.user.role === 'owner' ? '/owner' : '/home', { replace: true });
    } catch (err) {
      smartError(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="app-shell min-h-screen animate-fade-in">
      <Header title="تسجيل الدخول" subtitle="أدخل بيانات حسابك" onBack={() => navigate('/')} />

      <form onSubmit={handleLogin} className="px-5 py-8">
        <Input label="البريد الإلكتروني" icon={Mail} type="email" value={email}
          onChange={(e) => setEmail(e.target.value)} placeholder="example@email.com" required />
        <Input label="كلمة المرور" icon={Lock} type="password" value={password}
          onChange={(e) => setPassword(e.target.value)} placeholder="••••••••" required />

        <Button type="submit" loading={loading} className="mt-4">دخول</Button>

        <p className="text-center text-gray-500 text-sm mt-6">
          صاحب ملعب جديد؟{' '}
          <button type="button" onClick={() => navigate('/register-owner')} className="text-amber-600 font-bold hover:underline">
            سجّل ملعبك
          </button>
        </p>

        <p className="text-center text-gray-400 text-xs mt-3">
          حساب تجريبي: owner@test.com / 123456
        </p>
      </form>
    </div>
  );
}

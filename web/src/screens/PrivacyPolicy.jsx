import { Link, useNavigate } from 'react-router-dom';
import Header from '../components/Header';
import PageTransition from '../components/PageTransition';

export default function PrivacyPolicy() {
  const navigate = useNavigate();
  return (
    <PageTransition>
      <div className="min-h-screen bg-slate-950 text-slate-100">
        <Header title="سياسة الخصوصية" onBack={() => navigate(-1)} />
        <main className="max-w-2xl mx-auto px-4 py-8 prose prose-invert prose-sm">
          <p className="text-slate-400">آخر تحديث: يوليو 2026</p>

          <h2>مقدمة</h2>
          <p>
            تطبيق «رياضة» (Riyada) يتيح حجز الملاعب الرياضية في العراق. نحترم خصوصيتك ونلتزم بحماية بياناتك
            وفق هذه السياسة.
          </p>

          <h2>البيانات التي نجمعها</h2>
          <ul>
            <li>معلومات الحساب: الاسم، البريد الإلكتروني، رقم الهاتف</li>
            <li>بيانات الحجز: الملعب، التاريخ، المدة، حالة الدفع</li>
            <li>الموقع (بإذنك): لعرض الملاعب القريبة</li>
            <li>معرّف الجهاز لإشعارات Firebase (FCM)</li>
            <li>الصور التي ترفعها كصورة شخصية (اختياري)</li>
          </ul>

          <h2>كيف نستخدم البيانات</h2>
          <ul>
            <li>إتمام الحجوزات والدفع</li>
            <li>إرسال إشعارات بحالة الحجز</li>
            <li>تحسين الخدمة ودعم المستخدمين</li>
            <li>منع الاحتيال وإساءة الاستخدام</li>
          </ul>

          <h2>مشاركة البيانات</h2>
          <p>
            نشارك بيانات الحجز مع صاحب الملعب المعني فقط. لا نبيع بياناتك لأطراف ثالثة. قد نستخدم مزودي
            خدمات (استضافة، Firebase، بوابات الدفع) بموجب عقود حماية البيانات.
          </p>

          <h2>الأمان</h2>
          <p>
            نستخدم HTTPS لتشفير الاتصال. كلمات المرور مخزّنة بشكل مشفّر. يُنصح بعدم مشاركة بيانات الدخول.
          </p>

          <h2>حقوقك</h2>
          <p>
            يمكنك طلب تصحيح أو حذف حسابك عبر التواصل معنا. يمكنك إلغاء إذن الموقع أو الإشعارات من إعدادات
            جهازك.
          </p>

          <h2>الأطفال</h2>
          <p>التطبيق غير موجّه لمن دون 13 عاماً.</p>

          <h2>التواصل</h2>
          <p>
            البريد: <a href="mailto:support@riyada.iq">support@riyada.iq</a>
          </p>

          <p className="pt-6">
            <Link to="/" className="text-teal-400 hover:underline">
              العودة للرئيسية
            </Link>
          </p>
        </main>
      </div>
    </PageTransition>
  );
}

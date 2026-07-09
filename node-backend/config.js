/**
 * إعدادات البيئة — مصدر واحد لجميع المتغيرات.
 * في الإنتاج: MONGODB_URI و JWT_SECRET إلزاميان.
 */

const IS_PROD = process.env.NODE_ENV === 'production';

const config = {
  port: Number(process.env.PORT) || 3000,
  jwtSecret: process.env.JWT_SECRET || '',
  mongodbUri: process.env.MONGODB_URI || '',
  isProd: IS_PROD,
  commissionRate: 0.10,
};

function validateConfig() {
  const missing = [];
  if (IS_PROD && !config.mongodbUri) missing.push('MONGODB_URI');
  if (IS_PROD && !config.jwtSecret) missing.push('JWT_SECRET');
  if (missing.length) {
    console.error(`❌ متغيرات البيئة المطلوبة في الإنتاج: ${missing.join(', ')}`);
    process.exit(1);
  }
  if (!config.jwtSecret) {
    config.jwtSecret = 'dev-secret-change-me';
    console.warn('⚠️  JWT_SECRET غير مضبوط — يُستخدم مفتاح تطوير (لا تستخدمه في الإنتاج).');
  }
  if (!config.mongodbUri) {
    console.warn('⚠️  MONGODB_URI غير مضبوط — التخزين في الذاكرة (البيانات تُمسح عند إعادة التشغيل).');
  }
}

module.exports = { config, validateConfig };

export const CASH_PAYMENT_METHOD = 'cash';

export function assertCashOnly(paymentMethod = CASH_PAYMENT_METHOD) {
  if (paymentMethod !== CASH_PAYMENT_METHOD) {
    const error = new Error('CASH_ONLY');
    error.code = 'CASH_ONLY';
    throw error;
  }
  return CASH_PAYMENT_METHOD;
}

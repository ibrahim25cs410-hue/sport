import { describe, expect, it } from 'vitest';
import { assertCashOnly, CASH_PAYMENT_METHOD } from './paymentPolicy';

describe('cash-only policy', () => {
  it('accepts cash', () => {
    expect(assertCashOnly('cash')).toBe(CASH_PAYMENT_METHOD);
  });

  it.each(['card', 'wallet', 'bank_transfer'])('rejects %s', (method) => {
    expect(() => assertCashOnly(method)).toThrowError('CASH_ONLY');
  });
});

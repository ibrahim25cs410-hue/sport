import { render, screen } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';
import { ErrorBoundary } from './AppQuality';

vi.mock('../lib/monitoring', () => ({ captureException: vi.fn() }));

function Broken() {
  throw new Error('failure');
}

describe('customer error boundary', () => {
  it('renders an Arabic recovery surface', () => {
    document.documentElement.lang = 'ar';
    render(<ErrorBoundary><Broken /></ErrorBoundary>);
    expect(screen.getByRole('alert')).toHaveTextContent('حدث خطأ غير متوقع');
    expect(screen.queryByText('failure')).not.toBeInTheDocument();
  });
});

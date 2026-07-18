import { render, screen } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';
import { ErrorBoundary } from './AppQuality';

vi.mock('../lib/monitoring', () => ({ captureException: vi.fn() }));

function Broken() {
  throw new Error('private failure');
}

describe('ErrorBoundary', () => {
  it('shows a recoverable, privacy-safe fallback', () => {
    document.documentElement.lang = 'en';
    render(<ErrorBoundary><Broken /></ErrorBoundary>);
    expect(screen.getByRole('alert')).toHaveTextContent('could not be displayed');
    expect(screen.getByRole('button', { name: 'Try again' })).toBeEnabled();
  });
});

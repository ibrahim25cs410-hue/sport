import React from 'react';
import ReactDOM from 'react-dom/client';
import { QueryClientProvider } from '@tanstack/react-query';
import './i18n';
import App from './App';
import { queryClient } from './lib/queryClient';
import { ErrorBoundary } from './components/AppQuality';
import { initMonitoring } from './lib/monitoring';
import './index.css';

initMonitoring();

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <ErrorBoundary>
      <QueryClientProvider client={queryClient}>
        <App />
      </QueryClientProvider>
    </ErrorBoundary>
  </React.StrictMode>
);

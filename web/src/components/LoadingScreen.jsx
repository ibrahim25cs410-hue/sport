import { AppLoadingScreen } from './AppLogo';

export default function LoadingScreen({ message = 'جاري التحميل...' }) {
  return <div role="status" aria-live="polite" aria-busy="true"><AppLoadingScreen message={message} /></div>;
}

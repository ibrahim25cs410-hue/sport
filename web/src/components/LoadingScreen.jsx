import { AppLoadingScreen } from './AppLogo';

export default function LoadingScreen({ message = 'جاري التحميل...' }) {
  return <AppLoadingScreen message={message} />;
}

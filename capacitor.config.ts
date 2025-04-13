
import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'app.lovable.5705166c114b4808b1867bd844609ed0',
  appName: 'credit-card-savvy-droid',
  webDir: 'dist',
  server: {
    url: "https://5705166c-114b-4808-b186-7bd844609ed0.lovableproject.com?forceHideBadge=true",
    cleartext: true
  },
  android: {
    buildOptions: {
      keystorePath: undefined,
      keystoreAlias: undefined,
      keystorePassword: undefined,
      keystoreAliasPassword: undefined,
    }
  }
};

export default config;

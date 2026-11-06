// Type definitions for fload-attribution-cordova. The plugin is on `window.FloadAttribution`
// after `deviceready`.

export type FloadLogLevel = 'none' | 'error' | 'warning' | 'info' | 'debug';

export interface ConfigureOptions {
  /** The app's public write key (`fload_pk_…`) from Fload. */
  key: string;
  /** Fload's ingest endpoint. Change it only to test against your own Fload API. Default `https://ingest.fload.com`. */
  endpoint?: string;
  /** Default `warning`. */
  logLevel?: FloadLogLevel;
}

export interface FloadAttributionPlugin {
  /** Starts the SDK. Call it once, early, after `deviceready`. */
  configure(options: ConfigureOptions): Promise<void>;
  /** Links your app's user id (for example RevenueCat's appUserID) to this install. */
  setUserId(options: { id: string }): Promise<void>;
  /** This install's random reference, or null before configure has loaded the SDK's state. */
  getInstallReference(): Promise<{ installReference: string | null }>;
}

declare global {
  interface Window {
    FloadAttribution: FloadAttributionPlugin;
  }
  const FloadAttribution: FloadAttributionPlugin;
}

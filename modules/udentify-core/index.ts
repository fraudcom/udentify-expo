// udentify-core - Core shared components for Udentify Expo modules
// This package provides shared native frameworks and utilities used by expo-nfc, expo-ocr, and other Udentify modules

import { requireNativeModule } from 'expo-modules-core';

export interface UdentifyCoreModule {
  getVersion(): string;
  getFrameworkInfo(): {
    ios: string[];
    android: string[];
  };
  loadCertificateFromAssets(certificateName: string, extension: string): Promise<boolean>;
  setSSLCertificateBase64(certificateBase64: string): Promise<boolean>;
  removeSSLCertificate(): Promise<boolean>;
  getSSLCertificateBase64(): Promise<string | null>;
  isSSLPinningEnabled(): Promise<boolean>;
  instantiateServerBasedLocalization(language: string, serverUrl: string, transactionId: string, requestTimeout: number): Promise<void>;
  getLocalizationMap(): Promise<Record<string, string> | null>;
  clearLocalizationCache(language: string): Promise<void>;
  mapSystemLanguageToEnum(): Promise<string | null>;
}

// Require the native module
const UdentifyCoreNative = requireNativeModule<UdentifyCoreModule>('UdentifyCore');

// MARK: - SSL Pinning Functions

/**
 * Load a certificate from the app bundle (iOS) or assets folder (Android)
 * and automatically set it for SSL pinning.
 * 
 * The certificate must be in DER format with .cer or .der extension.
 * 
 * @param certificateName - Name of the certificate file without extension (e.g., 'MyServerCertificate')
 * @param extension - File extension, typically 'cer' or 'der'
 * @returns Promise resolving to true if certificate was loaded and set successfully
 * 
 * @example
 * ```typescript
 * await loadCertificateFromAssets('MyServerCertificate', 'cer');
 * ```
 */
export async function loadCertificateFromAssets(
  certificateName: string,
  extension: string
): Promise<boolean> {
  console.log('UdentifyCore - loadCertificateFromAssets called');
  
  try {
    const result = await UdentifyCoreNative.loadCertificateFromAssets(
      certificateName,
      extension
    );
    console.log('UdentifyCore - Certificate loaded successfully');
    return result;
  } catch (error) {
    console.error('UdentifyCore - Failed to load certificate:', error);
    throw error;
  }
}

/**
 * Set SSL certificate using base64 encoded certificate data.
 * The certificate must be in DER format.
 * 
 * @param certificateBase64 - Base64 encoded certificate data
 * @returns Promise resolving to true if certificate was set successfully
 * 
 * @example
 * ```typescript
 * await setSSLCertificateBase64(base64EncodedCertificate);
 * ```
 */
export async function setSSLCertificateBase64(
  certificateBase64: string
): Promise<boolean> {
  console.log('UdentifyCore - setSSLCertificateBase64 called');
  
  try {
    const result = await UdentifyCoreNative.setSSLCertificateBase64(certificateBase64);
    console.log('UdentifyCore - SSL certificate set successfully');
    return result;
  } catch (error) {
    console.error('UdentifyCore - Failed to set SSL certificate:', error);
    throw error;
  }
}

/**
 * Remove the currently set SSL certificate, disabling SSL pinning.
 * 
 * @returns Promise resolving to true if certificate was removed successfully
 * 
 * @example
 * ```typescript
 * await removeSSLCertificate();
 * ```
 */
export async function removeSSLCertificate(): Promise<boolean> {
  console.log('UdentifyCore - removeSSLCertificate called');
  
  try {
    const result = await UdentifyCoreNative.removeSSLCertificate();
    console.log('UdentifyCore - SSL certificate removed successfully');
    return result;
  } catch (error) {
    console.error('UdentifyCore - Failed to remove SSL certificate:', error);
    throw error;
  }
}

/**
 * Get the currently set SSL certificate as a base64 encoded string.
 * 
 * @returns Promise resolving to base64 string or null if no certificate is set
 * 
 * @example
 * ```typescript
 * const cert = await getSSLCertificateBase64();
 * if (cert) {
 *   console.log('Certificate is set');
 * }
 * ```
 */
export async function getSSLCertificateBase64(): Promise<string | null> {
  console.log('UdentifyCore - getSSLCertificateBase64 called');
  
  try {
    const result = await UdentifyCoreNative.getSSLCertificateBase64();
    console.log('UdentifyCore - Retrieved SSL certificate');
    return result;
  } catch (error) {
    console.error('UdentifyCore - Failed to get SSL certificate:', error);
    throw error;
  }
}

/**
 * Check if SSL pinning is currently enabled.
 * 
 * @returns Promise resolving to true if SSL pinning is enabled
 * 
 * @example
 * ```typescript
 * const isEnabled = await isSSLPinningEnabled();
 * console.log('SSL Pinning enabled:', isEnabled);
 * ```
 */
export async function isSSLPinningEnabled(): Promise<boolean> {
  console.log('UdentifyCore - isSSLPinningEnabled called');
  
  try {
    const result = await UdentifyCoreNative.isSSLPinningEnabled();
    console.log('UdentifyCore - SSL pinning enabled:', result);
    return result;
  } catch (error) {
    console.error('UdentifyCore - Failed to check SSL pinning status:', error);
    throw error;
  }
}

// MARK: - Remote Language Pack Functions

/**
 * Instantiate server-based localization by downloading the localization file from the server.
 * This should be called before using any Udentify modules to ensure localization is available.
 * 
 * @param language - Language code (e.g., 'EN', 'FR', 'TR', 'DE', 'ES', 'IT', 'PT', 'RU', 'AR', 'ZH', 'JA', 'KO')
 * @param serverUrl - URL of the Udentify API Server where the localization file is hosted
 * @param transactionId - Transaction ID received from Udentify API Server
 * @param requestTimeout - Timeout duration for the network request in seconds (default: 30)
 * @returns Promise resolving when localization is instantiated
 * 
 * @example
 * ```typescript
 * const language = await mapSystemLanguageToEnum() || 'EN';
 * await instantiateServerBasedLocalization(language, serverUrl, transactionId);
 * ```
 */
export async function instantiateServerBasedLocalization(
  language: string,
  serverUrl: string,
  transactionId: string,
  requestTimeout: number = 30
): Promise<void> {
  console.log('UdentifyCore - instantiateServerBasedLocalization called');
  
  try {
    await UdentifyCoreNative.instantiateServerBasedLocalization(
      language,
      serverUrl,
      transactionId,
      requestTimeout
    );
    console.log('UdentifyCore - Server-based localization instantiated successfully');
  } catch (error) {
    console.error('UdentifyCore - Failed to instantiate localization:', error);
    throw error;
  }
}

/**
 * Get the localization map downloaded from the server.
 * This map contains the localization content for the current language.
 * 
 * Note: The localization map is used automatically by the SDK in the background.
 * This method is primarily for debugging purposes.
 * 
 * @returns Promise resolving to localization map or null if not available
 * 
 * @example
 * ```typescript
 * const map = await getLocalizationMap();
 * if (map) {
 *   console.log('Localization entries:', Object.keys(map).length);
 * }
 * ```
 */
export async function getLocalizationMap(): Promise<Record<string, string> | null> {
  console.log('UdentifyCore - getLocalizationMap called');
  
  try {
    const result = await UdentifyCoreNative.getLocalizationMap();
    console.log('UdentifyCore - Retrieved localization map');
    return result;
  } catch (error) {
    console.error('UdentifyCore - Failed to get localization map:', error);
    throw error;
  }
}

/**
 * Clear the localization cache for a specific language.
 * This removes the localization content saved locally and updates the localization map to null.
 * 
 * @param language - Language code to clear cache for
 * @returns Promise resolving when cache is cleared
 * 
 * @example
 * ```typescript
 * await clearLocalizationCache('EN');
 * ```
 */
export async function clearLocalizationCache(language: string): Promise<void> {
  console.log('UdentifyCore - clearLocalizationCache called');
  
  try {
    await UdentifyCoreNative.clearLocalizationCache(language);
    console.log('UdentifyCore - Localization cache cleared successfully');
  } catch (error) {
    console.error('UdentifyCore - Failed to clear localization cache:', error);
    throw error;
  }
}

/**
 * Map the system language to the enum value used by the SDK.
 * This is useful for automatically detecting the user's preferred language.
 * 
 * @returns Promise resolving to language code or null if system language is not supported
 * 
 * @example
 * ```typescript
 * const systemLanguage = await mapSystemLanguageToEnum();
 * const language = systemLanguage || 'EN';
 * await instantiateServerBasedLocalization(language, serverUrl, transactionId);
 * ```
 */
export async function mapSystemLanguageToEnum(): Promise<string | null> {
  console.log('UdentifyCore - mapSystemLanguageToEnum called');
  
  try {
    const result = await UdentifyCoreNative.mapSystemLanguageToEnum();
    console.log('UdentifyCore - System language mapped:', result);
    return result;
  } catch (error) {
    console.error('UdentifyCore - Failed to map system language:', error);
    throw error;
  }
}

// Core framework info for debugging
export const UdentifyCore = {
  // Version info for debugging
  version: '1.0.0',
  
  // Core framework info
  frameworks: {
    ios: ['UdentifyCommons.xcframework'],
    android: ['commons-25.2.1.aar']
  },
  
  // Platform availability
  platforms: {
    ios: true,
    android: true
  }
};

export default UdentifyCore;

export * from "./src/ExpoNFC.types";

export { default } from './src/ExpoNFCModule';

import ExpoNfcModule from './src/ExpoNFCModule';

// Re-export types
export {
  NFCCredentials,
  NFCPassportResponse,
  NFCStatusResponse,
  NFCLocationResponse,
  NFCLocation,
  NFCAvailability
} from './src/ExpoNFC.types';

// Framework availability and info functions
export async function checkAvailability() {
  return await ExpoNfcModule.checkAvailability();
}

export async function getFrameworkInfo() {
  return await ExpoNfcModule.getFrameworkInfo();
}

// NFC Status functions
export async function isNFCAvailable(): Promise<boolean> {
  try {
    return await ExpoNfcModule.isNFCAvailable();
  } catch (error) {
    console.error('ExpoNfc - isNFCAvailable error:', error);
    return false;
  }
}

export async function isNFCEnabled(): Promise<boolean> {
  try {
    return await ExpoNfcModule.isNFCEnabled();
  } catch (error) {
    console.error('ExpoNfc - isNFCEnabled error:', error);
    return false;
  }
}

export async function getNFCStatus() {
  try {
    return await ExpoNfcModule.getNFCStatus();
  } catch (error) {
    console.error('ExpoNfc - getNFCStatus error:', error);
    return {
      isAvailable: false,
      isEnabled: false,
      message: `Error checking NFC status: ${error}`
    };
  }
}

// NFC Reading functions
export async function startNFCReading(credentials: any) {
  try {
    // Validate required MRZ credentials
    if (!credentials.documentNumber || !credentials.dateOfBirth || !credentials.expiryDate) {
      throw new Error('Document number, date of birth, and expiry date are required for NFC reading');
    }

    // Validate date formats (YYMMDD)
    const dateRegex = /^\d{6}$/;
    if (!dateRegex.test(credentials.dateOfBirth)) {
      throw new Error('Date of birth must be in YYMMDD format');
    }
    if (!dateRegex.test(credentials.expiryDate)) {
      throw new Error('Expiry date must be in YYMMDD format');
    }

    return await ExpoNfcModule.startNFCReading(credentials);
  } catch (error) {
    console.error('ExpoNfc - startNFCReading error:', error);
    throw error;
  }
}

export async function cancelNFCReading(): Promise<boolean> {
  try {
    return await ExpoNfcModule.cancelNFCReading();
  } catch (error) {
    console.error('ExpoNfc - cancelNFCReading error:', error);
    return false;
  }
}

// NFC Location functions
export async function getNFCLocation(serverURL: string) {
  try {
    if (!serverURL) {
      throw new Error('Server URL is required for NFC location detection');
    }

    return await ExpoNfcModule.getNFCLocation(serverURL);
  } catch (error) {
    console.error('ExpoNfc - getNFCLocation error:', error);
    throw error;
  }
}

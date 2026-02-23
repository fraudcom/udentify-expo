import { 
  NFCCredentials,
  NFCPassportResponse,
  NFCStatusResponse,
  NFCLocationResponse,
  NFCAvailability,
  NFCLocation
} from './ExpoNFC.types';

export default {
  async checkAvailability(): Promise<NFCAvailability> {
    return {
      isAvailable: false,
      deviceSupported: false,
      osVersion: 'Web',
      frameworkImported: false
    };
  },

  async getFrameworkInfo(): Promise<{
    frameworkName: string;
    version: string;
    status: string;
  }> {
    return {
      frameworkName: 'UdentifyNFC',
      version: 'Web stub',
      status: 'NFC not supported on web'
    };
  },

  async isNFCAvailable(): Promise<boolean> {
    return false;
  },

  async isNFCEnabled(): Promise<boolean> {
    return false;
  },

  async getNFCStatus(): Promise<NFCStatusResponse> {
    return {
      isAvailable: false,
      isEnabled: false,
      message: 'NFC is not supported on web platform'
    };
  },

  async startNFCReading(credentials: NFCCredentials): Promise<NFCPassportResponse> {
    throw new Error('NFC reading is not supported on web platform');
  },

  async cancelNFCReading(): Promise<boolean> {
    return false;
  },

  async getNFCLocation(serverURL: string): Promise<NFCLocationResponse> {
    return {
      success: false,
      location: NFCLocation.unknown,
      message: 'NFC location detection is not supported on web platform'
    };
  },
};

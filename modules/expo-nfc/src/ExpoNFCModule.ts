import { NativeModule, requireNativeModule } from 'expo';

import { 
  NFCCredentials,
  NFCPassportResponse,
  NFCStatusResponse,
  NFCLocationResponse,
  NFCAvailability
} from './ExpoNFC.types';

declare class ExpoNFCModule extends NativeModule {
  // Framework availability and info
  checkAvailability(): Promise<NFCAvailability>;
  getFrameworkInfo(): Promise<{
    frameworkName: string;
    version: string;
    status: string;
  }>;

  // NFC Status Methods
  isNFCAvailable(): Promise<boolean>;
  isNFCEnabled(): Promise<boolean>;
  getNFCStatus(): Promise<NFCStatusResponse>;

  // NFC Reading Methods
  startNFCReading(credentials: NFCCredentials): Promise<NFCPassportResponse>;
  cancelNFCReading(): Promise<boolean>;

  // NFC Location Methods
  getNFCLocation(serverURL: string): Promise<NFCLocationResponse>;
}

export default requireNativeModule<ExpoNFCModule>('ExpoNFC');

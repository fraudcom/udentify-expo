import { NativeModule, requireNativeModule } from 'expo';

import type {DocumentTypeValue} from './constants/DocumentType';
import type {DocumentSideValue} from './constants/DocumentSide';
import type {OCRAvailability, DocumentLivenessResponse, OCRUIConfiguration} from './types/ui.types';
import type {OCRResponse, OCRAndDocumentLivenessResponse} from './types/ocr.types';
import type {HologramResponse} from './types/hologram.types';

declare class ExpoOCRModule extends NativeModule {
  // Framework availability and info
  checkAvailability(): Promise<OCRAvailability>;
  getFrameworkInfo(): Promise<{
    frameworkName: string;
    version: string;
    status: string;
  }>;
  
  // UI Configuration
  configureUISettings(uiConfig: OCRUIConfiguration): Promise<boolean>;
  
  // OCR Methods
  startOCRScanning(
    serverURL: string,
    transactionID: string,
    documentType: DocumentTypeValue,
    documentSide: DocumentSideValue,
    country?: string
  ): Promise<boolean>;
  
  performOCR(
    serverURL: string,
    transactionID: string,
    frontSideImage: string,
    backSideImage: string,
    documentType: DocumentTypeValue,
    country?: string
  ): Promise<OCRResponse>;
  
  performDocumentLiveness(
    serverURL: string,
    transactionID: string,
    frontSideImage: string,
    backSideImage: string
  ): Promise<DocumentLivenessResponse>;
  
  performOCRAndDocumentLiveness(
    serverURL: string,
    transactionID: string,
    frontSideImage: string,
    backSideImage: string,
    documentType: DocumentTypeValue,
    country?: string
  ): Promise<OCRAndDocumentLivenessResponse>;
  
  // Hologram Methods
  startHologramCamera(
    serverURL: string,
    transactionID: string
  ): Promise<boolean>;
  
  performHologramCheck(
    serverURL: string,
    transactionID: string,
    videoUrls: string[]
  ): Promise<HologramResponse>;
}

export default requireNativeModule<ExpoOCRModule>('ExpoOCR');

import type {DocumentTypeValue} from './constants/DocumentType';
import type {DocumentSideValue} from './constants/DocumentSide';
import type {OCRAvailability, DocumentLivenessResponse, OCRUIConfiguration} from './types/ui.types';
import type {OCRResponse, OCRAndDocumentLivenessResponse} from './types/ocr.types';
import type {HologramResponse} from './types/hologram.types';

const webNotSupportedError = () => {
  throw new Error("OCR functionality is not supported on web platform");
};

export default {
  async checkAvailability(): Promise<OCRAvailability> {
    return {
      isAvailable: false,
      reason: "OCR is not supported on web platform",
      deviceSupported: false,
      osVersion: "web",
      frameworkImported: false
    };
  },

  async getFrameworkInfo(): Promise<{
    frameworkName: string;
    version: string;
    status: string;
  }> {
    return {
      frameworkName: "UdentifyOCR",
      version: "Not available on web",
      status: "Web platform not supported"
    };
  },

  async configureUISettings(_uiConfig: OCRUIConfiguration): Promise<boolean> {
    console.warn("OCR UI configuration is not supported on web platform");
    return false;
  },

  async startOCRScanning(
    _serverURL: string,
    _transactionID: string,
    _documentType: DocumentTypeValue,
    _documentSide: DocumentSideValue,
    _country?: string
  ): Promise<boolean> {
    webNotSupportedError();
    return false;
  },

  async performOCR(
    _serverURL: string,
    _transactionID: string,
    _frontSideImage: string,
    _backSideImage: string,
    _documentType: DocumentTypeValue,
    _country?: string
  ): Promise<OCRResponse> {
    webNotSupportedError();
    return {} as OCRResponse;
  },

  async performDocumentLiveness(
    _serverURL: string,
    _transactionID: string,
    _frontSideImage: string,
    _backSideImage: string
  ): Promise<DocumentLivenessResponse> {
    webNotSupportedError();
    return {} as DocumentLivenessResponse;
  },

  async performOCRAndDocumentLiveness(
    _serverURL: string,
    _transactionID: string,
    _frontSideImage: string,
    _backSideImage: string,
    _documentType: DocumentTypeValue,
    _country?: string
  ): Promise<OCRAndDocumentLivenessResponse> {
    webNotSupportedError();
    return {} as OCRAndDocumentLivenessResponse;
  },

  async startHologramCamera(
    _serverURL: string,
    _transactionID: string
  ): Promise<boolean> {
    webNotSupportedError();
    return false;
  },

  async performHologramCheck(
    _serverURL: string,
    _transactionID: string,
    _videoUrls: string[]
  ): Promise<HologramResponse> {
    webNotSupportedError();
    return {} as HologramResponse;
  }
};

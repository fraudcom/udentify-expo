export interface OCRResponse {
  success: boolean;
  transactionID: string;
  documentType: string;
  extractedData: {
    firstName?: string;
    lastName?: string;
    documentNumber?: string;
    identityNo?: string;
    expiryDate?: string;
    birthDate?: string;
    nationality?: string;
    gender?: string;
    countryCode?: string;
    documentIssuer?: string;
    motherName?: string;
    fatherName?: string;
    licenseType?: string;
    city?: string;
    district?: string;
    isDocumentExpired?: boolean;
    isIDValid?: boolean;
    hasPhoto?: boolean;
    hasSignature?: boolean;
  };
  message?: string;
  timestamp: number;
}

export interface OCRAndDocumentLivenessResponse {
  success: boolean;
  transactionID: string;
  timestamp: number;
  
  ocrData?: OCRResponse;
  
  frontSideProbability?: number;
  backSideProbability?: number;
  frontSideResults?: Array<{
    name: string;
    probability: number;
    calibration: string;
  }>;
  backSideResults?: Array<{
    name: string;
    probability: number;
    calibration: string;
  }>;
  
  error?: string;
}

/**
 * Document Scan Result interface
 */
export interface DocumentScanResult {
  documentSide: 'frontSide' | 'backSide' | 'bothSide';
  frontSidePhoto?: string;
  backSidePhoto?: string;
  frontSidePhotoPath?: string;
  backSidePhotoPath?: string;
  transactionID?: string;
  serverURL?: string;
  documentType?: string;
}





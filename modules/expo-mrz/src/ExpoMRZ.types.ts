export interface MrzData {
  documentType: string;
  issuingCountry: string;
  documentNumber: string;
  optionalData1?: string;
  dateOfBirth: string;
  gender: string;
  dateOfExpiration: string;
  nationality: string;
  optionalData2?: string;
  surname: string;
  givenNames: string;
}

export interface BACCredentials {
  documentNumber: string;
  dateOfBirth: string;
  dateOfExpiration: string;
}

export interface MrzResult {
  success: boolean;
  mrzData?: MrzData;
  errorMessage?: string;
  bacCredentials?: BACCredentials;
  documentNumber?: string;
  dateOfBirth?: string;
  dateOfExpiration?: string;
}

export interface MrzUICustomization {
  focusViewBorderColor?: string;
  focusViewStrokeWidth?: number;
  instructionText?: string;
  instructionTextColor?: string;
  showCancelButton?: boolean;
  cancelButtonText?: string;
  cancelButtonColor?: string;
}

export enum MrzErrorType {
  MRZ_NOT_FOUND = 'ERR_MRZ_NOT_FOUND',
  INVALID_DATE_OF_BIRTH = 'ERR_INVALID_DATE_OF_BIRTH',
  INVALID_DATE_OF_BIRTH_SIZE = 'ERR_INVALID_DATE_OF_BIRTH_SIZE',
  INVALID_DATE_OF_EXPIRE = 'ERR_INVALID_DATE_OF_EXPIRE',
  INVALID_DATE_OF_EXPIRE_SIZE = 'ERR_INVALID_DATE_OF_EXPIRE_SIZE',
  INVALID_DOC_NO = 'ERR_INVALID_DOC_NO',
  CAMERA_ERROR = 'CAMERA_ERROR',
  PERMISSION_DENIED = 'PERMISSION_DENIED',
  SDK_NOT_AVAILABLE = 'SDK_NOT_AVAILABLE',
  USER_CANCELLED = 'USER_CANCELLED',
  UNKNOWN = 'UNKNOWN'
}

export type MrzProgressCallback = (progress: number) => void;


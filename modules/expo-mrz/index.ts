import { EventEmitter } from 'expo-modules-core';
import ExpoMRZModule from './src/ExpoMRZModule';

const eventEmitter = new EventEmitter(ExpoMRZModule);

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

export interface MrzUICustomization {
  focusViewBorderColor?: string;
  focusViewStrokeWidth?: number;
  instructionText?: string;
  instructionTextColor?: string;
  showCancelButton?: boolean;
  cancelButtonText?: string;
  cancelButtonColor?: string;
}

export async function checkPermissions(): Promise<boolean> {
  try {
    const result = await ExpoMRZModule.checkPermissions();
    return result;
  } catch (error) {
    console.error('ExpoMRZ - checkPermissions error:', error);
    return false;
  }
}

export async function requestPermissions(): Promise<string> {
  try {
    const result = await ExpoMRZModule.requestPermissions();
    return result;
  } catch (error) {
    console.error('ExpoMRZ - requestPermissions error:', error);
    return 'denied';
  }
}

export async function startMrzCamera(
  onProgress?: MrzProgressCallback,
  customization?: MrzUICustomization
): Promise<MrzResult> {
  let progressSubscription: any = null;
  
  if (onProgress) {
    progressSubscription = eventEmitter.addListener('onMrzProgress', (progress: number) => {
      onProgress(progress);
    });
  }
  
  try {
    const result = await ExpoMRZModule.startMrzCamera(customization);
    
    if (result.success && result.mrzData) {
      result.bacCredentials = {
        documentNumber: result.mrzData.documentNumber,
        dateOfBirth: result.mrzData.dateOfBirth,
        dateOfExpiration: result.mrzData.dateOfExpiration
      };
      
      result.documentNumber = result.mrzData.documentNumber;
      result.dateOfBirth = result.mrzData.dateOfBirth;
      result.dateOfExpiration = result.mrzData.dateOfExpiration;
    }
    
    return result;
  } catch (error) {
    console.error('ExpoMRZ - startMrzCamera error:', error);
    return {
      success: false,
      errorMessage: `Failed to start MRZ camera: ${error}`
    };
  } finally {
    if (progressSubscription) {
      progressSubscription.remove();
    }
  }
}

export async function processMrzImage(
  imageBase64: string
): Promise<MrzResult> {
  if (!imageBase64) {
    return {
      success: false,
      errorMessage: 'Image data is required'
    };
  }
  
  try {
    const result = await ExpoMRZModule.processMrzImage(imageBase64);
    
    if (result.success && result.mrzData) {
      result.bacCredentials = {
        documentNumber: result.mrzData.documentNumber,
        dateOfBirth: result.mrzData.dateOfBirth,
        dateOfExpiration: result.mrzData.dateOfExpiration
      };
      
      result.documentNumber = result.mrzData.documentNumber;
      result.dateOfBirth = result.mrzData.dateOfBirth;
      result.dateOfExpiration = result.mrzData.dateOfExpiration;
    }
    
    return result;
  } catch (error) {
    console.error('ExpoMRZ - processMrzImage error:', error);
    return {
      success: false,
      errorMessage: `Failed to process MRZ image: ${error}`
    };
  }
}

export async function cancelMrzScanning(): Promise<void> {
  try {
    await ExpoMRZModule.cancelMrzScanning();
  } catch (error) {
    console.error('ExpoMRZ - cancelMrzScanning error:', error);
    throw error;
  }
}

export function getFullName(mrzData: MrzData): string {
  return `${mrzData.givenNames} ${mrzData.surname}`.trim();
}

export function formatMrzDate(
  dateString: string,
  format: 'DD/MM/YYYY' | 'MM/DD/YYYY' | 'YYYY-MM-DD' = 'DD/MM/YYYY'
): string {
  if (!dateString || dateString.length !== 6) {
    return dateString;
  }
  
  const year = parseInt(dateString.substring(0, 2));
  const month = dateString.substring(2, 4);
  const day = dateString.substring(4, 6);
  
  const fullYear = year <= 30 ? 2000 + year : 1900 + year;
  
  switch (format) {
    case 'MM/DD/YYYY':
      return `${month}/${day}/${fullYear}`;
    case 'YYYY-MM-DD':
      return `${fullYear}-${month}-${day}`;
    case 'DD/MM/YYYY':
    default:
      return `${day}/${month}/${fullYear}`;
  }
}

export function validateMrzData(mrzData: MrzData): string[] {
  const missingFields: string[] = [];
  
  if (!mrzData.documentNumber) missingFields.push('documentNumber');
  if (!mrzData.dateOfBirth) missingFields.push('dateOfBirth');
  if (!mrzData.dateOfExpiration) missingFields.push('dateOfExpiration');
  if (!mrzData.surname) missingFields.push('surname');
  if (!mrzData.givenNames) missingFields.push('givenNames');
  if (!mrzData.nationality) missingFields.push('nationality');
  
  return missingFields;
}


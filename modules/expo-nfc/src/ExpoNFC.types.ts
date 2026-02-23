// NFC Module Types - Based on React Native NFC Library

/**
 * NFC Credentials interface for passport reading
 */
export interface NFCCredentials {
  // MRZ data required for NFC chip reading
  documentNumber: string;
  dateOfBirth: string; // Format: YYMMDD
  expiryDate: string; // Format: YYMMDD

  // Server configuration
  serverURL: string;
  transactionID: string;

  // Optional settings
  requestTimeout?: number; // Default: 10 seconds
  isActiveAuthenticationEnabled?: boolean; // Default: true
  isPassiveAuthenticationEnabled?: boolean; // Default: true
  enableAutoTriggering?: boolean; // Default: true (Android)
  logLevel?: 'warning' | 'info' | 'debug' | 'error'; // Default: 'warning'
}

/**
 * NFC Passport/ID Response interface based on Udentify SDK
 */
export interface NFCPassportResponse {
  success: boolean;
  transactionID: string;
  timestamp: number;

  // Passport/ID data
  firstName?: string;
  lastName?: string;
  documentNumber?: string;
  nationality?: string;
  dateOfBirth?: string;
  expiryDate?: string;
  gender?: string;
  personalNumber?: string;
  placeOfBirth?: string;
  issuingAuthority?: string;

  // Authentication results
  passedPA?: 'disabled' | 'true' | 'false' | 'notSupported'; // Passive Authentication
  passedAA?: 'disabled' | 'true' | 'false' | 'notSupported'; // Active Authentication

  // Images
  faceImage?: string; // Base64 encoded
  signatureImage?: string; // Base64 encoded

  // Error information
  error?: string;
  message?: string;
}

/**
 * NFC Status Response interface
 */
export interface NFCStatusResponse {
  isAvailable: boolean;
  isEnabled: boolean;
  message?: string;
}

/**
 * NFC Location Response interface
 */
export interface NFCLocationResponse {
  success: boolean;
  location: NFCLocation;
  message?: string;
  timestamp?: number;
}

/**
 * NFC Location enum based on Udentify SDK
 */
export enum NFCLocation {
  unknown = 0,
  frontTop = 1,
  frontCenter = 2,
  frontBottom = 3,
  rearTop = 4,
  rearCenter = 5,
  rearBottom = 6,
}

/**
 * NFC Availability interface
 */
export interface NFCAvailability {
  isAvailable: boolean;
  deviceSupported: boolean;
  osVersion: string;
  frameworkImported?: boolean;
}

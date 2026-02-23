// OCR Constants - Based on React Native OCR Library

/**
 * OCR Modules supported
 */
export const OCR_MODULES = {
  OCR: 'OCR',
  OCR_HOLOGRAM: 'OCR_HOLOGRAM',
  NFC: 'NFC',
} as const;

/**
 * Document types supported by OCR
 */
export const DOCUMENT_TYPES = {
  ID_CARD: 'ID_CARD',
  PASSPORT: 'PASSPORT',
  DRIVER_LICENSE: 'DRIVER_LICENSE',
} as const;

/**
 * Document sides for scanning
 */
export const DOCUMENT_SIDES = {
  FRONT: 'FRONT',
  BACK: 'BACK',
  BOTH: 'BOTH',
} as const;

/**
 * Countries supported
 */
export const COUNTRIES = {
  TUR: { code: 'TUR', name: 'Turkey' },
  USA: { code: 'USA', name: 'United States' },
  GBR: { code: 'GBR', name: 'United Kingdom' },
  DEU: { code: 'DEU', name: 'Germany' },
  FRA: { code: 'FRA', name: 'France' },
  ITA: { code: 'ITA', name: 'Italy' },
  ESP: { code: 'ESP', name: 'Spain' },
  NLD: { code: 'NLD', name: 'Netherlands' },
  BEL: { code: 'BEL', name: 'Belgium' },
  CHE: { code: 'CHE', name: 'Switzerland' },
  AUT: { code: 'AUT', name: 'Austria' },
  POL: { code: 'POL', name: 'Poland' },
  CZE: { code: 'CZE', name: 'Czech Republic' },
  HUN: { code: 'HUN', name: 'Hungary' },
  SVK: { code: 'SVK', name: 'Slovakia' },
  SVN: { code: 'SVN', name: 'Slovenia' },
  HRV: { code: 'HRV', name: 'Croatia' },
  SRB: { code: 'SRB', name: 'Serbia' },
  BGR: { code: 'BGR', name: 'Bulgaria' },
  ROU: { code: 'ROU', name: 'Romania' },
  GRC: { code: 'GRC', name: 'Greece' },
  CYP: { code: 'CYP', name: 'Cyprus' },
  MLT: { code: 'MLT', name: 'Malta' },
  EST: { code: 'EST', name: 'Estonia' },
  LVA: { code: 'LVA', name: 'Latvia' },
  LTU: { code: 'LTU', name: 'Lithuania' },
  FIN: { code: 'FIN', name: 'Finland' },
  SWE: { code: 'SWE', name: 'Sweden' },
  DNK: { code: 'DNK', name: 'Denmark' },
  NOR: { code: 'NOR', name: 'Norway' },
  ISL: { code: 'ISL', name: 'Iceland' },
  IRL: { code: 'IRL', name: 'Ireland' },
  PRT: { code: 'PRT', name: 'Portugal' },
  LUX: { code: 'LUX', name: 'Luxembourg' },
} as const;

/**
 * Timeout configurations
 */
export const TIMEOUTS = {
  CAMERA_LOADING: 30000, // 30 seconds
  API_REQUEST: 60000, // 60 seconds
  TRANSACTION_TIMEOUT: 120000, // 2 minutes
} as const;

/**
 * Error messages
 */
export const ERROR_MESSAGES = {
  CAMERA_PERMISSION_DENIED: 'Camera permission is required to use OCR functionality',
  PHONE_STATE_PERMISSION_DENIED: 'Phone state permission is required for the Udentify SDK',
  OCR_MODULE_NOT_AVAILABLE: 'OCR Module not available. Please ensure the native module is properly linked.',
  TRANSACTION_ID_FAILED: 'Failed to get transaction ID from server',
  OCR_SCANNING_FAILED: 'Failed to start OCR scanning',
  HOLOGRAM_REQUIRES_OCR: 'Please perform OCR scanning first. Hologram verification requires an existing OCR transaction.',
  UI_CONFIG_NOT_AVAILABLE: 'UI Configuration feature is not yet available in the current OCR module build.',
} as const;

/**
 * Success messages
 */
export const SUCCESS_MESSAGES = {
  OCR_COMPLETED: 'OCR processing completed successfully!',
  HOLOGRAM_COMPLETED: 'Hologram processing completed successfully!',
  UI_CONFIG_APPLIED: 'UI configuration applied successfully! The new settings will be used in the next OCR scan.',
  HOLOGRAM_CAMERA_STARTED: 'Follow the instructions to record the hologram video. The SDK will automatically verify the hologram after recording completes.',
} as const;

export type OCRModuleValue = typeof OCR_MODULES[keyof typeof OCR_MODULES];
export type DocumentTypeValue = typeof DOCUMENT_TYPES[keyof typeof DOCUMENT_TYPES];
export type DocumentSideValue = typeof DOCUMENT_SIDES[keyof typeof DOCUMENT_SIDES];
export type CountryCode = keyof typeof COUNTRIES;

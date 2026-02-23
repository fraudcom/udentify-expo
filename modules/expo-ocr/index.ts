// Constants
export {DocumentType} from './src/constants/DocumentType';
export type {DocumentTypeValue} from './src/constants/DocumentType';
export {DocumentSide} from './src/constants/DocumentSide';
export type {DocumentSideValue} from './src/constants/DocumentSide';
export {IQAFeedback} from './src/constants/IQAFeedback';
export type {IQAFeedbackValue} from './src/constants/IQAFeedback';

// IQA Types
export type {
  IQAResult,
  IQABannerStyle,
  IQAButtonStyle,
  IQAProgressBarStyle,
  IQAImageStyle,
  IQAResultAreaPositioning,
  IQAScreenStyle,
} from './src/types/iqa.types';

// OCR Types
export type {
  OCRResponse,
  OCRAndDocumentLivenessResponse,
  DocumentScanResult,
} from './src/types/ocr.types';

// Hologram Types
export type {HologramResponse} from './src/types/hologram.types';

// UI Types
export type {
  DocumentLivenessResponse,
  OCRUIConfiguration,
  OCRAvailability,
} from './src/types/ui.types';

// API Functions
export {startOCRScanning} from './src/api/scanning';
export {performOCR, performOCRAndDocumentLiveness} from './src/api/ocr';
export {performDocumentLiveness} from './src/api/liveness';
export {startHologramCamera, performHologramCheck} from './src/api/hologram';
export {configureUISettings} from './src/api/config';

// Events
export {addIQAResultListener, removeAllIQAResultListeners} from './src/events/iqaEvents';

// Native Module (default export)
export {default} from './src/ExpoOCRModule';

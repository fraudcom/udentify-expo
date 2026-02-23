import type {IQAScreenStyle} from './iqa.types';

export interface DocumentLivenessResponse {
  success: boolean;
  livenessScore?: number;
  isLive?: boolean;
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
  message?: string;
  timestamp: number;
}

export interface OCRUIConfiguration {
  placeholderTemplate?: 'hidden' | 'defaultStyle' | 'countrySpecificStyle';
  orientation?: 'horizontal' | 'vertical';
  
  backgroundColor?: string;
  borderColor?: string;
  cornerRadius?: number;
  borderWidth?: number;
  maskLayerColor?: string;
  buttonBackColor?: string;
  
  detectionAccuracy?: number;
  blurCoefficient?: number;
  requestTimeout?: number;
  backButtonEnabled?: boolean;
  reviewScreenEnabled?: boolean;
  footerViewHidden?: boolean;
  
  // IQA (Image Quality Assessment) settings
  isIQAServiceEnabled?: boolean;
  iqaEnabled?: boolean; // Android naming
  iqaSuccessAutoDismissDelay?: number; // Android only
  iqaScreenStyle?: IQAScreenStyle;
  
  footerBackgroundColor?: string;
  footerTextColor?: string;
  footerFontSize?: number;
  footerHeight?: number;
  
  useButtonBackgroundColor?: string;
  useButtonTextColor?: string;
  useButtonFontSize?: number;
  useButtonHeight?: number;
  
  retakeButtonBackgroundColor?: string;
  retakeButtonTextColor?: string;
  retakeButtonFontSize?: number;
  retakeButtonHeight?: number;
  
  titleTextColor?: string;
  titleFontSize?: number;
  instructionTextColor?: string;
  instructionFontSize?: number;
  reviewTitleTextColor?: string;
  reviewTitleFontSize?: number;
  reviewInstructionTextColor?: string;
  reviewInstructionFontSize?: number;
  
  progressBackgroundColor?: string;
  progressColor?: string;
  progressCompletionColor?: string;
  progressCornerRadius?: number;
  progressTextColor?: string;
  progressFontSize?: number;
  
  tableName?: string;
}

/**
 * OCR Availability interface
 */
export interface OCRAvailability {
  isAvailable: boolean;
  reason?: string;
  deviceSupported: boolean;
  osVersion: string;
  frameworkImported?: boolean;
}





export interface FaceRecognizerCredentials {
  serverURL: string;
  transactionID: string;
  userID: string;
  
  autoTake?: boolean;
  errorDelay?: number;
  successDelay?: number;
  runInBackground?: boolean;
  blinkDetectionEnabled?: boolean;
  requestTimeout?: number;
  eyesOpenThreshold?: number;
  maskConfidence?: number;
  invertedAnimation?: boolean;
  activeLivenessAutoNextEnabled?: boolean;
  hybridLivenessEnabled?: boolean;
}

export interface LivenessPermissionStatus {
  camera: 'granted' | 'denied' | 'permanentlyDenied' | 'unknown';
  readPhoneState: 'granted' | 'denied' | 'permanentlyDenied' | 'unknown';
  internet: 'granted' | 'denied' | 'permanentlyDenied' | 'unknown';
  recordAudio?: 'granted' | 'denied' | 'permanentlyDenied' | 'unknown';
  bluetoothConnect?: 'granted' | 'denied' | 'permanentlyDenied' | 'unknown';
}

export interface FaceIDResult {
  verified: boolean;
  matchScore: number;
  description: string;
  transactionID: string;
  userID: string;
  header?: string;
  listNames?: string;
  listIds?: string;
  registrationTransactionID?: string;
  method: string;
  referencePhotoBase64?: string;
  metadata?: Record<string, any>;
  error?: {
    code: string;
    description: string;
  };
}

export interface LivenessResult {
  assessmentValue: number;
  assessmentDescription: string;
  probability: number;
  quality: number;
  livenessScore: number;
  transactionID: string;
  assessment?: string;
  error?: {
    code: string;
    description: string;
  };
}

export interface ActiveLivenessResult {
  transactionID: string;
  gestureResult: Record<string, any>;
  error?: {
    code: string;
    description: string;
  };
}

export interface FaceIDMessage {
  success: boolean;
  message: string;
  isFailed?: boolean;
  faceIDResult?: FaceIDResult;
  livenessResult?: LivenessResult;
  activeLivenessResult?: ActiveLivenessResult;
}

export interface FaceRecognitionResult {
  status: 'success' | 'failure';
  faceIDMessage: FaceIDMessage;
}

export interface SelfieResult {
  base64Image: string;
}

export interface ListOperationResult {
  success: boolean;
  data?: {
    id: number;
    userId: number;
    customerList: {
      id: number;
      name: string;
      listRole: string;
      description: string;
      creationDate: string;
    };
  };
  message?: string;
  userID?: string;
  transactionID?: string;
  listName?: string;
  matchScore?: number;
  registrationTransactionID?: string;
}

export interface UIColors {
  titleColor?: string;
  titleBG?: string;
  buttonErrorColor?: string;
  buttonSuccessColor?: string;
  buttonColor?: string;
  buttonTextColor?: string;
  buttonErrorTextColor?: string;
  buttonSuccessTextColor?: string;
  buttonBackColor?: string;
  footerTextColor?: string;
  checkmarkTintColor?: string;
  backgroundColor?: string;
}

export interface UIFonts {
  titleFont?: {
    name?: string;
    size?: number;
  };
  buttonFont?: {
    name?: string;
    size?: number;
  };
  footerFont?: {
    name?: string;
    size?: number;
  };
}

export interface ProgressBarStyle {
  backgroundColor?: string;
  progressColor?: string;
  completionColor?: string;
  cornerRadius?: number;
}

export interface UIConfigs {
  cameraPosition?: 'front' | 'back';
  requestTimeout?: number;
  autoTake?: boolean;
  errorDelay?: number;
  successDelay?: number;
  tableName?: string;
  maskDetection?: boolean;
  maskConfidence?: number;
  invertedAnimation?: boolean;
  backButtonEnabled?: boolean;
  multipleFacesRejected?: boolean;
  progressBarStyle?: ProgressBarStyle;
}

export interface UIDimensions {
  buttonHeight?: number;
  buttonMarginLeft?: number;
  buttonMarginRight?: number;
  buttonCornerRadius?: number;
}

export interface UISettings {
  colors?: UIColors;
  fonts?: UIFonts;
  configs?: UIConfigs;
  dimensions?: UIDimensions;
}

export interface LocalizationStrings {
  [key: string]: string;
}


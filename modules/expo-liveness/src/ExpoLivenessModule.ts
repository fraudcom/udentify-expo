import { NativeModule, requireNativeModule } from 'expo';

import {
  FaceRecognizerCredentials,
  LivenessPermissionStatus,
  FaceRecognitionResult,
  SelfieResult,
  ListOperationResult,
  UISettings
} from './ExpoLiveness.types';

declare class ExpoLivenessModule extends NativeModule {
  checkPermissions(): Promise<LivenessPermissionStatus>;
  requestPermissions(): Promise<LivenessPermissionStatus>;

  startFaceRecognitionRegistration(credentials: FaceRecognizerCredentials): Promise<FaceRecognitionResult>;
  startFaceRecognitionAuthentication(credentials: FaceRecognizerCredentials): Promise<FaceRecognitionResult>;

  startActiveLiveness(credentials: FaceRecognizerCredentials, isAuthentication?: boolean): Promise<FaceRecognitionResult>;
  startHybridLiveness(credentials: FaceRecognizerCredentials, isAuthentication?: boolean): Promise<FaceRecognitionResult>;

  startSelfieCapture(credentials: FaceRecognizerCredentials): Promise<FaceRecognitionResult>;
  performFaceRecognitionWithSelfie(
    credentials: FaceRecognizerCredentials,
    base64Image: string,
    isAuthentication?: boolean
  ): Promise<FaceRecognitionResult>;

  registerUserWithPhoto(credentials: FaceRecognizerCredentials, base64Image: string): Promise<FaceRecognitionResult>;
  authenticateUserWithPhoto(credentials: FaceRecognizerCredentials, base64Image: string): Promise<FaceRecognitionResult>;

  cancelFaceRecognition(): Promise<void>;
  isFaceRecognitionInProgress(): Promise<boolean>;

  addUserToList(
    serverURL: string,
    transactionId: string,
    status: string,
    metadata?: Record<string, any>
  ): Promise<ListOperationResult>;

  startFaceRecognitionIdentification(
    serverURL: string,
    transactionId: string,
    listName: string,
    logLevel?: string
  ): Promise<FaceRecognitionResult>;

  deleteUserFromList(
    serverURL: string,
    transactionId: string,
    listName: string,
    photoBase64: string
  ): Promise<ListOperationResult>;

  configureUISettings(settings: UISettings): Promise<boolean>;
  setLocalization(languageCode: string, customStrings?: Record<string, string>): Promise<void>;
}

export default requireNativeModule<ExpoLivenessModule>('ExpoLiveness');

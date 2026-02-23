import {
  FaceRecognizerCredentials,
  LivenessPermissionStatus,
  FaceRecognitionResult,
  ListOperationResult,
  UISettings
} from './ExpoLiveness.types';

export default {
  async checkPermissions(): Promise<LivenessPermissionStatus> {
    return {
      camera: 'denied',
      readPhoneState: 'denied',
      internet: 'granted'
    };
  },

  async requestPermissions(): Promise<LivenessPermissionStatus> {
    throw new Error('Permission requests are not supported on web platform');
  },

  async startFaceRecognitionRegistration(credentials: FaceRecognizerCredentials): Promise<FaceRecognitionResult> {
    throw new Error('Face recognition registration is not supported on web platform');
  },

  async startFaceRecognitionAuthentication(credentials: FaceRecognizerCredentials): Promise<FaceRecognitionResult> {
    throw new Error('Face recognition authentication is not supported on web platform');
  },

  async startActiveLiveness(
    credentials: FaceRecognizerCredentials,
    isAuthentication: boolean = false
  ): Promise<FaceRecognitionResult> {
    throw new Error('Active liveness detection is not supported on web platform');
  },

  async startHybridLiveness(
    credentials: FaceRecognizerCredentials,
    isAuthentication: boolean = false
  ): Promise<FaceRecognitionResult> {
    throw new Error('Hybrid liveness detection is not supported on web platform');
  },

  async startSelfieCapture(credentials: FaceRecognizerCredentials): Promise<FaceRecognitionResult> {
    throw new Error('Selfie capture is not supported on web platform');
  },

  async performFaceRecognitionWithSelfie(
    credentials: FaceRecognizerCredentials,
    base64Image: string,
    isAuthentication: boolean = false
  ): Promise<FaceRecognitionResult> {
    throw new Error('Face recognition with selfie is not supported on web platform');
  },

  async registerUserWithPhoto(
    credentials: FaceRecognizerCredentials,
    base64Image: string
  ): Promise<FaceRecognitionResult> {
    throw new Error('User registration with photo is not supported on web platform');
  },

  async authenticateUserWithPhoto(
    credentials: FaceRecognizerCredentials,
    base64Image: string
  ): Promise<FaceRecognitionResult> {
    throw new Error('User authentication with photo is not supported on web platform');
  },

  async cancelFaceRecognition(): Promise<void> {
    return;
  },

  async isFaceRecognitionInProgress(): Promise<boolean> {
    return false;
  },

  async addUserToList(
    serverURL: string,
    transactionId: string,
    status: string,
    metadata?: Record<string, any>
  ): Promise<ListOperationResult> {
    throw new Error('List operations are not supported on web platform');
  },

  async startFaceRecognitionIdentification(
    serverURL: string,
    transactionId: string,
    listName: string,
    logLevel?: string
  ): Promise<FaceRecognitionResult> {
    throw new Error('Face recognition identification is not supported on web platform');
  },

  async deleteUserFromList(
    serverURL: string,
    transactionId: string,
    listName: string,
    photoBase64: string
  ): Promise<ListOperationResult> {
    throw new Error('Delete user from list is not supported on web platform');
  },

  async configureUISettings(settings: UISettings): Promise<boolean> {
    return false;
  },

  async setLocalization(languageCode: string, customStrings?: Record<string, string>): Promise<void> {
    return;
  },
};


import { EventEmitter } from 'expo-modules-core';
import ExpoLivenessModule from './src/ExpoLivenessModule';

const eventEmitter = new EventEmitter(ExpoLivenessModule);

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
}

export interface FaceIDMessage {
  success: boolean;
  message: string;
  faceIDResult?: FaceIDResult;
}

export interface FaceIDResult {
  verified?: boolean;
  matchScore?: number;
  userID?: string;
  transactionID?: string;
  isFailed?: boolean;
  error?: string;
}

export interface LivenessResult {
  status: string;
  faceIDMessage?: FaceIDMessage;
  timestamp?: number;
}

export interface PermissionStatus {
  camera: string;
  readPhoneState: string;
  internet: string;
  recordAudio: string;
  bluetoothConnect: string;
}

export type LivenessEventCallback = (data: any) => void;

export async function checkPermissions(): Promise<PermissionStatus> {
  try {
    const result = await ExpoLivenessModule.checkPermissions();
    return result;
  } catch (error) {
    console.error('ExpoLiveness - checkPermissions error:', error);
    return {
      camera: 'denied',
      readPhoneState: 'denied',
      internet: 'denied',
      recordAudio: 'denied',
      bluetoothConnect: 'denied'
    };
  }
}

export async function requestPermissions(): Promise<string> {
  try {
    const result = await ExpoLivenessModule.requestPermissions();
    return result;
  } catch (error) {
    console.error('ExpoLiveness - requestPermissions error:', error);
    return 'denied';
  }
}

export async function startFaceRecognitionRegistration(
  credentials: FaceRecognizerCredentials
): Promise<LivenessResult> {
  try {
    const result = await ExpoLivenessModule.startFaceRecognitionRegistration(credentials);
    return result;
  } catch (error) {
    console.error('ExpoLiveness - startFaceRecognitionRegistration error:', error);
    throw error;
  }
}

export async function startFaceRecognitionAuthentication(
  credentials: FaceRecognizerCredentials
): Promise<LivenessResult> {
  try {
    const result = await ExpoLivenessModule.startFaceRecognitionAuthentication(credentials);
    return result;
  } catch (error) {
    console.error('ExpoLiveness - startFaceRecognitionAuthentication error:', error);
    throw error;
  }
}

export async function startActiveLiveness(
  credentials: FaceRecognizerCredentials,
  isAuthentication: boolean = false
): Promise<LivenessResult> {
  try {
    const result = await ExpoLivenessModule.startActiveLiveness(credentials, isAuthentication);
    return result;
  } catch (error) {
    console.error('ExpoLiveness - startActiveLiveness error:', error);
    throw error;
  }
}

export async function startHybridLiveness(
  credentials: FaceRecognizerCredentials,
  isAuthentication: boolean
): Promise<LivenessResult> {
  try {
    const result = await ExpoLivenessModule.startHybridLiveness(credentials, isAuthentication);
    return result;
  } catch (error) {
    console.error('ExpoLiveness - startHybridLiveness error:', error);
    throw error;
  }
}

export async function startSelfieCapture(
  credentials: FaceRecognizerCredentials
): Promise<LivenessResult> {
  try {
    const result = await ExpoLivenessModule.startSelfieCapture(credentials);
    return result;
  } catch (error) {
    console.error('ExpoLiveness - startSelfieCapture error:', error);
    throw error;
  }
}

export async function performFaceRecognitionWithSelfie(
  credentials: FaceRecognizerCredentials,
  base64Image: string,
  isAuthentication: boolean
): Promise<LivenessResult> {
  try {
    const result = await ExpoLivenessModule.performFaceRecognitionWithSelfie(
      credentials,
      base64Image,
      isAuthentication
    );
    return result;
  } catch (error) {
    console.error('ExpoLiveness - performFaceRecognitionWithSelfie error:', error);
    throw error;
  }
}

export async function registerUserWithPhoto(
  credentials: FaceRecognizerCredentials,
  base64Image: string
): Promise<LivenessResult> {
  try {
    const result = await ExpoLivenessModule.registerUserWithPhoto(credentials, base64Image);
    return result;
  } catch (error) {
    console.error('ExpoLiveness - registerUserWithPhoto error:', error);
    throw error;
  }
}

export async function authenticateUserWithPhoto(
  credentials: FaceRecognizerCredentials,
  base64Image: string
): Promise<LivenessResult> {
  try {
    const result = await ExpoLivenessModule.authenticateUserWithPhoto(credentials, base64Image);
    return result;
  } catch (error) {
    console.error('ExpoLiveness - authenticateUserWithPhoto error:', error);
    throw error;
  }
}

export async function cancelFaceRecognition(): Promise<void> {
  try {
    await ExpoLivenessModule.cancelFaceRecognition();
  } catch (error) {
    console.error('ExpoLiveness - cancelFaceRecognition error:', error);
    throw error;
  }
}

export async function isFaceRecognitionInProgress(): Promise<boolean> {
  try {
    const result = await ExpoLivenessModule.isFaceRecognitionInProgress();
    return result;
  } catch (error) {
    console.error('ExpoLiveness - isFaceRecognitionInProgress error:', error);
    return false;
  }
}

export async function configureUISettings(settings: any): Promise<any> {
  try {
    const result = await ExpoLivenessModule.configureUISettings(settings);
    return result;
  } catch (error) {
    console.error('ExpoLiveness - configureUISettings error:', error);
    throw error;
  }
}

export async function setLocalization(
  languageCode: string,
  customStrings?: Record<string, string>
): Promise<void> {
  try {
    await ExpoLivenessModule.setLocalization(languageCode, customStrings);
  } catch (error) {
    console.error('ExpoLiveness - setLocalization error:', error);
    throw error;
  }
}

export function addFaceIDCompleteListener(callback: LivenessEventCallback): any {
  return eventEmitter.addListener('onFaceRecognitionResult', callback);
}

export function addFaceIDErrorListener(callback: LivenessEventCallback): any {
  return eventEmitter.addListener('onFaceRecognitionError', callback);
}

export function addActiveLivenessResultListener(callback: LivenessEventCallback): any {
  return eventEmitter.addListener('onActiveLivenessResult', callback);
}

export function addActiveLivenessFailureListener(callback: LivenessEventCallback): any {
  return eventEmitter.addListener('onActiveLivenessFailure', callback);
}

export function addPhotoTakenListener(callback: LivenessEventCallback): any {
  return eventEmitter.addListener('onPhotoTaken', callback);
}

export function addSelfieTakenListener(callback: LivenessEventCallback): any {
  return eventEmitter.addListener('onSelfieTaken', callback);
}

export function addBackButtonPressedListener(callback: LivenessEventCallback): any {
  return eventEmitter.addListener('onBackButtonPressed', callback);
}

export function addWillDismissListener(callback: LivenessEventCallback): any {
  return eventEmitter.addListener('onWillDismiss', callback);
}

export function addDidDismissListener(callback: LivenessEventCallback): any {
  return eventEmitter.addListener('onDidDismiss', callback);
}

export function addVideoTakenListener(callback: LivenessEventCallback): any {
  return eventEmitter.addListener('onVideoTaken', callback);
}



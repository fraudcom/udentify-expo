import { NativeModule, requireNativeModule } from 'expo';

import {
  VideoCallCredentials,
  VideoCallConfig,
  VideoCallPermissionStatus,
  VideoCallResult
} from './ExpoVideoCall.types';

declare class ExpoVideoCallModule extends NativeModule {
  checkPermissions(): Promise<VideoCallPermissionStatus>;
  requestPermissions(): Promise<string>;
  startVideoCall(credentials: VideoCallCredentials): Promise<VideoCallResult>;
  endVideoCall(): Promise<VideoCallResult>;
  getVideoCallStatus(): Promise<string>;
  setVideoCallConfig(config: VideoCallConfig): Promise<void>;
  toggleCamera(): Promise<boolean>;
  switchCamera(): Promise<boolean>;
  toggleMicrophone(): Promise<boolean>;
  dismissVideoCall(): Promise<void>;
}

export default requireNativeModule<ExpoVideoCallModule>('ExpoVideoCall');

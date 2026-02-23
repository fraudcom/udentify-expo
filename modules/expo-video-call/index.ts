export * from './src/ExpoVideoCall.types';

export { default } from './src/ExpoVideoCallModule';

import ExpoVideoCallModule from './src/ExpoVideoCallModule';

export {
  VideoCallCredentials,
  VideoCallConfig,
  VideoCallPermissionStatus,
  VideoCallResult,
  VideoCallStatusEvent,
  VideoCallUserStateEvent,
  VideoCallParticipantStateEvent,
  VideoCallErrorEvent
} from './src/ExpoVideoCall.types';

export async function checkPermissions() {
  try {
    return await ExpoVideoCallModule.checkPermissions();
  } catch (error) {
    console.error('ExpoVideoCall - checkPermissions error:', error);
    return {
      hasCameraPermission: false,
      hasPhoneStatePermission: false,
      hasInternetPermission: false,
      hasRecordAudioPermission: false
    };
  }
}

export async function requestPermissions() {
  try {
    return await ExpoVideoCallModule.requestPermissions();
  } catch (error) {
    console.error('ExpoVideoCall - requestPermissions error:', error);
    return 'denied';
  }
}

export async function startVideoCall(credentials: any) {
  try {
    if (!credentials.serverURL || !credentials.wssURL || !credentials.userID || 
        !credentials.transactionID || !credentials.clientName) {
      throw new Error('Missing required video call credentials');
    }
    return await ExpoVideoCallModule.startVideoCall(credentials);
  } catch (error) {
    console.error('ExpoVideoCall - startVideoCall error:', error);
    throw error;
  }
}

export async function endVideoCall() {
  try {
    return await ExpoVideoCallModule.endVideoCall();
  } catch (error) {
    console.error('ExpoVideoCall - endVideoCall error:', error);
    return { success: false, status: 'error' };
  }
}

export async function getVideoCallStatus() {
  try {
    return await ExpoVideoCallModule.getVideoCallStatus();
  } catch (error) {
    console.error('ExpoVideoCall - getVideoCallStatus error:', error);
    return 'idle';
  }
}

export async function setVideoCallConfig(config: any) {
  try {
    return await ExpoVideoCallModule.setVideoCallConfig(config);
  } catch (error) {
    console.error('ExpoVideoCall - setVideoCallConfig error:', error);
    throw error;
  }
}

export async function toggleCamera() {
  try {
    return await ExpoVideoCallModule.toggleCamera();
  } catch (error) {
    console.error('ExpoVideoCall - toggleCamera error:', error);
    return false;
  }
}

export async function switchCamera() {
  try {
    return await ExpoVideoCallModule.switchCamera();
  } catch (error) {
    console.error('ExpoVideoCall - switchCamera error:', error);
    return false;
  }
}

export async function toggleMicrophone() {
  try {
    return await ExpoVideoCallModule.toggleMicrophone();
  } catch (error) {
    console.error('ExpoVideoCall - toggleMicrophone error:', error);
    return false;
  }
}

export async function dismissVideoCall() {
  try {
    return await ExpoVideoCallModule.dismissVideoCall();
  } catch (error) {
    console.error('ExpoVideoCall - dismissVideoCall error:', error);
  }
}

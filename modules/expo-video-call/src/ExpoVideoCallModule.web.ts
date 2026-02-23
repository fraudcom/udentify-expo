import { EventEmitter } from 'expo-modules-core';

const emitter = new EventEmitter({} as any);

export default {
  async checkPermissions() {
    throw new Error('Video Call is not supported on web');
  },
  async requestPermissions() {
    throw new Error('Video Call is not supported on web');
  },
  async startVideoCall() {
    throw new Error('Video Call is not supported on web');
  },
  async endVideoCall() {
    throw new Error('Video Call is not supported on web');
  },
  async getVideoCallStatus() {
    throw new Error('Video Call is not supported on web');
  },
  async setVideoCallConfig() {
    throw new Error('Video Call is not supported on web');
  },
  async toggleCamera() {
    throw new Error('Video Call is not supported on web');
  },
  async switchCamera() {
    throw new Error('Video Call is not supported on web');
  },
  async toggleMicrophone() {
    throw new Error('Video Call is not supported on web');
  },
  async dismissVideoCall() {
    throw new Error('Video Call is not supported on web');
  },
  addListener: emitter.addListener.bind(emitter),
  removeListener: emitter.removeListener.bind(emitter),
  removeAllListeners: emitter.removeAllListeners.bind(emitter),
};

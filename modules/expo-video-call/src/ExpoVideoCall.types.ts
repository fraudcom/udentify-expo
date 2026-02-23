export interface VideoCallCredentials {
  serverURL: string;
  wssURL: string;
  userID: string;
  transactionID: string;
  clientName: string;
  idleTimeout: string;
}

export interface VideoCallConfig {
  backgroundColor?: string;
  textColor?: string;
  pipViewBorderColor?: string;
  notificationLabelDefault?: string;
  notificationLabelCountdown?: string;
  notificationLabelTokenFetch?: string;
}

export interface VideoCallPermissionStatus {
  hasCameraPermission: boolean;
  hasPhoneStatePermission: boolean;
  hasInternetPermission: boolean;
  hasRecordAudioPermission: boolean;
}

export interface VideoCallResult {
  success: boolean;
  status?: string;
  transactionID?: string;
}

export interface VideoCallStatusEvent {
  status: string;
  message?: string;
}

export interface VideoCallUserStateEvent {
  state: string;
  userId?: string;
}

export interface VideoCallParticipantStateEvent {
  state: string;
  participantId?: string;
}

export interface VideoCallErrorEvent {
  error: string;
  message: string;
}

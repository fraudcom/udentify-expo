export const VIDEO_CALL_STATUS = {
  IDLE: 'idle',
  CONNECTING: 'connecting',
  CONNECTED: 'connected',
  DISCONNECTED: 'disconnected',
  FAILED: 'failed',
  COMPLETED: 'completed',
} as const;

export type VideoCallStatusType = typeof VIDEO_CALL_STATUS[keyof typeof VIDEO_CALL_STATUS];

export const VIDEO_CALL_ERROR_TYPES = {
  SDK_NOT_AVAILABLE: 'ERR_SDK_NOT_AVAILABLE',
  UNKNOWN: 'ERR_UNKNOWN',
  SDK: 'ERR_SDK',
  PERMISSION_DENIED: 'PERMISSION_DENIED',
  MISSING_PARAMETERS: 'MISSING_PARAMETERS',
} as const;

export const TIMEOUTS = {
  DEFAULT: '30',
  SHORT: '15',
  MEDIUM: '60',
  LONG: '120',
} as const;

export const ERROR_MESSAGES = {
  SDK_NOT_AVAILABLE: 'Udentify SDK is not available. Please ensure AAR files are properly integrated.',
  PERMISSION_DENIED: 'Required permissions not granted',
  MISSING_PARAMETERS: 'Missing required parameters',
  NO_ACTIVITY: 'Activity not available',
} as const;

export const SUCCESS_MESSAGES = {
  CALL_STARTED: 'Video call started successfully',
  CALL_ENDED: 'Video call ended successfully',
  PERMISSIONS_GRANTED: 'All permissions granted',
} as const;

export const UI_COLORS = {
  BACKGROUND_COLORS: {
    BLACK: '#000000',
    WHITE: '#FFFFFF',
    GRAY: '#808080',
    BLUE: '#0000FF',
  },
  TEXT_COLORS: {
    BLACK: '#000000',
    WHITE: '#FFFFFF',
    RED: '#FF0000',
    GREEN: '#00FF00',
  },
  BORDER_COLORS: {
    WHITE: '#FFFFFF',
    BLACK: '#000000',
    BLUE: '#0000FF',
    GREEN: '#00FF00',
  },
} as const;

export const NOTIFICATION_LABELS = {
  DEFAULT: 'Preparing video call...',
  COUNTDOWN: 'Starting in %d seconds...',
  TOKEN_FETCH: 'Connecting to server...',
} as const;

import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  Button,
  Alert,
  StyleSheet,
  ScrollView,
  Platform,
  PermissionsAndroid,
  TextInput,
  TouchableOpacity,
} from 'react-native';
import OptionPicker from './OptionPicker';
import UICustomizeModal from './UICustomizeModal';
import { udentifyApiService } from '../services/udentifyApiService';
import { currentConfig } from '../config/apiConfig';
import { 
  VIDEO_CALL_STATUS,
  VIDEO_CALL_ERROR_TYPES,
  TIMEOUTS, 
  ERROR_MESSAGES, 
  SUCCESS_MESSAGES,
  UI_COLORS,
  NOTIFICATION_LABELS,
  VideoCallStatusType 
} from '../constants/videoCallConstants';
import ExpoVideoCallModule from '../modules/expo-video-call';

const checkPermissions = async () => {
  return await ExpoVideoCallModule.checkPermissions();
};

const requestPermissions = async () => {
  return await ExpoVideoCallModule.requestPermissions();
};

const startVideoCall = async (credentials: any) => {
  return await ExpoVideoCallModule.startVideoCall(credentials);
};

const endVideoCall = async () => {
  return await ExpoVideoCallModule.endVideoCall();
};

const getVideoCallStatus = async () => {
  return await ExpoVideoCallModule.getVideoCallStatus();
};

const setVideoCallConfig = async (config: any) => {
  return await ExpoVideoCallModule.setVideoCallConfig(config);
};

const toggleCamera = async () => {
  return await ExpoVideoCallModule.toggleCamera();
};

const switchCamera = async () => {
  return await ExpoVideoCallModule.switchCamera();
};

const toggleMicrophone = async () => {
  return await ExpoVideoCallModule.toggleMicrophone();
};

const dismissVideoCall = async () => {
  return await ExpoVideoCallModule.dismissVideoCall();
};

interface VideoCallPermissionStatus {
  hasCameraPermission: boolean;
  hasPhoneStatePermission: boolean;
  hasInternetPermission: boolean;
  hasRecordAudioPermission: boolean;
}

interface VideoCallResult {
  success: boolean;
  status?: string;
  transactionID?: string;
  error?: any;
  metadata?: any;
}

const VideoCallTab: React.FC = () => {
  // Server configuration from current config
  const serverUrl = currentConfig.baseURL || currentConfig.baseUrl;
  const wssUrl = currentConfig.wssURL || 'wss://livekit.np.fraud.com';
  const clientName = currentConfig.clientName || 'TestClient_Expo';
  
  // Form state for user ID (needs to be unique per test)
  const [userID, setUserID] = useState(`user_${Date.now()}`);
  
  // State variables
  const [status, setStatus] = useState('Ready');
  const [currentStatus, setCurrentStatus] = useState<VideoCallStatusType>(VIDEO_CALL_STATUS.IDLE);
  const [permissions, setPermissions] = useState<VideoCallPermissionStatus | null>(null);
  const [isInCall, setIsInCall] = useState(false);
  const [isCameraEnabled, setIsCameraEnabled] = useState(true);
  const [isMicrophoneEnabled, setIsMicrophoneEnabled] = useState(true);
  const [idleTimeout, setIdleTimeout] = useState<string>(TIMEOUTS.DEFAULT);
  const [configModalVisible, setConfigModalVisible] = useState(false);

  // Configuration state
  const [backgroundColor, setBackgroundColor] = useState(UI_COLORS.BACKGROUND_COLORS.BLACK);
  const [textColor, setTextColor] = useState(UI_COLORS.TEXT_COLORS.WHITE);
  const [pipViewBorderColor, setPipViewBorderColor] = useState(UI_COLORS.BORDER_COLORS.WHITE);
  const [notificationLabelDefault, setNotificationLabelDefault] = useState(NOTIFICATION_LABELS.DEFAULT);
  const [notificationLabelCountdown, setNotificationLabelCountdown] = useState(NOTIFICATION_LABELS.COUNTDOWN);
  const [notificationLabelTokenFetch, setNotificationLabelTokenFetch] = useState(NOTIFICATION_LABELS.TOKEN_FETCH);

  useEffect(() => {
    checkPermissionsStatus();
    setupEventListeners();
    
    return () => {
      clearEventListeners();
    };
  }, []);

  const setupEventListeners = () => {
    const statusChangedListener = ExpoVideoCallModule.addListener('onStatusChanged', (data: any) => {
      const newStatus = (data.status || data) as VideoCallStatusType;
      setCurrentStatus(newStatus);
      setStatus(`Status: ${newStatus}`);
      
      if (newStatus === VIDEO_CALL_STATUS.CONNECTED) {
        setIsInCall(true);
      } else if (
        newStatus === VIDEO_CALL_STATUS.DISCONNECTED ||
        newStatus === VIDEO_CALL_STATUS.COMPLETED ||
        newStatus === VIDEO_CALL_STATUS.FAILED
      ) {
        setIsInCall(false);
      }
    });

    const errorListener = ExpoVideoCallModule.addListener('onError', (errorData: any) => {
      setStatus(`Error: ${errorData.message || errorData}`);
      setIsInCall(false);
    });

    const userStateListener = ExpoVideoCallModule.addListener('onUserStateChanged', (data: any) => {
      console.log('VideoCallTab - User state changed:', data.state);
    });

    const participantStateListener = ExpoVideoCallModule.addListener('onParticipantStateChanged', (data: any) => {
      console.log('VideoCallTab - Participant state changed:', data.participantType, data.state);
    });

    return () => {
      statusChangedListener.remove();
      errorListener.remove();
      userStateListener.remove();
      participantStateListener.remove();
    };
  };

  const clearEventListeners = () => {
    // Event listeners are automatically removed in useEffect cleanup
  };

  const checkPermissionsStatus = async () => {
    try {
      const permissionStatus = await checkPermissions();
      setPermissions(permissionStatus);
      setStatus('Permissions checked');
    } catch (error) {
      setStatus(`Permission check failed: ${error}`);
    }
  };

  const requestPermissionsHandler = async () => {
    try {
      const result = await requestPermissions();
      console.log('Permission request result:', result);
      await checkPermissionsStatus();
    } catch (error) {
      console.log('Error requesting permissions:', error);
      setStatus(`Permission request failed: ${error}`);
    }
  };

  const startVideoCallHandler = async () => {
    if (isInCall) return;

    console.log('VideoCallTab - Starting video call process...');
    
    setStatus('Getting transaction ID...');

    try {
      const transactionId = await udentifyApiService.getVideoCallTransactionId();
      if (!transactionId) {
        setStatus('Failed to get transaction ID');
        return;
      }

      setStatus('Starting video call...');

      const credentials = {
        serverURL: serverUrl,
        wssURL: wssUrl,
        userID: userID,
        transactionID: transactionId,
        clientName: clientName,
        idleTimeout: idleTimeout,
      };

      console.log('VideoCallTab - Calling startVideoCall with credentials:', credentials);
      const result: VideoCallResult = await startVideoCall(credentials);
      console.log('VideoCallTab - startVideoCall result:', result);

      if (result.success) {
        setStatus('Video call started successfully!');
        const newStatus = (result.status || VIDEO_CALL_STATUS.CONNECTING) as VideoCallStatusType;
        setCurrentStatus(newStatus);
      } else {
        setStatus(`Video call failed: ${result.error?.message || 'Unknown error'}`);
      }
    } catch (error) {
      setStatus(`Video call failed: ${error}`);
    }
  };

  const endVideoCallHandler = async () => {
    if (!isInCall) return;

    setStatus('Ending video call...');

    try {
      const result: VideoCallResult = await endVideoCall();

      setIsInCall(false);
      setCurrentStatus(VIDEO_CALL_STATUS.DISCONNECTED);
      
      if (result.success) {
        setStatus('Video call ended successfully');
      } else {
        setStatus(`Failed to end video call: ${result.error?.message || 'Unknown error'}`);
      }
    } catch (error) {
      setStatus(`Failed to end video call: ${error}`);
      setIsInCall(false);
    }
  };

  const getVideoCallStatusHandler = async () => {
    try {
      const statusResult = await getVideoCallStatus();
      setCurrentStatus(statusResult as VideoCallStatusType);
      setStatus(`Current status: ${statusResult}`);
    } catch (error) {
      setStatus(`Failed to get status: ${error}`);
    }
  };

  const toggleCameraHandler = async () => {
    try {
      const isEnabled = await toggleCamera();
      setIsCameraEnabled(isEnabled);
      setStatus(`Camera ${isEnabled ? 'enabled' : 'disabled'}`);
    } catch (error) {
      setStatus(`Failed to toggle camera: ${error}`);
    }
  };

  const switchCameraHandler = async () => {
    try {
      const success = await switchCamera();
      setStatus(success ? 'Camera switched' : 'Failed to switch camera');
    } catch (error) {
      setStatus(`Failed to switch camera: ${error}`);
    }
  };

  const toggleMicrophoneHandler = async () => {
    try {
      const isEnabled = await toggleMicrophone();
      setIsMicrophoneEnabled(isEnabled);
      setStatus(`Microphone ${isEnabled ? 'enabled' : 'disabled'}`);
    } catch (error) {
      setStatus(`Failed to toggle microphone: ${error}`);
    }
  };

  const setVideoCallConfigHandler = async () => {
    try {
      const config = {
        backgroundColor,
        textColor,
        pipViewBorderColor,
        notificationLabelDefault,
        notificationLabelCountdown,
        notificationLabelTokenFetch,
      };

      await setVideoCallConfig(config);
      setStatus('Video call configuration set');
    } catch (error) {
      setStatus(`Failed to set configuration: ${error}`);
    }
  };

  const getStatusColor = (status: VideoCallStatusType) => {
    switch (status) {
      case VIDEO_CALL_STATUS.IDLE:
        return '#999999';
      case VIDEO_CALL_STATUS.CONNECTING:
        return '#FF9500';
      case VIDEO_CALL_STATUS.CONNECTED:
        return '#00AA00';
      case VIDEO_CALL_STATUS.DISCONNECTED:
        return '#0066CC';
      case VIDEO_CALL_STATUS.FAILED:
        return '#CC0000';
      case VIDEO_CALL_STATUS.COMPLETED:
        return '#9900CC';
      default:
        return '#999999';
    }
  };

  return (
    <ScrollView style={styles.container}>
      {/* Status Card */}
      <View style={styles.card}>
        <Text style={styles.cardTitle}>Status</Text>
        <Text style={styles.statusText}>{status}</Text>
        <View style={styles.statusRow}>
          <View style={[styles.statusBadge, { backgroundColor: getStatusColor(currentStatus) }]}>
            <Text style={styles.statusBadgeText}>
              {currentStatus.toUpperCase()}
            </Text>
          </View>
          {isInCall && (
            <View style={styles.controlIcons}>
              <Text style={[styles.icon, { color: isCameraEnabled ? '#00AA00' : '#CC0000' }]}>
                📹
              </Text>
              <Text style={[styles.icon, { color: isMicrophoneEnabled ? '#00AA00' : '#CC0000' }]}>
                🎤
              </Text>
            </View>
          )}
        </View>
      </View>

      {/* Permissions Card */}
      <View style={styles.card}>
        <Text style={styles.cardTitle}>Permissions</Text>
        {permissions ? (
          <View>
            <Text>Camera: {permissions.hasCameraPermission ? '✓' : '✗'}</Text>
            <Text>Phone State: {permissions.hasPhoneStatePermission ? '✓' : '✗'}</Text>
            <Text>Internet: {permissions.hasInternetPermission ? '✓' : '✗'}</Text>
            <Text>Record Audio: {permissions.hasRecordAudioPermission ? '✓' : '✗'}</Text>
          </View>
        ) : (
          <Text>Checking permissions...</Text>
        )}
        <View style={styles.buttonRow}>
          <TouchableOpacity style={styles.button} onPress={checkPermissionsStatus}>
            <Text style={styles.buttonText}>Check</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.button} onPress={requestPermissionsHandler}>
            <Text style={styles.buttonText}>Request</Text>
          </TouchableOpacity>
        </View>
      </View>

      {/* Configuration Card */}
      <View style={styles.card}>
        <Text style={styles.cardTitle}>Video Call Configuration</Text>
        
        <View style={styles.inputContainer}>
          <Text style={styles.inputLabel}>User ID</Text>
          <TextInput
            style={styles.textInput}
            value={userID}
            onChangeText={setUserID}
            placeholder="Unique identifier for this test session"
          />
        </View>

        <OptionPicker
          label="Idle Timeout"
          selectedValue={idleTimeout}
          options={Object.values(TIMEOUTS).map((value) => ({ label: `${value}s`, value }))}
          onValueChange={setIdleTimeout}
        />

        <View style={styles.configInfo}>
          <Text style={styles.configInfoText}>📡 Server: {serverUrl}</Text>
          <Text style={styles.configInfoText}>🔌 WebSocket: {wssUrl}</Text>
          <Text style={styles.configInfoText}>📱 Client: {clientName}</Text>
        </View>
      </View>

      {/* Action Buttons Card */}
      <View style={styles.card}>
        <Text style={styles.cardTitle}>Actions</Text>
        
        {/* Main call controls */}
        <View style={styles.buttonRow}>
          <TouchableOpacity 
            style={[styles.button, styles.startButton, !isInCall ? {} : styles.disabledButton]}
            onPress={startVideoCallHandler}
            disabled={isInCall}
          >
            <Text style={styles.buttonText}>Start Video Call</Text>
          </TouchableOpacity>
          <TouchableOpacity 
            style={[styles.button, styles.endButton, isInCall ? {} : styles.disabledButton]}
            onPress={endVideoCallHandler}
            disabled={!isInCall}
          >
            <Text style={styles.buttonText}>End Video Call</Text>
          </TouchableOpacity>
        </View>

        {/* Status and config */}
        <View style={styles.buttonRow}>
          <TouchableOpacity style={styles.button} onPress={getVideoCallStatusHandler}>
            <Text style={styles.buttonText}>Get Status</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.button} onPress={setVideoCallConfigHandler}>
            <Text style={styles.buttonText}>Set Config</Text>
          </TouchableOpacity>
        </View>

        {/* Call controls (only enabled during call) */}
        <Text style={styles.sectionTitle}>Call Controls</Text>
        
        <View style={styles.buttonRow}>
          <TouchableOpacity 
            style={[styles.button, isInCall ? {} : styles.disabledButton]}
            onPress={toggleCameraHandler}
            disabled={!isInCall}
          >
            <Text style={styles.buttonText}>
              {isCameraEnabled ? 'Disable Camera' : 'Enable Camera'}
            </Text>
          </TouchableOpacity>
          <TouchableOpacity 
            style={[styles.button, isInCall ? {} : styles.disabledButton]}
            onPress={switchCameraHandler}
            disabled={!isInCall}
          >
            <Text style={styles.buttonText}>Switch Camera</Text>
          </TouchableOpacity>
        </View>

        <TouchableOpacity 
          style={[styles.button, styles.fullWidthButton, isInCall ? {} : styles.disabledButton]}
          onPress={toggleMicrophoneHandler}
          disabled={!isInCall}
        >
          <Text style={styles.buttonText}>
            {isMicrophoneEnabled ? 'Disable Microphone' : 'Enable Microphone'}
          </Text>
        </TouchableOpacity>
      </View>

      {/* Information Card */}
      <View style={styles.card}>
        <Text style={styles.cardTitle}>About Video Call</Text>
        <Text style={styles.infoText}>
          This video call feature uses Udentify's SDK to establish secure video connections for identity verification.
          {'\n\n'}
          Features:
          {'\n'}• Real-time video communication
          {'\n'}• Camera and microphone controls
          {'\n'}• Customizable UI
          {'\n'}• WebSocket-based connection
          {'\n'}• Transaction-based sessions
          {'\n\n'}
          Note: This implementation requires Udentify SDK frameworks to be added for full functionality.
        </Text>
      </View>

      {/* UI Customization Modal */}
      <UICustomizeModal
        visible={configModalVisible}
        onClose={() => setConfigModalVisible(false)}
        onApply={(settings: any) => {
          if (settings.backgroundColor) setBackgroundColor(settings.backgroundColor);
          if (settings.textColor) setTextColor(settings.textColor);
          if (settings.pipViewBorderColor) setPipViewBorderColor(settings.pipViewBorderColor);
          if (settings.notificationLabelDefault) setNotificationLabelDefault(settings.notificationLabelDefault);
          if (settings.notificationLabelCountdown) setNotificationLabelCountdown(settings.notificationLabelCountdown);
          if (settings.notificationLabelTokenFetch) setNotificationLabelTokenFetch(settings.notificationLabelTokenFetch);
          setConfigModalVisible(false);
        }}
      />
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
    backgroundColor: '#f5f5f5',
  },
  card: {
    backgroundColor: 'white',
    borderRadius: 8,
    padding: 16,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 12,
    color: '#333',
  },
  statusText: {
    fontSize: 14,
    marginBottom: 8,
    color: '#666',
  },
  statusRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  statusBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
  },
  statusBadgeText: {
    color: 'white',
    fontSize: 12,
    fontWeight: 'bold',
  },
  controlIcons: {
    flexDirection: 'row',
    gap: 8,
  },
  icon: {
    fontSize: 16,
  },
  buttonRow: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 8,
  },
  button: {
    flex: 1,
    backgroundColor: '#007AFF',
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 8,
    alignItems: 'center',
  },
  buttonText: {
    color: 'white',
    fontSize: 14,
    fontWeight: '600',
  },
  startButton: {
    backgroundColor: '#00AA00',
  },
  endButton: {
    backgroundColor: '#CC0000',
  },
  disabledButton: {
    backgroundColor: '#CCCCCC',
  },
  fullWidthButton: {
    marginTop: 8,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    marginTop: 16,
    marginBottom: 8,
    color: '#333',
  },
  inputContainer: {
    marginBottom: 12,
  },
  inputLabel: {
    fontSize: 14,
    fontWeight: '600',
    marginBottom: 4,
    color: '#333',
  },
  textInput: {
    borderWidth: 1,
    borderColor: '#DDD',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    fontSize: 14,
    backgroundColor: '#FAFAFA',
  },
  configInfo: {
    backgroundColor: '#E3F2FD',
    borderWidth: 1,
    borderColor: '#BBDEFB',
    borderRadius: 8,
    padding: 12,
    marginTop: 8,
  },
  configInfoText: {
    fontSize: 12,
    color: '#1976D2',
    marginBottom: 2,
  },
  infoText: {
    fontSize: 14,
    lineHeight: 20,
    color: '#666',
  },
});

export default VideoCallTab;

import React, { useState } from 'react';
import { SafeAreaView, StyleSheet } from 'react-native';

// Import components
import TabNavigator from '../../components/TabNavigator';
import SSLPinningTab from '../../components/SSLPinningTab';
import OCRTab from '../../components/OCRTab';
import NFCTab from '../../components/NFCTab';
import LivenessTab from '../../components/LivenessTab';
import MRZTab from '../../components/MRZTab';
import VideoCallTab from '../../components/VideoCallTab';
import PlaceholderTab from '../../components/PlaceholderTab';
import RemoteLanguagePackTest from '../../components/RemoteLanguagePackTest';

// Create placeholder components for future tabs
const BiometricTab = () => (
  <PlaceholderTab 
    title="Biometric" 
    description="Face recognition and biometric verification will be available here." 
  />
);

const SettingsTab = () => (
  <PlaceholderTab 
    title="Settings" 
    description="App configuration and settings will be available here." 
  />
);

export default function Home() {
  // Shared state for MRZ data that can be used by NFC tab
  const [mrzData, setMrzData] = useState<{
    documentNumber?: string;
    dateOfBirth?: string;
    dateOfExpiration?: string;
  } | null>(null);
  
  // Current active tab state
  const [activeTab, setActiveTab] = useState<string>('ssl');

  // Handle MRZ data extraction
  const handleMrzDataExtracted = (documentNumber?: string, dateOfBirth?: string, dateOfExpiration?: string) => {
    console.log('Home - MRZ data extracted:', { documentNumber, dateOfBirth, dateOfExpiration });
    setMrzData({
      documentNumber,
      dateOfBirth,
      dateOfExpiration,
    });
  };

  // Handle switch to NFC tab with MRZ data
  const handleSwitchToNFC = () => {
    console.log('Home - Switching to NFC tab with MRZ data:', mrzData);
    setActiveTab('nfc');
  };

  const tabs = [
    {
      id: 'ssl',
      title: 'SSL',
      component: SSLPinningTab,
    },
    {
      id: 'language',
      title: 'Language',
      component: RemoteLanguagePackTest,
    },
    {
      id: 'ocr',
      title: 'OCR',
      component: OCRTab,
    },
    {
      id: 'nfc',
      title: 'NFC',
      component: NFCTab,
      props: {
        mrzData: mrzData,
      }
    },
    {
      id: 'mrz',
      title: 'MRZ',
      component: MRZTab,
      props: {
        onMrzDataExtracted: handleMrzDataExtracted,
        onSwitchToNFC: handleSwitchToNFC,
      },
    },
    {
      id: 'liveness',
      title: 'Liveness',
      component: LivenessTab
    },
    {
      id: 'videocall',
      title: 'Video Call',
      component: VideoCallTab
    }
  ];

  return (
    <SafeAreaView style={styles.container}>
      <TabNavigator 
        tabs={tabs} 
        activeTab={activeTab}
        onTabChange={setActiveTab}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'white',
  },
});

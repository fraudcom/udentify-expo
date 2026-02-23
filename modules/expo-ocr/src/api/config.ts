import ExpoOCRModule from '../ExpoOCRModule';
import type {OCRUIConfiguration} from '../types/ui.types';

export async function configureUISettings(
  uiConfig: OCRUIConfiguration
): Promise<boolean> {
  try {
    console.log('📱 Configuring OCR UI settings:', uiConfig);
    return await ExpoOCRModule.configureUISettings(uiConfig);
  } catch (error) {
    console.error('ExpoOCR - configureUISettings error:', error);
    throw error;
  }
}





import ExpoOCRModule from '../ExpoOCRModule';
import type {HologramResponse} from '../types/hologram.types';

export async function startHologramCamera(
  serverURL: string,
  transactionID: string
): Promise<boolean> {
  try {
    return await ExpoOCRModule.startHologramCamera(
      serverURL,
      transactionID
    );
  } catch (error) {
    console.error('ExpoOCR - startHologramCamera error:', error);
    return false;
  }
}

export async function performHologramCheck(
  serverURL: string,
  transactionID: string,
  videoUrls: string[]
): Promise<HologramResponse> {
  try {
    return await ExpoOCRModule.performHologramCheck(
      serverURL,
      transactionID,
      videoUrls
    );
  } catch (error) {
    console.error('ExpoOCR - performHologramCheck error:', error);
    throw error;
  }
}





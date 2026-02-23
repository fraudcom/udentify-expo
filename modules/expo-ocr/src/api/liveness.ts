import ExpoOCRModule from '../ExpoOCRModule';
import type {DocumentLivenessResponse} from '../types/ui.types';

export async function performDocumentLiveness(
  serverURL: string,
  transactionID: string,
  frontSideImage: string,
  backSideImage: string
): Promise<DocumentLivenessResponse> {
  try {
    return await ExpoOCRModule.performDocumentLiveness(
      serverURL,
      transactionID,
      frontSideImage,
      backSideImage
    );
  } catch (error) {
    console.error('ExpoOCR - performDocumentLiveness error:', error);
    throw error;
  }
}





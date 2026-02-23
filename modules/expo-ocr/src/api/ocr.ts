import ExpoOCRModule from '../ExpoOCRModule';
import type {DocumentTypeValue} from '../constants/DocumentType';
import type {OCRResponse, OCRAndDocumentLivenessResponse} from '../types/ocr.types';

export async function performOCR(
  serverURL: string,
  transactionID: string,
  frontSideImage: string,
  backSideImage: string,
  documentType: DocumentTypeValue,
  country: string = 'TUR'
): Promise<OCRResponse> {
  try {
    return await ExpoOCRModule.performOCR(
      serverURL,
      transactionID,
      frontSideImage,
      backSideImage,
      documentType,
      country
    );
  } catch (error) {
    console.error('ExpoOCR - performOCR error:', error);
    throw error;
  }
}

export async function performOCRAndDocumentLiveness(
  serverURL: string,
  transactionID: string,
  frontSideImage: string,
  backSideImage: string,
  documentType: DocumentTypeValue,
  country: string = 'TUR'
): Promise<OCRAndDocumentLivenessResponse> {
  try {
    return await ExpoOCRModule.performOCRAndDocumentLiveness(
      serverURL,
      transactionID,
      frontSideImage,
      backSideImage,
      documentType,
      country
    );
  } catch (error) {
    console.error('ExpoOCR - performOCRAndDocumentLiveness error:', error);
    throw error;
  }
}





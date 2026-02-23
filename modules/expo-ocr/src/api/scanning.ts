import ExpoOCRModule from '../ExpoOCRModule';
import type {DocumentTypeValue} from '../constants/DocumentType';
import type {DocumentSideValue} from '../constants/DocumentSide';

export async function startOCRScanning(
  serverURL: string,
  transactionID: string,
  documentType: DocumentTypeValue,
  documentSide: DocumentSideValue,
  country: string = 'TUR'
): Promise<boolean> {
  console.log('startOCRScanning called');
  console.log('ExpoOCR - Country:', country);
  
  try {
    return await ExpoOCRModule.startOCRScanning(
      serverURL,
      transactionID,
      documentType,
      documentSide,
      country
    );
  } catch (error) {
    console.error('ExpoOCR - startOCRScanning error:', error);
    return false;
  }
}





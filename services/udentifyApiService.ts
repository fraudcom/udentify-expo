// Udentify API Service for transaction management

import { currentConfig } from '../config/apiConfig';
import { OCRModuleValue } from '../constants/ocrConstants';

export interface TransactionResponse {
  transactionId: string;
  status: string;
  message?: string;
}

export interface ApiError {
  message: string;
  code?: string;
  status?: number;
}

class UdentifyApiService {
  private baseUrl: string;
  private apiKey: string;
  private timeout: number;

  constructor() {
    this.baseUrl = currentConfig.baseUrl;
    this.apiKey = currentConfig.apiKey;
    this.timeout = currentConfig.timeout;
  }

  /**
   * Update API configuration
   */
  updateConfig(baseUrl?: string, apiKey?: string, timeout?: number) {
    if (baseUrl) this.baseUrl = baseUrl;
    if (apiKey) this.apiKey = apiKey;
    if (timeout) this.timeout = timeout;
  }

  /**
   * Start a new transaction with specified modules
   */
  async startTransaction(modules: OCRModuleValue[]): Promise<string> {
    try {
      console.log('UdentifyApiService - Starting transaction with modules:', modules);
      console.log('UdentifyApiService - Using base URL:', this.baseUrl);
      
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), this.timeout);

      const response = await fetch(`${this.baseUrl}/transaction/start`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Key': this.apiKey,
        },
        body: JSON.stringify({
          moduleList: modules,
        }),
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        const errorText = await response.text();
        console.error('UdentifyApiService - API Error Response:', errorText);
        throw new Error(`API Error: ${response.status} - ${errorText}`);
      }

      const data: any = await response.json();
      console.log('UdentifyApiService - Transaction started successfully:', data);
      
      // Match React Native version - transaction ID is in response.response.id
      if (data.response && data.response.id) {
        console.log('UdentifyApiService - Transaction ID from server:', data.response.id);
        return data.response.id;
      } else {
        console.log('UdentifyApiService - No transaction ID found in response');
        console.log('UdentifyApiService - Response structure:', JSON.stringify(data, null, 2));
        throw new Error('No transaction ID found in server response');
      }
    } catch (error) {
      console.error('UdentifyApiService - Failed to start transaction:', error);
      
      if (error instanceof Error) {
        if (error.name === 'AbortError') {
          throw new Error('Transaction request timed out');
        }
        throw error;
      }
      
      throw new Error('Unknown error occurred while starting transaction');
    }
  }

  /**
   * Get transaction status
   */
  async getTransactionStatus(transactionId: string): Promise<any> {
    try {
      console.log('UdentifyApiService - Getting transaction status for:', transactionId);
      
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), this.timeout);

      const response = await fetch(`${this.baseUrl}/transaction/${transactionId}/status`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Key': this.apiKey,
        },
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        const errorText = await response.text();
        console.error('UdentifyApiService - Status API Error Response:', errorText);
        throw new Error(`Status API Error: ${response.status} - ${errorText}`);
      }

      const data = await response.json();
      console.log('UdentifyApiService - Transaction status retrieved:', data);
      
      return data;
    } catch (error) {
      console.error('UdentifyApiService - Failed to get transaction status:', error);
      
      if (error instanceof Error) {
        if (error.name === 'AbortError') {
          throw new Error('Status request timed out');
        }
        throw error;
      }
      
      throw new Error('Unknown error occurred while getting transaction status');
    }
  }

  /**
   * Complete a transaction
   */
  async completeTransaction(transactionId: string): Promise<any> {
    try {
      console.log('UdentifyApiService - Completing transaction:', transactionId);
      
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), this.timeout);

      const response = await fetch(`${this.baseUrl}/transaction/${transactionId}/complete`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Key': this.apiKey,
        },
        body: JSON.stringify({
          timestamp: Date.now(),
        }),
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        const errorText = await response.text();
        console.error('UdentifyApiService - Complete API Error Response:', errorText);
        throw new Error(`Complete API Error: ${response.status} - ${errorText}`);
      }

      const data = await response.json();
      console.log('UdentifyApiService - Transaction completed:', data);
      
      return data;
    } catch (error) {
      console.error('UdentifyApiService - Failed to complete transaction:', error);
      
      if (error instanceof Error) {
        if (error.name === 'AbortError') {
          throw new Error('Complete request timed out');
        }
        throw error;
      }
      
      throw new Error('Unknown error occurred while completing transaction');
    }
  }

  async getVideoCallTransactionId(channelId: number = 252, severity: string = 'NORMAL'): Promise<string | null> {
    console.log('UdentifyApiService - Getting Video Call transaction ID');
    
    try {
      const requestBody = {
        moduleList: [
          'OCR',
          'FACE_REGISTRATION', 
          'FACE_LIVENESS',
          'VIDEO_CALL'
        ],
        transactionSource: 1,
        channelId: channelId,
        severity: severity,
      };

      console.log('UdentifyApiService - Video Call API request body:', JSON.stringify(requestBody));
      console.log('UdentifyApiService - Using base URL:', this.baseUrl);

      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), this.timeout);

      const response = await fetch(`${this.baseUrl}/transaction/start`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Key': this.apiKey,
        },
        body: JSON.stringify(requestBody),
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        const errorText = await response.text();
        console.error('UdentifyApiService - Video Call API Error Response:', errorText);
        throw new Error(`Video Call API Error: ${response.status} - ${errorText}`);
      }

      const data: any = await response.json();
      console.log('UdentifyApiService - Video Call transaction response:', data);

      if (data.response && data.response.id) {
        console.log('UdentifyApiService - Video Call Transaction ID obtained:', data.response.id);
        return data.response.id;
      } else {
        console.error('UdentifyApiService - No transaction ID in Video Call response');
        return null;
      }
    } catch (error) {
      console.error('UdentifyApiService - Error getting Video Call transaction ID:', error);
      
      if (error instanceof Error) {
        if (error.name === 'AbortError') {
          console.error('UdentifyApiService - Video Call transaction request timed out');
        }
      }
      
      return null;
    }
  }
}

// Export singleton instance
export const udentifyApiService = new UdentifyApiService();

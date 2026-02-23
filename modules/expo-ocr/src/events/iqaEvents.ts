import { EventEmitter, Subscription } from 'expo-modules-core';
import ExpoOCRModule from '../ExpoOCRModule';
import type {IQAResult} from '../types/iqa.types';

const emitter = new EventEmitter(ExpoOCRModule);

export function addIQAResultListener(
  callback: (result: IQAResult) => void
): () => void {
  try {
    const subscription: Subscription = emitter.addListener(
      'onIQAResult',
      callback
    );
    
    return () => {
      subscription.remove();
    };
  } catch (error) {
    console.error('ExpoOCR - addIQAResultListener error:', error);
    return () => {};
  }
}

export function removeAllIQAResultListeners(): void {
  try {
    emitter.removeAllListeners('onIQAResult');
  } catch (error) {
    console.error('ExpoOCR - removeAllIQAResultListeners error:', error);
  }
}





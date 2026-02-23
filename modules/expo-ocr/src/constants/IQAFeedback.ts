export const IQAFeedback = {
  SUCCESS: 'success',
  BLUR_DETECTED: 'blurDetected',
  GLARE_DETECTED: 'glareDetected',
  HOLOGRAM_GLARE: 'hologramGlare',
  CARD_NOT_DETECTED: 'cardNotDetected',
  CARD_CLASSIFICATION_MISMATCH: 'cardClassificationMismatch',
  CARD_NOT_INTACT: 'cardNotIntact',
  OTHER: 'other',
} as const;

export type IQAFeedbackValue = typeof IQAFeedback[keyof typeof IQAFeedback];





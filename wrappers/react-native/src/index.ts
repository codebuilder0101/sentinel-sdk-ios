import { NativeModules, Platform } from 'react-native';
import { CaptureOptions, CapturePayload } from './types';

const LINKING_ERROR =
  `The package '@sentinel/react-native' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const SentinelModule = NativeModules.SentinelModule
  ? NativeModules.SentinelModule
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

export interface InitOptions {
  apiKey: string;
  environment?: 'production' | 'staging' | 'sandbox';
}

export class SentinelSDK {
  /**
   * Initializes the Sentinel SDK with client API credentials.
   */
  static async initialize(options: InitOptions): Promise<boolean> {
    return SentinelModule.initialize(options.apiKey, options.environment || 'production');
  }

  /**
   * Captures customer identity, device parameters, location, and gambling app screening.
   */
  static async capture(options: CaptureOptions): Promise<CapturePayload> {
    const rawJson = await SentinelModule.capture({
      ...options,
      wrapper: 'react-native'
    });
    return typeof rawJson === 'string' ? JSON.parse(rawJson) : rawJson;
  }
}

export * from './types';
export default SentinelSDK;

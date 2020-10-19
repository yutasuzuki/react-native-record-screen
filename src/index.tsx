import { NativeModules, Dimensions } from 'react-native';

export type RecordingStartResponse = 'started';

export type RecordScreenConfigType = {
  mic?: boolean;
};

export type RecordingSuccessResponse = {
  status: 'success';
  result: {
    outputURL: string;
  };
};

export type RecordingErrorResponse = {
  status: 'error';
  result: any;
};

export type RecordingResponse =
  | RecordingSuccessResponse
  | RecordingErrorResponse;

type RecordScreenType = {
  setup(config: RecordScreenConfigType): void;
  startRecording(
    config?: RecordScreenConfigType
  ): Promise<RecordingStartResponse>;
  stopRecording(): Promise<RecordingResponse>;
  clean(): Promise<string>;
};

const { RecordScreen } = NativeModules;

const RS = RecordScreen as RecordScreenType;

class ReactNativeRecordScreenClass {
  private _screenWidth = Dimensions.get('window').width;
  private _screenHeight = Dimensions.get('window').height;

  setup(config: RecordScreenConfigType = {}): void {
    const conf = Object.assign(
      {
        mic: true,
        width: this._screenWidth,
        height: this._screenHeight,
      },
      config
    );
    RS.setup(conf);
  }

  async startRecording(
    config: RecordScreenConfigType = {}
  ): Promise<RecordingStartResponse> {
    this.setup(config);
    return new Promise((resolve, reject) => {
      RS.startRecording().then(resolve).catch(reject);
    });
  }

  stopRecording(): Promise<RecordingResponse> {
    return new Promise((resolve, reject) => {
      RS.stopRecording().then(resolve).catch(reject);
    });
  }

  clean(): Promise<string> {
    return new Promise((resolve, reject) => {
      RS.clean().then(resolve).catch(reject);
    });
  }
}

const ReactNativeRecordScreen = new ReactNativeRecordScreenClass();

export default ReactNativeRecordScreen;

import { NativeModules, Dimensions } from 'react-native';

type RecordScreenCropConfigType = {
  width: number;
  height: number;
  x: number;
  y: number;
  fps: number;
};

type RecordScreenConfigType = {
  width?: number;
  height?: number;
  crop?: RecordScreenCropConfigType;
};

type RecordingSuccessResponse = {
  status: 'success';
  result: {
    outputURL: string;
  };
};

type RecordingErrorResponse = {
  status: 'error';
  result: {
    outputURL: string;
  };
};

type RecordingResponse = RecordingSuccessResponse | RecordingErrorResponse;

type RecordScreenType = {
  setup(config: RecordScreenConfigType): void;
  startRecording(config?: RecordScreenConfigType): Promise<void>;
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
        audio: true,
        width: this._screenWidth,
        height: this._screenHeight,
      },
      config
    );
    RS.setup(conf);
  }

  async startRecording(config: RecordScreenConfigType = {}): Promise<void> {
    Object.keys(config).length && this.setup(config);
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

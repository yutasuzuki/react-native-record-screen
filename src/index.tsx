import { NativeModules } from 'react-native';

type RecordScreenEditConfigType = {
  width: number;
  height: number;
  translateX: number;
  translateY: number;
  fps: number;
};

type RecordScreenConfigType = {
  audio: boolean;
  width: number;
  height: number;
  edit?: RecordScreenEditConfigType;
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
};

const { RecordScreen } = NativeModules;

export default RecordScreen as RecordScreenType;

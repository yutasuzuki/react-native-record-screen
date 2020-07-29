import { NativeModules } from 'react-native';

type RecordScreenType = {
  multiply(a: number, b: number): Promise<number>;
};

const { RecordScreen } = NativeModules;

export default RecordScreen as RecordScreenType;

# react-native-record-screen

react-native-record-screen

## Device

iOS Only

## Installation

```sh
npm install react-native-record-screen
```

add info.pilot

```
<key>NSCameraUsageDescription</key>
<string>Please allow use of camera</string>
```

## Usage

```js
import RecordScreen from 'react-native-record-screen';

// recording start
RecordScreen.startRecording().catch((error) => console.error(error));

// recording stop
const res = await RecordScreen.stopRecording().catch((error) =>
  console.error(error)
);
if (res) {
  const url = res.result.outputURL;
}
```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

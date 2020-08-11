# react-native-record-screen

A screen record module for React Native.

- Support iOS >= 11.0

Sorry...Android dont't support yet.(It will be supported soon.)

## Installation

```sh
npm install react-native-record-screen
```

add info.pilot

```
<key>NSCameraUsageDescription</key>
<string>Please allow use of camera</string>
```

pod install

```
cd ios && pod install && cd ../
```

## Usage

### Recording full screen

```js
import RecordScreen from 'react-native-record-screen';

// recording start
RecordScreen.startRecording().catch((error) => console.error(error));

// recording stop
const res = await RecordScreen.stopRecording().catch((error) =>
  console.warn(error)
);
if (res) {
  const url = res.result.outputURL;
}
```

### Croped screen

```js
// set up RecordScreen
RecordScreen.setup({
  crop: {
    width: Dimensions.get('window').width,
    height: Dimensions.get('window').height - 180,
    x: 0,
    y: 80,
    fps: 24,
  },
});

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

or

```js
// recording start
RecordScreen.startRecording({
  crop: {
    width: Dimensions.get('window').width,
    height: Dimensions.get('window').height - 180,
    x: 0,
    y: 80,
    fps: 24,
  },
}).catch((error) => console.error(error));

// recording stop
const res = await RecordScreen.stopRecording().catch((error) =>
  console.warn(error)
);
if (res) {
  const url = res.result.outputURL;
}
```

### Clean Sandbox

```js
RecordScreen.clean();
```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

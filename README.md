# react-native-record-screen

A screen record module for React Native.

- Support iOS >= 11.0

- Support Android
  - minSdkVersion = 26
  - compileSdkVersion = 29
  - targetSdkVersion = 29
  - use [HBRecorder](https://github.com/HBiSoft/HBRecorder)

## Installation

### iOS

```sh
npm install react-native-record-screen
```

add info.pilot

```
<key>NSCameraUsageDescription</key>
<string>Please allow use of camera</string>
```

pod install

```sh
cd ios && pod install && cd ../
```

### Android

AndroidManifest.xml

```
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
  <uses-permission android:name="android.permission.WRITE_INTERNAL_STORAGE" />
  <uses-permission android:name="android.permission.RECORD_AUDIO" />
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
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

### Crop screen(iOS Only)

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

## License

MIT

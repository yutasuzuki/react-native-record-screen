[![Stand With Ukraine](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/banner2-direct.svg)](https://stand-with-ukraine.pp.ua)

# react-native-record-screen

A screen record module for React Native.

- Support iOS >= 11.0 (Simulator is not work)

- Support Android
  - minSdkVersion = 26
  - compileSdkVersion = 33
  - targetSdkVersion = 31
  - use [HBRecorder](https://github.com/HBiSoft/HBRecorder)

## Installation

```sh
npm install react-native-record-screen
```

### iOS

1. Add the permission strings to your Info.plist

```xml
<key>NSCameraUsageDescription</key>
<string>Please allow use of camera</string>
<!-- If you intend to use the microphone -->
<key>NSMicrophoneUsageDescription</key>
<string>Please allow use of microphone</string>
```

2. pod install

```sh
npx pod-install
```

3. Add ReplayKit.framework at Link Binary With Libraries

![Add ReplayKit.framework at Link Binary With Libraries](https://user-images.githubusercontent.com/4530616/257236753-e3555d2f-53a5-4ffd-87eb-db1691d0552d.png)

### Android

1. Add the permissions to your AndroidManifest.xml

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<!-- If you intend to use the microphone -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

## Usage

### Recording full screen

```js
import RecordScreen, { RecordingStartResponse } from 'react-native-record-screen';

// recording start
const res = RecordScreen.startRecording().catch((error) => console.error(error));
if (res === RecordingStartResponse.PermissionError) {
  // user denies access
}

// recording stop
const res = await RecordScreen.stopRecording().catch((error) =>
  console.warn(error)
);
if (res) {
  const url = res.result.outputURL;
}
```

### Setting microphone

default true.

```js
// mic off
RecordScreen.startRecording({ mic: false }).catch((error) =>
  console.error(error)
);

// recording stop
const res = await RecordScreen.stopRecording().catch((error) =>
  console.warn(error)
);
if (res) {
  const url = res.result.outputURL;
}
```

### Adjusting bitrate / frame rate

```js
RecordScreen.startRecording({
  bitrate: 1024000, // default 236390400
  fps: 24, // default 60
})
```

### Clean Sandbox

```js
RecordScreen.clean();
```

## License

MIT

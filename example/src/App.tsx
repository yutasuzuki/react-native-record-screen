import React, { useState, useMemo } from 'react';
import {
  StyleSheet,
  View,
  Text,
  Dimensions,
  StatusBar,
  SafeAreaView,
  ScrollView,
  TouchableHighlight,
} from 'react-native';
import Video from 'react-native-video';
import RecordScreen from 'react-native-record-screen';

export default function App() {
  const [uri, setUri] = useState<string>('');
  const [recording, setRecording] = useState<boolean>(false);

  const _handleOnRecording = async () => {
    if (recording) {
      setRecording(false);
      const res = await RecordScreen.stopRecording().catch((error) =>
        console.warn(error)
      );
      console.log('res', res);
      if (res) {
        setUri(res.result.outputURL);
      }
    } else {
      setUri('');
      setRecording(true);
      await RecordScreen.startRecording({
        crop: {
          width: Dimensions.get('window').width,
          height: Dimensions.get('window').height - 180,
          x: 0,
          y: 80,
          fps: 60,
        },
      }).catch((error) => {
        console.warn(error);
        setRecording(false);
        setUri('');
      });
    }
  };

  const btnStyle = useMemo(() => {
    return recording ? styles.btnActive : styles.btnDefault;
  }, [recording]);

  return (
    <>
      <StatusBar barStyle="light-content" />
      <View style={styles.navbar}>
        {recording ? (
          <View style={styles.recordingMark}>
            <Text style={styles.recordingMarkText}>Recording</Text>
          </View>
        ) : null}
      </View>
      <SafeAreaView style={styles.container}>
        <ScrollView>
          <View style={styles.scrollView}>
            <Text style={styles.heading}>Lorem ipsum dolor sit amet</Text>
            <Text style={styles.text}>
              Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi
              malesuada enim id fermentum pretium. Sed tempor, urna sed
              facilisis convallis, massa eros porttitor lectus, ac maximus urna
              mauris et lorem. In ac pretium felis, quis iaculis odio.
              Vestibulum et arcu in leo egestas maximus eu a risus. Praesent nec
              viverra mauris, at porta ligula. Sed at hendrerit dolor. Mauris
              quis scelerisque mi. Nam porttitor justo molestie orci hendrerit,
              quis rutrum dui finibus. Cras tincidunt libero non nulla
              malesuada, a fermentum mi posuere. Nunc ultricies consectetur
              lectus, vel ullamcorper ipsum ornare sed. Etiam rhoncus nunc ac
              est efficitur consectetur.
            </Text>
            <Text style={styles.heading}>Sed vitae semper dolor</Text>
            <Text style={styles.text}>
              Sed vitae semper dolor. Nulla at blandit neque. Cras luctus
              ullamcorper nisi, at venenatis purus porta eu. Praesent sed ante
              sed orci placerat efficitur. Maecenas sed dapibus enim.
              Suspendisse ac imperdiet mauris. Pellentesque arcu justo, accumsan
              eu turpis vel, ornare dapibus urna. Fusce vitae sagittis urna. Sed
              pulvinar justo ipsum, at porta tortor aliquet vitae. Sed suscipit
              orci suscipit pretium efficitur. In vulputate dictum quam,
              lobortis euismod elit scelerisque sed. Donec sed nunc justo.
              Pellentesque habitant morbi tristique senectus et netus et
              malesuada fames ac turpis egestas.
            </Text>
            <Text style={styles.heading}>Nam ligula nisi</Text>
            <Text style={styles.text}>
              Nam ligula nisi, tempus et condimentum vel, tincidunt in diam.
              Vestibulum lorem sapien, gravida id semper non, interdum at risus.
              Praesent viverra posuere aliquet. Cras convallis vitae augue sed
              accumsan. Aenean vel tincidunt orci, scelerisque dapibus sem. Sed
              porta neque sit amet tincidunt imperdiet. Phasellus tortor lacus,
              mattis id placerat a, blandit non neque. Morbi maximus, erat eu
              tincidunt interdum, ipsum neque maximus nisi, at viverra nunc
              purus volutpat nibh. Curabitur sagittis ac metus ac condimentum.
              Integer sodales erat quis turpis ornare imperdiet. Aenean
              hendrerit fringilla ipsum, eget egestas lectus vestibulum quis. In
              auctor, dolor quis mattis tincidunt, lacus leo interdum mi, a
              viverra quam libero non nisl.
            </Text>
            <Text style={styles.heading}>Etiam non ante augue</Text>
            <Text style={styles.text}>
              Etiam non ante augue. Integer varius mi eget nulla rutrum commodo.
              Suspendisse in congue metus. Curabitur ullamcorper quam eu mollis
              commodo. Vivamus dictum velit tortor, quis blandit ante euismod
              vel. Cras placerat, eros at gravida volutpat, enim mi fermentum
              ligula, et suscipit tortor ipsum eget ante. Nullam viverra
              dignissim turpis, in consequat velit aliquam ut.
            </Text>
            <Text style={styles.heading}>Praesent sed orci turpis</Text>
            <Text style={styles.text}>
              Praesent sed orci turpis. Aenean gravida quam quis sollicitudin
              rutrum. Nullam ac risus sem. Aenean erat arcu, cursus sed nibh
              vel, venenatis sagittis odio. Mauris volutpat lectus enim, a
              interdum felis eleifend at. In porta sollicitudin fringilla. Nam
              eu mauris nisi. Donec vitae lobortis nulla. Pellentesque euismod
              tristique mauris, non eleifend lacus laoreet a.
            </Text>
          </View>
        </ScrollView>
      </SafeAreaView>
      <View style={styles.btnContainer}>
        <TouchableHighlight onPress={_handleOnRecording}>
          <View style={styles.btnWrapper}>
            <View style={btnStyle} />
          </View>
        </TouchableHighlight>
      </View>
      {!!uri ? (
        <View style={styles.preview}>
          <Video
            source={{
              uri,
            }}
            style={styles.video}
          />
        </View>
      ) : null}
    </>
  );
}

const styles = StyleSheet.create({
  navbar: {
    height: 80,
    backgroundColor: '#212121',
    alignItems: 'center',
    justifyContent: 'flex-end',
  },
  recordingMark: {
    backgroundColor: 'red',
    paddingVertical: 6,
    paddingHorizontal: 16,
    marginBottom: 10,
    borderRadius: 24,
  },
  recordingMarkText: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#fff',
  },
  container: {
    flex: 1,
  },
  scrollView: {
    flex: 1,
    padding: 24,
  },
  heading: {
    fontSize: 24,
    lineHeight: 32,
    paddingBottom: 16,
    fontWeight: 'bold',
  },
  text: {
    fontSize: 16,
    lineHeight: 24,
    paddingBottom: 36,
  },
  btnContainer: {
    height: 100,
    paddingTop: 12,
    alignItems: 'center',
    justifyContent: 'flex-start',
    backgroundColor: '#212121',
  },
  btnWrapper: {
    alignItems: 'center',
    justifyContent: 'center',
    width: 60,
    height: 60,
    backgroundColor: '#fff',
    borderRadius: 30,
  },
  btnDefault: {
    width: 48,
    height: 48,
    backgroundColor: '#fff',
    borderRadius: 24,
    borderWidth: 4,
    borderStyle: 'solid',
    borderColor: '#212121',
  },
  btnActive: {
    width: 36,
    height: 36,
    backgroundColor: 'red',
    borderRadius: 8,
  },
  preview: {
    position: 'absolute',
    right: 12,
    bottom: 116,
    width: Dimensions.get('window').width / 2,
    height: Dimensions.get('window').height / 3,
    zIndex: 1,
    padding: 8,
    backgroundColor: '#aaa',
  },
  video: {
    flex: 1,
  },
});

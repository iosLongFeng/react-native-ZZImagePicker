/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 * @flow
 */

import React, {PureComponent} from 'react';
import {
  SafeAreaView,
  StyleSheet,
  ScrollView,
  View,
  Text,
  StatusBar,
  Image,
  NativeModules,
} from 'react-native';

import {
  Header,
  LearnMoreLinks,
  Colors,
  DebugInstructions,
  ReloadInstructions,
} from 'react-native/Libraries/NewAppScreen';
import ZZImagePIcker from './ZZImagePicker/ZZImagePIcker';
let appCommonMoudle = NativeModules.APPCommonMoudle;
class App extends PureComponent {
  state = {
    images: [],
    video: null,
  };
  render() {
    console.log(this.state.images);
    return (
      <View style={{flex: 1}}>
        <StatusBar barStyle="dark-content" />
        <SafeAreaView>
          <Text onPress={this._takePhoto} style={{fontSize: 20, marginTop: 10}}>
            take phooto
          </Text>
          <Text onPress={this._takeVideo} style={{fontSize: 20, marginTop: 10}}>
            take video
          </Text>

          <Text onPress={this._zipVideo} style={{fontSize: 20, marginTop: 10}}>
            zip video111
          </Text>
          <Text
            onPress={this._uploadFile}
            style={{fontSize: 20, marginTop: 10}}>
            upload file
          </Text>
          {this.state.images.map(uri => {
            return (
              <Image
                key={uri}
                source={{uri}}
                style={{width: 100, height: 200, backgroundColor: 'red'}}
                resizeMode={'stretch'}
              />
            );
          })}
        </SafeAreaView>
      </View>
    );
  }
  _takePhoto = async () => {
    try {
      let result = await ZZImagePIcker.pickPhoto(4, true, true);
      this.setState({
        images: result,
      });
      console.log(result);
      // 选择成功
    } catch (err) {
      console.log(err);
      // 取消选择，err.message为"取消"
    }
  };

  _takeVideo = async () => {
    try {
      let result = await ZZImagePIcker.pickVideo(120, true);
      console.log(result);
      let url = result.coverImage;
      this.setState({
        images: [url],
        video: result,
      });
      // 选择成功
    } catch (err) {
      console.log(err);
      // 取消选择，err.message为"取消"
    }
  };

  _zipVideo = async () => {
    try {
      let result = await ZZImagePIcker.zipVideo(this.state.video.videoPath);
      console.log('压缩完成' + result);
    } catch (e) {
      console.log('压缩失败');
    }
  };

  _uploadFile = async () => {
    try {
      //let path = await ZZImagePIcker.zipVideo(this.state.video.videoPath)
      let result = await appCommonMoudle.uploadFileArr(this.state.images);
      console.log('上传成功' + result);
    } catch (e) {
      console.log('上传失败');
    }
  };
}

const styles = StyleSheet.create({
  scrollView: {
    backgroundColor: Colors.lighter,
  },
  engine: {
    position: 'absolute',
    right: 0,
  },
  body: {
    backgroundColor: Colors.white,
  },
  sectionContainer: {
    marginTop: 32,
    paddingHorizontal: 24,
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: '600',
    color: Colors.black,
  },
  sectionDescription: {
    marginTop: 8,
    fontSize: 18,
    fontWeight: '400',
    color: Colors.dark,
  },
  highlight: {
    fontWeight: '700',
  },
  footer: {
    color: Colors.dark,
    fontSize: 12,
    fontWeight: '600',
    padding: 4,
    paddingRight: 12,
    textAlign: 'right',
  },
});

export default App;

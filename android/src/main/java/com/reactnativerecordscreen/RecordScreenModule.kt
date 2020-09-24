package com.reactnativerecordscreen

import android.app.Activity
import android.app.Application
import android.content.Context
import android.content.Intent
import android.media.MediaCodecList
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.util.SparseIntArray
import android.view.Surface
import androidx.appcompat.app.AppCompatActivity
import com.facebook.react.bridge.*
import com.hbisoft.hbrecorder.HBRecorder
import com.hbisoft.hbrecorder.HBRecorderListener
import java.io.File
import java.io.IOException
import kotlin.math.ceil


class RecordScreenModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext), HBRecorderListener {

  private var hbRecorder: HBRecorder? = null;
  private var screenWidth: Number = 0;
  private var screenHeight: Number = 0;
  private var mic: Boolean = true;
  private var currentVersion: String = "";
  private var outputUri: File? = null;
  private var startPromise: Promise? = null;
  private var stopPromise: Promise? = null;

  companion object {
    private val ORIENTATIONS = SparseIntArray();
    const val SCREEN_RECORD_REQUEST_CODE = 1000;

    init {
      ORIENTATIONS.append(Surface.ROTATION_0, 90);
      ORIENTATIONS.append(Surface.ROTATION_90, 0);
      ORIENTATIONS.append(Surface.ROTATION_180, 270);
      ORIENTATIONS.append(Surface.ROTATION_270, 180);
    }
  }

  override fun getName(): String {
    return "RecordScreen"
  }

  private val mActivityEventListener: ActivityEventListener = object : BaseActivityEventListener() {
    override fun onActivityResult(activity: Activity, requestCode: Int, resultCode: Int, intent: Intent?) {
      println("resultCode")
      println(resultCode)
      println("AppCompatActivity.RESULT_OK")
      println(AppCompatActivity.RESULT_OK)
      if (requestCode == SCREEN_RECORD_REQUEST_CODE) {
        if (resultCode == AppCompatActivity.RESULT_OK) {
          hbRecorder!!.startScreenRecording(intent, resultCode, Activity());
        } else {
          startPromise!!.reject("404", "cancel!!");
        }
      } else {
        startPromise!!.reject("404", "cancel!");
      }
      startPromise!!.resolve(true);
    }
  }

  override fun initialize() {
    super.initialize()
    currentVersion = Build.VERSION.SDK_INT.toString()
    outputUri = reactApplicationContext.getExternalFilesDir("ReactNativeRecordScreen");
  }

  @ReactMethod
  fun setup(readableMap: ReadableMap) {
    Application().onCreate()
    screenWidth = if (readableMap.hasKey("width")) ceil(readableMap.getDouble("width")).toInt() else 0;
    screenHeight = if (readableMap.hasKey("height")) ceil(readableMap.getDouble("height")).toInt() else 0;
    mic =  if (readableMap.hasKey("mic")) readableMap.getBoolean("mic") else true;
    hbRecorder = HBRecorder(reactApplicationContext, this);
    hbRecorder!!.setOutputPath(outputUri.toString());
    if(doesSupportEncoder("h264")){
      hbRecorder!!.setVideoEncoder("H264");
    }else{
      hbRecorder!!.setVideoEncoder("DEFAULT");
    }
    hbRecorder!!.isAudioEnabled(mic);
    reactApplicationContext.addActivityEventListener(mActivityEventListener);
  }

  private fun startRecordingScreen() {
    val mediaProjectionManager = reactApplicationContext.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager;
    val permissionIntent = mediaProjectionManager.createScreenCaptureIntent();
    currentActivity!!.startActivityForResult(permissionIntent, SCREEN_RECORD_REQUEST_CODE);
  }


  @ReactMethod
  fun startRecording(promise: Promise) {
    startPromise = promise;
    try {
      startRecordingScreen();
      println("startRecording");
    } catch (e: IllegalStateException) {
      promise.reject("404", "error!");
      println(e.toString());
    } catch (e: IOException) {
      println(e);
      e.printStackTrace();
      promise.reject("404", "error!!");
    }
  }

  @ReactMethod
  fun stopRecording(promise: Promise) {
    stopPromise = promise
    hbRecorder!!.stopScreenRecording();
  }

  @ReactMethod
  fun clean(promise: Promise) {
    println("clean");
    outputUri!!.delete();
    promise.resolve("cleaned");
  }

  override fun HBRecorderOnStart() {
    println("HBRecorderOnStart")
  }

  override fun HBRecorderOnComplete() {
    println("HBRecorderOnComplete")
    var uri = hbRecorder!!.filePath;
    val response = WritableNativeMap();
    val result =  WritableNativeMap();
    result.putString("outputURL", uri);
    response.putString("status", "success");
    response.putMap("result", result);
    stopPromise!!.resolve(response);
  }

  override fun HBRecorderOnError(errorCode: Int, reason: String?) {
    println("HBRecorderOnError")
    println("errorCode")
    println(errorCode)
    println("reason")
    println(reason)
  }

  private fun doesSupportEncoder(encoder: String): Boolean {
    val numCodecs = MediaCodecList.getCodecCount()
    for (i in 0 until numCodecs) {
      val codecInfo = MediaCodecList.getCodecInfoAt(i)
      if (codecInfo.isEncoder) {
        if (codecInfo.name != null) {
          if (codecInfo.name.contains(encoder)) {
            return true
          }
        }
      }
    }
    return false
  }
}

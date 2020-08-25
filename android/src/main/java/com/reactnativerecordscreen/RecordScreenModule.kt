package com.reactnativerecordscreen

import android.hardware.display.VirtualDisplay
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Environment
import android.view.WindowManager
import com.facebook.react.bridge.*
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.ceil

class RecordScreenModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

    private var screenDensity: Int = 0;
    private var projectManager: MediaProjectionManager? = null;
    private var mediaProjection: MediaProjection? = null;
    private var virtualDisplay: VirtualDisplay? = null;
    private var mediaProjectionCallback: MediaProjectionCallback? = null;
    private var mediaRecorder: MediaRecorder? = null;
      private var windowManager: WindowManager? = null

    private var screenWidth: Number = 0;
    private var screenHeight: Number = 0;
    private var crop: ReadableMap? = null;

    internal var videoUri: String = "";

    override fun getName(): String {
        return "RecordScreen"
    }

    inner class MediaProjectionCallback: MediaProjection.Callback() {
      override fun onStop() {
        // ボタンが押されたら
        // super.onStop()
        mediaRecorder!!.stop();
        mediaRecorder!!.reset();

        mediaProjection = null;

      }
    }


    @ReactMethod
    fun setup(readableMap: ReadableMap) {
      screenWidth = if (readableMap.hasKey("width")) ceil(readableMap.getDouble("width") as Double).toInt() else 0;
      screenHeight = if (readableMap.hasKey("height")) ceil(readableMap.getDouble("height") as Double).toInt() else 0;
      crop =  if (readableMap.hasKey("crop")) readableMap.getMap("crop") else null;

      println(screenWidth as Int);
      println(screenHeight as Int);
      println(crop?.getDouble("fps"));
    }

    @ReactMethod
    fun startRecording(promise: Promise) {
      mediaRecorder = MediaRecorder()
      try {
        mediaRecorder!!.setVideoSource(MediaRecorder.VideoSource.SURFACE);
        mediaRecorder!!.setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP);
        videoUri = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
          .toString() + StringBuilder("/")
          .append("EDMT_Record_")
          .append(SimpleDateFormat("dd-MM-yyyy-hh_mm_ss").format(Date()))
          .append(".mp4")
          .toString();

        println(videoUri);

        mediaRecorder!!.setOutputFile(videoUri);
        mediaRecorder!!.setVideoSize(screenWidth as Int, screenHeight as Int);
        mediaRecorder!!.setVideoEncoder(MediaRecorder.VideoEncoder.H264);
        mediaRecorder!!.setVideoEncodingBitRate(512 * 1000);
        mediaRecorder!!.setVideoFrameRate(crop?.getDouble("fps")?.toInt() as Int);

        try {
          mediaRecorder!!.prepare()
          mediaRecorder!!.start();
          promise.resolve(null);
        } catch (e: IOException) {
          promise.reject("error", "error");
        }


        println("startRecording");

      } catch (e: IOException) {
        e.printStackTrace();
      }
    }

    @ReactMethod
    fun stopRecording(promise: Promise) {
      println("stopRecording");
      val response = WritableNativeMap();
      val result =  WritableNativeMap();
      result.putString("outputUrl", "hogehoge");
      response.putString("status", "success");
      response.putMap("result", result);
      mediaRecorder!!.stop();
      promise.resolve(response);

    }

    @ReactMethod
    fun clean(promise: Promise) {
      println("clean");
      promise.resolve(null);
    }

}

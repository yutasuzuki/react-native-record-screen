package com.reactnativerecordscreen

import android.app.Activity
import android.app.Activity.RESULT_OK
import android.content.Context
import android.content.Intent
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Environment
import android.util.DisplayMetrics
import com.facebook.react.bridge.*
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.ceil


class RecordScreenModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {
    private val REQUEST_CODE = 1000
    private var screenDensity: Int = 0;
    private var projectManager: MediaProjectionManager? = null;
    private var mediaProjection: MediaProjection? = null;
    private var virtualDisplay: VirtualDisplay? = null;
    private var mediaRecorder: MediaRecorder? = null;

    private var screenWidth: Number = 0;
    private var screenHeight: Number = 0;
    private var crop: ReadableMap? = null;

    internal var videoUri: String = "";

    override fun getName(): String {
        return "RecordScreen"
    }

    private val mActivityEventListener: ActivityEventListener = object : BaseActivityEventListener() {
      override fun onActivityResult(activity: Activity, requestCode: Int, resultCode: Int, data: Intent) {
        if (requestCode != REQUEST_CODE) {
            return
        }

        if (resultCode != RESULT_OK) {
            return
        }

        mediaProjection = projectManager!!.getMediaProjection(resultCode, data)
        mediaProjection!!.registerCallback(MediaProjectionCallback(), null)
        virtualDisplay = createVirtualDisplay()
        mediaRecorder?.start()
      }
    }

    init {
      reactContext.addActivityEventListener(mActivityEventListener);
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
      projectManager = this.reactApplicationContext.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager

      val metrics = DisplayMetrics()
      reactApplicationContext.currentActivity?.windowManager?.defaultDisplay?.getMetrics(metrics)
      screenDensity = metrics.densityDpi
    }

    private fun createVirtualDisplay(): VirtualDisplay? {
      return mediaProjection?.createVirtualDisplay("ScreenSharingDemo",
              screenWidth as Int, screenHeight as Int, screenDensity,
              DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
              mediaRecorder?.getSurface(), null /*Callbacks*/, null /*Handler*/)
    }

    private fun shareScreen() {
      if (mediaProjection == null) {
        val i = projectManager!!.createScreenCaptureIntent()
        this.currentActivity!!.startActivityForResult(i, REQUEST_CODE)
        return
      }

      virtualDisplay = createVirtualDisplay()
      mediaRecorder!!.start()
    }

    @ReactMethod
    fun startRecording(promise: Promise) {
      initRecorder()
      shareScreen()
    }

    private fun initRecorder() {
      try {
        mediaRecorder = MediaRecorder()
        mediaRecorder!!.setAudioSource(MediaRecorder.AudioSource.MIC);
        mediaRecorder!!.setVideoSource(MediaRecorder.VideoSource.SURFACE)
        mediaRecorder!!.setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP)

        videoUri = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                .toString() + StringBuilder("/")
                .append("EDMT_Record_")
                .append(SimpleDateFormat("dd-MM-yyyy-hh_mm_ss").format(Date()))
                .append(".mp4")
                .toString();

        mediaRecorder!!.setOutputFile(videoUri)
        mediaRecorder!!.setVideoSize(screenWidth as Int, screenHeight as Int)
        mediaRecorder!!.setAudioEncoder(MediaRecorder.AudioEncoder.AAC);
        mediaRecorder!!.setVideoEncoder(MediaRecorder.VideoEncoder.H264)
        mediaRecorder!!.setVideoEncodingBitRate(512 * 1024)
        mediaRecorder!!.setVideoFrameRate(24)
        mediaRecorder!!.prepare()
      } catch (e: IOException) {
        e.printStackTrace()
      }
    }

    @ReactMethod
    fun stopRecording(promise: Promise) {
      try {
        val response = WritableNativeMap();
        val result = WritableNativeMap();
        result.putString("videoUrl", videoUri);
        response.putString("status", "success");
        response.putMap("result", result);
        mediaRecorder!!.stop();
        mediaRecorder!!.release();
        promise.resolve(response);
      } catch (err: RuntimeException) {
        err.printStackTrace();
      }
    }

    @ReactMethod
    fun clean(promise: Promise) {
      println("clean");
      promise.resolve(null);
    }

}

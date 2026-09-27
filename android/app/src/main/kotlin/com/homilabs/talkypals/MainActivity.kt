package com.homilabs.talkypals

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Bridges the native audio (voice echo, sound effects, speech) to Flutter.
 *   method channel  talkypals/audio         commands
 *   event channel   talkypals/audio_events  {type: state|level|speaking, ...}
 */
class MainActivity : FlutterActivity() {
    private val main = Handler(Looper.getMainLooper())
    private var events: EventChannel.EventSink? = null
    private lateinit var engine: TalkEngine
    private lateinit var sfx: SfxPlayer
    private var speaker: Speaker? = null
    private var simulateReceiver: BroadcastReceiver? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        volumeControlStream = AudioManager.STREAM_MUSIC
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        sfx = SfxPlayer(this)
        val debuggable = applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0
        engine = TalkEngine(verbose = debuggable, listener = object : TalkEngine.Listener {
            override fun onState(state: String) = emit(mapOf("type" to "state", "state" to state))
            override fun onLevel(phase: String, level: Double) =
                emit(mapOf("type" to "level", "phase" to phase, "value" to level))
        })

        val messenger = flutterEngine.dartExecutor.binaryMessenger
        EventChannel(messenger, "talkypals/audio_events").setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, sink: EventChannel.EventSink?) { events = sink }
            override fun onCancel(args: Any?) { events = null }
        })
        MethodChannel(messenger, "talkypals/audio").setMethodCallHandler { call, result ->
            when (call.method) {
                "startListening" -> { engine.start(); result.success(null) }
                "stopListening" -> { engine.stop(); result.success(null) }
                "setVoice" -> {
                    engine.voice = TalkEngine.Voice(
                        pitch = call.argument<Double>("pitch") ?: 1.6,
                        vibratoHz = call.argument<Double>("vibratoHz") ?: 0.0,
                        vibratoDepth = call.argument<Double>("vibratoDepth") ?: 0.0,
                        tremoloHz = call.argument<Double>("tremoloHz") ?: 0.0,
                        tremoloDepth = call.argument<Double>("tremoloDepth") ?: 0.0,
                    )
                    result.success(null)
                }
                "setSensitivity" -> { engine.sensitivity = call.argument<Double>("value") ?: 0.6; result.success(null) }
                "preloadSfx" -> {
                    val names = call.argument<List<String>>("names") ?: emptyList()
                    Thread { sfx.preload(names); main.post { result.success(null) } }.start()
                }
                "playSfx" -> {
                    val ms = sfx.play(call.argument<String>("name") ?: "",
                        call.argument<Double>("rate") ?: 1.0, call.argument<Double>("volume") ?: 1.0)
                    engine.muteFor(ms + 150)
                    result.success(ms)
                }
                "speak" -> {
                    val ok = speaker().speak(call.argument<String>("text") ?: "",
                        call.argument<Double>("pitch") ?: 1.0, call.argument<Double>("rate") ?: 1.0)
                    if (ok) engine.muteFor(1000) // until synthesis starts and onStart arrives
                    result.success(ok)
                }
                "warmUpSpeech" -> { speaker(); result.success(null) }
                "stopAllSounds" -> { sfx.stopAll(); speaker?.stop(); result.success(null) }
                "mediaVolume" -> {
                    val am = getSystemService(AUDIO_SERVICE) as AudioManager
                    val max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC).coerceAtLeast(1)
                    result.success(am.getStreamVolume(AudioManager.STREAM_MUSIC).toDouble() / max)
                }
                "showVolumeControl" -> {
                    val am = getSystemService(AUDIO_SERVICE) as AudioManager
                    am.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_SAME, AudioManager.FLAG_SHOW_UI)
                    result.success(null)
                }
                "simulateUtterance" -> {
                    val path = call.argument<String>("path")
                    if (debuggable && path != null && File(path).exists()) { engine.inject(File(path)); result.success(true) }
                    else result.success(false)
                }
                else -> result.notImplemented()
            }
        }

        // Debug builds only, for on-device tests without a child's voice:
        //   adb shell am broadcast -a com.homilabs.talkypals.SIMULATE --es path <wav>
        // feeds a 44.1 kHz WAV straight into the listening pipeline; add `--es mode acoustic`
        // to play it through the phone's speaker instead, so the real microphone hears it.
        if (debuggable) {
            simulateReceiver = object : BroadcastReceiver() {
                override fun onReceive(c: Context?, i: Intent?) {
                    val p = i?.getStringExtra("path") ?: return
                    if (!File(p).exists()) return
                    if (i.getStringExtra("mode") == "acoustic") {
                        android.media.MediaPlayer().apply {
                            setDataSource(p)
                            setOnCompletionListener { it.release() }
                            prepare()
                            start()
                        }
                    } else {
                        engine.inject(File(p))
                    }
                }
            }
            val filter = IntentFilter("com.homilabs.talkypals.SIMULATE")
            if (Build.VERSION.SDK_INT >= 33) registerReceiver(simulateReceiver, filter, Context.RECEIVER_EXPORTED)
            else registerReceiver(simulateReceiver, filter)
        }
    }

    /** The parrot's voice; mutes the listener while it talks so it doesn't echo itself. */
    private fun speaker(): Speaker = speaker ?: Speaker(this) { speaking ->
        engine.speaking = speaking
        emit(mapOf("type" to "speaking", "value" to speaking))
    }.also { speaker = it }

    private fun emit(event: Map<String, Any>) {
        main.post { events?.success(event) }
    }

    override fun onDestroy() {
        simulateReceiver?.let { unregisterReceiver(it) }
        engine.shutdown()
        speaker?.shutdown()
        sfx.release()
        super.onDestroy()
    }
}

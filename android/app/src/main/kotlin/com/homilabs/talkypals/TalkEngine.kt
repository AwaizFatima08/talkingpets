package com.homilabs.talkypals

import android.annotation.SuppressLint
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.os.SystemClock
import android.util.Log
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.Executors
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.log10
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * Listens on the microphone, waits for the child to say something, records
 * it and plays it straight back in a funny voice.
 *
 *   listening --(voice)--> hearing --(silence)--> talking --(done)--> listening
 *
 * Audio lives only in memory for one round and is never written anywhere.
 * Everything runs on one worker thread; [listener] is called on that thread.
 */
class TalkEngine(private val verbose: Boolean = false, private val listener: Listener) {

    interface Listener {
        fun onState(state: String)
        /** Loudness 0..1 of what is being heard or played ([phase] "hearing"/"talking"). */
        fun onLevel(phase: String, level: Double)
    }

    /** How the pet's voice sounds. Pitch 1.6 = 1.6x higher (and faster). */
    data class Voice(
        val pitch: Double = 1.6,
        val vibratoHz: Double = 0.0,
        val vibratoDepth: Double = 0.0,
        val tremoloHz: Double = 0.0,
        val tremoloDepth: Double = 0.0,
    )

    @Volatile var voice = Voice()
    /** 0 = needs a loud voice, 1 = reacts to whispers. */
    @Volatile var sensitivity = 0.6
    @Volatile private var ignoreUntil = 0L
    @Volatile private var running = false
    @Volatile private var injected: ShortArray? = null
    private var thread: Thread? = null

    val isRunning get() = running

    /** Don't react to sounds for [ms] (the app's own sound effects). */
    fun muteFor(ms: Long) {
        ignoreUntil = max(ignoreUntil, SystemClock.elapsedRealtime() + ms)
    }

    /** Deaf while the app's own text-to-speech talks, plus a short tail after. */
    @Volatile var speaking = false
        set(value) {
            field = value
            if (!value) muteFor(300)
        }

    /** Test hook: treat a 16-bit mono WAV as if it came from the microphone. */
    fun inject(file: File) {
        val bytes = file.readBytes()
        val bb = ByteBuffer.wrap(bytes, 44, bytes.size - 44).order(ByteOrder.LITTLE_ENDIAN)
        val out = ShortArray((bytes.size - 44) / 2)
        bb.asShortBuffer().get(out)
        injected = out
    }

    // Start/stop requests run in order on one thread, so a quick stop -> start
    // (an ad closing while the app resumes) can never leave the mic off.
    private val control = Executors.newSingleThreadExecutor()

    fun start() = control.execute {
        if (running) return@execute
        running = true
        thread = Thread({ loop() }, "TalkEngine").apply { start() }
    }

    fun stop() = control.execute { halt() }

    /** Stops and waits for the worker (call off the main thread). */
    private fun halt() {
        running = false
        thread?.join(1500)
        thread = null
    }

    fun shutdown() {
        control.execute { halt() }
        control.shutdown()
    }

    // ---- worker ----

    @SuppressLint("MissingPermission") // checked by the Flutter side before start()
    private fun loop() {
        val minBuf = AudioRecord.getMinBufferSize(SR, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
        val rec = try {
            AudioRecord(MediaRecorder.AudioSource.VOICE_RECOGNITION, SR, AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT, max(minBuf, FRAME * 8))
        } catch (e: Exception) {
            Log.e(TAG, "AudioRecord failed", e); null
        }
        if (rec == null || rec.state != AudioRecord.STATE_INITIALIZED) {
            rec?.release()
            running = false
            listener.onState("error")
            return
        }
        rec.startRecording()
        listener.onState("listening")

        val frame = ShortArray(FRAME)
        val preRoll = ArrayDeque<ShortArray>()
        val take = ArrayList<ShortArray>()
        val takeDb = ArrayList<Double>()
        val floor = NoiseFloor()
        var recording = false
        var above = 0
        var silent = 0
        var voiced = 0
        var levelTick = 0
        var frames = 0
        var statMax = -120.0

        while (running) {
            val n = rec.read(frame, 0, FRAME)
            if (n <= 0) continue
            injected?.let { inj -> injectInto(frame, inj) }
            val db = dbfs(frame)
            val now = SystemClock.elapsedRealtime()
            frames++
            val muted = now < ignoreUntil || speaking
            if (!muted) floor.add(db)
            val threshold = startThreshold(floor.value)
            statMax = max(statMax, db)
            if (frames % 250 == 0) { // every 5 s
                if (verbose) Log.d(TAG, "room: floor %.1f dB, loudest %.1f dB, threshold %.1f".format(floor.value, statMax, threshold))
                statMax = -120.0
            }

            if (!recording) {
                if (muted || frames < CALIBRATION_FRAMES) { preRoll.clear(); above = 0; continue }
                preRoll.addLast(frame.copyOf())
                if (preRoll.size > PRE_ROLL_FRAMES) preRoll.removeFirst()
                above = if (db > threshold) above + 1 else 0
                if (above >= 2) {
                    if (verbose) Log.d(TAG, "voice start: %.1f dB (floor %.1f, threshold %.1f)".format(db, floor.value, threshold))
                    recording = true
                    take.clear(); take.addAll(preRoll); preRoll.clear()
                    takeDb.clear()
                    silent = 0; voiced = 2
                    listener.onState("hearing")
                }
            } else {
                take.add(frame.copyOf())
                takeDb.add(db)
                if (db > threshold - 4) { voiced++; silent = 0 } else silent++
                if (++levelTick % 2 == 0) listener.onLevel("hearing", level(db))
                val tooLong = take.size >= MAX_FRAMES
                if (silent >= END_SILENCE_FRAMES || tooLong) {
                    recording = false
                    above = 0
                    val spread = stdDev(takeDb)
                    val steady = takeDb.size > 100 && spread < 3.5 // a fan, hum or engine, not a voice
                    if (verbose) Log.d(TAG, "voice end: ${take.size * 20} ms, voiced ${voiced * 20} ms, spread %.1f dB, floor %.1f%s"
                        .format(spread, floor.value, if (steady) " -> ignored (steady noise)" else ""))
                    if (voiced >= MIN_VOICED_FRAMES && !steady) {
                        rec.stop()
                        val trimmed = take.dropLast(max(0, silent - TAIL_KEEP_FRAMES))
                        play(render(trimmed))
                        muteFor(250)
                        if (running) rec.startRecording()
                    }
                    take.clear()
                    if (running) listener.onState("listening")
                }
            }
        }
        rec.stop()
        rec.release()
        listener.onState("idle")
    }

    /** Room loudness: a low percentile of the last few seconds, so pauses between words count. */
    private class NoiseFloor {
        private val window = DoubleArray(150) { -60.0 } // 3 s
        private var i = 0
        private var filled = 0
        var value = -60.0
            private set

        fun add(db: Double) {
            window[i] = max(db, -90.0) // digital silence (muted mic) must not drag the floor down
            i = (i + 1) % window.size
            filled = min(filled + 1, window.size)
            val sorted = window.copyOf(filled).also { it.sort() }
            value = sorted[(filled * 0.15).toInt()]
        }
    }

    private fun stdDev(xs: List<Double>): Double {
        if (xs.isEmpty()) return 0.0
        val m = xs.average()
        return sqrt(xs.sumOf { (it - m) * (it - m) } / xs.size)
    }

    private fun startThreshold(floorDb: Double): Double {
        val margin = 16.0 - 10.0 * sensitivity // 6..16 dB above the room
        val absMin = -52.0 + (1 - sensitivity) * 14 // never trigger on near-silence
        return max(floorDb + margin, absMin)
    }

    /** Mixes the injected clip into the live microphone frame. */
    private fun injectInto(frame: ShortArray, inj: ShortArray) {
        val pos = injectPos
        for (i in frame.indices) {
            if (pos + i < inj.size) frame[i] = (frame[i] + inj[pos + i]).coerceIn(-32768, 32767).toShort()
        }
        injectPos += frame.size
        if (injectPos >= inj.size) { injected = null; injectPos = 0 }
    }
    private var injectPos = 0

    /** Resample (pitch + vibrato), add tremolo, normalise, fade the ends. */
    private fun render(frames: List<ShortArray>): FloatArray {
        val input = FloatArray(frames.size * FRAME)
        var k = 0
        for (f in frames) for (s in f) input[k++] = s / 32768f
        // Remove DC offset.
        val mean = input.average().toFloat()
        for (i in input.indices) input[i] -= mean

        val v = voice
        val out = FloatArray((input.size / v.pitch * 1.2).toInt() + 16)
        var pos = 0.0
        var o = 0
        while (o < out.size) {
            val i = pos.toInt()
            if (i + 1 >= input.size) break
            val frac = (pos - i).toFloat()
            val t = o.toDouble() / SR
            var s = input[i] * (1 - frac) + input[i + 1] * frac
            if (v.tremoloDepth > 0) s *= (1 - v.tremoloDepth * (0.5 + 0.5 * sin(2 * PI * v.tremoloHz * t))).toFloat()
            out[o++] = s
            pos += v.pitch * (1 + v.vibratoDepth * sin(2 * PI * v.vibratoHz * t))
        }
        val y = out.copyOf(o)
        var peak = 1e-4f
        for (s in y) peak = max(peak, abs(s))
        val gain = min(0.92f / peak, 8f) // quiet little voices get boosted
        val fade = min(y.size / 4, SR / 50)
        for (i in y.indices) {
            var g = gain
            if (i < fade) g *= i.toFloat() / fade
            if (i >= y.size - fade) g *= (y.size - 1 - i).toFloat() / fade
            y[i] *= g
        }
        return y
    }

    private fun play(samples: FloatArray) {
        if (samples.size < FRAME) return
        val pcm = ShortArray(samples.size) { (samples[it].coerceIn(-1f, 1f) * 32767).toInt().toShort() }
        // Loudness envelope for the mouth, one value per 1/30 s.
        val step = SR / 30
        val levels = DoubleArray(pcm.size / step + 1) { c ->
            var sum = 0.0
            val end = min(pcm.size, (c + 1) * step)
            for (i in c * step until end) sum += pcm[i].toDouble() * pcm[i]
            val rms = sqrt(sum / max(1, end - c * step)) / 32768.0
            level(20 * log10(rms + 1e-9))
        }
        val track = AudioTrack.Builder()
            .setAudioAttributes(AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_GAME)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build())
            .setAudioFormat(AudioFormat.Builder()
                .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                .setSampleRate(SR)
                .setChannelMask(AudioFormat.CHANNEL_OUT_MONO).build())
            .setTransferMode(AudioTrack.MODE_STATIC)
            .setBufferSizeInBytes(pcm.size * 2)
            .build()
        try {
            track.write(pcm, 0, pcm.size)
            listener.onState("talking")
            track.play()
            val deadline = SystemClock.elapsedRealtime() + pcm.size * 1000L / SR + 1000
            while (running) {
                val head = track.playbackHeadPosition
                if (head >= pcm.size || SystemClock.elapsedRealtime() > deadline) break
                listener.onLevel("talking", levels[min(levels.size - 1, head / step)])
                Thread.sleep(33)
            }
            listener.onLevel("talking", 0.0)
        } catch (e: Exception) {
            Log.e(TAG, "playback failed", e)
        } finally {
            track.stop()
            track.release()
        }
    }

    private fun dbfs(frame: ShortArray): Double {
        var sum = 0.0
        for (s in frame) sum += s.toDouble() * s
        return 20 * log10(sqrt(sum / frame.size) / 32768.0 + 1e-9)
    }

    /** Map dBFS to 0..1 for animation (-50 dB -> 0, -10 dB -> 1). */
    private fun level(db: Double) = ((db + 50) / 40).coerceIn(0.0, 1.0)

    companion object {
        private const val TAG = "TalkEngine"
        const val SR = 44100
        const val FRAME = SR / 50 // 20 ms
        const val PRE_ROLL_FRAMES = 15 // 300 ms before the trigger
        const val END_SILENCE_FRAMES = 35 // 700 ms of quiet ends a phrase
        const val TAIL_KEEP_FRAMES = 8
        const val MIN_VOICED_FRAMES = 12 // ignore claps and bumps (< 240 ms)
        const val MAX_FRAMES = 50 * 6 // 6 s
        const val CALIBRATION_FRAMES = 25 // 0.5 s to learn the room
    }
}

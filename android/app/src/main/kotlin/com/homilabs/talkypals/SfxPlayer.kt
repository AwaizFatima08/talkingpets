package com.homilabs.talkypals

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaMetadataRetriever
import android.media.SoundPool
import android.util.Log
import io.flutter.FlutterInjector
import java.io.File

/** Short animal sounds, preloaded into a SoundPool from the Flutter assets. */
class SfxPlayer(private val context: Context) {
    private val pool = SoundPool.Builder()
        .setMaxStreams(4)
        .setAudioAttributes(AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_GAME)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build())
        .build()
    private val ids = HashMap<String, Int>()
    private val durations = HashMap<String, Long>()

    /**
     * Loads every sound: a plain name means `assets/sfx/<name>.wav` (made by
     * scripts/make_sfx.py); a name ending in .ogg is a full asset path (homidev
     * sounds in assets/audio/sfx/). Call off the main thread.
     */
    fun preload(names: List<String>) {
        val loader = FlutterInjector.instance().flutterLoader()
        val dir = File(context.cacheDir, "sfx").apply { mkdirs() }
        for (name in names) {
            if (ids.containsKey(name)) continue
            try {
                val ogg = name.endsWith(".ogg")
                val asset = if (ogg) name else "assets/sfx/$name.wav"
                val file = File(dir, asset.substringAfterLast('/'))
                context.assets.open(loader.getLookupKeyForAsset(asset)).use { input -> file.outputStream().use { input.copyTo(it) } }
                durations[name] = if (ogg) {
                    MediaMetadataRetriever().run {
                        try {
                            setDataSource(file.path)
                            extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 1000L
                        } finally {
                            release()
                        }
                    }
                } else {
                    // 16-bit mono WAV with a 44-byte header.
                    (file.length() - 44) * 1000 / (2 * 22050)
                }
                ids[name] = pool.load(file.path, 1)
            } catch (e: Exception) {
                Log.e("SfxPlayer", "could not load $name", e)
            }
        }
    }

    /** Plays [name] at [rate] (0.5..2) and returns its length in ms, or 0. */
    fun play(name: String, rate: Double, volume: Double): Long {
        val id = ids[name] ?: return 0
        val r = rate.coerceIn(0.5, 2.0).toFloat()
        val v = volume.coerceIn(0.0, 1.0).toFloat()
        pool.play(id, v, v, 1, 0, r)
        return ((durations[name] ?: 0) / r).toLong()
    }

    fun stopAll() = pool.autoPause()

    fun release() = pool.release()
}

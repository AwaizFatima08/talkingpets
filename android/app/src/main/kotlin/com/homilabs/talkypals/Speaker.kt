package com.homilabs.talkypals

import android.content.Context
import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import java.util.Locale

/** Device text-to-speech, used for the parrot's words ("Hello!"). */
class Speaker(context: Context, private val onSpeaking: (Boolean) -> Unit) {
    @Volatile private var ready = false
    private val tts: TextToSpeech = TextToSpeech(context.applicationContext) { status ->
        if (status == TextToSpeech.SUCCESS) {
            val lang = tts.setLanguage(Locale.US)
            ready = lang != TextToSpeech.LANG_MISSING_DATA && lang != TextToSpeech.LANG_NOT_SUPPORTED
            tts.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(id: String?) = onSpeaking(true)
                override fun onDone(id: String?) = onSpeaking(false)
                // Interrupted (stop() or a newer utterance): onDone is not called.
                override fun onStop(id: String?, interrupted: Boolean) = onSpeaking(false)
                @Deprecated("Deprecated in Java")
                override fun onError(id: String?) = onSpeaking(false)
                override fun onError(id: String?, code: Int) = onSpeaking(false)
            })
        }
    }

    /** Returns false when no TTS voice is available (callers fall back to a sound). */
    fun speak(text: String, pitch: Double, rate: Double): Boolean {
        if (!ready) return false
        tts.setPitch(pitch.toFloat())
        tts.setSpeechRate(rate.toFloat())
        tts.speak(text, TextToSpeech.QUEUE_FLUSH, Bundle(), "u${System.nanoTime()}")
        return true
    }

    fun stop() {
        tts.stop()
        onSpeaking(false)
    }

    fun shutdown() = tts.shutdown()
}

package com.example.vibration_control

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.roundToInt

class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL_NAME = "com.example.vibration_control/haptics"
        const val MIN_DURATION_MS = 1
        const val MAX_DURATION_MS = 5000
        const val MAX_REPEAT_COUNT = 100
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCapabilities" -> result.success(capabilities())
                "play" -> {
                    try {
                        result.success(play(call.arguments as? Map<*, *>))
                    } catch (error: Exception) {
                        result.error(
                            "PLAYBACK_ERROR",
                            error.message ?: "Playback failed.",
                            null,
                        )
                    }
                }
                "stop" -> {
                    vibrator()?.cancel()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onPause() {
        vibrator()?.cancel()
        super.onPause()
    }

    override fun onDestroy() {
        vibrator()?.cancel()
        super.onDestroy()
    }

    private fun vibrator(): Vibrator? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager =
                getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            manager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    private fun capabilities(): Map<String, Any?> {
        val vibrator = vibrator()
        val hasActuator = vibrator?.hasVibrator() == true
        val supportsAmplitude =
            hasActuator &&
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                vibrator?.hasAmplitudeControl() == true

        val warnings = when {
            !hasActuator -> listOf("No vibration actuator was reported by this device.")
            !supportsAmplitude -> listOf(
                "This device does not report amplitude control; playback uses an on/off waveform.",
            )
            else -> emptyList()
        }

        return mapOf(
            "platform" to "Android",
            "osVersion" to "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})",
            "hasActuator" to hasActuator,
            "supportsAmplitude" to supportsAmplitude,
            "supportsIntensity" to false,
            "supportsCustomPatterns" to hasActuator,
            "supportsStop" to hasActuator,
            "supportsCoreHaptics" to false,
            "supportsLegacyVibration" to hasActuator,
            "warnings" to warnings,
        )
    }

    private fun play(arguments: Map<*, *>?): Map<String, Any?> {
        val requestId = arguments?.get("requestId") as? String ?: ""
        val vibrator = vibrator()

        if (vibrator == null || !vibrator.hasVibrator()) {
            return playbackFailure(
                requestId = requestId,
                errorCode = "NO_VIBRATOR",
                warning = "No vibration actuator is available.",
            )
        }

        val segments =
            (arguments?.get("segments") as? List<*>)
                ?.mapNotNull { it as? Map<*, *> }
                ?.mapNotNull { segmentFrom(it) }
                .orEmpty()

        if (segments.isEmpty()) {
            return playbackFailure(
                requestId = requestId,
                errorCode = "INVALID_ARGUMENT",
                warning = "The vibration request contains no playable segments.",
            )
        }

        val repeatCount =
            ((arguments?.get("repeatCount") as? Number)?.toInt() ?: 1)
                .coerceIn(1, MAX_REPEAT_COUNT)
        val supportsAmplitude =
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                vibrator.hasAmplitudeControl()
        val timings = mutableListOf<Long>()
        val amplitudes = mutableListOf<Int>()

        repeat(repeatCount) { repeatIndex ->
            for ((segmentIndex, segment) in segments.withIndex()) {
                timings.add(segment.vibrationMs.toLong())
                amplitudes.add(amplitudeFor(segment.strengthPercent))

                if (segment.pauseAfterMs > 0) {
                    timings.add(segment.pauseAfterMs.toLong())
                    amplitudes.add(0)
                } else if (
                    !supportsAmplitude &&
                    (segmentIndex < segments.lastIndex || repeatIndex < repeatCount - 1)
                ) {
                    timings.add(1L)
                    amplitudes.add(0)
                }
            }
        }

        vibrator.cancel()
        val effect =
            if (supportsAmplitude) {
                VibrationEffect.createWaveform(
                    timings.toLongArray(),
                    amplitudes.toIntArray(),
                    -1,
                )
            } else {
                VibrationEffect.createWaveform(
                    (listOf(0L) + timings).toLongArray(),
                    -1,
                )
            }

        val warnings = mutableListOf<String>()
        if (!supportsAmplitude) {
            warnings.add("Amplitude control is unavailable; using on/off timing.")
        }

        vibrator.vibrate(effect)

        return mapOf(
            "started" to true,
            "effectiveMode" to if (supportsAmplitude) "amplitude" else "onOff",
            "warnings" to warnings,
            "requestId" to requestId,
            "errorCode" to null,
        )
    }

    private fun segmentFrom(raw: Map<*, *>): Segment? {
        val vibrationMs =
            ((raw["vibrationMs"] as? Number)?.toInt() ?: 0)
                .coerceIn(MIN_DURATION_MS, MAX_DURATION_MS)
        val pauseAfterMs =
            ((raw["pauseAfterMs"] as? Number)?.toInt() ?: 0).coerceAtLeast(0)
        val strengthPercent =
            ((raw["strengthPercent"] as? Number)?.toInt() ?: 1).coerceIn(1, 100)

        return Segment(vibrationMs, pauseAfterMs, strengthPercent)
    }

    private fun amplitudeFor(strengthPercent: Int): Int {
        return (strengthPercent.coerceIn(1, 100) * 255.0 / 100.0)
            .roundToInt()
            .coerceIn(1, 255)
    }

    private fun playbackFailure(
        requestId: String,
        errorCode: String,
        warning: String,
    ): Map<String, Any?> {
        return mapOf(
            "started" to false,
            "effectiveMode" to "unsupported",
            "warnings" to listOf(warning),
            "requestId" to requestId,
            "errorCode" to errorCode,
        )
    }

    private data class Segment(
        val vibrationMs: Int,
        val pauseAfterMs: Int,
        val strengthPercent: Int,
    )
}

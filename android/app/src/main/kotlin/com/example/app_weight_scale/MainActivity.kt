package com.example.app_weight_scale

import android.content.Context
import android.content.SharedPreferences
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import kotlin.math.sqrt

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.example.weightscale/sensor"
        private const val PREFS_NAME = "weight_scale_prefs"
        private const val KEY_CALIBRATION_FACTOR = "calibration_factor"
        private const val DEFAULT_CALIBRATION = 1000.0
        private const val SAMPLE_TIMEOUT_MS = 8000L // 8 seconds max wait
    }

    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null
    private lateinit var prefs: SharedPreferences

    // Stored baseline (Z-axis mean with nothing on phone)
    private var baselineX: Double = 0.0
    private var baselineY: Double = 0.0
    private var baselineZ: Double = 0.0
    private var isBaselineSet: Boolean = false
    private var calibrationFactor: Double = DEFAULT_CALIBRATION
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        // Load saved calibration factor
        calibrationFactor = prefs.getFloat(KEY_CALIBRATION_FACTOR, DEFAULT_CALIBRATION.toFloat()).toDouble()

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                // Check sensor availability
                "checkSensors" -> {
                    result.success(
                        mapOf(
                            "accelerometer" to (accelerometer != null),
                            "type" to (accelerometer?.name ?: "none"),
                            "maxRange" to (accelerometer?.maximumRange ?: 0f)
                        )
                    )
                }

                // Collect N samples and return statistical summary
                "collectSamples" -> {
                    val count = call.argument<Int>("count") ?: 200
                    scope.launch {
                        try {
                            val stats = collectAccelerometerSamples(count)
                            withContext(Dispatchers.Main) {
                                result.success(stats)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("SENSOR_ERROR", e.message, null)
                            }
                        }
                    }
                }

                // Set baseline: collect samples and store mean Z
                "setBaseline" -> {
                    scope.launch {
                        try {
                            val stats = collectAccelerometerSamples(300)
                            if (stats.containsKey("error")) {
                                withContext(Dispatchers.Main) {
                                    result.error("SENSOR_ERROR", stats["error"] as? String ?: "Unknown error", null)
                                }
                                return@launch
                            }
                            baselineX = (stats["xMean"] as? Double) ?: 0.0
                            baselineY = (stats["yMean"] as? Double) ?: 0.0
                            baselineZ = (stats["zMean"] as? Double) ?: 0.0
                            isBaselineSet = true
                            withContext(Dispatchers.Main) {
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("BASELINE_ERROR", e.message ?: "Failed to set baseline", null)
                            }
                        }
                    }
                }

                // Save calibration: store factor in SharedPreferences
                "saveCalibration" -> {
                    val knownGrams = call.argument<Double>("knownGrams") ?: 100.0
                    val rawDelta = call.argument<Double>("rawDelta") ?: 1.0
                    if (rawDelta > 0.0001) {
                        calibrationFactor = knownGrams / rawDelta
                        prefs.edit()
                            .putFloat(KEY_CALIBRATION_FACTOR, calibrationFactor.toFloat())
                            .apply()
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }

                // Return saved calibration factor
                "getCalibrationFactor" -> {
                    result.success(calibrationFactor)
                }

                else -> result.notImplemented()
            }
        }
    }

    /**
     * Collects [count] accelerometer samples at SENSOR_DELAY_FASTEST.
     * Returns a map with:
     *   - xMean, yMean, zMean       → mean of each axis
     *   - xDelta, yDelta, zDelta    → delta from baseline
     *   - stdDev                    → standard deviation of Z (stability metric)
     *   - sampleCount               → actual samples collected
     */
    private suspend fun collectAccelerometerSamples(count: Int): Map<String, Any> =
        suspendCancellableCoroutine { cont ->
            val sensor = accelerometer
            if (sensor == null) {
                cont.resume(mapOf("error" to "No accelerometer")) {}
                return@suspendCancellableCoroutine
            }

            val samplesX = mutableListOf<Float>()
            val samplesY = mutableListOf<Float>()
            val samplesZ = mutableListOf<Float>()

            var timeoutJob: Job? = null

            val listener = object : SensorEventListener {
                override fun onSensorChanged(event: SensorEvent) {
                    if (event.sensor.type != Sensor.TYPE_ACCELEROMETER) return

                    samplesX.add(event.values[0])
                    samplesY.add(event.values[1])
                    samplesZ.add(event.values[2])

                    if (samplesZ.size >= count) {
                        sensorManager.unregisterListener(this)
                        timeoutJob?.cancel()
                        cont.resume(computeStats(samplesX, samplesY, samplesZ)) {}
                    }
                }

                override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
            }

            sensorManager.registerListener(
                listener,
                sensor,
                SensorManager.SENSOR_DELAY_FASTEST
            )

            // Timeout safety: unregister after SAMPLE_TIMEOUT_MS
            timeoutJob = scope.launch {
                delay(SAMPLE_TIMEOUT_MS)
                if (cont.isActive && samplesZ.isNotEmpty()) {
                    sensorManager.unregisterListener(listener)
                    cont.resume(computeStats(samplesX, samplesY, samplesZ)) {}
                } else if (cont.isActive) {
                    sensorManager.unregisterListener(listener)
                    cont.resume(mapOf("error" to "Timeout: no samples")) {}
                }
            }

            cont.invokeOnCancellation {
                timeoutJob?.cancel()
                sensorManager.unregisterListener(listener)
            }
        }

    private fun computeStats(
        samplesX: List<Float>,
        samplesY: List<Float>,
        samplesZ: List<Float>
    ): Map<String, Any> {
        if (samplesZ.isEmpty()) {
            return mapOf("error" to "No samples")
        }

        val n = samplesZ.size.toDouble()
        val meanX = samplesX.sumOf { it.toDouble() } / n
        val meanY = samplesY.sumOf { it.toDouble() } / n
        val meanZ = samplesZ.sumOf { it.toDouble() } / n

        // Standard deviation of Z (measures how stable the reading is)
        val variance = samplesZ.sumOf { (it.toDouble() - meanZ) * (it.toDouble() - meanZ) } / n
        val stdDev = sqrt(variance)

        // Delta from baseline
        val xDelta = if (isBaselineSet) meanX - baselineX else 0.0
        val yDelta = if (isBaselineSet) meanY - baselineY else 0.0
        val zDelta = if (isBaselineSet) meanZ - baselineZ else 0.0

        return mapOf(
            "xMean" to meanX,
            "yMean" to meanY,
            "zMean" to meanZ,
            "xDelta" to xDelta,
            "yDelta" to yDelta,
            "zDelta" to zDelta,
            "stdDev" to stdDev,
            "sampleCount" to samplesZ.size,
            "baselineX" to baselineX,
            "baselineY" to baselineY,
            "baselineZ" to baselineZ
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        scope.cancel()
    }
}

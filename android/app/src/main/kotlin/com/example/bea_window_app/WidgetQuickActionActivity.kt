package com.example.bea_window_app

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.drawable.GradientDrawable
import android.media.MediaRecorder
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.provider.MediaStore
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import androidx.core.content.FileProvider
import java.io.File
import java.io.FileOutputStream

class WidgetQuickActionActivity : Activity() {
    companion object {
        const val EXTRA_ACTION = "widget_quick_action"
        const val ACTION_CAMERA = "camera"
        const val ACTION_DRAW = "draw"
        const val ACTION_PULSE = "pulse"
        const val ACTION_VOICE = "voice"

        private const val CAMERA_REQUEST = 4101
        private const val CAMERA_PERMISSION_REQUEST = 4102
        private const val AUDIO_PERMISSION_REQUEST = 4103
    }

    private val handler = Handler(Looper.getMainLooper())
    private var cameraFile: File? = null
    private var voiceFile: File? = null
    private var recorder: MediaRecorder? = null
    private var recording = false
    private var voiceStatus: TextView? = null
    private var voiceButton: Button? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        when (intent.getStringExtra(EXTRA_ACTION)) {
            ACTION_CAMERA -> startCameraFlow()
            ACTION_DRAW -> showDrawingFlow()
            ACTION_PULSE -> sendPulse()
            ACTION_VOICE -> showVoiceFlow()
            else -> finishAndRemoveTask()
        }
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        releaseRecorder()
        super.onDestroy()
    }

    private fun startCameraFlow() {
        if (checkSelfPermission(Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(arrayOf(Manifest.permission.CAMERA), CAMERA_PERMISSION_REQUEST)
            return
        }
        launchCamera()
    }

    private fun launchCamera() {
        val directory = File(filesDir, "widget_share").apply { mkdirs() }
        val file = File(directory, "snap_${System.currentTimeMillis()}.jpg")
        cameraFile = file
        val uri: Uri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            file
        )
        val captureIntent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
            putExtra(MediaStore.EXTRA_OUTPUT, uri)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        if (captureIntent.resolveActivity(packageManager) == null) {
            finishWithMessage(false, "No camera app found")
            return
        }
        startActivityForResult(captureIntent, CAMERA_REQUEST)
    }

    @Deprecated("Deprecated in Android; retained for broad camera-app compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != CAMERA_REQUEST) return
        val file = cameraFile
        if (resultCode != RESULT_OK || file == null || file.length() == 0L) {
            file?.delete()
            finishAndRemoveTask()
            return
        }
        showLoading("Sending snap…", "Uploading securely to your Bae")
        WidgetNativeShareService.shareMedia(file, "Image", "image") { success, message ->
            file.delete()
            finishWithMessage(success, message)
        }
    }

    private fun showDrawingFlow() {
        val root = createPanel()
        root.addView(title("Draw for your Bae"))
        root.addView(subtitle("Draw below, then tap Send"))

        val drawingView = WidgetDrawingView(this)
        root.addView(
            drawingView,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1f
            ).apply { topMargin = dp(14) }
        )

        val actions = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(0, dp(14), 0, 0)
        }
        actions.addView(actionButton("Clear", false) { drawingView.clear() })
        actions.addView(
            actionButton("Send drawing", true) {
                if (!drawingView.hasDrawing) {
                    Toast.makeText(this, "Draw something first", Toast.LENGTH_SHORT).show()
                    return@actionButton
                }
                val file = File(
                    File(filesDir, "widget_share").apply { mkdirs() },
                    "draw_${System.currentTimeMillis()}.png"
                )
                FileOutputStream(file).use { output ->
                    drawingView.toBitmap().compress(Bitmap.CompressFormat.PNG, 100, output)
                }
                showLoading("Sending drawing…", "Uploading securely to your Bae")
                WidgetNativeShareService.shareMedia(file, "Draw", "image") { success, message ->
                    file.delete()
                    finishWithMessage(success, message)
                }
            },
            LinearLayout.LayoutParams(0, dp(48), 1.35f).apply { marginStart = dp(10) }
        )
        root.addView(actions)
        setContentView(root)
        configureWindow(tall = true)
    }

    private fun sendPulse() {
        vibrateTap()
        showLoading("Sending pulse…", "A little heartbeat for your Bae")
        WidgetNativeShareService.sendPulse { success, message ->
            finishWithMessage(success, message)
        }
    }

    private fun showVoiceFlow() {
        val root = createPanel().apply {
            gravity = Gravity.CENTER_HORIZONTAL
        }
        root.addView(title("Voice for your Bae"))
        voiceStatus = subtitle("Tap record for a voice clip up to 5 seconds").also {
            root.addView(it)
        }
        voiceButton = actionButton("Start recording", true) {
            if (recording) stopAndSendVoice() else requestOrStartVoice()
        }.also {
            root.addView(
                it,
                LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    dp(56)
                ).apply { topMargin = dp(24) }
            )
        }
        setContentView(root)
        configureWindow(tall = false)
    }

    private fun requestOrStartVoice() {
        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), AUDIO_PERMISSION_REQUEST)
            return
        }
        startVoiceRecording()
    }

    private fun startVoiceRecording() {
        val directory = File(filesDir, "widget_share").apply { mkdirs() }
        val file = File(directory, "voice_${System.currentTimeMillis()}.m4a")
        voiceFile = file

        try {
            @Suppress("DEPRECATION")
            val mediaRecorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(this)
            } else {
                MediaRecorder()
            }
            mediaRecorder.setAudioSource(MediaRecorder.AudioSource.MIC)
            mediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            mediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            mediaRecorder.setAudioEncodingBitRate(96_000)
            mediaRecorder.setAudioSamplingRate(44_100)
            mediaRecorder.setOutputFile(file.absolutePath)
            mediaRecorder.prepare()
            mediaRecorder.start()
            recorder = mediaRecorder
            recording = true
            voiceStatus?.text = "Recording… tap again to stop and send"
            voiceButton?.text = "Stop & send"
            handler.postDelayed({
                if (recording) stopAndSendVoice()
            }, 5_000)
        } catch (error: Exception) {
            releaseRecorder()
            file.delete()
            finishWithMessage(false, error.message ?: "Could not start recording")
        }
    }

    private fun stopAndSendVoice() {
        val file = voiceFile ?: return
        if (!recording) return
        try {
            recorder?.stop()
        } catch (_: Exception) {
            file.delete()
            releaseRecorder()
            finishWithMessage(false, "Voice clip was too short")
            return
        }
        releaseRecorder()
        showLoading("Sending voice…", "Uploading securely to your Bae")
        WidgetNativeShareService.shareMedia(file, "Voice", "video") { success, message ->
            file.delete()
            finishWithMessage(success, message)
        }
    }

    private fun releaseRecorder() {
        recording = false
        try {
            recorder?.release()
        } catch (_: Exception) {
        }
        recorder = null
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        when (requestCode) {
            CAMERA_PERMISSION_REQUEST -> if (granted) launchCamera() else {
                finishWithMessage(false, "Camera permission is required")
            }
            AUDIO_PERMISSION_REQUEST -> if (granted) startVoiceRecording() else {
                finishWithMessage(false, "Microphone permission is required")
            }
        }
    }

    private fun showLoading(heading: String, detail: String) {
        setContentView(createPanel().apply {
            gravity = Gravity.CENTER
            addView(ProgressBar(this@WidgetQuickActionActivity))
            addView(title(heading).apply { gravity = Gravity.CENTER })
            addView(subtitle(detail).apply { gravity = Gravity.CENTER })
        })
        configureWindow(tall = false)
    }

    private fun createPanel(): LinearLayout {
        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(22), dp(22), dp(22), dp(22))
            background = GradientDrawable(
                GradientDrawable.Orientation.TL_BR,
                intArrayOf(Color.rgb(36, 25, 42), Color.rgb(20, 17, 24))
            ).apply {
                cornerRadius = dp(28).toFloat()
                setStroke(dp(1), Color.argb(60, 255, 255, 255))
            }
        }
    }

    private fun title(text: String): TextView {
        return TextView(this).apply {
            this.text = text
            setTextColor(Color.WHITE)
            textSize = 20f
            setPadding(0, dp(8), 0, dp(4))
        }
    }

    private fun subtitle(text: String): TextView {
        return TextView(this).apply {
            this.text = text
            setTextColor(Color.argb(170, 255, 255, 255))
            textSize = 13f
        }
    }

    private fun actionButton(
        label: String,
        primary: Boolean,
        onClick: () -> Unit
    ): Button {
        return Button(this).apply {
            text = label
            isAllCaps = false
            setTextColor(Color.WHITE)
            textSize = 14f
            background = GradientDrawable(
                GradientDrawable.Orientation.LEFT_RIGHT,
                if (primary) {
                    intArrayOf(Color.rgb(255, 89, 126), Color.rgb(155, 91, 255))
                } else {
                    intArrayOf(Color.rgb(67, 59, 72), Color.rgb(48, 42, 53))
                }
            ).apply { cornerRadius = dp(16).toFloat() }
            setOnClickListener { onClick() }
        }
    }

    private fun finishWithMessage(success: Boolean, message: String) {
        runOnUiThread {
            Toast.makeText(this, message, Toast.LENGTH_LONG).show()
            if (success) vibrateTap()
            finishAndRemoveTask()
        }
    }

    private fun configureWindow(tall: Boolean) {
        window.decorView.post {
            val metrics = resources.displayMetrics
            window.setLayout(
                (metrics.widthPixels * 0.92f).toInt(),
                if (tall) {
                    (metrics.heightPixels * 0.78f).toInt()
                } else {
                    WindowManager.LayoutParams.WRAP_CONTENT
                }
            )
            window.setGravity(Gravity.CENTER)
        }
    }

    private fun vibrateTap() {
        @Suppress("DEPRECATION")
        val vibrator = getSystemService(VIBRATOR_SERVICE) as Vibrator
        if (!vibrator.hasVibrator()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(90, 170))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(90)
        }
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()
}

private class WidgetDrawingView(activity: Activity) : View(activity) {
    private val strokes = mutableListOf<Path>()
    private var currentPath: Path? = null
    private val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.rgb(255, 103, 151)
        style = Paint.Style.STROKE
        strokeWidth = resources.displayMetrics.density * 5f
        strokeCap = Paint.Cap.ROUND
        strokeJoin = Paint.Join.ROUND
    }
    private val backgroundPaint = Paint().apply { color = Color.rgb(18, 16, 22) }

    val hasDrawing: Boolean
        get() = strokes.isNotEmpty()

    init {
        background = GradientDrawable().apply {
            setColor(Color.rgb(18, 16, 22))
            cornerRadius = resources.displayMetrics.density * 20f
            setStroke(
                resources.displayMetrics.density.toInt().coerceAtLeast(1),
                Color.argb(45, 255, 255, 255)
            )
        }
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        strokes.forEach { canvas.drawPath(it, strokePaint) }
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                currentPath = Path().apply { moveTo(event.x, event.y) }
                strokes.add(currentPath!!)
                invalidate()
                return true
            }
            MotionEvent.ACTION_MOVE -> {
                currentPath?.lineTo(event.x, event.y)
                invalidate()
                return true
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                currentPath?.lineTo(event.x, event.y)
                currentPath = null
                invalidate()
                return true
            }
        }
        return super.onTouchEvent(event)
    }

    fun clear() {
        strokes.clear()
        currentPath = null
        invalidate()
    }

    fun toBitmap(): Bitmap {
        val safeWidth = width.coerceAtLeast(1)
        val safeHeight = height.coerceAtLeast(1)
        return Bitmap.createBitmap(safeWidth, safeHeight, Bitmap.Config.ARGB_8888).also {
            val canvas = Canvas(it)
            canvas.drawRect(0f, 0f, safeWidth.toFloat(), safeHeight.toFloat(), backgroundPaint)
            strokes.forEach { path -> canvas.drawPath(path, strokePaint) }
        }
    }
}

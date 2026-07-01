package com.example.bea_window_app

import android.os.Handler
import android.os.Looper
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import org.json.JSONObject
import java.io.BufferedOutputStream
import java.io.DataOutputStream
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.Executors

object WidgetNativeShareService {
    private const val CLOUD_NAME = "dpvo4otoj"
    private const val UPLOAD_PRESET = "bae_window_avatars"

    private val executor = Executors.newCachedThreadPool()
    private val mainHandler = Handler(Looper.getMainLooper())

    fun shareMedia(
        file: File,
        snapType: String,
        resourceType: String,
        callback: (Boolean, String) -> Unit
    ) {
        val user = FirebaseAuth.getInstance().currentUser
        if (user == null) {
            callback(false, "Open Bae Window and sign in once first")
            return
        }

        executor.execute {
            val uploadResult = uploadToCloudinary(file, resourceType)
            val url = uploadResult.getOrNull()
            if (url == null) {
                postResult(callback, false, uploadResult.exceptionOrNull()?.message ?: "Upload failed")
                return@execute
            }
            saveSharedMedia(user.uid, url, snapType, callback)
        }
    }

    fun sendPulse(callback: (Boolean, String) -> Unit) {
        val user = FirebaseAuth.getInstance().currentUser
        if (user == null) {
            callback(false, "Open Bae Window and sign in once first")
            return
        }

        val firestore = FirebaseFirestore.getInstance()
        val userRef = firestore.collection("users").document(user.uid)
        userRef.get()
            .addOnSuccessListener { snapshot ->
                val data = snapshot.data
                val pairId = data?.get("pairId") as? String
                if (data?.get("pairStatus") != "paired" || pairId.isNullOrBlank()) {
                    callback(false, "Pair with your Bae first")
                    return@addOnSuccessListener
                }

                val dayKey = currentDayKey()
                val batch = firestore.batch()
                batch.set(
                    userRef,
                    mapOf(
                        "latestPulse" to mapOf(
                            "id" to "${user.uid}_${System.nanoTime()}",
                            "sentAtClientMs" to System.currentTimeMillis(),
                            "sentAt" to FieldValue.serverTimestamp()
                        ),
                        "weeklyEngagement" to mapOf(
                            dayKey to FieldValue.increment(1)
                        )
                    ),
                    SetOptions.merge()
                )
                batch.set(
                    firestore.collection("couples").document(pairId),
                    mapOf(
                        "weeklyEngagement" to mapOf(
                            user.uid to mapOf(
                                dayKey to FieldValue.increment(1)
                            )
                        )
                    ),
                    SetOptions.merge()
                )
                batch.commit()
                    .addOnSuccessListener { callback(true, "Pulse sent to your Bae") }
                    .addOnFailureListener { callback(false, it.message ?: "Could not send pulse") }
            }
            .addOnFailureListener { callback(false, it.message ?: "Could not load pairing") }
    }

    private fun saveSharedMedia(
        uid: String,
        url: String,
        snapType: String,
        callback: (Boolean, String) -> Unit
    ) {
        val firestore = FirebaseFirestore.getInstance()
        val userRef = firestore.collection("users").document(uid)
        userRef.get()
            .addOnSuccessListener { snapshot ->
                val data = snapshot.data
                val normalizedType = snapType.lowercase(Locale.US)
                val urlField: String
                val timeField: String
                when (normalizedType) {
                    "draw" -> {
                        urlField = "latestDrawingUrl"
                        timeField = "latestDrawingTime"
                    }
                    "voice" -> {
                        urlField = "latestVoiceUrl"
                        timeField = "latestVoiceTime"
                    }
                    else -> {
                        urlField = "latestImageUrl"
                        timeField = "latestImageTime"
                    }
                }

                val dayKey = currentDayKey()
                val updates = mapOf<String, Any>(
                    urlField to url,
                    timeField to FieldValue.serverTimestamp(),
                    "latestSnapUrl" to url,
                    "latestSnapType" to snapType,
                    "lastSnapTime" to FieldValue.serverTimestamp(),
                    "weeklyEngagement" to mapOf(
                        dayKey to FieldValue.increment(1)
                    )
                )
                val batch = firestore.batch()
                batch.set(userRef, updates, SetOptions.merge())

                val pairId = data?.get("pairId") as? String
                if (data?.get("pairStatus") == "paired" && !pairId.isNullOrBlank()) {
                    batch.set(
                        firestore.collection("couples").document(pairId),
                        mapOf(
                            "weeklyEngagement" to mapOf(
                                uid to mapOf(
                                    dayKey to FieldValue.increment(1)
                                )
                            )
                        ),
                        SetOptions.merge()
                    )
                }

                batch.commit()
                    .addOnSuccessListener {
                        val label = when (normalizedType) {
                            "draw" -> "Drawing"
                            "voice" -> "Voice message"
                            else -> "Snap"
                        }
                        postResult(callback, true, "$label sent to your Bae")
                    }
                    .addOnFailureListener {
                        postResult(callback, false, it.message ?: "Could not share with your Bae")
                    }
            }
            .addOnFailureListener {
                postResult(callback, false, it.message ?: "Could not load your profile")
            }
    }

    private fun uploadToCloudinary(file: File, resourceType: String): Result<String> {
        if (!file.exists() || file.length() == 0L) {
            return Result.failure(IllegalStateException("Captured file is empty"))
        }

        val boundary = "----BaeWindow${System.currentTimeMillis()}"
        val lineEnd = "\r\n"
        var connection: HttpURLConnection? = null
        return try {
            val endpoint = "https://api.cloudinary.com/v1_1/$CLOUD_NAME/$resourceType/upload"
            connection = URL(endpoint).openConnection() as HttpURLConnection
            connection.requestMethod = "POST"
            connection.doOutput = true
            connection.connectTimeout = 20_000
            connection.readTimeout = 45_000
            connection.setRequestProperty("Content-Type", "multipart/form-data; boundary=$boundary")

            DataOutputStream(BufferedOutputStream(connection.outputStream)).use { output ->
                output.writeBytes("--$boundary$lineEnd")
                output.writeBytes("Content-Disposition: form-data; name=\"upload_preset\"$lineEnd")
                output.writeBytes(lineEnd)
                output.writeBytes(UPLOAD_PRESET)
                output.writeBytes(lineEnd)

                output.writeBytes("--$boundary$lineEnd")
                output.writeBytes(
                    "Content-Disposition: form-data; name=\"file\"; filename=\"${file.name}\"$lineEnd"
                )
                val contentType = when (resourceType) {
                    "video" -> "audio/mp4"
                    else -> if (file.extension.lowercase(Locale.US) == "png") "image/png" else "image/jpeg"
                }
                output.writeBytes("Content-Type: $contentType$lineEnd")
                output.writeBytes(lineEnd)
                file.inputStream().use { input -> input.copyTo(output) }
                output.writeBytes(lineEnd)
                output.writeBytes("--$boundary--$lineEnd")
                output.flush()
            }

            val responseCode = connection.responseCode
            val responseStream = if (responseCode in 200..299) {
                connection.inputStream
            } else {
                connection.errorStream
            }
            val responseBody = responseStream?.bufferedReader()?.use { it.readText() }.orEmpty()
            if (responseCode !in 200..299) {
                Result.failure(IllegalStateException("Upload failed ($responseCode)"))
            } else {
                val secureUrl = JSONObject(responseBody).optString("secure_url")
                if (secureUrl.isBlank()) {
                    Result.failure(IllegalStateException("Upload returned no URL"))
                } else {
                    Result.success(secureUrl)
                }
            }
        } catch (error: Exception) {
            Result.failure(error)
        } finally {
            connection?.disconnect()
        }
    }

    private fun currentDayKey(): String {
        return SimpleDateFormat("yyyy-MM-dd", Locale.US).apply {
            timeZone = TimeZone.getDefault()
        }.format(Date())
    }

    private fun postResult(
        callback: (Boolean, String) -> Unit,
        success: Boolean,
        message: String
    ) {
        mainHandler.post { callback(success, message) }
    }
}

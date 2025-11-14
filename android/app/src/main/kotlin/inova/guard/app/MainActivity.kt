package inova.guard.app

import android.app.admin.DevicePolicyManager
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    // 1. Define el nombre del canal (DEBE SER IDÉNTICO AL DE DART)
    private val CHANNEL_NAME = "inova.guard.app/provisioning"
    private var channel: MethodChannel? = null

    // 2. Variable para guardar el código cuando la app se inicia
    private var deviceCode: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 3. Lee el "deviceCode" que pasamos desde el QR
        val extras = intent.getParcelableExtra<Bundle>(
            DevicePolicyManager.EXTRA_PROVISIONING_ADMIN_EXTRAS_BUNDLE
        )
        if (extras != null) {
            // La clave "inova.guard.app.DEVICE_CODE" DEBE ser idéntica a la del JSON de Laravel
            deviceCode = extras.getString("inova.guard.app.DEVICE_CODE")
            android.util.Log.i("MainActivity", "DeviceCode recibido del Intent: $deviceCode")
        } else {
            android.util.Log.w("MainActivity", "No se recibieron extras de aprovisionamiento.")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 4. Configura el MethodChannel
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)

        // 5. Define lo que pasa cuando Dart llama a este código
        channel?.setMethodCallHandler { call, result ->
            if (call.method == "getDeviceCode") {
                // Si Dart pide el "getDeviceCode", le devolvemos el código que guardamos
                if (deviceCode != null) {
                    result.success(deviceCode)
                } else {
                    android.util.Log.e("MainActivity", "Flutter pidió el deviceCode, pero es null.")
                    result.success(null) // Devuelve null si no lo tiene
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
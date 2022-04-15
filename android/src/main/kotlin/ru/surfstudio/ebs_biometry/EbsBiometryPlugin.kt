package ru.surfstudio.ebs_biometry

import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.app.ActivityCompat.requestPermissions

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener
import ru.rtlabs.ebs.sdk.androidx.EbsApi
import androidx.fragment.app.FragmentActivity
import androidx.fragment.app.FragmentManager

/** EbsBiometryPlugin */
class EbsBiometryPlugin : FlutterPlugin, MethodCallHandler,
    RequestPermissionsResultListener, ActivityAware {

    companion object {
        const val REQUEST_CODE__PERMISSION = 119
        const val REQUEST_CODE__VERIFICATION = 120
    }

    private lateinit var context: Context
    private lateinit var channel: MethodChannel
    private lateinit var infoSystem: String

    private var currentActivity: Activity? = null
    private var permissionResult: Result? = null
    private var initialized = false

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "ru.surfstudio/ebs_biometry"
        )
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "configureSdk" -> configureSdk(call, result)

            "hasVerificationPermission" -> result.success(hasVerificationPermission())

            "requestVerificationPermission" -> requestVerificationPermission(result)

            "isEbsAppInstalled" -> result.success(isEbsAppInstalled())

            "requestInstallApp" -> {
                requestInstallApp()
                result.success(null)
            }

            "requestEsiaVerification" -> requestEsiaVerification(call, result)

            "requestEbsVerification" -> requestEbsVerification(call, result)

            else -> result.notImplemented()
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        currentActivity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        currentActivity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        currentActivity = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        currentActivity = null
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>, grantResults: IntArray
    ): Boolean {
        if (requestCode == REQUEST_CODE__PERMISSION) {
            if (!permissions.isNullOrEmpty() && permissions[0] == EbsApi.PERMISSION__VERIFICATION) {
                permissionResult?.success(grantResults[0] == PackageManager.PERMISSION_GRANTED)
            } else {
                permissionResult?.success(false)
            }
        }

        return true
    }

    private fun configureSdk(@NonNull call: MethodCall, @NonNull result: Result) {
        call.argument<String>("infoSystem")?.let {
            this.infoSystem = it
            initialized = true
            result.success(true)
        } ?: result.error(
            "no_arguments",
            "appScheme and infoSystem arguments are required",
            null
        )

    }

    /** Проверка наличия разрешения на верификацию через биометрию*/
    private fun hasVerificationPermission(): Boolean {
        val checkResult = ActivityCompat.checkSelfPermission(
            context,
            EbsApi.PERMISSION__VERIFICATION
        )

        return checkResult == PackageManager.PERMISSION_GRANTED
    }

    /** Запрос разрешения на верификацию */
    private fun requestVerificationPermission(@NonNull result: Result) {
        if (hasVerificationPermission()) {
            result.success(true)
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            currentActivity?.let {
                permissionResult = result
                requestPermissions(
                    it,
                    arrayOf(EbsApi.PERMISSION__VERIFICATION),
                    REQUEST_CODE__PERMISSION
                )
                return
            }
            result.error("NO_ACTIVITY", "Activity not attached", "")
        } else {
            result.success(true)
        }
    }

    /** Установлено ли приложение Ебс */
    private fun isEbsAppInstalled(): Boolean {
        return EbsApi.isInstalledApp(context)
    }

    /** Открыть google play для установки приложения ЕБС */
    private fun requestInstallApp() {
        EbsApi.requestInstallApp(context)
    }

    /** Запрос на верефикацию через госуслуги */
    private fun requestEsiaVerification(@NonNull call: MethodCall, @NonNull result: Result) {
        if (!initialized) {
            result.error(
                "not_initialized",
                "ebs_biometry plugin must be initialized before request verification.",
                null
            )
            return
        }

        val esiaVerificationUri = call.argument<String>("esiaVerificationUri")

        if (esiaVerificationUri == null) {
            result.error(
                "no_arguments",
                "esiaVerificationUri argument is required",
                null
            )
        }

        startVerification(
            result,
            VerificationFragment(
                RequestType.ESIA_VERIFICATION,
                result,
                infoSystem = infoSystem,
                esiaVerificationUri = esiaVerificationUri
            )
        )
    }

    /** Запрос на верефикацию через биометрию */
    private fun requestEbsVerification(@NonNull call: MethodCall, @NonNull result: Result) {
        if (!initialized) {
            result.error(
                "not_initialized",
                "ebs_biometry plugin must be initialized before request verification.",
                null
            )
            return
        }

        val ebsSessionId = call.argument<String>("ebsSessionId")

        if (ebsSessionId == null) {
            result.error(
                "no_arguments",
                "ebsSessionId argument is required",
                null
            )
        }

        startVerification(
            result,
            VerificationFragment(
                RequestType.EBS_VERIFICATION,
                result,
                infoSystem = infoSystem,
                ebsSessionId = ebsSessionId
            )
        )
    }

    private fun startVerification(result: Result, verificationFragment: VerificationFragment) {
        if (currentActivity !is FragmentActivity) {
            result.error(
                "no_fragment_activity",
                "ebs_biometry plugin requires activity to be a FragmentActivity.",
                null
            )
            return
        }

        if (!isEbsAppInstalled()) {
            result.success(
                VerificationResult(VerificationResultStatus.EBS_NOT_INSTALLED).result
            )
            return
        }

        val vParams: ViewGroup.LayoutParams = ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT
        )

        val container = FrameLayout(context)
        container.layoutParams = vParams
        container.id = REQUEST_CODE__VERIFICATION
        currentActivity?.addContentView(container, vParams)
        val fm: FragmentManager = (currentActivity as FragmentActivity).supportFragmentManager
        fm.beginTransaction()
            .replace(REQUEST_CODE__VERIFICATION, verificationFragment)
            .commitAllowingStateLoss()
    }
}

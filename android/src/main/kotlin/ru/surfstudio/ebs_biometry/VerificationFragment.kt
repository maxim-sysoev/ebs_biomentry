package ru.surfstudio.ebs_biometry

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import androidx.fragment.app.Fragment
import io.flutter.plugin.common.MethodChannel
import ru.rtlabs.ebs.sdk.EbsVerificationRequest
import ru.rtlabs.ebs.sdk.EsiaVerificationRequest
import ru.rtlabs.ebs.sdk.VerificationRequestMode
import ru.rtlabs.ebs.sdk.VerificationState
import ru.rtlabs.ebs.sdk.androidx.EbsApi
import java.lang.Exception

/** Fragment для вызова верификации пользователия
 *
 * @param requestType тип верификации
 * @param result callback для ответа
 * @param infoSystem информация о системе
 * @param esiaVerificationUri uri верификации через ЕСИА
 * @param ebsSessionId id сессии для верификации через биометрию
 * */
class VerificationFragment(
    private val requestType: RequestType,
    private val result: MethodChannel.Result,
    private val infoSystem: String,
    private val esiaVerificationUri: String? = null,
    private val ebsSessionId: String? = null
) : Fragment() {
    companion object {
        const val REQUEST_CODE__ESIA_VERIFICATION = 120
        const val REQUEST_CODE__EBS_VERIFICATION = 121
    }

    private var resultReplied = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            when (requestType) {
                RequestType.ESIA_VERIFICATION -> startEsiaVerification(
                    esiaVerificationUri ?: throw IllegalArgumentException(),
                    infoSystem
                )

                RequestType.EBS_VERIFICATION -> startEbsVerification(
                    ebsSessionId ?: throw IllegalArgumentException(),
                    infoSystem
                )
            }
        } catch (error: Exception) {
            errorVerification()
        }
    }

    override fun onDestroy() {
        if (!resultReplied) {
            replyResult(VerificationResult(VerificationResultStatus.ERROR))
        }
        super.onDestroy()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (resultCode == Activity.RESULT_OK) {
            when (requestCode) {
                REQUEST_CODE__ESIA_VERIFICATION -> {
                    val result = EbsApi.getEsiaVerificationResult(data)
                    when (result.state) {
                        VerificationState.SUCCESS -> {
                            if (result.isValid) {
                                finishEsiaVerification(result.esiaCode!!, result.esiaState!!)
                            } else {
                                errorVerification()
                            }
                        }
                        VerificationState.FAILURE -> errorVerification()
                        VerificationState.CANCEL -> cancelVerification()
                        VerificationState.REPEAT -> repeatVerification()
                    }
                }

                REQUEST_CODE__EBS_VERIFICATION -> {
                    val result = EbsApi.getEbsVerificationResult(data)
                    when (result.state) {
                        VerificationState.SUCCESS -> {
                            if (result.isValid) {
                                finishEbsVerification(result.ebsToken!!, result.ebsTokenExpired!!)
                            } else {
                                errorVerification()
                            }
                        }
                        VerificationState.FAILURE -> errorVerification()
                        VerificationState.CANCEL -> cancelVerification()
                        VerificationState.REPEAT -> repeatVerification()
                    }
                }

                else -> cancelVerification()
            }
        } else {
            cancelVerification()
        }
    }

    private fun startEsiaVerification(verificationUri: String, infoSystem: String) {
        val request = EsiaVerificationRequest.builder().infoSystem(infoSystem)
            .esiaVerificationUri(verificationUri).build()

        if (!EbsApi.requestEsiaVerification(
                this,
                request,
                REQUEST_CODE__ESIA_VERIFICATION,
                VerificationRequestMode.AUTOMATIC
            )
        ) {
            errorVerification()
        }
    }

    private fun startEbsVerification(sessionId: String, infoSystem: String) {
        val request = EbsVerificationRequest.builder().infoSystem(infoSystem)
            .sessionId(sessionId).build()

        if (!EbsApi.requestEbsVerification(this, request, REQUEST_CODE__EBS_VERIFICATION)) {
            errorVerification()
        }
    }

    private fun finishEsiaVerification(esiaCode: String, esiaState: String) {
        finishFragment(
            VerificationResult(
                VerificationResultStatus.SUCCESS,
                esiaCode = esiaCode,
                esiaState = esiaState
            )
        )
    }

    private fun finishEbsVerification(ebsToken: String, ebsTokenExpired: String) {
        finishFragment(
            VerificationResult(
                VerificationResultStatus.SUCCESS,
                ebsToken = ebsToken,
                ebsTokenExpired = ebsTokenExpired
            )
        )
    }

    private fun repeatVerification() {
        finishFragment(VerificationResult(VerificationResultStatus.REPEAT))
    }

    private fun cancelVerification() {
        finishFragment(VerificationResult(VerificationResultStatus.CANCELED))
    }

    private fun errorVerification() {
        finishFragment(VerificationResult(VerificationResultStatus.ERROR))
    }

    private fun finishFragment(
        verificationResult: VerificationResult
    ) {
        replyResult(verificationResult)
        activity?.supportFragmentManager?.beginTransaction()?.remove(this)?.commit()
    }

    private fun replyResult(
        verificationResult: VerificationResult
    ) {
        result.success(verificationResult.result)
        resultReplied = true
    }
}

package ru.surfstudio.ebs_biometry

class VerificationResult(
    private val status: VerificationResultStatus,
    private val esiaCode: String? = null,
    private val esiaState: String? = null,
    private val ebsToken: String? = null,
    private val ebsTokenExpired: String? = null
) {
    val result: MutableMap<String, String?> get() {
        val map : MutableMap<String, String?> = HashMap()
        map["status"] = status.name
        map["esiaCode"] = esiaCode
        map["esiaState"] = esiaState
        map["ebsToken"] = ebsToken
        map["ebsTokenExpired"] = ebsTokenExpired

        return map
    }
}

enum class VerificationResultStatus {
    SUCCESS,
    REPEAT,
    CANCELED,
    ERROR,
    EBS_NOT_INSTALLED,
}

enum class RequestType {
    ESIA_VERIFICATION,
    EBS_VERIFICATION,
}
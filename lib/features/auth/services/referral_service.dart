/// Simple in-memory holder for a pending referral code captured from an incoming dynamic link.
/// The code is consumed once by the UI (signup) and then cleared.
class ReferralService {
  static String? _pendingReferralCode;

  static void setPending(String code) {
    _pendingReferralCode = code;
  }

  static String? consumePending() {
    final code = _pendingReferralCode;
    _pendingReferralCode = null;
    return code;
  }

  static String? peek() => _pendingReferralCode;
}

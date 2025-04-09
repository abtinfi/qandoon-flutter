final Map<String, DateTime> otpExpiryMap = {};
final Map<String, int> otpRequestCount = {};
final int maxAttempts = 3;

bool canSendOtp(String email) {
  return (otpRequestCount[email] ?? 0) < maxAttempts;
}

void increaseOtpCount(String email) {
  otpRequestCount[email] = (otpRequestCount[email] ?? 0) + 1;
  otpExpiryMap[email] = DateTime.now().add(const Duration(seconds: 6));
}

int remainingTime(String email) {
  final expiry = otpExpiryMap[email];
  if (expiry == null) return 0;
  final diff = expiry.difference(DateTime.now()).inSeconds;
  return diff > 0 ? diff : 0;
}

bool isOtpExpired(String email) => remainingTime(email) == 0;

// utils/otp_tracker.dart

// توجه: این پیگیری وضعیت سمت کلاینت و در حافظه برنامه (در این سشن) است.
// با بسته شدن کامل برنامه (فورس استاپ)، این اطلاعات پاک می شوند.
// منطق اصلی محدودیت درخواست مجدد و زمان انقضا باید توسط بک‌اند مدیریت شود.

// Map برای ذخیره زمان انقضای کد OTP برای هر ایمیل
// Key: email (String), Value: DateTime (زمان دقیق انقضا)
Map<String, DateTime> otpExpiryMap = {};

// Map برای ذخیره تعداد دفعات درخواست OTP برای هر ایمیل در این سشن
Map<String, int> otpRequestCount = {};

// حداکثر تعداد دفعات مجاز برای درخواست OTP در یک بازه زمانی (مثلا 5 دقیقه)
// این باید با تنظیمات بک‌اند شما همخوانی داشته باشد
const int maxAttempts = 3; // مثال: حداکثر 3 تلاش برای درخواست مجدد


// تابعی برای تنظیم زمان انقضای کد OTP برای یک ایمیل
// expiresInSeconds: مدتی که کد معتبر است (به ثانیه)، از بک‌اند دریافت می شود
void setOtpExpiry(String email, int expiresInSeconds) {
  // محاسبه زمان دقیق انقضا با اضافه کردن مدت زمان به زمان فعلی
  otpExpiryMap[email] = DateTime.now().add(Duration(seconds: expiresInSeconds));
}

// تابعی برای محاسبه زمان باقی مانده تا انقضای کد OTP (به ثانیه)
// اگر کدی برای این ایمیل در tracker نیست یا منقضی شده، 0 برمی گرداند.
int remainingTime(String email) {
  // اگر ایمیل در Map نیست یا زمان انقضا گذشته است
  if (!otpExpiryMap.containsKey(email) || otpExpiryMap[email]!.isBefore(DateTime.now())) {
    return 0;
  }
  // محاسبه تفاوت زمان فعلی با زمان انقضا و برگرداندن به ثانیه
  final expiryDateTime = otpExpiryMap[email]!; // چون چک کردیم ContainsKey، دیگر null نیست
  final durationLeft = expiryDateTime.difference(DateTime.now());
  // اطمینان از اینکه عدد منفی برگردانده نشود
  return durationLeft.inSeconds > 0 ? durationLeft.inSeconds : 0;
}

// تابعی برای بررسی اینکه آیا می توان برای این ایمیل درخواست OTP مجدد ارسال کرد یا خیر
// بر اساس زمان باقی مانده و تعداد تلاش ها تصمیم می گیرد.
bool canSendOtp(String email) {
  // می توان درخواست داد اگر:
  // 1. زمان باقی مانده صفر باشد (تایمر تمام شده باشد)
  // 2. تعداد تلاش های سمت کلاینت هنوز به حداکثر نرسیده باشد
  return remainingTime(email) <= 0 && (otpRequestCount[email] ?? 0) < maxAttempts;
}

// تابعی برای افزایش شمارنده تلاش درخواست OTP برای یک ایمیل
void increaseOtpCount(String email) {
  otpRequestCount[email] = (otpRequestCount[email] ?? 0) + 1;
}

// تابعی برای پاک کردن وضعیت پیگیری OTP برای یک ایمیل (مثلاً بعد از تایید موفق یا لاگ اوت)
void resetOtpTracker(String email) {
  otpExpiryMap.remove(email);
  otpRequestCount.remove(email);
  // اگر تایمر های مربوط به این ایمیل را مستقیماً در اینجا ذخیره می کنید (که در کد SignupOTPScreen اینطور نیست)، باید آن ها را هم لغو و پاک کنید.
}

// تابع کمکی اختیاری: بررسی اینکه آیا تعداد تلاش ها به حداکثر رسیده است
bool isMaxAttemptsReached(String email) {
  return (otpRequestCount[email] ?? 0) >= maxAttempts;
}
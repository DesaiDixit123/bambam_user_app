# Keep razorpay classes
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Keep proguard annotation package references used by razorpay
-dontwarn proguard.annotation.**
-keep class proguard.annotation.** { *; }

# Safety: keep analytics/event classes used by razorpay
-keep class com.razorpay.AnalyticsEvent { *; }

import re

with open('lib/app/pages/home_screen/home_controller.dart', 'r') as f:
    content = f.read()

new_method = """
  // ------------------------------------------------------------------------
  // RECONSTRUCTED RAZORPAY METHODS
  // ------------------------------------------------------------------------

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint("Payment Success: ${response.paymentId}");
    // Typically call backend to verify or confirm booking
    Utility.showMessage("Payment Successful", MessageType.success, null, "OK");
    // e.g. confirmBooking();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("Payment Error: ${response.code} - ${response.message}");
    Utility.showMessage("Payment Failed", MessageType.error, null, "OK");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("External Wallet: ${response.walletName}");
    Utility.showMessage("External Wallet selected", MessageType.information, null, "OK");
  }

  void openRazorpayCheckout() {
    // Basic Razorpay options
    final options = {
      'key': 'rzp_test_YOUR_KEY_HERE', // Replace with actual key or fetch from env
      'amount': 100 * 100, // 100 INR in paise
      'name': 'BAMBAM CABS',
      'description': 'Booking Payment',
      'prefill': {
        'contact': '9876543210',
        'email': 'test@example.com'
      }
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Error opening razorpay: $e");
    }
  }
"""

parts = content.rsplit("}", 1)
new_content = parts[0] + new_method + "\n}" + parts[1]

with open('lib/app/pages/home_screen/home_controller.dart', 'w') as f:
    f.write(new_content)

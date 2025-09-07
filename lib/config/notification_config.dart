class NotificationConfig {
  // Email configuration
  static const String smtpHost =
      String.fromEnvironment('SMTP_HOST', defaultValue: 'smtp.gmail.com');
  static const int smtpPort =
      int.fromEnvironment('SMTP_PORT', defaultValue: 587);
  static const String senderEmail = String.fromEnvironment('SENDER_EMAIL',
      defaultValue: '232a.dabor@gmail.com');
  static const String senderPassword =
      String.fromEnvironment('SENDER_PASSWORD', defaultValue: 'new232C0mForT.');
  static const String senderName = String.fromEnvironment('SENDER_NAME',
      defaultValue: 'StockSense Inventory System');

  // SMS configuration (Twilio)
  static const String twilioAccountSid = String.fromEnvironment(
      'TWILIO_ACCOUNT_SID',
      defaultValue: 'twilio-account-sid');
  static const String twilioAuthToken = String.fromEnvironment(
      'TWILIO_AUTH_TOKEN',
      defaultValue: 'twilio-auth-token');
  static const String twilioPhoneNumber = String.fromEnvironment(
      'TWILIO_PHONE_NUMBER',
      defaultValue: '+1234567890');
  static const String twilioApiUrl =
      'https://api.twilio.com/2010-04-01/Accounts';

  // Validation methods
  static bool get isEmailConfigured {
    return senderEmail != '232a.dabor@gmail.com' &&
        senderPassword != 'new232C0mForT.';
  }

  static bool get isSmsConfigured {
    return twilioAccountSid != 'twilio-account-sid' &&
        twilioAuthToken != 'twilio-auth-token' &&
        twilioPhoneNumber != '+1234567890';
  }
}

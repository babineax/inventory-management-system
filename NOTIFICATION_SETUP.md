# StockSense Notification Setup Guide

This guide will help you configure email and SMS notifications for the StockSense inventory management system.

## 📧 Email Configuration (Gmail SMTP)

### Step 1: Prepare Your Gmail Account

1. **Enable 2-Factor Authentication**

   - Go to [Google Account Security](https://myaccount.google.com/security)
   - Enable 2-Step Verification if not already enabled

2. **Generate App Password**
   - Go to Security → App passwords
   - Select "Mail" as the app
   - Generate a 16-character app password
   - **Save this password** - you'll need it for configuration

### Step 2: Configure Email Settings

You have two options to configure email settings:

#### Option A: Direct Configuration (Quick Setup)

Edit `lib/config/notification_config.dart` and replace the default values:

```dart
static const String senderEmail = 'your-actual-email@gmail.com';
static const String senderPassword = 'your-16-char-app-password';
```

#### Option B: Environment Variables (Recommended for Production)

Set environment variables when running the app:

```bash
flutter run --dart-define=SENDER_EMAIL=your-email@gmail.com --dart-define=SENDER_PASSWORD=your-app-password
```

## 📱 SMS Configuration (Twilio)

### Step 1: Create Twilio Account

1. **Sign up for Twilio**

   - Go to [Twilio Console](https://console.twilio.com/)
   - Create a free account (includes $15 credit)

2. **Get Your Credentials**

   - **Account SID**: Found on your Console Dashboard
   - **Auth Token**: Found on your Console Dashboard (click to reveal)

3. **Get a Phone Number**
   - Go to Phone Numbers → Manage → Buy a number
   - Choose a number from your country
   - Note: Free trial accounts can only send to verified numbers

### Step 2: Configure SMS Settings

#### Option A: Direct Configuration

Edit `lib/config/notification_config.dart`:

```dart
static const String twilioAccountSid = 'account-sid';
static const String twilioAuthToken = 'auth-token';
static const String twilioPhoneNumber = '+1234567890'; // My Twilio number
```

#### Option B: Environment Variables

```bash
flutter run --dart-define=TWILIO_ACCOUNT_SID=your-sid --dart-define=TWILIO_AUTH_TOKEN=your-token --dart-define=TWILIO_PHONE_NUMBER=+1234567890
```

## 🔧 Complete Environment Variables Setup

For production deployment, use all environment variables:

```bash
flutter run \
  --dart-define=SENDER_EMAIL=your-email@gmail.com \
  --dart-define=SENDER_PASSWORD=your-app-password \
  --dart-define=SENDER_NAME="Your Company Name" \
  --dart-define=TWILIO_ACCOUNT_SID=your-account-sid \
  --dart-define=TWILIO_AUTH_TOKEN=your-auth-token \
  --dart-define=TWILIO_PHONE_NUMBER=+1234567890
```

## 🧪 Testing Notifications

### Test Email and SMS

1. **Run the app** with your configured settings
2. **Login** to your account
3. **Go to Profile → Notification Settings**
4. **Enable** email and/or SMS notifications
5. **Add your phone number** (for SMS)
6. **Tap "Test Notifications"** button

### Expected Results

- ✅ **Email**: You should receive a test email in your inbox
- ✅ **SMS**: You should receive a test SMS on your phone
- ❌ **Errors**: Check the console logs for any configuration issues

## 🚨 Troubleshooting

### Email Issues

- **"Authentication failed"**: Check your app password is correct
- **"Less secure app access"**: Use App Password, not regular password
- **"SMTP connection failed"**: Check internet connection and firewall

### SMS Issues

- **"Authentication Error"**: Verify Account SID and Auth Token
- **"Invalid phone number"**: Ensure number includes country code (+1, +44, etc.)
- **"Trial account restrictions"**: Verify recipient phone number in Twilio console

### Common Issues

- **Environment variables not working**: Restart your IDE after setting variables
- **Configuration not updating**: Do a clean build: `flutter clean && flutter pub get`

## 📋 Notification Features

Once configured, your app will automatically send notifications for:

### 📦 Stock Alerts

- **Low stock warnings** when items reach reorder level
- **Out of stock alerts** when quantity reaches zero
- **Automatic monitoring** every hour

### ⏰ Expiry Alerts

- **7 days before expiry** for perishable items
- **3 days before expiry** for critical items
- **Day of expiry** and **expired items**

### 🔮 AI Prediction Alerts

- **Stock depletion predictions** based on usage patterns
- **Reorder recommendations** with confidence levels
- **Trend analysis** for inventory planning

### 🎉 Welcome Notifications

- **New user welcome emails** with feature overview
- **Account setup confirmation**

## 🔐 Security Best Practices

1. **Never commit credentials** to version control
2. **Use environment variables** in production
3. **Rotate credentials** regularly
4. **Monitor usage** in Twilio console
5. **Set up billing alerts** to avoid unexpected charges

## 💰 Cost Considerations

### Gmail SMTP

- **Free** for reasonable usage
- **Rate limits**: 500 emails/day for free accounts

### Twilio SMS

- **Pay-per-message** pricing
- **Free trial**: $15 credit included
- **Typical cost**: $0.0075 per SMS in US
- **International**: Varies by country

## 📞 Support

If you need help with configuration:

1. Check the console logs for detailed error messages
2. Verify all credentials are correct
3. Test with a simple email/SMS first
4. Contact Twilio support for SMS issues
5. Check Gmail security settings for email issues

---

**Ready to go?** Follow the steps above and your notification system will be fully functional! 🚀

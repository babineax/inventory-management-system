# Password Reset Functionality Setup

## Overview
The StockSense app includes a complete password reset feature that allows users to reset their passwords via email. This feature uses Firebase Authentication's built-in password reset functionality.

## How It Works
1. User clicks "Forgot Password?" on the login screen
2. User enters their email address in the dialog
3. App sends password reset email via Firebase Auth
4. User receives email with password reset link
5. User clicks link and sets new password
6. Password is automatically updated in Firebase Auth

## Firebase Console Configuration Required

### Step 1: Enable Email/Password Sign-in Method
1. Go to Firebase Console → Authentication → Sign-in method
2. Ensure "Email/Password" is enabled
3. This should already be enabled for your app to work

### Step 2: Configure Email Templates (Optional but Recommended)
1. Go to Firebase Console → Authentication → Templates
2. Customize the password reset email template if desired
3. Set the sender name and reply-to email
4. The default Firebase template will work, but customization improves user experience

### Step 3: Verify Domain Configuration
1. Go to Firebase Console → Authentication → Settings
2. Under "Authorized domains", ensure your app's domain is listed
3. For web apps, add your domain (e.g., `localhost` for development)
4. For mobile apps, this is usually handled automatically

## Testing the Feature

### Manual Testing
1. Run the app and go to the login screen
2. Click "Forgot Password?"
3. Enter a valid email address of an existing user
4. Check that a password reset email is sent
5. Verify the email contains a working reset link

### Error Scenarios to Test
- Invalid email format
- Non-existent user email
- Network connectivity issues
- Too many reset requests (rate limiting)

## Code Implementation Details

### UI Components
- `LoginPage._showForgotPasswordDialog()` - Shows the forgot password dialog
- Email input field with validation
- "Send Reset Email" button with loading state

### Service Layer
- `AuthService.resetPassword()` - Calls Firebase Auth API
- Proper error handling for various Firebase exceptions
- User-friendly error messages

### Error Handling
The implementation handles these Firebase Auth errors:
- `user-not-found`: "No user found with this email address"
- `invalid-email`: "Invalid email address"
- `too-many-requests`: "Too many requests. Please try again later"

## Security Considerations
- Password reset emails are sent securely via Firebase
- Reset links expire after a certain time (configurable in Firebase)
- Users must verify their identity before resetting passwords
- No sensitive information is exposed in the reset process

## Troubleshooting

### Common Issues
1. **"Password reset email not received"**
   - Check spam/junk folder
   - Verify email address is correct
   - Check Firebase Console email template configuration

2. **"Invalid email" error**
   - Ensure email format is valid
   - Check for typos in email address

3. **Rate limiting errors**
   - Wait before trying again
   - This is a security feature to prevent abuse

### Debug Steps
1. Check Firebase Console → Authentication → Users to verify user exists
2. Check Firebase Console → Authentication → Templates for email configuration
3. Verify network connectivity
4. Check browser console for any JavaScript errors (for web version)

## Production Deployment Notes
- Ensure Firebase project is properly configured for production
- Test password reset functionality in production environment
- Monitor Firebase Console for authentication events
- Consider implementing additional security measures if needed
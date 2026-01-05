# Email Setup Guide

## Why You're Seeing the Warning

The warning appears because Gmail authentication is failing. This happens when:
1. You're using your regular Gmail password instead of an **App Password**
2. 2-Step Verification is not enabled on your Google Account
3. SMTP credentials are incorrect or missing

## Good News! 🎉

**The server will still run without email configured!** Email is optional for development. The app will work, but:
- User registration will work (OTP will be logged in console in dev mode)
- Password reset won't send emails
- You can test the app without email functionality

## How to Fix Email Authentication

### Option 1: Set Up Gmail App Password (Recommended)

1. **Enable 2-Step Verification:**
   - Go to [Google Account Security](https://myaccount.google.com/security)
   - Enable "2-Step Verification" if not already enabled

2. **Generate App Password:**
   - Go to [App Passwords](https://myaccount.google.com/apppasswords)
   - Select "Mail" and "Other (Custom name)"
   - Enter "Chat App" as the name
   - Click "Generate"
   - Copy the 16-character password (no spaces)

3. **Update your `.env` file:**
   ```env
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USERNAME=your-email@gmail.com
   SMTP_PASSWORD=your-16-char-app-password
   EMAIL_FROM=your-email@gmail.com
   ```

4. **Restart the server:**
   ```bash
   npm run dev
   ```

### Option 2: Use a Different Email Service

You can use other SMTP providers:

#### Outlook/Hotmail:
```env
SMTP_HOST=smtp-mail.outlook.com
SMTP_PORT=587
SMTP_USERNAME=your-email@outlook.com
SMTP_PASSWORD=your-password
EMAIL_FROM=your-email@outlook.com
```

#### SendGrid (Free tier available):
```env
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=your-sendgrid-api-key
EMAIL_FROM=your-verified-email@domain.com
```

#### Mailtrap (For testing - doesn't send real emails):
```env
SMTP_HOST=sandbox.smtp.mailtrap.io
SMTP_PORT=2525
SMTP_USERNAME=your-mailtrap-username
SMTP_PASSWORD=your-mailtrap-password
EMAIL_FROM=test@mailtrap.io
```

### Option 3: Disable Email (For Development)

If you don't need email functionality right now:

1. **Comment out or remove SMTP settings** in `.env`:
   ```env
   # SMTP_HOST=smtp.gmail.com
   # SMTP_PORT=587
   # SMTP_USERNAME=
   # SMTP_PASSWORD=
   # EMAIL_FROM=
   ```

2. **The server will run without email**
   - In development mode, OTP codes will be logged to console
   - You can manually check the console for OTP codes during registration

## Development Mode Behavior

When email is not configured or fails:
- ✅ Server still runs normally
- ✅ All API endpoints work
- ✅ In development mode, OTP codes are logged to console
- ⚠️ Registration emails won't be sent
- ⚠️ Password reset emails won't be sent

## Testing Email Setup

After configuring email, you should see:
```
✓ Connected to email server successfully
```

Instead of:
```
⚠ Email authentication failed...
```

## Troubleshooting

### "Invalid login" or "BadCredentials"
- ✅ Make sure you're using an App Password (not regular password)
- ✅ Check that 2-Step Verification is enabled
- ✅ Verify SMTP_USERNAME is your full email address
- ✅ Make sure there are no extra spaces in .env values

### "Connection timeout"
- ✅ Check your internet connection
- ✅ Verify SMTP_HOST and SMTP_PORT are correct
- ✅ Check firewall settings

### "Email service is disabled"
- ✅ This is fine for development! Server will still work
- ✅ OTP codes will be logged to console in dev mode

## Quick Test

To test if email is working, try registering a new user. If email is configured correctly, you'll receive an OTP email. If not configured, check the server console for the OTP code.


# Vercel Deployment Guide - Fixing 404 Error

## Problem
Getting `404: NOT_FOUND` error on Vercel because:
1. Vercel expects serverless functions, not traditional Express servers
2. Socket.IO doesn't work on Vercel (WebSocket limitations)
3. Missing Vercel configuration

## ⚠️ Important Limitations

**Socket.IO will NOT work on Vercel** because:
- Vercel doesn't support WebSocket connections
- Socket.IO requires persistent connections
- Real-time features won't work

## Solution Options

### Option 1: Deploy API Only (Without Socket.IO) - Recommended for Vercel

**Step 1: Create Vercel Configuration**

I've created `vercel.json` for you. Make sure it's in the `chat_backend` folder.

**Step 2: Update package.json**

Add build script:
```json
"scripts": {
  "start": "node src/server.js",
  "dev": "node --watch --env-file=.env src/server.js",
  "build": "echo 'No build needed'"
}
```

**Step 3: Deploy to Vercel**

1. Go to Vercel Dashboard
2. Import your GitHub repository
3. Set **Root Directory** to: `chat_backend`
4. Set **Build Command**: `npm install` (or leave empty)
5. Set **Output Directory**: (leave empty)
6. Add Environment Variables:
   - `MONGODB_URL`
   - `JWT_SECRET`
   - `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `EMAIL_FROM`
   - `PORT` (Vercel will set this automatically)

**Step 4: Update API Base URL in Flutter**

Change `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'https://your-app.vercel.app/api';
```

### Option 2: Use Alternative Platforms (Recommended for Full Features)

Since your app uses Socket.IO, consider these platforms:

#### A. Railway (Recommended)
- ✅ Supports Socket.IO
- ✅ Easy MongoDB integration
- ✅ Free tier available

**Deploy to Railway:**
1. Go to: https://railway.app
2. New Project → Deploy from GitHub
3. Select your repository
4. Set root directory: `chat_backend`
5. Add environment variables
6. Deploy!

#### B. Render
- ✅ Supports Socket.IO
- ✅ Free tier available
- ✅ Easy setup

**Deploy to Render:**
1. Go to: https://render.com
2. New Web Service
3. Connect GitHub repository
4. Root Directory: `chat_backend`
5. Build Command: `npm install`
6. Start Command: `npm start`
7. Add environment variables

#### C. Heroku
- ✅ Supports Socket.IO
- ✅ Well-documented
- ⚠️ Paid plans (free tier discontinued)

#### D. DigitalOcean App Platform
- ✅ Supports Socket.IO
- ✅ Good performance
- ⚠️ Paid (but affordable)

### Option 3: Hybrid Approach

1. **Deploy REST API to Vercel** (for HTTP endpoints)
2. **Deploy Socket.IO server separately** to Railway/Render
3. **Update Flutter app** to use both:
   - API calls → Vercel
   - Socket.IO → Railway/Render

## Quick Fix for Vercel (API Only)

### 1. Update vercel.json

Make sure `chat_backend/vercel.json` exists with:
```json
{
  "version": 2,
  "builds": [
    {
      "src": "src/app.js",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/api/(.*)",
      "dest": "src/app.js"
    }
  ]
}
```

### 2. Create API Handler

Create `chat_backend/api/index.js`:
```javascript
const app = require('../src/app');
module.exports = app;
```

### 3. Update app.js for Vercel

Modify `chat_backend/src/app.js` to export the app:
```javascript
// At the end of app.js
module.exports = app;
```

### 4. Remove Socket.IO from Vercel Deployment

For Vercel, you'll need to disable Socket.IO initialization. Create a separate server file for Vercel.

## Recommended Solution

**For a WhatsApp-like app with real-time features:**

1. **Deploy to Railway or Render** (supports Socket.IO)
2. **Use MongoDB Atlas** (free tier available)
3. **Update Flutter app** with new backend URL

**Steps for Railway:**
```bash
# 1. Install Railway CLI (optional)
npm i -g @railway/cli

# 2. Login
railway login

# 3. Initialize project
cd chat_backend
railway init

# 4. Add environment variables
railway variables set MONGODB_URL=your_mongodb_url
railway variables set JWT_SECRET=your_secret

# 5. Deploy
railway up
```

## Environment Variables Needed

Add these in your deployment platform:

```
MONGODB_URL=mongodb+srv://...
JWT_SECRET=your-secret-key
JWT_ACCESS_EXPIRATION_MINUTES=30
JWT_REFRESH_EXPIRATION_DAYS=30
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
EMAIL_FROM=your-email@gmail.com
PORT=3000
NODE_ENV=production
```

## Testing After Deployment

1. Check API health: `https://your-app.vercel.app/api/users/me`
2. Test authentication: `POST https://your-app.vercel.app/api/auth/login`
3. Update Flutter app with new base URL

## Next Steps

1. **If using Vercel**: Follow Option 1 (API only, no Socket.IO)
2. **If you need Socket.IO**: Use Railway or Render (Option 2)
3. **Update Flutter app** with the new backend URL

Would you like me to:
- Set up Railway deployment?
- Configure Vercel for API-only deployment?
- Create a hybrid setup?


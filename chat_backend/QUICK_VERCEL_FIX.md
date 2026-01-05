# Quick Fix for Vercel 404 Error

## Problem
Getting `404: NOT_FOUND` on Vercel because the Express app isn't configured correctly.

## ✅ Solution

I've created the necessary files:
- ✅ `vercel.json` - Vercel configuration
- ✅ `api/index.js` - Serverless function entry point

## Steps to Deploy

### 1. Commit the New Files
```powershell
git add chat_backend/vercel.json chat_backend/api/index.js
git commit -m "Add Vercel configuration"
git push
```

### 2. Deploy on Vercel

**Option A: Via Vercel Dashboard**
1. Go to: https://vercel.com/dashboard
2. Click "Add New Project"
3. Import your GitHub repository
4. **Important Settings:**
   - **Root Directory**: `chat_backend`
   - **Framework Preset**: Other
   - **Build Command**: (leave empty or `npm install`)
   - **Output Directory**: (leave empty)
   - **Install Command**: `npm install`

5. **Add Environment Variables:**
   - `MONGODB_URL` = your MongoDB connection string
   - `JWT_SECRET` = your secret key
   - `JWT_ACCESS_EXPIRATION_MINUTES` = 30
   - `JWT_REFRESH_EXPIRATION_DAYS` = 30
   - `SMTP_HOST` = smtp.gmail.com
   - `SMTP_PORT` = 587
   - `SMTP_USERNAME` = your email
   - `SMTP_PASSWORD` = your app password
   - `EMAIL_FROM` = your email
   - `NODE_ENV` = production

6. Click "Deploy"

**Option B: Via Vercel CLI**
```powershell
cd chat_backend
npm i -g vercel
vercel login
vercel
```

### 3. Update Flutter App

After deployment, update `lib/services/api_service.dart`:

```dart
// Change this:
static const String baseUrl = 'http://localhost:3000/api';

// To this (replace with your Vercel URL):
static const String baseUrl = 'https://your-app-name.vercel.app/api';
```

And `lib/services/socket_service.dart`:
```dart
// ⚠️ Socket.IO won't work on Vercel!
// You'll need to deploy Socket.IO separately to Railway/Render
static const String socketUrl = 'https://your-socket-server.railway.app';
```

## ⚠️ Important Limitations

### Socket.IO Won't Work on Vercel
Vercel doesn't support WebSocket connections, so:
- ❌ Real-time messaging won't work
- ❌ Typing indicators won't work
- ❌ Online/offline status won't work
- ✅ REST API endpoints will work fine

### Solution: Hybrid Deployment

1. **Deploy REST API to Vercel** (what we're doing now)
2. **Deploy Socket.IO server to Railway/Render** separately
3. **Update Flutter app** to use both services

## Test After Deployment

1. Check if API is working:
   ```
   https://your-app.vercel.app/api/users/me
   ```

2. Test login:
   ```bash
   POST https://your-app.vercel.app/api/auth/login
   Body: {"email": "test@example.com", "password": "password"}
   ```

## Alternative: Deploy Everything to Railway (Recommended)

Railway supports Socket.IO and is easier:

1. Go to: https://railway.app
2. New Project → Deploy from GitHub
3. Select repository
4. Root Directory: `chat_backend`
5. Add environment variables
6. Deploy!

Railway will give you a URL like: `https://your-app.railway.app`

Then update Flutter:
```dart
static const String baseUrl = 'https://your-app.railway.app/api';
static const String socketUrl = 'https://your-app.railway.app';
```

## Current Status

✅ Vercel configuration files created
✅ Ready to deploy
⏳ Need to commit and push files
⏳ Deploy on Vercel
⏳ Add environment variables


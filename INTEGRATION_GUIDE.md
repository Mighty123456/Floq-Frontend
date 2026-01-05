# WhatsApp-like Chat Application - Integration Guide

## Backend Implementation Complete ✅

### Features Implemented:

1. **Authentication System**
   - User registration with email verification (OTP)
   - Login with JWT tokens
   - Password reset functionality
   - Token-based authentication middleware

2. **User Management**
   - Get user profile
   - Update user profile (name, email, profile picture, status)
   - Search users
   - Online/offline status tracking
   - Last seen tracking

3. **Chat System**
   - Create one-on-one chats
   - Fetch all user chats
   - Group chat support
   - Latest message tracking

4. **Messaging**
   - Send messages
   - Get all messages for a chat
   - Mark messages as read
   - Real-time message delivery via Socket.IO

5. **Friend Requests**
   - Send friend requests
   - Accept/decline friend requests
   - Get pending requests
   - Get friends list
   - Remove friends

6. **Group Management**
   - Create groups
   - Rename groups
   - Add/remove members
   - Group admin management

7. **Real-time Features (Socket.IO)**
   - Real-time messaging
   - Typing indicators
   - Online/offline status
   - Message read receipts
   - Socket authentication

## Flutter Integration

### Setup Steps:

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Update API Base URL**
   - Open `lib/services/api_service.dart`
   - Update `baseUrl` constant to match your backend:
     ```dart
     static const String baseUrl = 'http://YOUR_IP:3000/api';
     // For Android emulator use: http://10.0.2.2:3000/api
     // For iOS simulator use: http://localhost:3000/api
     // For physical device use your computer's IP: http://192.168.x.x:3000/api
     ```

3. **Update Socket URL**
   - Open `lib/services/socket_service.dart`
   - Update `socketUrl` constant:
     ```dart
     static const String socketUrl = 'http://YOUR_IP:3000';
     ```

### API Endpoints Available:

#### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/verify-email` - Verify email with OTP
- `POST /api/auth/login` - Login user
- `POST /api/auth/forgot-password` - Request password reset
- `POST /api/auth/reset-password` - Reset password with OTP

#### Users
- `GET /api/users/me` - Get current user
- `GET /api/users/:userId` - Get user by ID
- `PATCH /api/users/me` - Update profile
- `GET /api/users/search?q=query` - Search users

#### Chats
- `POST /api/chats` - Create/access chat (body: {userId})
- `GET /api/chats` - Get all user chats

#### Messages
- `POST /api/messages` - Send message (body: {chatId, content})
- `GET /api/messages/:chatId` - Get messages for chat
- `POST /api/messages/read` - Mark messages as read (body: {chatId})

#### Groups
- `POST /api/groups` - Create group (body: {name, users: []})
- `PUT /api/groups/rename` - Rename group (body: {chatId, chatName})
- `PUT /api/groups/add` - Add member (body: {chatId, userId})
- `PUT /api/groups/remove` - Remove member (body: {chatId, userId})

#### Friend Requests
- `POST /api/friend-requests/send` - Send request (body: {receiverId})
- `POST /api/friend-requests/accept` - Accept request (body: {requestId})
- `POST /api/friend-requests/decline` - Decline request (body: {requestId})
- `GET /api/friend-requests` - Get requests (returns {sent: [], received: []})
- `GET /api/friend-requests/friends` - Get friends list
- `DELETE /api/friend-requests/remove` - Remove friend (body: {friendId})

### Socket.IO Events:

#### Client → Server
- `authenticate` - Authenticate socket with token
- `join chat` - Join a chat room
- `leave chat` - Leave a chat room
- `typing` - Send typing indicator (data: {chatId, userId})
- `stop typing` - Stop typing indicator (data: {chatId, userId})
- `new message` - Emit new message (after sending via API)
- `message read` - Mark message as read (data: {chatId, messageId})

#### Server → Client
- `authenticated` - Socket authenticated successfully
- `auth_error` - Authentication failed
- `message received` - New message received
- `typing` - User is typing (data: {chatId, userId, userName})
- `stop typing` - User stopped typing (data: {chatId, userId})
- `user_online` - User came online (data: {userId})
- `user_offline` - User went offline (data: {userId})
- `message read` - Message was read (data: {chatId, messageId, readBy})

### Next Steps for Full Integration:

1. **Update Remaining Screens:**
   - `users_screen.dart` - Fetch users from API
   - `chats_screen.dart` - Fetch chats and integrate Socket.IO
   - `chat_screen.dart` - Real-time messaging with Socket.IO
   - `requests_screen.dart` - Fetch and handle friend requests
   - `contacts_screen.dart` - Show friends list
   - `preferences_screen.dart` - Update user profile

2. **Add State Management:**
   - Consider using Provider, Riverpod, or Bloc for state management
   - Manage user session state
   - Manage chat and message state
   - Manage online status

3. **Error Handling:**
   - Add proper error handling throughout
   - Show user-friendly error messages
   - Handle network errors gracefully

4. **Testing:**
   - Test on physical devices
   - Test real-time features
   - Test offline scenarios

## Backend Configuration

Make sure your `.env` file has:
```
PORT=3000
MONGODB_URL=mongodb://localhost:27017/chat-app
JWT_SECRET=your-secret-key-here
JWT_ACCESS_EXPIRATION_MINUTES=30
JWT_REFRESH_EXPIRATION_DAYS=30

SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
EMAIL_FROM=your-email@gmail.com
```

## Running the Application

1. **Start Backend:**
   ```bash
   cd chat_backend
   npm install
   npm run dev
   ```

2. **Start Flutter App:**
   ```bash
   flutter pub get
   flutter run
   ```

## Notes

- The login screen is already integrated with the API
- Register screen is integrated with API
- Socket.IO service is ready to use
- All API methods are available in `ApiService` class
- Remember to update the base URLs for your environment


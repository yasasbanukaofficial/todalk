# Todalk — Voice-Powered Task Manager

Full-stack task management app with voice-controlled task creation via Deepgram STT/TTS. Built with Flutter + NestJS + PostgreSQL (Neon).

## Stack

| Layer   | Tech                                                                    |
| ------- | ----------------------------------------------------------------------- |
| Mobile  | Flutter, Riverpod, Dio, google_sign_in, just_audio, record              |
| Server  | NestJS, TypeORM, PostgreSQL, JWT (access + refresh rotation), Deepgram SDK |
| Voice   | WebSocket (`@nestjs/platform-ws`), Deepgram STT (Nova-3) + TTS (Aura-2) |
| Auth    | Email/password (bcrypt) + Google OAuth                                  |
| DB      | PostgreSQL via Neon, TypeORM with `synchronize: true`                   |
| Deploy  | Railway (server), Vercel (alternative serverless), Flutter (Android/iOS) |

## Project Structure

```
todalk/
├── mobile/                        # Flutter app
│   └── lib/
│       ├── main.dart              # Entry point, ProviderScope, splash screen
│       ├── providers/
│       │   ├── api_providers.dart   # Dio Provider
│       │   ├── auth_provider.dart   # AuthNotifier (Riverpod)
│       │   └── task_provider.dart   # TaskNotifier + filtered/recent providers
│       ├── screens/
│       │   ├── auth_screen.dart      # Login/Register + Google G button
│       │   ├── home_screen.dart      # Main screen with task list
│       │   ├── recording_screen.dart # Push-to-talk voice FSM
│       │   ├── task_detail_screen.dart
│       │   ├── task_list_screen.dart
│       │   └── profile_screen.dart
│       ├── services/
│       │   ├── api_service.dart      # Dio HTTP client, JWT refresh
│       │   └── voice_service.dart    # WebSocket client, reconnect with retry
│       ├── models/
│       │   └── task.dart
│       ├── widgets/
│       │   ├── manual_add_task_sheet.dart
│       │   ├── task_card.dart
│       │   ├── morphing_blob.dart
│       │   └── ...
│       └── theme/
│           └── app_theme.dart
├── server/                        # NestJS backend
│   └── src/
│       ├── main.ts                # Bootstrap, WsAdapter, global pipes
│       ├── app.module.ts
│       ├── auth/                  # JWT auth + Google OAuth
│       ├── users/                 # User CRUD
│       ├── todos/                 # Task CRUD
│       ├── voice/                 # WebSocket gateway, Deepgram STT/TTS, FSM
│       ├── database/              # TypeORM config
│       ├── config/                # Env config + Joi validation
│       └── common/                # Filters, interceptors, decorators
└── ARCHITECTURE.md                # Detailed architecture docs
```

## Getting Started

### Prerequisites

- Flutter SDK 3.12+
- Node.js 22+
- PostgreSQL database (Neon recommended)
- Deepgram API key (for voice features)
- Google Cloud Console project (for Google OAuth)

### Server

```bash
cd server
npm install
cp .env.example .env    # or edit .env with your values
npm run start:dev       # http://localhost:3000
```

Required env vars:

| Variable             | Description                      |
| -------------------- | -------------------------------- |
| `DATABASE_URL`       | PostgreSQL connection string     |
| `JWT_SECRET`         | Access token signing secret      |
| `JWT_REFRESH_SECRET` | Refresh token signing secret     |
| `DEEPGRAM_API_KEY`   | Deepgram STT/TTS API key         |
| `GOOGLE_CLIENT_ID`   | Google OAuth client ID (optional)|

### Mobile

```bash
cd mobile
flutter pub get
# Edit mobile/.env with your server URL
flutter run
```

Required env vars:

| Variable                   | Description                              |
| -------------------------- | ---------------------------------------- |
| `API_BASE_URL`             | Backend URL (e.g. `http://10.0.2.2:3000`) |
| `GOOGLE_SERVER_CLIENT_ID`  | Google OAuth server client ID            |

### Voice Flow

1. User holds the mic button → audio streams via WebSocket to server
2. Server sends audio chunks to Deepgram STT (Nova-3) for transcription
3. Transcript is processed through a conversation FSM (task → date → priority)
4. Server responds with TTS audio (Aura-2) + JSON state changes
5. On completion, a task is created and synced to the database

## API Endpoints

| Method | Path              | Auth     | Description          |
| ------ | ----------------- | -------- | -------------------- |
| POST   | `/auth/register`  | No       | Register with email  |
| POST   | `/auth/login`     | No       | Login with email     |
| POST   | `/auth/google`    | No       | Google OAuth login   |
| POST   | `/auth/refresh`   | Token    | Rotate refresh token |
| POST   | `/auth/logout`    | Token    | Invalidate session   |
| GET    | `/users/me`       | Bearer   | Current user profile |
| GET    | `/todos`          | Bearer   | List tasks           |
| POST   | `/todos`          | Bearer   | Create task          |
| GET    | `/todos/:id`      | Bearer   | Get task             |
| PATCH  | `/todos/:id`      | Bearer   | Update task          |
| DELETE | `/todos/:id`      | Bearer   | Delete task          |
| GET    | `/health`         | No       | Health check         |
| WS     | `/voice/stream`   | No       | WebSocket voice      |

## State Management (Riverpod)

- **Providers**: `authProvider`, `taskProvider`, `apiServiceProvider`
- **Computed providers**: `filteredTasksProvider`, `recentTasksProvider`
- All state is immutable (`copyWith` pattern), notifiers extend `Notifier<T>`
- Screens use `ConsumerWidget` / `ConsumerStatefulWidget`

## HTTP Client (Dio)

- Single `ApiService` instance with interceptors for auth headers
- JWT expiry tracked client-side; auto-refresh before requests
- Proactive refresh on stale tokens, reactive refresh on 401
- Typed `DioException` error handling

## Authentication

- Email/password with bcrypt-hashed passwords
- Google OAuth via `google_sign_in` (no Firebase)
- JWT with refresh token rotation (old refresh hash stored in DB)
- Token stored in FlutterSecureStorage (platform-encrypted)

## Deployment

### Railway (recommended for WebSocket)

```bash
cd server
# Set root directory to server/ in Railway dashboard
# Add env vars in Railway dashboard
# Railway auto-detects Node.js and runs npm run build + npm start
```

### Vercel (HTTP only, no WebSocket)

The `server/api/index.ts` provides a serverless entry point. WebSocket voice features won't work on Vercel serverless.

## License

MIT

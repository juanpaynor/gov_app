# MyRoxas - App Blueprint

## Overview

MyRoxas is a city government services app for Roxas City, Capiz, Philippines. It connects Roxasnons with their local government through a calm, modern, and trustworthy mobile experience.

## Design Philosophy

**Visual Identity:**
- Colors inspired by Capiz provincial seal
- Deep blue (#1B4B7F) for trust and stability
- Gold (#D4A13D) for warmth and service
- Light backgrounds (#F8F9FA) for clarity
- Soft shadows and rounded corners (12-16px radius)

**Typography:**
- Headings: Poppins (bold, modern)
- Body text: Inter (readable, clean)
- Sizes are clear and hierarchical

**User Experience:**
- Warm, localized greeting ("Maayong aga, Capizeño!")
- Clear feature cards for navigation
- Simple forms with validation
- No overwhelming colors or clutter
- Smooth transitions

## Features Implemented

### 1. Home Screen
- Time-based Hiligaynon greeting
- Feature cards with icons for:
  - Report an Issue
  - Book Appointment
  - Emergency Hotlines
  - Announcements
- Help information banner
- Bottom tab navigation

### 2. Reports
- **Reports List**: View all submitted reports (currently empty state)
- **New Report Form**:
  - Category dropdown (Roads, Flooding, Street Lights, Waste, Other)
  - Title field
  - Description textarea
  - Photo upload via camera
  - Submit button
  - Validation on all fields

### 3. Appointments
- **Appointments List**: View scheduled appointments (currently empty state)
- **Book Appointment Form**:
  - Office/department dropdown (City Hall, Licensing, etc.)
  - Full name field
  - Contact number field
  - Purpose of visit textarea
  - Date picker
  - Time slot selection (chip-based)
  - Submit button
  - Validation on all fields

### 4. Hotlines
- Emergency contacts list
- Call-to-action buttons using url_launcher
- Contact categories:
  - City Emergency Response (911)
  - City Health Office
  - Police Station
  - Fire Department
  - Disaster Risk Reduction
  - Roxas City Hall
- Warning banner about emergency use

### 5. Announcements
- City updates feed
- Sample announcements with:
  - Category icons (health, infrastructure, weather)
  - Color-coded types
  - Timestamps
  - Readable content with proper spacing

### 6. Profile
- User avatar placeholder
- Name and email display
- Settings options:
  - Edit Profile
  - Notifications
  - Help & Support
  - About MyRoxas
- Logout functionality with confirmation dialog
- App version display

### 7. AI Chat Support System (Niño) + Human Agent Handoff
- **AI Chat Assistant (Niño)**:
  - Client-side AI using Google Generative AI (Gemini 2.5 Flash Lite)
  - Multi-language support (English, Tagalog, Hiligaynon)
  - Trained on MyRoxas app features (Reports, Appointments, Hotlines, News)
  - Optimized for brevity (1-2 sentences for simple questions)
  - Modal bottom sheet interface with minimize/close options
  - Autocorrect and suggestions disabled for better UX
  
- **Human Agent Handoff Flow**:
  - User can request human agent from AI chat
  - REST API integration with https://myroxas.ph backend
  - Three endpoints:
    - `POST /api/support/conversations/request-agent` - Creates support request
    - `GET /api/support/conversations/{id}/queue-status` - Polls queue status
    - `POST /api/support/conversations/close` - Ends conversation
  - Queue system with position tracking and wait time estimates
  - Automatic polling every 10 seconds until agent joins
  - Retry logic (6 attempts / 1 minute) for backend delays
  
- **Stream Chat Integration** (Real-time Agent Messaging):
  - Stream Chat Flutter SDK v8.0.0
  - API Key: `8pggmzbbj58a` (production)
  - Channel type: `team` (open permissions for agent-user chat)
  - Automatic connection when agent accepts conversation
  - Token-based authentication (1-hour expiration with warnings)
  - Real-time bidirectional messaging via Stream Chat widgets:
    - `StreamMessageListView` for message display
    - `StreamMessageInput` for message composition
  - System messages for welcome and agent join events
  - Conditional UI rendering (AI chat ↔ Stream Chat)
  - Proper cleanup on dispose and token expiration
  
- **Token Management**:
  - 1-hour token expiration
  - Warning at 5 minutes remaining
  - Auto-disconnect on expiration
  - Manual close with confirmation dialog

- **Current Issues** 🚨:
  1. **UI Not Switching to Stream Chat**: Agent accepts conversation and backend confirms agent is added as channel member, but mobile UI remains on AI chat screen instead of switching to Stream Chat interface
  2. **Status Detection Working**: Queue polling correctly detects `with_agent` status
  3. **Connection Method Called**: `_connectToStreamChat()` is invoked when agent joins
  4. **State Update Unclear**: Need to verify if `_agentConnected` is being set to `true` and if `build()` is re-rendering with correct state
  5. **Detailed Logging Added**: Console logs now track full connection flow, member counts, channel state, and build state to identify where the UI switch is failing

## Technical Architecture

### Project Structure
```
lib/
├── core/
│   ├── auth/
│   │   └── auth_service.dart       # Supabase authentication
│   ├── config/
│   │   └── supabase_config.dart    # API keys & config
│   ├── navigation/
│   │   └── main_scaffold.dart      # Bottom nav wrapper
│   ├── router/
│   │   └── app_router.dart         # Go Router config
│   ├── services/
│   │   ├── gemini_service.dart     # Gemini AI integration
│   │   ├── supabase_service.dart   # Supabase client
│   │   └── ai_faq_service.dart     # AI FAQ & chat logic
│   └── theme/
│       ├── app_colors.dart         # Color constants
│       └── app_theme.dart          # Theme configuration
├── features/
│   ├── announcements/
│   │   └── screens/
│   │       └── announcements_screen.dart
│   ├── appointments/
│   │   └── screens/
│   │       ├── appointments_screen.dart
│   │       └── book_appointment_screen.dart
│   ├── auth/
│   │   └── screens/
│   │       ├── login_screen.dart
│   │       └── signup_screen.dart
│   ├── chat/
│   │   └── screens/
│   │       └── ai_chat_screen.dart # AI + Stream Chat UI
│   ├── common/
│   │   └── widgets/
│   │       ├── background_shape.dart
│   │       ├── circular_icon_button.dart
│   │       ├── feature_card.dart   # Reusable home card
│   │       ├── greeting_header.dart # Localized greeting
│   │       └── stats_card.dart
│   ├── home/
│   │   └── screens/
│   │       └── home_screen.dart
│   │   └── widgets/
│   │       └── news_carousel.dart
│   ├── hotlines/
│   │   └── screens/
│   │       └── hotlines_screen.dart
│   ├── profile/
│   │   └── screens/
│   │       └── profile_screen.dart
│   ├── reports/
│   │   └── screens/
│   │       ├── new_report_screen.dart
│   │       └── reports_screen.dart
│   └── splash/
│       └── screens/
│           └── splash_screen.dart
└── main.dart
```

### Dependencies
- **go_router** ^14.6.2 - Declarative routing with deep linking support
- **provider** ^6.1.2 - State management (for future use)
- **google_fonts** ^6.2.1 - Poppins and Inter fonts
- **image_picker** ^1.1.2 - Photo attachments for reports
- **url_launcher** ^6.3.1 - Phone call functionality
- **intl** ^0.19.0 - Date/time formatting
- **supabase_flutter** ^2.8.0 - Backend integration (Auth, Database, Storage)
- **http** ^1.2.2 - REST API calls for agent handoff
- **stream_chat_flutter** ^8.0.0 - Real-time agent chat messaging
- **google_generative_ai** ^0.4.7 - Gemini AI for Niño chat assistant

### Navigation
- Bottom tab navigation (5 tabs)
- Shell routes for main screens
- Full-screen routes for forms (reports, appointments)
- No transitions between tabs (instant switching)

### State Management
- Currently using StatefulWidget for local state
- Provider added for future app-wide state
- Forms use Form widget with validation

## UI Components

### Reusable Widgets
1. **FeatureCard** - Home screen navigation cards
2. **GreetingHeader** - Time-based localized greeting
3. **MainScaffold** - Bottom navigation wrapper
4. **_NavItem** - Custom bottom nav item
5. **_SettingsItem** - Profile settings list item

### Common Patterns
- Cards: 16px border radius, no elevation, 1px border
- Buttons: 12px border radius, 16px vertical padding
- Input fields: 12px border radius, proper labels and hints
- Icons: 24px default size, color-coded by context
- Spacing: 8, 12, 16, 20, 24, 32px multiples

## Backend Integration (Supabase)

### ✅ Completed
1. **Authentication System**
   - Supabase Auth configured with email/password
   - Session management and token handling
   - Login and signup screens implemented
   - Auth state persistence across app restarts
   - User profile metadata (full_name, contact_number)

2. **Database Setup**
   - Supabase project configured
   - Connection credentials updated
   - Reports database schema created and deployed

3. **AI Chat Support (Niño)**
   - Client-side Gemini AI integration (gemini-2.5-flash-lite)
   - Multi-language support (English, Tagalog, Hiligaynon)
   - MyRoxas app features knowledge base
   - Optimized response length for better UX

4. **Human Agent Handoff System**
   - REST API integration with https://myroxas.ph
   - Queue management with polling (10-second intervals)
   - Conversation state tracking (in_queue → with_agent → resolved)
   - Retry logic for backend delays (6 attempts / 1 minute)

5. **Stream Chat Real-time Messaging**
   - Stream Chat Flutter SDK v8.0.0 integrated
   - Token-based user authentication
   - Channel watching and member management
   - Event listeners for real-time message delivery
   - Token expiration handling (1 hour with warnings)
   - Conditional UI switching (AI chat ↔ Stream Chat)

### 🚧 In Progress / Issues
1. **Stream Chat UI Switching Issue** 🚨
   - **Problem**: UI not switching from AI chat to Stream Chat interface when agent accepts
   - **Backend Status**: ✅ Agent is added as channel member correctly
   - **Queue Detection**: ✅ Status change to `with_agent` detected
   - **Connection Method**: ✅ `_connectToStreamChat()` is called
   - **Unknown**: Whether `_agentConnected` state is properly updating and triggering rebuild
   - **Debug Tools Added**: Comprehensive logging for connection flow, channel state, member counts
   - **Next Steps**: Verify state update in `_connectToStreamChat()` and check if `build()` sees correct state

2. **Reports Feature** (Database Ready)
   - ✅ Database tables created:
     - `report_categories` - Admin-configurable categories (6 default categories)
     - `reports` - Main reports table with status tracking
     - `report_attachments` - Photo storage integration
     - `report_comments` - User and admin comments
     - `report_status_history` - Audit trail for status changes
   - ✅ Database functions and triggers implemented
   - ✅ Storage bucket created for report photos
   - ✅ Initial categories seeded (Public Works, Tricycle Fare, Safety, Environment, Health, Other)
   - 🚧 Flutter UI implementation pending
   - 🚧 Admin dashboard (web) pending

### 📋 Planned Features
3. **Appointments**
   - [ ] Database schema design
   - [ ] Real-time slot availability
   - [ ] Booking confirmation
   - [ ] SMS/Email reminders
   - [ ] Admin dashboard for appointment management

4. **Announcements**
   - [ ] Database schema design
   - [ ] Real-time updates
   - [ ] Push notifications
   - [ ] Read status tracking
   - [ ] Admin dashboard for posting announcements

5. **Hotlines**
   - [ ] Dynamic contact list from database
   - [ ] Emergency escalation workflow
   - [ ] Call logging

### Additional Features
- [ ] Push notifications (FCM integration)
- [ ] Offline support (local caching)
- [ ] Multi-language (English/Hiligaynon toggle)
- [ ] Document upload (PDF, images)
- [ ] Payment integration (GCash, PayMaya)
- [ ] Feedback/rating system
- [ ] Analytics dashboard
- [ ] Admin web dashboard (React/Next.js)

## Development Guidelines

### Code Style
- Use const constructors wherever possible
- Keep widgets small and focused
- Extract reusable components
- Add comments for clarity
- Follow feature-first organization

### Naming Conventions
- Files: snake_case (e.g., `home_screen.dart`)
- Classes: PascalCase (e.g., `HomeScreen`)
- Variables: camelCase (e.g., `selectedDate`)
- Private members: _camelCase (e.g., `_formKey`)

### Form Validation
- All required fields have validators
- Show friendly error messages
- Validate on submit, not on change
- Use TextFormField for all inputs

### Color Usage
- Primary actions: Capiz Blue
- Secondary/warm: Capiz Gold
- Success: Green
- Warning: Orange
- Error: Red (soft tone)
- Info: Blue (lighter)

## Testing
- Basic smoke test implemented
- Verifies app loads with greeting
- Ready for expanded test coverage

## Reports Feature Implementation Plan

### Phase 1: Flutter Integration (Mobile App) - NEXT
1. Create Dart models for reports data
2. Set up Supabase client in Flutter
3. Implement repository/service layer
4. Build report submission flow
   - Fetch categories from database
   - Photo upload to Supabase Storage
   - Form submission to reports table
5. Build reports list screen
   - Fetch user's reports
   - Display status badges
   - Real-time status updates
6. Build report details screen
   - View full report with attachments
   - View comments thread
   - Add follow-up comments
   - View status history

### Phase 2: Admin Dashboard (Web) - IN PROGRESS
1. Set up React/Next.js project
2. Integrate Supabase JavaScript client
3. Implement admin authentication
4. Build reports dashboard
   - List all reports with filters
   - Search and sort functionality
   - Real-time updates
5. Build report details page
   - Update report status
   - Assign to staff
   - Add admin comments
   - Upload response photos
6. Build category management
   - CRUD operations for categories
   - Reorder categories
7. Build analytics dashboard
   - Reports by status/category
   - Resolution time metrics
   - Location-based statistics

### Phase 3: Testing & Deployment
1. Test mobile app with real data
2. Test admin dashboard workflows
3. Set up staging environment
4. User acceptance testing
5. Production deployment
6. Monitor and optimize

## Documentation

- **BLUEPRINT.md** - This file, comprehensive project overview
- **Reports Database Schema**: `REPORTS_DATABASE_SCHEMA.md` - Complete SQL schema for mobile dev team
- **Web Team Documentation**: `WEB_TEAM_REPORTS_DOCUMENTATION.md` - Supabase integration guide for web developers
- **Chat Support Issues**: 
  - `ISSUE_FOR_WEB_TEAM.md` - Initial 404 error report (resolved: database join issue)
  - `URGENT_ISSUE_STREAM_CHAT_NOT_RECEIVING.md` - Agent messages not received (resolved: agent not added as channel member)
  - `RESPONSE_TO_MOBILE_TEAM.md` - Backend fix for queue-status 404 error
  - `MOBILE_TEAM_STREAM_CHAT_UPDATE.md` - Agent join flow improvements and system messages
  - `RESPONSE_STREAM_CHAT_MESSAGE_ISSUE.md` - Backend fix for agent member addition
- **Team Instructions**: `MOBILE_APP_TEAM_INSTRUCTIONS copy.md` - Web team's Stream Chat integration guide

## Technical Decisions & Lessons Learned

### Stream Chat Integration Challenges
1. **Initial 404 Error**: Queue-status endpoint had problematic database join (`user_profiles!user_id`). Fixed by removing join and fetching data separately.

2. **Agent Not Added as Member**: Backend was failing to add agent to Stream Chat channel due to missing `created_by_id` parameter. Fixed by:
   ```typescript
   const channel = client.channel('team', channelId, {
     created_by_id: createdById  // Required for server-side queries
   });
   await channel.addMembers([agentId]);
   ```

3. **Current UI Switching Issue**: Mobile app's Stream Chat integration is correct (verified), but UI may not be switching from AI chat to Stream Chat interface when agent connects. Debugging with extensive logging to identify state update issue.

### Best Practices Established
- **Error Handling**: Never fail silently - backend should throw errors if critical operations (like adding agent to channel) fail
- **Retry Logic**: Mobile apps should retry transient failures (implemented 6-attempt retry for 404s)
- **Detailed Logging**: Both client and server should log key events (connection, member addition, status changes) for debugging
- **Token Management**: Implement expiration warnings before tokens expire to prevent sudden disconnections
- **State Validation**: Always validate critical state (e.g., `_agentConnected`, `_streamChannel`, `_streamChatClient`) before rendering dependent UI

### Code Patterns
1. **Conditional UI Rendering**:
   ```dart
   if (_agentConnected && _streamChannel != null && _streamChatClient != null) {
     return StreamChat(client: _streamChatClient!, child: StreamChannel(...));
   }
   // else return AI chat UI
   ```

2. **Stream Chat Connection**:
   ```dart
   _streamChatClient = StreamChatClient(apiKey, logLevel: Level.INFO);
   await _streamChatClient!.connectUser(User(id: userId), token);
   _streamChannel = _streamChatClient!.channel('team', id: channelId);
   await _streamChannel!.watch();
   ```

3. **Event Listening**:
   ```dart
   _streamChannel!.on().listen((event) {
     if (event.message != null) {
       // Handle new message
     }
   });
   ```

## Known Issues & Troubleshooting

### Current Blocker 🚨
**Issue**: UI not switching to Stream Chat when agent accepts conversation

**What's Working**:
- ✅ Backend adds agent as channel member
- ✅ Queue polling detects `with_agent` status
- ✅ `_connectToStreamChat()` is called
- ✅ No connection errors in logs

**What's Unknown**:
- ❓ Is `setState(() { _agentConnected = true; })` executing?
- ❓ Is `build()` being called after state update?
- ❓ Are all three conditions (`_agentConnected && _streamChannel != null && _streamChatClient != null`) true?

**Debug Steps Added**:
- Comprehensive logging in `_connectToStreamChat()` method
- Build method now logs all state variables on each render
- Queue polling logs when status changes to `with_agent`

**Next Actions**:
1. Run app and request agent
2. Check console for: `🎯 Setting _agentConnected = true`
3. Check console for: `🔍 Build called - _agentConnected: true, _streamChannel: true, _streamChatClient: true`
4. If state is correct but UI doesn't switch, investigate `StreamChat` widget initialization
5. If state is incorrect, investigate async execution order in `_connectToStreamChat()`

### Resolved Issues ✅
1. **404 on queue-status** - Fixed by removing problematic database join
2. **Agent messages not received** - Fixed by properly adding agent as channel member with `created_by_id`
3. **Token expiration** - Implemented warning system at 5 minutes and auto-disconnect
4. **Import conflicts** - Resolved `User` class conflict by hiding from `supabase_flutter`

## Next Immediate Steps
1. 🚨 **URGENT: Fix Stream Chat UI switching issue**
   - Debug with new logging to identify state update problem
   - Verify `_agentConnected` is being set to `true`
   - Ensure `build()` is re-rendering with correct state
2. Test complete agent handoff flow end-to-end
3. Implement Flutter reports UI (submit, list, details screens)
4. Begin admin dashboard development
5. Implement remaining features (Appointments, Announcements)

---

**Version**: 1.2.0  
**Last Updated**: November 23, 2025  
**Status**: AI Chat + Agent Handoff implemented, Stream Chat UI switching issue under investigation

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

## Technical Architecture

### Project Structure
```
lib/
├── core/
│   ├── navigation/
│   │   └── main_scaffold.dart      # Bottom nav wrapper
│   ├── router/
│   │   └── app_router.dart         # Go Router config
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
│   ├── common/
│   │   └── widgets/
│   │       ├── feature_card.dart   # Reusable home card
│   │       └── greeting_header.dart # Localized greeting
│   ├── home/
│   │   └── screens/
│   │       └── home_screen.dart
│   ├── hotlines/
│   │   └── screens/
│   │       └── hotlines_screen.dart
│   ├── profile/
│   │   └── screens/
│   │       └── profile_screen.dart
│   └── reports/
│       └── screens/
│           ├── new_report_screen.dart
│           └── reports_screen.dart
└── main.dart
```

### Dependencies
- **go_router** ^14.6.2 - Declarative routing with deep linking support
- **provider** ^6.1.2 - State management (for future use)
- **google_fonts** ^6.2.1 - Poppins and Inter fonts
- **image_picker** ^1.1.2 - Photo attachments for reports
- **url_launcher** ^6.3.1 - Phone call functionality
- **intl** ^0.19.0 - Date/time formatting

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
1. **Database Setup**
   - Supabase project configured
   - Connection credentials updated
   - Reports database schema created and deployed

### 🚧 In Progress
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
   - [ ] Submit report with photo upload
   - [ ] Track report status in real-time
   - [ ] View report history
   - [ ] Push notifications for status updates

### 📋 Planned Features
3. **Authentication**
   - [ ] User signup/login with Supabase Auth
   - [ ] Session management
   - [ ] Password reset
   - [ ] Profile management

4. **Appointments**
   - [ ] Database schema design
   - [ ] Real-time slot availability
   - [ ] Booking confirmation
   - [ ] SMS/Email reminders
   - [ ] Admin dashboard for appointment management

5. **Announcements**
   - [ ] Database schema design
   - [ ] Real-time updates
   - [ ] Push notifications
   - [ ] Read status tracking
   - [ ] Admin dashboard for posting announcements

6. **Hotlines**
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

- **Reports Database Schema**: `REPORTS_DATABASE_SCHEMA.md` - Complete SQL schema for mobile dev team
- **Web Team Documentation**: `WEB_TEAM_REPORTS_DOCUMENTATION.md` - Supabase integration guide for web developers

## Next Immediate Steps
1. ✅ Database schema created and deployed
2. **→ Implement Flutter reports UI** (submit, list, details screens)
3. Connect Flutter app to Supabase
4. Test report submission flow
5. Begin admin dashboard development
6. Implement remaining features (Auth, Appointments, Announcements)

---

**Version**: 1.1.0  
**Last Updated**: November 20, 2025  
**Status**: Reports database ready, Flutter UI implementation in progress

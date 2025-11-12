# MyRoxas

**City Government Services for Roxas City**

MyRoxas is a modern civic app that connects Roxasnons with their city government. It provides an easy, friendly way to report issues, book appointments, access emergency hotlines, and stay updated with city announcements.

## Features

- **Report Issues** - Submit concerns about roads, flooding, or local problems with photos
- **Book Appointments** - Schedule visits to city offices for permits, licensing, and services
- **Emergency Hotlines** - Quick access to important contact numbers
- **Announcements** - Stay updated with city news and advisories
- **User Profile** - Manage your account and settings

## Design Philosophy

MyRoxas is designed to feel calm, modern, and trustworthy:

- Clean layouts with soft colors inspired by the Capiz provincial seal
- Deep blue for trust and stability
- Gold accents for warmth and service
- Simple, friendly language
- Easy navigation with bottom tabs

## Getting Started

### Prerequisites

- Flutter SDK (3.9.0 or higher)
- Dart SDK

### Installation

1. Clone the repository
```bash
git clone https://github.com/juanpaynor/gov_app.git
cd gov_app
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

## Project Structure

```
lib/
├── core/              # Core app functionality
│   ├── navigation/    # Bottom navigation and routing
│   ├── router/        # Go Router configuration
│   └── theme/         # App theme and colors
├── features/          # Feature modules
│   ├── home/          # Home screen
│   ├── reports/       # Issue reporting
│   ├── appointments/  # Appointment booking
│   ├── hotlines/      # Emergency contacts
│   ├── announcements/ # Provincial updates
│   ├── profile/       # User profile
│   └── common/        # Shared widgets
└── main.dart          # App entry point
```

## Technologies Used

- **Flutter** - UI framework
- **go_router** - Declarative routing
- **provider** - State management
- **google_fonts** - Typography (Poppins & Inter)
- **image_picker** - Photo attachments
- **url_launcher** - Phone calls
- **intl** - Date/time formatting

## Future Plans

- Supabase backend integration
- Push notifications for announcements
- User authentication
- Real-time status updates for reports and appointments
- Multi-language support (English & Hiligaynon)

## Contributing

This is a government service app for Roxas City, Capiz. For contributions or inquiries, please contact the development team.

## License

Copyright © 2025 City of Roxas, Capiz

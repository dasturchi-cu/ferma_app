# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is **ferma_app** - a Flutter-based chicken farm management application written in Uzbek language. The app is designed for managing chicken farms with features for tracking egg production, managing customers, debt records, and generating reports. It uses Supabase as the backend with local Hive storage for offline functionality.

**Core Purpose**: Professional chicken farm management tool for tracking daily operations, customer relationships, and financial records.

**Target Platforms**: Android, iOS, Web, Desktop (Flutter multi-platform)

## Common Development Commands

### Basic Flutter Commands
```bash
# Install dependencies
flutter pub get

# Run code generation for models (JSON serialization)
flutter packages pub run build_runner build

# Clean and regenerate generated files
flutter packages pub run build_runner clean
flutter packages pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run                    # Debug mode on connected device
flutter run -d chrome          # Web version in Chrome
flutter run --release          # Release mode
flutter run -t lib/main.dart   # Explicit main file

# Build for production
flutter build apk              # Android APK
flutter build appbundle        # Android App Bundle
flutter build ios              # iOS build
flutter build web              # Web build

# Testing
flutter test                   # Run unit tests
flutter integration_test       # Run integration tests

# Code analysis and formatting  
flutter analyze                # Static analysis
flutter format lib/           # Format code
```

### Development Workflow
```bash
# After making changes to model files with @JsonSerializable
flutter packages pub run build_runner build

# When working with new dependencies
flutter pub get
flutter clean
flutter pub get

# Generate app icons and splash screens
flutter pub run flutter_launcher_icons:main
flutter pub run flutter_native_splash:create
```

## Code Architecture

### High-Level Architecture Pattern
The app follows a **Provider-based state management** pattern with clean separation of concerns:

**State Management**: Provider pattern with two main providers:
- `AuthProvider`: Manages user authentication and farm data loading
- `FarmProvider`: Handles farm operations, real-time updates, and local persistence

**Data Flow**:
1. **Supabase Backend** ↔ **Providers** ↔ **UI Screens**
2. **Local Storage (Hive)** ↔ **Providers** (for offline functionality)
3. **Real-time Streams** → **FarmProvider** → **UI Updates**

### Key Architectural Components

**Models** (`lib/models/`):
- All models use `@JsonSerializable` and `@HiveType` for JSON and local storage
- Core models: `Farm`, `Chicken`, `Egg`, `Customer`, `DailyRecord`
- Generated files (`.g.dart`) handle serialization automatically

**Providers** (`lib/providers/`):
- `AuthProvider`: Authentication state, farm loading, user session management
- `FarmProvider`: Farm operations, real-time subscriptions, offline sync

**Services** (`lib/services/`):
- `SupabaseConfig`: Centralized Supabase client configuration
- `StorageService`: Hive-based local storage with offline mode support
- `DatabaseService`: Database operations wrapper
- Various utility services for notifications, exports, biometrics

**Screens Structure**:
- `main/`: Dashboard and main navigation
- `auth/`: Login and authentication flows  
- `eggs/`, `chickens/`, `customers/`, `debts/`: Feature-specific screens
- `analytics/`: Reports and statistics

### Database Architecture

**Primary Data Storage**: Supabase PostgreSQL with optional granular tables for real-time features

**Required Table**: `farms` - JSONB-based storage for all farm data
**Optional Tables**: `egg_productions`, `customers` - for enhanced real-time streams

**Offline Strategy**: 
- Hive local storage mirrors Supabase data structure
- App gracefully handles missing Supabase tables
- Falls back to main `farms` table if granular tables unavailable

**Real-time Features**:
- Supabase real-time subscriptions for live updates
- Multiple stream subscriptions managed in `FarmProvider`
- Automatic fallback to local storage on network issues

### Navigation Structure

**Main Navigation**: `MainScreen` with `IndexedStack` and drawer navigation
- Dashboard (index 0): Main farm statistics and quick actions
- Customers (index 1): Customer management
- Eggs (index 2): Egg production and sales tracking  
- Reports (index 3): Analytics and reports
- Debts (index 4): Debt ledger management

**Route Structure**:
- `/login`: Authentication screen
- `/home`: Main screen (default after login)
- Feature screens accessible via main navigation tabs

### State Management Flow

**Authentication Flow**:
1. `AuthProvider` monitors Supabase auth state changes
2. Auto-loads farm data when user authenticates
3. Creates new farm if none exists for user
4. Maintains session across app lifecycle

**Data Persistence Flow**:
1. User actions trigger provider methods
2. Data updated in memory (immediate UI update)
3. Saved to Supabase (cloud sync)
4. Saved to Hive (offline backup)
5. Real-time subscriptions update other clients

**Offline Mode**:
- App detects connectivity and switches to offline mode
- All operations continue with local Hive storage
- Data syncs automatically when connectivity restored

## Key Implementation Details

**Error Handling**: Comprehensive error handling with graceful degradation
- Database errors logged as warnings, not crashes
- Fallback to local storage on network issues
- User-friendly error messages in Uzbek

**Localization**: App uses Uzbek language throughout
- All UI text, error messages, and user interactions in Uzbek
- Consider this when making UI changes or adding features

**Build Configuration**: 
- Uses `build_runner` for code generation (models, serialization)
- Icon and splash screen generation configured in `pubspec.yaml`
- Analysis options configured for Flutter best practices

**Real-time Architecture**:
- Multiple Supabase stream subscriptions in `FarmProvider`
- Proper subscription cleanup on provider disposal
- Handles missing tables gracefully with error logging

This architecture provides robust offline capability, real-time sync, and scalable state management for a production farm management application.
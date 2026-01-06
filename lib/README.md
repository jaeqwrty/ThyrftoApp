# Project Structure

This document explains the organization of the Thryfto app codebase.

## Directory Structure

```
lib/
├── core/                          # Core application infrastructure
│   ├── constants/                 # App-wide constants
│   │   ├── app_colors.dart        # Color theme definitions
│   │   ├── app_constants.dart     # General app constants
│   │   └── app_text_styles.dart   # Text style definitions
│   │
│   ├── providers/                 # Riverpod state management providers
│   │   ├── auth_providers.dart    # Authentication state providers
│   │   ├── chat_providers.dart    # Chat state providers
│   │   ├── home_providers.dart    # Home feed providers
│   │   └── notification_providers.dart  # Notification providers
│   │
│   ├── services/                  # Business logic and API services
│   │   ├── auth_service.dart      # Authentication service
│   │   ├── chat_service.dart      # Chat/messaging service
│   │   ├── database_service.dart  # Firestore database service
│   │   ├── notification_service.dart  # Notification service
│   │   ├── location_service.dart  # Location services
│   │   └── ...                    # Other services
│   │
│   └── utils/                     # Utility functions and helpers
│       ├── snackbar_utils.dart    # Standardized snackbar messages
│       ├── input_decorations.dart # Reusable input decorations
│       ├── common_dialogs.dart    # Common dialog implementations
│       ├── common_modals.dart     # Common modal implementations
│       ├── common_decorations.dart # Reusable decorations
│       └── loading_indicators.dart # Loading indicator widgets
│
├── features/                      # Feature-based organization
│   ├── auth/                      # Authentication feature
│   │   ├── pages/
│   │   │   ├── login_page.dart
│   │   │   ├── signup_page.dart
│   │   │   ├── forgot_password_page.dart
│   │   │   └── onboarding_page.dart
│   │   └── widgets/
│   │       └── auth_widgets.dart  # Auth-specific widgets
│   │
│   ├── chat/                      # Chat/Messaging feature
│   │   ├── pages/
│   │   │   ├── chat_page.dart     # Chat list page
│   │   │   └── conversation_page.dart  # Individual conversation
│   │   └── widgets/
│   │       ├── message_list.dart
│   │       ├── messages_bubble.dart
│   │       └── messages_input.dart
│   │
│   ├── home/                      # Home feed feature
│   │   ├── pages/
│   │   │   ├── home_page.dart     # Main home feed
│   │   │   └── notification_page.dart  # Notifications
│   │   └── widgets/
│   │       └── home_widgets.dart  # PostCard and feed widgets
│   │
│   ├── listings/                  # Product listings feature
│   │   ├── pages/
│   │   │   ├── listing_detail_page.dart  # View listing details
│   │   │   ├── sell_page.dart     # Create new listing
│   │   │   ├── edit_listing_page.dart  # Edit existing listing
│   │   │   └── set_location_page.dart  # Set item location
│   │   └── widgets/
│   │       ├── listing_form_fields.dart  # Reusable form fields
│   │       └── listing_form_widgets.dart # Form helper widgets
│   │
│   ├── profile/                   # User profile feature
│   │   ├── pages/
│   │   │   ├── profile_page.dart       # Own profile view
│   │   │   ├── edit_profile_page.dart  # Edit profile
│   │   │   ├── profile_setup_page.dart # Initial profile setup
│   │   │   ├── user_profile_page.dart  # View other user profiles
│   │   │   ├── user_follow_page.dart   # Followers/following lists
│   │   │   └── blocked_users_page.dart # Blocked users management
│   │   └── widgets/
│   │       ├── profile_widgets.dart      # Profile UI components
│   │       ├── user_profileWidgets.dart  # User profile components
│   │       ├── profile_dialogs.dart      # Profile-related dialogs
│   │       └── profile_settings_handler.dart  # Settings logic
│   │
│   └── search/                    # Search feature
│       └── search_page.dart       # Search and filters
│
├── shared/                        # Shared across features
│   ├── models/                    # (Future: Data models)
│   ├── widgets/                   # Truly shared widgets
│   │   ├── app_logo.dart          # App logo widget
│   │   ├── auth_wrapper.dart      # Auth state wrapper
│   │   ├── category_condition_selection.dart
│   │   ├── comments_widget.dart   # Comments UI
│   │   ├── comments_modal.dart    # Comments modal
│   │   ├── custom_elevated_button.dart
│   │   ├── custom_textfield.dart
│   │   ├── empty_state.dart       # Empty state UI
│   │   ├── error.dart             # Error widgets
│   │   ├── image_placeholder.dart
│   │   ├── main_navigation.dart   # Bottom navigation
│   │   ├── notification_bell.dart # Notification bell icon
│   │   ├── search_bar.dart        # Search bar widget
│   │   ├── section_labels.dart
│   │   ├── share_modal.dart       # Share functionality
│   │   ├── tag.dart               # Tag widgets
│   │   └── user_avatar.dart       # User avatar widget
│   │
│   └── shared.dart                # Barrel export for shared utilities
│
├── main.dart                      # App entry point
└── firebase_options.dart          # Firebase configuration
```

## Architecture Principles

### 1. Feature-Based Organization
- Related pages and widgets are grouped by feature (auth, chat, profile, etc.)
- Makes it easy to find and understand code for a specific feature
- Reduces coupling between features

### 2. Core Infrastructure
- **Constants**: App-wide theming and configuration
- **Providers**: Riverpod state management (follows DRY principle)
- **Services**: Business logic separated from UI
- **Utils**: Reusable utility functions and helper widgets

### 3. Shared Resources
- Truly shared widgets that are used across multiple features
- Avoids duplication while maintaining clear boundaries

### 4. DRY Principle (Don't Repeat Yourself)
- `snackbar_utils.dart`: Standardized success/error/info messages
- `input_decorations.dart`: Consistent TextField styling
- `listing_form_fields.dart`: Reusable listing form components
- Riverpod providers: Centralized state management

## Import Guidelines

### Importing from Core
```dart
// Constants
import 'package:thryfto/core/constants/app_colors.dart';
import 'package:thryfto/core/constants/app_constants.dart';

// Services
import 'package:thryfto/core/services/auth_service.dart';
import 'package:thryfto/core/services/database_service.dart';

// Providers
import 'package:thryfto/core/providers/auth_providers.dart';

// Utils
import 'package:thryfto/core/utils/snackbar_utils.dart';
import 'package:thryfto/core/utils/common_modals.dart';
```

### Importing from Features
```dart
// Auth
import 'package:thryfto/features/auth/pages/login_page.dart';
import 'package:thryfto/features/auth/widgets/auth_widgets.dart';

// Profile
import 'package:thryfto/features/profile/pages/profile_page.dart';
import 'package:thryfto/features/profile/widgets/profile_widgets.dart';

// Listings
import 'package:thryfto/features/listings/pages/listing_detail_page.dart';
import 'package:thryfto/features/listings/widgets/listing_form_fields.dart';
```

### Importing Shared Resources
```dart
// Shared widgets
import 'package:thryfto/shared/widgets/main_navigation.dart';
import 'package:thryfto/shared/widgets/user_avatar.dart';

// Barrel export (imports all shared utilities)
import 'package:thryfto/shared/shared.dart';
```

## Benefits of This Structure

1. **Better Navigation**: Easy to find files by feature
2. **Clear Separation**: UI (pages/widgets) separated from logic (services/providers)
3. **Reduced Duplication**: Shared utilities avoid code repetition
4. **Scalability**: Easy to add new features without affecting existing code
5. **Maintainability**: Clear boundaries make updates safer
6. **Team Collaboration**: Multiple developers can work on different features with minimal conflicts

## Migration Notes

All imports have been automatically updated to reflect the new structure. The functionality and UI remain unchanged.

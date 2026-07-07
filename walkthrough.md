# FireShield AI - Commercial SaaS Walkthrough

Welcome to **FireShield AI**, an industry-ready commercial application built on a modern enterprise Flutter architecture, following Clean Architecture principles.

## 1. Project Architecture
The codebase strictly adheres to the **Feature-First Clean Architecture**:
- **Domain Layer**: Contains business logic, models (`DeviceModel`, `NotificationModel`), and abstract repository contracts.
- **Data Layer**: Implements the repositories (`MockAuthRepository`, `FirestoreDeviceRepository`) to manage Firebase, APIs, and hardware IoT bridges.
- **Presentation Layer**: 
  - Segmented strictly by features (`auth`, `dashboard`, `device`, `map`, `settings`).
  - Utilizes **Riverpod** for declarative, predictable state management.
  - Implements **GoRouter** for scalable navigation, deeply supporting web/deep-linking and `ShellRoute` for the persistent bottom navigation bar.

## 2. Core Features Built
### Authentication (`Milestone 2`)
A fully designed authentication flow supporting Email/Password login, Signup, and Forgot Password, protected by form validation and responsive to network states.

### Dashboard (`Milestone 3`)
A glassmorphism-inspired UI featuring an alert banner that reacts dynamically to hardware statuses. Includes an "At-a-Glance" grid of connected IoT hardware sensors showing realtime data.

### Device Management (`Milestone 4`)
Displays a comprehensive list of registered fire detection devices. You can view deep diagnostic details (battery, wifi, temperature) for each device.

### Real-Time Charts (`Milestone 5`)
Integrated `fl_chart` to render real-time temperature and CO (Carbon Monoxide) readings in the `DeviceDetailsScreen` for continuous hardware monitoring.

### Live Maps (`Milestone 6`)
Integrated `google_maps_flutter` to plot device locations. Real-time markers color-code devices based on their online status or battery alerts, bridging hardware status to a geographical view.

### Settings & User Profile (`Milestone 8`)
Provides user account management, notification preferences, and a dark/light mode theme toggle structure to ensure a premium user experience.

### Backend Foundations & Hardware Bridge (`Milestone 9 & 10`)
Created abstract data contracts and fail-safe implementations using Streams. The UI is 100% reactive. When the real ESP32 hardware and Firebase backend are connected, the UI requires **zero changes**—it simply listens to the new data streams.

## 3. UI/UX Design (Material 3)
- Fully implemented using Material 3 `ColorScheme`.
- Employs smooth Hero animations, gradient backgrounds, and premium Glassmorphism styling (`AnimatedCard`, `SensorCard`).
- Standardized UI components (e.g., `CustomTextField`, `PrimaryButton`) for a cohesive brand identity.

## Next Steps for Production
1. Go to the [Firebase Console](https://console.firebase.google.com/), create a project, and run `flutterfire configure`.
2. Swap out the `MockDeviceRepository` for the real `FirestoreDeviceRepository` in `repository_providers.dart`.
3. Integrate the proprietary ESP32 hardware SDK into `HardwareProtocolRepository` to start ingesting live sensor data!

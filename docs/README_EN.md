# Starbucks Official App Clone (English)

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.38.5-blue?style=for-the-badge&logo=flutter"/>
  <img alt="Dart" src="https://img.shields.io/badge/Dart-%3E%3D3.10.0-blue?style=for-the-badge&logo=dart"/>
  <img alt="Supabase" src="https://img.shields.io/badge/Supabase-BaaS-green?style=for-the-badge&logo=supabase"/>
  <img alt="Firebase" src="https://img.shields.io/badge/Firebase-Analytics%20%26%20Push-orange?style=for-the-badge&logo=firebase"/>
</p>

## 📖 Project Overview

A comprehensive Flutter application that faithfully recreates the Starbucks official mobile app. This project implements all major features including **mobile ordering, payments, store locator, and rewards program**, demonstrating enterprise-level mobile development practices and architectural patterns.

**Portfolio Highlights:**
- 🏗️ **Riverpod 3.0** - Modern state management architecture
- 🔐 **Security-First** design (SSL Pinning, authentication, encryption)
- 📱 **Native Integration** (location services, push notifications, biometric auth)
- ⚡ **High Performance** (efficient data caching, real-time updates)
- 🧪 **Quality Assurance** (comprehensive test suite, CI/CD)

## ✨ Key Features

### 🔐 Authentication & User Management
- **Google OAuth Authentication** - Secure user authentication via Supabase integration
- **Biometric Authentication** - Touch ID / Face ID support
- **Account Management** - Profile editing, email settings, nickname management

### 📱 Mobile Ordering System
- **Product Catalog** - Category-based product display, detailed information, customization options
- **Shopping Cart** - Add/remove items, quantity adjustment, cart persistence
- **Order Customization** - Size, temperature, additional options selection
- **Pickup Methods** - Dine-in, takeout, drive-thru support
- **Order History** - Past order review, reorder functionality

### 💳 Payment & Points System
- **Starbucks Card** - Balance management, top-up functionality
- **Star Points** - Earn through purchases, redeem rewards
- **Payment Methods** - Card payments, points usage
- **Ticket Management** - eTicket issuance, usage history

### 🗺️ Store Search & Maps
- **Location Services** - Distance calculation from current location
- **Store Details** - Business hours, facility information, access details
- **Favorite Stores** - Store bookmarking functionality
- **Google Maps Integration** - Interactive map display

### 🎁 Gifts & Promotions
- **eGift Features** - Digital gift sending
- **Campaigns** - Limited-time offer displays
- **New Product Info** - Product release notifications

### 📧 Notifications & Communication
- **Push Notifications** - Order status, campaign information
- **Inbox** - In-app message management

## 🛠️ Technology Stack

### Frameworks & Languages
| Technology | Version | Purpose |
|------------|---------|---------|
| **Flutter** | 3.38.5 | UI Framework |
| **Dart** | >=3.10.0 | Programming Language |
| **FVM** | Latest | Flutter Version Management |

### Backend & Database
| Technology | Purpose |
|------------|---------|
| **Supabase** | BaaS (Authentication, Database, Storage) |
| **PostgreSQL** | Relational Database |
| **Row Level Security** | Advanced security policies |

### State Management & Architecture
| Technology | Purpose |
|------------|---------|
| **Riverpod 3.0** | State management (using Notifier API) |
| **go_router** | Declarative routing |
| **get_it** | Dependency injection |

### External Services & APIs
| Service | Purpose |
|---------|---------|
| **Firebase** | Analytics, Crashlytics, Performance, Push notifications |
| **Google Maps** | Map display, location services |
| **Google Sign-In** | OAuth authentication |

### Security & Quality
| Technology/Method | Purpose |
|-------------------|---------|
| **SSL Pinning** | Network security |
| **flutter_secure_storage** | Encrypted sensitive data storage |
| **local_auth** | Biometric authentication |
| **MobSF** | Security scanning |

## 🏗️ Project Structure

```
lib/
├── app/                    # Application initialization
├── config/                 # Configuration & routing
├── constants/              # Constant definitions
├── core/                   # Core models & services
│   ├── models/             # Data models
│   └── services/           # Core services
├── data/repository/        # Data access layer
├── provider/               # Riverpod Provider definitions
├── screens/                # Screen implementations
│   ├── starbucks_user_side/    # User-facing screens
│   └── starbucks_store_side/   # Store-side screens (QR scanner, etc.)
├── services/               # Business logic
└── shared/                 # Shared widgets & utilities
```

### Riverpod 3.0 Architecture Example

```dart
@riverpod
class AuthState extends _$AuthState {
  @override
  User? build() {
    return null;
  }

  Future<void> signIn(String email, String password) async {
    // Authentication logic implementation
    state = await authRepository.signIn(email, password);
  }
}

// Usage example
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return authState != null 
      ? HomeScreen() 
      : SignInForm();
  }
}
```

## 🚀 Development Environment Setup

### Requirements
- Flutter 3.38.5 (FVM management recommended)
- Dart >=3.10.0
- Android Studio / Xcode
- Firebase project
- Supabase project

### Setup Instructions

1. **Clone Repository**
```bash
git clone https://github.com/eno-conan/flutter-starbucks-clone.git
cd flutter-starbucks-clone
```

2. **FVM Setup**
```bash
# Install FVM
dart pub global activate fvm

# Apply project Flutter version
fvm install
fvm use --force
```

3. **Install Dependencies**
```bash
fvm flutter pub get
```

4. **Environment Configuration**
```bash
# Firebase configuration
flutterfire configure

# Supabase configuration (environment variables)
cp .env.example .env
# Edit .env file to add Supabase credentials
```

5. **Run Application**
```bash
# Debug run
fvm flutter run

# Release build
fvm flutter build apk --release
```

## 🧪 Quality Assurance & Testing

### Testing Strategy
- **Unit Tests** - Business logic, utility functions
- **Widget Tests** - UI components
- **Integration Tests** - Screen flows, API integration
- **Golden Tests** - UI regression testing

### Code Quality
```bash
# Static analysis
fvm flutter analyze

# Format
fvm flutter format .

# Run tests
fvm flutter test

# Coverage measurement
fvm flutter test --coverage
```

## 🔐 Security Measures

- **SSL Certificate Pinning** - Man-in-the-middle attack prevention
- **Encrypted Storage** - Secure storage of sensitive data
- **API Authentication** - JWT token-based authentication
- **Input Validation** - SQL injection prevention
- **OWASP Mobile Top 10** compliance
- **MobSF Security Scanning** - Regular security assessments

## 📊 Performance & Monitoring

- **Firebase Performance** - App performance monitoring
- **Crashlytics** - Error tracking & analysis
- **Data Caching** - Offline support & acceleration
- **Image Optimization** - WebP format, lazy loading

## 📚 Documentation

For detailed development documentation, refer to:

| Document | Content |
|----------|---------|
| [Development Environment Setup](project/setup.md) | FVM, dependency management, environment variables, secret settings |
| [Testing](project/testing.md) | Test execution, coverage, Golden test |
| [CI/CD](project/cicd.md) | GitHub Actions workflow details |
| [Firebase](project/firebase.md) | App Distribution, App Links |
| [Supabase](project/supabase.md) | Local development, Edge Functions, Google authentication |
| [Security](project/security.md) | MobSF, security best practices |

## 🎯 Technical Highlights

### Enterprise-Level Development
- **Clean Architecture** - Testable design through layer separation
- **SOLID Principles** - Maintainable code structure
- **Type Safety** - Leveraging Dart's powerful type system
- **Error Handling** - Comprehensive error processing and user feedback

### Mobile Optimization
- **Responsive Design** - Support for various screen sizes
- **Native Feature Utilization** - Proper integration of platform-specific features
- **Battery Efficiency** - Location service optimization
- **Offline Functionality** - Proper behavior during network disconnection

---

**This project was created as a portfolio piece to demonstrate modern mobile development technologies and best practices, referencing the actual Starbucks official app.**
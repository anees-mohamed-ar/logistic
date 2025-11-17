# Multi-Company Setup for Logistics App

This document explains how the app is configured to support multiple companies with different branding and PDF templates.

## Companies

The app supports two companies:

1. **Sri Krishna Cargo Corporation** (Company ID: 7)
   - App ID: com.example.logistic.cargo
   - PDF Template: gc_pdf.dart

2. **Sri Krishna Carrying Corporation** (Company ID: 6)
   - App ID: com.example.logistic.carrying
   - PDF Template: gc_pdf_carrying.dart

## Architecture

The multi-company support is implemented using Flutter flavors and Android product flavors:

### Android Configuration

The Android build is configured with product flavors in `android/app/build.gradle.kts`:

```kotlin
flavorDimensions += "company"
    
productFlavors {
    create("cargo") {
        dimension = "company"
        applicationIdSuffix = ".cargo"
        resValue("string", "app_name", "Sri Krishna Cargo")
        resValue("string", "company_id", "7")
    }
    create("carrying") {
        dimension = "company"
        applicationIdSuffix = ".carrying"
        resValue("string", "app_name", "Sri Krishna Carrying")
        resValue("string", "company_id", "6")
    }
}
```

### Flutter Configuration

The Flutter app uses a flavor configuration system:

1. **FlavorConfig** (`lib/config/flavor_config.dart`): Manages the app's flavor configuration and provides company-specific settings.

2. **CompanyConfig** (`lib/config/company_config.dart`): Uses the FlavorConfig to provide company-specific values throughout the app.

3. **GCPdfFactory** (`lib/widgets/gc_pdf_factory.dart`): Factory class that selects the appropriate PDF generator based on the company.

## Building the App

To build both APKs, run the provided batch script:

```
.\build_apks.bat
```

This will create two APKs:
- `build\app\outputs\flutter-apk\app-cargo-release.apk` - Sri Krishna Cargo Corporation
- `build\app\outputs\flutter-apk\app-carrying-release.apk` - Sri Krishna Carrying Corporation

## Running in Development

To run the app for a specific company during development:

```
flutter run --flavor cargo     # For Sri Krishna Cargo Corporation
flutter run --flavor carrying  # For Sri Krishna Carrying Corporation
```

## Adding More Companies

To add more companies:

1. Add a new flavor to `android/app/build.gradle.kts`
2. Add a new enum value to `Flavor` in `lib/config/flavor_config.dart`
3. Create a new PDF template file if needed
4. Update the `GCPdfFactory` to handle the new company

# Firebase Configuration Guide

This document explains how to properly configure Firebase for the Quiz app, including authentication, Firestore database, and security rules.

## Prerequisites

- A Google account
- Flutter SDK and Firebase CLI installed
- Android Studio or VS Code with Flutter plugins

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or "Create a project"
3. Enter a project name (e.g., "quiz-app")
4. Follow the setup steps and click "Create project"

## Step 2: Add Android and iOS Apps to Firebase

### For Android:
1. In Firebase Console, click the Android icon to add an Android app
2. Enter the package name (check `android/app/build.gradle` for `applicationId`)
3. Download the `google-services.json` file
4. Place the file in `android/app/` directory

### For iOS:
1. In Firebase Console, click the iOS icon to add an iOS app
2. Enter the bundle ID (check `ios/Runner.xcworkspace` for bundle ID)
3. Download the `GoogleService-Info.plist` file
4. Place the file in `ios/Runner/` directory

## Step 3: Install Firebase CLI and Initialize

```bash
# Install Firebase CLI globally
npm install -g firebase-tools

# Navigate to your Flutter project root
cd C:/quiz_flutter/Quiz-app_flutter

# Login to Firebase
firebase login

# Initialize Firebase in the project
firebase init
```

When prompted during `firebase init`, select:
- Firestore: Yes
- Authentication: Yes
- Firestore Security Rules: Yes
- Firestore Indexes: Yes

## Step 4: Configure Firebase Authentication

1. In Firebase Console, go to Authentication
2. Click "Get Started"
3. Enable "Email/Password" sign-in provider
4. If needed, enable other providers (Google, etc.)

## Step 5: Configure Firestore Database

1. In Firebase Console, click "Firestore Database" in the navigation panel
2. Click "Create database"
3. Start in "test mode" (for development) or set rules directly (for production)

For development purposes, use these test rules:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to all users
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

For production, use more secure rules:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read/write their own data
    match /quizzes/{quizId} {
      allow read, write: if request.auth != null;
    }
    
    match /quiz_results/{resultId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.studentId || 
        request.auth.uid == resource.data.teacherId;
    }
    
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 6: Update pubspec.yaml

Make sure your `pubspec.yaml` includes the required Firebase dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  provider: ^6.1.1
  # Add other dependencies as needed
```

## Step 7: Add Android Configuration

In `android/app/build.gradle`, make sure you have:

```gradle
dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-analytics'
    // Add other Firebase dependencies
}
```

In `android/build.gradle` (project level), make sure you have:

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
        // ...
    }
}
```

## Step 8: Add iOS Configuration

In `ios/Podfile`, run `pod install` after adding the Firebase dependencies.

## Step 9: Verify Firebase Integration

1. In your Flutter app, verify these imports are in your main file:
```dart
import 'package:firebase_core/firebase_core.dart';
```

2. Initialize Firebase in your main function:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
```

## Step 10: Troubleshooting Common Issues

### PIN Code Issues:
1. Make sure the `pinCode` field is being properly saved to Firestore when quizzes are created
2. Verify that the query to find quizzes by PIN is correct:
```dart
final snapshot = await _db
    .collection('quizzes')
    .where('pinCode', isEqualTo: enteredPin)
    .where('isActive', isEqualTo: true)
    .get();
```

### Calendar/Notifications not showing:
1. Make sure quiz schedule data is being properly added to Firestore
2. Check that the schedule query is correctly fetching data
3. Verify that the user has proper permissions to read the scheduled items
4. Confirm that authentication is working properly

### Testing Setup:

To test if Firebase is properly configured:
1. Create a simple test screen that writes and reads data to/from Firestore
2. Try logging in with Firebase Auth
3. Check Firebase Console for the data being created

## Step 11: Security Considerations

1. Never expose private keys in the client app
2. Use Firestore Security Rules to properly secure data access
3. Validate all data on the client before sending to Firebase
4. Use Firebase Functions for sensitive operations instead of client-side

## Common Errors and Solutions

1. **PlatformException** related to Firebase: Check that google-services.json is in the correct location (android/app/) and that the package name matches the Firebase project config.

2. **Permission denied**: Check Firestore Security Rules and ensure your authentication is working.

3. **No data appearing**: Verify the correct collection names and field names match what's in your code.

4. **PIN codes not working**: Ensure PIN generation code is working and the pinCode field is being stored properly in Firestore.
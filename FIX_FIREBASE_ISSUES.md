# Fixing Firebase Configuration Issues

Since your project uses Firestore (not Firebase Data Connect), we need to remove the Data Connect configuration that was added during firebase init.

## Steps to Fix Configuration Issues

### 1. Remove or Ignore Data Connect Files

If you're not using Firebase Data Connect, you can safely remove these files/directories:
- `dataconnect/` directory
- Any generated files that start with `dataconnect` prefix

### 2. Keep Only Firestore Configuration

Ensure these files remain (they are correct for Firestore):
- `firebase.json` - Contains Firebase project configuration
- `firestore.rules` - Contains Firestore security rules
- `firestore.indexes.json` - Contains Firestore indexes
- `database.rules.json` - Contains Realtime Database rules (if used)

### 3. Update firebase.json

Make sure your `firebase.json` looks like this for a Firestore-only project:

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "ignore": [
        "node_modules",
        ".git",
        "firebase-debug.log",
        "firebase-debug.*.log"
      ]
    }
  ],
  "storage": {
    "rules": "storage.rules"
  }
}
```

### 4. Remove Data Connect from firebase.json (if present)

If your `firebase.json` contains a `dataconnect` section, remove it:

```json
// Remove this section if present:
"dataconnect": {
  "source": "dataconnect"
}
```

### 5. Clean Up Pubspec Dependencies

Make sure your `pubspec.yaml` only includes Firestore-related dependencies and not Data Connect dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  # Add other necessary dependencies
  # Remove any data connect related dependencies
```

### 6. Update Git Ignore

Add these to your `.gitignore` to avoid committing generated files:

```
# Firebase Data Connect generated files
dataconnect_generated/
.fdcs/

# Firebase emulator files
.emulators/
firestore_export/
functions/__generated__/
functions/.runtimeconfig.json
```

### 7. Reinitialize Firebase (Optional)

If you want to completely start over with Firebase configuration:

```bash
firebase logout
firebase login
# Remove dataconnect section from firebase.json
# Or delete and recreate firebase.json with only Firestore configuration
```

### 8. Verify Your App Configuration

Make sure your Flutter app is initialized correctly with Firestore:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

### 9. Troubleshooting Common Issues

After cleaning up the Data Connect files:

1. **Run** `flutter clean` to clear build cache
2. **Run** `flutter pub get` to get dependencies
3. **Run** `flutter pub run build_runner build --delete-conflicting-outputs` if you have generated files
4. **Test** your app to ensure Firestore is working properly

The issues you're experiencing (199 problems) are likely due to the mismatch between your Flutter app code (which uses Firestore) and the Firebase Data Connect configuration that was added during initialization.

### 10. Focus on Firestore Collections

For your quiz app, make sure the following collections exist in Firestore:
- `users`
- `quizzes` 
- `quiz_results`
- `grade_settings`

Refer to the FIRESTORE_COLLECTIONS.md file for detailed information about the structure of these collections.

After following these steps, your Firebase configuration should work properly with the quiz app and should resolve the 199 problems you're seeing.
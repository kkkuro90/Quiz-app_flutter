# Clean Up Script for Quiz App

# Run these commands to clean up your Flutter project and fix Firebase issues:

# 1. Clean Flutter build cache
flutter clean

# 2. Get Flutter dependencies
flutter pub get

# 3. If you have build runner files that are causing issues
# flutter pub run build_runner build --delete-conflicting-outputs

# 4. Run Flutter doctor to check for any issues
flutter doctor

# 5. Build the project to test if errors are resolved
flutter build apk --debug

# Or run the app directly
flutter run

# 6. If you still have issues with the dataconnect folder
# You can safely remove it since it's not needed for your Firestore-based app
# rm -rf dataconnect/  # On Unix/Mac
# rmdir /s dataconnect\  # On Windows
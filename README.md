# WhatsApp ZIP Reader

A Flutter application that allows users to view and explore WhatsApp chat exports in ZIP format. This app provides a user-friendly interface to browse through chat messages and media files that were exported from WhatsApp.

## App Features

- **Import WhatsApp ZIP Files**: Easily import WhatsApp chat export ZIP files from your device storage
- **View Chat Messages**: Read through all chat messages with proper formatting and timestamps
- **Browse Media Files**: View images, videos, audio files, and documents that were part of the chat
- **Search Functionality**: Search through chat messages to find specific content
- **Media Preview**: Preview media files directly within the app
- **Download Media**: Save media files to your device
- **Clean Interface**: WhatsApp-like UI for a familiar experience

## Technologies Used

- **Flutter**: Cross-platform UI framework for building the application
- **Dart**: Programming language used with Flutter
- **Provider**: State management solution for handling app state
- **Archive**: Library for handling ZIP file extraction
- **File Picker**: For selecting ZIP files from device storage
- **Permission Handler**: Managing storage permissions
- **Path Provider**: Accessing device directories
- **Video Player**: For video media preview
- **Flutter SVG**: For SVG image support

## App Workflow

1. **Entry Screen**: The app starts with a welcome screen where users can import a WhatsApp ZIP file
2. **Permission Request**: The app requests necessary storage permissions to access ZIP files
3. **File Selection**: Users select a WhatsApp chat export ZIP file using the device's file picker
4. **Extraction Process**: The app extracts the ZIP file contents to a temporary directory
5. **Processing**:
   - Text files are parsed to extract chat messages with timestamps and sender information
   - Media files are categorized by type (images, videos, audio, documents)
6. **Main Screen**: Users can navigate between:
   - **Chat Tab**: Displays all messages in chronological order with a WhatsApp-like interface
   - **Media Tab**: Shows a grid of all media files organized by type
7. **Interaction**:
   - Search through messages
   - View and download media files
   - Navigate through the chat history

## How to Use

1. Export a chat from WhatsApp (WhatsApp > Chat > More > Export chat)
2. Choose "Include Media" when exporting to get the full experience
3. Open this app and tap the import button
4. Select the ZIP file you exported from WhatsApp
5. Browse through your messages and media

## Privacy

This app processes all data locally on your device. No chat data or media is sent to any external servers.

## Getting Started with Development

If you want to contribute to this project or run it locally:

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Connect a device or start an emulator
4. Run `flutter run` to start the app

## Requirements

- Flutter 3.3.0 or higher
- Dart 3.0.0 or higher
- Android 5.0+ or iOS 11.0+

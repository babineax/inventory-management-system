# Inventory Management System

A comprehensive Flutter-based inventory management application that helps businesses track stock levels, monitor movements, and predict restocking needs using Firebase as the backend.

## Features

### Core Functionality
- **User Authentication**: Secure login and registration with Firebase Auth
- **Inventory Management**: Add, edit, delete, and search inventory items
- **Stock Tracking**: Real-time stock level monitoring with automatic low-stock alerts
- **Stock Movements**: Track all stock in/out movements with detailed history
- **Predictions**: AI-powered stock depletion predictions based on usage patterns
- **Dashboard**: Comprehensive overview with key metrics and charts
- **Categories**: Organize items by predefined categories
- **User Profiles**: Manage user information and profile photos

### Technical Features
- **Firebase Integration**: Cloud Firestore for data storage, Firebase Auth for authentication
- **Real-time Updates**: Live data synchronization across devices
- **Offline Support**: Basic offline functionality with data sync
- **Responsive Design**: Optimized for mobile devices
- **Material Design**: Modern UI following Material Design principles
- **Charts & Analytics**: Visual representation of stock trends and statistics

## Screenshots

*Add screenshots of your app here*

## Installation

### Prerequisites
- Flutter SDK (version 3.0.5 or higher)
- Dart SDK (version 3.0.0 or higher)
- Android Studio or VS Code with Flutter extensions
- Firebase project with Firestore and Authentication enabled

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/inventory-management-system.git
   cd inventory-management-system
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Firestore Database and Authentication
   - Add your Android/iOS app to the Firebase project
   - Download the `google-services.json` file and place it in `android/app/`
   - Download the `GoogleService-Info.plist` file and place it in `ios/Runner/`

4. **Configure Firebase Options**
   - Run the following command to generate Firebase options:
   ```bash
   flutterfire configure
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## Usage

### Getting Started
1. Launch the app and create an account or sign in
2. Navigate through the bottom navigation bar:
   - **Dashboard**: View key metrics and charts
   - **Inventory**: Manage your inventory items
   - **Movements**: Track stock movements
   - **Predictions**: View items needing restock
   - **Profile**: Manage your account settings

### Managing Inventory
- **Add Items**: Tap the "+" button to add new inventory items
- **Edit Items**: Long press on an item to edit or delete
- **Search**: Use the search bar to find specific items
- **Categories**: Filter items by category
- **Stock Adjustments**: Adjust stock levels with automatic movement logging

### Monitoring Stock
- **Low Stock Alerts**: Automatic notifications for items below reorder level
- **Predictions**: View predicted depletion dates based on usage patterns
- **Movement History**: Track all stock changes with timestamps and user information

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── auth.dart                 # Authentication wrapper
├── widget_tree.dart          # Authentication state management
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
│   ├── inventory_item.dart
│   ├── stock_movement.dart
│   ├── stock_prediction.dart
│   └── user_model.dart
├── services/                 # Business logic services
│   ├── auth_service.dart
│   ├── inventory_service.dart
│   └── image_picker_service.dart
├── screens/                  # Main app screens
│   ├── dashboard_screen.dart
│   ├── inventory_form_screen.dart
│   ├── inventory_list_screen.dart
│   ├── predictions_screen.dart
│   ├── profile_screen.dart
│   └── stock_movements_screen.dart
├── pages/                    # Page-level widgets
│   ├── home_page.dart
│   └── login_register_page.dart
└── widgets/                  # Reusable UI components
```

## Dependencies

### Core Dependencies
- `firebase_core`: Firebase initialization
- `firebase_auth`: User authentication
- `cloud_firestore`: NoSQL database
- `provider`: State management
- `fl_chart`: Data visualization
- `image_picker`: Image selection
- `google_fonts`: Custom typography

### Development Dependencies
- `flutter_lints`: Code linting
- `flutter_test`: Unit testing

## Configuration

### Firebase Security Rules
Make sure to configure appropriate Firestore security rules for your use case:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Your security rules here
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Environment Variables
Create a `.env` file for any environment-specific configurations:

```
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow Flutter's official style guide
- Use meaningful variable and function names
- Add comments for complex logic
- Write unit tests for new features

## Testing

Run the test suite:
```bash
flutter test
```

Run tests with coverage:
```bash
flutter test --coverage
```

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Troubleshooting

### Common Issues
1. **Firebase connection issues**: Verify your Firebase configuration and internet connection
2. **Build failures**: Ensure all dependencies are properly installed with `flutter pub get`
3. **Authentication errors**: Check Firebase Auth settings and API keys

### Debug Mode
Enable debug logging by setting:
```dart
const bool isDebug = true;
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, email support@example.com or create an issue in the GitHub repository.

## Roadmap

- [ ] Push notifications for low stock alerts
- [ ] Barcode scanning for inventory items
- [ ] Multi-language support
- [ ] Advanced reporting and analytics
- [ ] Integration with external inventory systems
- [ ] Offline mode improvements

---

Built with ❤️ using Flutter and Firebase

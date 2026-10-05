# សាកលវិទ្យាល័យ បៀលប្រាយ (BUILD BRIGHT UNIVERSITY)
## មហាវិទ្យាល័យ វិទ្យាសាស្ត្រ និងបច្ចេកវិទ្យា (Faculty of Science and Technology)
### ជំនាញៈ វិទ្យាសាស្ត្រកុំព្យូទ័រ (Computer Science)

---

# របាយការណ៍កិច្ចការស្រាវជ្រាវ និងការអនុវត្តជាក់ស្តែង
## មុខវិជ្ជាៈ ការសរសេរកម្មវិធីលើទូរស័ព្ទដៃ II (Mobile Programming II)
### ប្រធានបទៈ ការរៀបចំ និងអនុវត្តប្រព័ន្ធពពក Firebase (Firebase Integration & Implementation)
### គម្រោងកម្មវិធីៈ RoomFinder KH - Rental Marketplace Mobile Application

---

## ព័ត៌មានទូទៅនៃគម្រោង (Project Information)
* **ឈ្មោះគម្រោង (Project Name):** RoomFinder KH
* **Package Name (Application ID):** `com.dinsarenkh.demo_access_refresh_token_app`
* **Firebase Project ID:** `roomfinder-kh`
* **បច្ចេកវិទ្យាប្រើប្រាស់ (Tech Stack):** 
  - Framework: **Flutter (Dart SDK ^3.12.2)**
  - State Management: **GetX**
  - Backend API: **Spring Boot RESTful API (JWT Token)**
  - Cloud Services: **Google Firebase**
    - `firebase_core: ^4.15.0`
    - `firebase_analytics: ^12.6.0`
    - `firebase_remote_config: ^6.7.0`

---

## មាតិកា (Table of Contents)
1. [I. សេចក្តីផ្តើម (Introduction)](#i-សេចក្តីផ្តើម-introduction)
2. [II. គោលបំណងនៃការប្រើប្រាស់ Firebase (Objectives)](#ii-គោលបំណងនៃការប្រើប្រាស់-firebase-objectives)
3. [III. ការបង្កើត Project និងការកំណត់រចនាសម្ព័ន្ធលើ Firebase Console (Firebase Setup)](#iii-ការបង្កើត-project-និងការកំណត់រចនាសម្ព័ន្ធលើ-firebase-console-firebase-setup)
4. [IV. ការដំឡើង Dependencies និងការតភ្ជាប់ជាមួយ Flutter (FlutterFire Configuration)](#iv-ការដំឡើង-dependencies-និងការតភ្ជាប់ជាមួយ-flutter-flutterfire-configuration)
5. [V. ស្ថាបត្យកម្មកូដ និងការគ្រប់គ្រង Firebase Service (Service Architecture)](#v-ស្ថាបត្យកម្មកូដ-និងការគ្រប់គ្រង-firebase-service-service-architecture)
6. [VI. ការអនុវត្តជាក់ស្តែងនៃ Firebase Remote Config (Dynamic App Configuration)](#vi-ការអនុវត្តជាក់ស្តែងនៃ-firebase-remote-config-dynamic-app-configuration)
7. [VII. ការអនុវត្តជាក់ស្តែងនៃ Firebase Analytics (User Behavior & Event Tracking)](#vii-ការអនុវត្តជាក់ស្តែងនៃ-firebase-analytics-user-behavior--event-tracking)
8. [VIII. ការតាមដាន និងវិភាគគ្រប់ទម្រង់ Form ទាំងអស់ក្នុង App (Form Analytics)](#viii-ការតាមដាន-និងវិភាគគ្រប់ទម្រង់-form-ទាំងអស់ក្នុង-app-form-analytics)
9. [IX. ការធ្វើតេស្តសាកល្បងជាមួយ Firebase DebugView (Testing & Verification)](#ix-ការធ្វើតេស្តសាកល្បងជាមួយ-firebase-debugview-testing--verification)
10. [X. សេចក្តីសន្និដ្ឋាន និងផលប្រយោជន៍ទទួលបាន (Conclusion)](#x-សេចក្តីសន្និដ្ឋាន-និងផលប្រយោជន៍ទទួលបាន-conclusion)

---

## I. សេចក្តីផ្តើម (Introduction)
នៅក្នុងការអភិវឌ្ឍកម្មវិធីទូរស័ព្ទដៃសម័យទំនើប ការគ្រប់គ្រងទិន្នន័យពីចម្ងាយ (Remote Configuration) និងការតាមដានសកម្មភាពរបស់អ្នកប្រើប្រាស់ (User Behavioral Analytics) គឺជាកត្តាស្នូលក្នុងការធ្វើឱ្យកម្មវិធីដំណើរការប្រកបដោយភាពរលូន និងឆ្លើយតបទៅនឹងតម្រូវការជាក់ស្តែងរបស់អ្នកប្រើប្រាស់។

សម្រាប់គម្រោង **RoomFinder KH** ដែលជាកម្មវិធីស្វែងរក និងគ្រប់គ្រងផ្ទះជួល/បន្ទប់ជួល (Rental Marketplace) សម្រាប់និស្សិត និងម្ចាស់ផ្ទះជួល យើងបានធ្វើការតភ្ជាប់ប្រព័ន្ធ **Google Firebase** ដែលជា Backend-as-a-Service (BaaS) ឈានមុខគេរបស់ក្រុមហ៊ុន Google ដើម្បីពង្រឹងប្រសិទ្ធភាព និងសុវត្ថិភាពកម្មវិធី។

![រូបភាពទី ០១: រូបភាពបង្ហាញពីផ្ទាំង Dashboard របស់ Firebase Console សម្រាប់គម្រោង RoomFinder KH](screenshots/image_01.png)
*រូបភាពទី ០១៖ រូបភាពបង្ហាញពីផ្ទាំង Dashboard របស់ Firebase Console សម្រាប់គម្រោង RoomFinder KH*

---

## II. គោលបំណងនៃការប្រើប្រាស់ Firebase (Objectives)
ការដាក់បញ្ចូល Firebase ទៅក្នុងកម្មវិធី RoomFinder KH មានគោលបំណងសំខាន់ៗដូចខាងក្រោម៖
1. **Dynamic Configuration ដោយពុំចាំបាច់ Re-deploy App:** ប្រើប្រាស់ **Firebase Remote Config** ដើម្បីគ្រប់គ្រងការកំណត់មួយចំនួនដូចជា អត្រាប្តូរប្រាក់ (Exchange Rate ៛/$) សារជូនដំណឹង (Welcome Banner) ការបើក/បិទមុខងារបង់ប្រាក់ KHQR និងរបៀបថែទាំប្រព័ន្ធ (Maintenance Mode)។
2. **ការតាមដាន និងវិភាគសកម្មភាពអ្នកប្រើប្រាស់ (Behavior Analytics):** ប្រើប្រាស់ **Firebase Analytics** ដើម្បីតាមដានថាតើអ្នកប្រើប្រាស់ (និស្សិត ឬម្ចាស់ផ្ទះ) ចូលទស្សនាទំព័រណាខ្លះ ស្វែងរកបន្ទប់ប្រភេទណា ចុចកក់ការណាត់ជួប ឬស្នើសុំមើលបន្ទប់ញឹកញាប់កម្រិតណា។
3. **ការគ្រប់គ្រងគុណភាព និងការបំពេញបែបបទ (Form Analytics):** តាមដានរាល់ទម្រង់ Form សំខាន់ៗ (Login, Register, Add Room, Add Tenant, Review, Avatar Upload) ដើម្បីដឹងពីអត្រាជោគជ័យ (Success Rate) និងកំហុស (Error Messages) ជួយសម្រួលដល់ការ Debug និងបង្កើន UX/UI។

---

## III. ការបង្កើត Project និងការកំណត់រចនាសម្ព័ន្ធលើ Firebase Console (Firebase Setup)

### ១. ការបង្កើត Project លើ Firebase
* ចូលទៅកាន់គេហទំព័រ [https://console.firebase.google.com/](https://console.firebase.google.com/)
* ចុចលើប៊ូតុង **"Add Project"** និងដាក់ឈ្មោះគម្រោងថា `roomfinder-kh`
* បើកមុខងារ Google Analytics សម្រាប់ Project ដើម្បីទទួលបាន Dashboard វិភាគទិន្នន័យ

![រូបភាពទី ០២: រូបភាពបង្ហាញពីការបង្កើត Project "roomfinder-kh" លើ Firebase Console](screenshots/image_02.png)
*រូបភាពទី ០២៖ រូបភាពបង្ហាញពីការបង្កើត Project "roomfinder-kh" លើ Firebase Console*

### ២. ការបន្ថែម Android Platform ទៅក្នុង Firebase
* បញ្ចូល **Package Name**: `com.dinsarenkh.demo_access_refresh_token_app`
* ទាញយកឯកសារកំណត់រចនាសម្ព័ន្ធ `google-services.json`
* ផ្លាស់ទីឯកសារ `google-services.json` ទៅដាក់ក្នុង Folder: `android/app/google-services.json`

![រូបភាពទី ០៣: រូបភាពបង្ហាញពីការកំណត់ Android App ក្នុង Firebase Console / FlutterFire និង google-services.json](screenshots/image_03.png)
*រូបភាពទី ០៣៖ រូបភាពបង្ហាញពីការកំណត់ Android App (com.dinsarenkh.demo_access_refresh_token_app) ក្នុង Firebase Console / FlutterFire*

### ៣. ការកំណត់ក្នុងកូដ Android Gradle
នៅក្នុងឯកសារ `android/app/build.gradle.kts` យើងបានបន្ថែម Google Services Plugin:
```kotlin
plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.dinsarenkh.demo_access_refresh_token_app"
    defaultConfig {
        applicationId = "com.dinsarenkh.demo_access_refresh_token_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // ...
    }
}
```

---

## IV. ការដំឡើង Dependencies និងការតភ្ជាប់ជាមួយ Flutter (FlutterFire Configuration)

### ១. ការដំឡើង Package ក្នុង `pubspec.yaml`
យើងបានដំឡើង Package ផ្លូវការរបស់ Firebase សម្រាប់ Flutter រួមមាន៖
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase Core & Services
  firebase_core: ^4.15.0
  firebase_analytics: ^12.6.0
  firebase_remote_config: ^6.7.0
```

### ២. ការបង្កើត `firebase_options.dart` ដោយស្វ័យប្រវត្ត (FlutterFire CLI)
យើងបានប្រើប្រាស់បញ្ជា `flutterfire configure` ដើម្បីបង្កើតឯកសារ `lib/firebase_options.dart` ដែលផ្ទុកនូវ API Key, App ID, និង Project Details ស្របតាម Platform នីមួយៗ (Android, iOS, Web)៖

```dart
// lib/firebase_options.dart
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBEW5ujSPaOPgvqVQQmJ5rUed943z0bnGU',
    appId: '1:386149399864:android:cc8f2ff76aec1b84bd55cd',
    messagingSenderId: '386149399864',
    projectId: 'roomfinder-kh',
    storageBucket: 'roomfinder-kh.firebasestorage.app',
  );
  // ...
}
```

![រូបភាពទី ០៤: រូបភាពបង្ហាញពីការដំណើរការបញ្ជា flutterfire configure លើ Terminal](screenshots/image_04.png)
*រូបភាពទី ០៤៖ រូបភាពបង្ហាញពីការដំណើរការបញ្ជា flutterfire configure លើ Terminal*

---

## V. ស្ថាបត្យកម្មកូដ និងការគ្រប់គ្រង Firebase Service (Service Architecture)

ដើម្បីធានាបាននូវ Clean Code Architecture និងភាពងាយស្រួលក្នុងការហៅប្រើប្រាស់នៅគ្រប់ទីកន្លែងក្នុង App យើងបានបង្កើត Class មួយឈ្មោះថា `AppFirebaseService` នៅក្នុង Folder `lib/core/services/firebase_service.dart` ដោយប្រើប្រាស់ **Singleton & Static Utility Pattern**។

### ១. ការ Initialize ក្នុង `main.dart`
មុនពេល App ដំណើរការ (Run App) Firebase Core និង Remote Config ត្រូវបាន Initialize ជាមុនសិន៖

```dart
// lib/main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  // Initialize Firebase Core
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase Remote Config
  await AppFirebaseService.initRemoteConfig();

  runApp(const MyApp());
}
```

### ២. ការភ្ជាប់ Observer ជាមួយ GetMaterialApp
ដើម្បីឱ្យ Firebase Analytics អាចចាប់យកឈ្មោះ Screen ដែល User កំពុងបើកដោយស្វ័យប្រវត្តិ យើងបានភ្ជាប់ `AppFirebaseService.observer` ទៅក្នុង `GetMaterialApp`៖

```dart
// lib/main.dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'RoomFinder KH - Rental Marketplace',
      navigatorObservers: [
        AppFirebaseService.observer, // Auto Screen Navigation Tracking
      ],
      // ...
    );
  }
}
```

---

## VI. ការអនុវត្តជាក់ស្តែងនៃ Firebase Remote Config (Dynamic App Configuration)

Firebase Remote Config ផ្តល់លទ្ធភាពឱ្យ Admin អាចកែប្រែតម្លៃ ឬមុខងារក្នុង App ភ្លាមៗពីចម្ងាយដោយមិនបាច់បញ្ចេញ App កំណែថ្មីលើ Play Store ឡើយ។

### ១. តម្លៃលំនាំដើម (Default Configurations)
នៅក្នុងកូដ `lib/core/services/firebase_service.dart` យើងបានកំណត់ Default Parameters៖

```dart
static Future<void> initRemoteConfig() async {
  try {
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      // កំឡុងពេល Debug ដាក់ Duration.zero ដើម្បី Fetch បានភ្លាមៗ
      minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
    ));

    // កំណត់ Default values ពេលគ្មាន Internet ឬមុនពេល Fetch បាន
    await remoteConfig.setDefaults(const {
      "welcome_message": "សូមស្វាគមន៍មកកាន់ RoomFinder KH",
      "maintenance_mode": false,
      "khr_exchange_rate": 4100,
      "enable_khqr_payment": true,
    });

    // Fetch និង Activate តម្លៃពី Firebase Console
    await remoteConfig.fetchAndActivate();
  } catch (e) {
    debugPrint("Remote Config Error: $e");
  }
}
```

### ២. ប៉ារ៉ាម៉ែត្រសំខាន់ៗដែលត្រូវបានគ្រប់គ្រង (Remote Config Parameters)
| Parameter Key | Data Type | Default Value | ការពិពណ៌នា និងការប្រើប្រាស់ក្នុង App |
|---|---|---|---|
| `khr_exchange_rate` | Integer | `4100` | អត្រាប្តូរប្រាក់រៀល/ដុល្លារ សម្រាប់គណនាតម្លៃជួល និងថ្លៃទឹកភ្លើង |
| `welcome_message` | String | `សូមស្វាគមន៍...` | សារស្វាគមន៍បង្ហាញលើ Home Screen |
| `maintenance_mode` | Boolean | `false` | បិទប្រព័ន្ធបណ្តោះអាសន្នពេលកំពុងជួសជុល Server |
| `enable_khqr_payment`| Boolean | `true` | បើក/បិទ មុខងារទូទាត់ប្រាក់តាម KHQR Code |

### ៣. ការទាញយកទិន្នន័យជាក់ស្តែងក្នុងផ្ទាំងកំណត់តម្លៃ (Owner Pricing View)
នៅក្នុង `lib/modules/owner/pricing/owner_pricing_view.dart` ម្ចាស់ផ្ទះអាចចុច Fetch តម្លៃអត្រាប្តូរប្រាក់ថ្មីពី Firebase មកប្រើប្រាស់ក្នុង Textbox ភ្លាមៗ៖

```dart
// lib/modules/owner/pricing/owner_pricing_view.dart
Future<void> _fetchFirebaseExchangeRate() async {
  final success = await AppFirebaseService.fetchRemoteConfig();
  if (success && mounted) {
    setState(() {
      _exchangeRateController.text = AppFirebaseService.exchangeRate.toString();
    });
    Get.snackbar(
      "Firebase Remote Config",
      "អត្រាប្តូរប្រាក់បច្ចុប្បន្នពី Firebase: ${AppFirebaseService.exchangeRate} ៛",
      backgroundColor: Colors.green.shade600,
      colorText: Colors.white,
    );
  }
}
```

![រូបភាពទី ០៥: រូបភាពបង្ហាញពីការកំណត់ Parameters លើផ្ទាំង Firebase Remote Config Console](screenshots/image_05.png)
*រូបភាពទី ០៥៖ រូបភាពបង្ហាញពីការកំណត់ Parameters លើផ្ទាំង Firebase Remote Config Console (khr_exchange_rate = 4150)*

![រូបភាពទី ០៦: រូបភាពបង្ហាញពីស្ថាបត្យកម្មកូដ និងការកំណត់ Remote Config & Analytics ក្នុង App](screenshots/image_06.png)
*រូបភាពទី ០៦៖ រូបភាពបង្ហាញពីស្ថាបត្យកម្មកូដ និងការកំណត់ Remote Config & Analytics ក្នុង App (firebase_service.dart)*

---

## VII. ការអនុវត្តជាក់ស្តែងនៃ Firebase Analytics (User Behavior & Event Tracking)

Firebase Analytics ជួយឱ្យយើងយល់ច្បាស់ពីសកម្មភាពជាក់ស្តែងរបស់អ្នកប្រើប្រាស់ក្នុងកម្មវិធី។

### ១. ការកំណត់អត្តសញ្ញាណ និងតួនាទីអ្នកប្រើប្រាស់ (User Identification & Role Property)
នៅពេល User ធ្វើការ Login ឬ Register ជោគជ័យ កម្មវិធីនឹងផ្ញើ `user_id` និង `user_role` (ម្ចាស់ផ្ទះជួល `owner` ឬ និស្សិត `student`) ទៅកាន់ Firebase៖

```dart
static Future<void> logLogin({required String method, required String role, String? userId}) async {
  await analytics.logLogin(loginMethod: method);
  if (userId != null && userId.isNotEmpty) {
    await analytics.setUserId(id: userId);
  }
  await analytics.setUserProperty(name: "user_role", value: role);
}
```

### ២. ការកត់ត្រាសកម្មភាពអាជីវកម្មស្នូល (Custom Business Events)
* **ការស្វែងរកបន្ទប់ជួល (Search):**
  ```dart
  static Future<void> logSearch(String searchTerm) async {
    await analytics.logSearch(searchTerm: searchTerm);
  }
  ```
* **ការបើកមើលព័ត៌មានលម្អិតបន្ទប់ (View Room Detail):**
  ```dart
  static Future<void> logViewRoom({required String roomId, required String roomTitle, required double price}) async {
    await analytics.logEvent(
      name: "view_room_detail",
      parameters: {
        "room_id": roomId,
        "room_title": roomTitle,
        "price": price,
      },
    );
  }
  ```
* **ការចុចស្នើសុំកក់ការណាត់ជួបមើលបន្ទប់ (Book Visit Request):**
  ```dart
  static Future<void> logBookVisit({required String propertyId, required String visitDate}) async {
    await analytics.logEvent(
      name: "book_visit_request",
      parameters: {
        "property_id": propertyId,
        "visit_date": visitDate,
      },
    );
  }
  ```
* **ការចុច Save ឬ Favorite បន្ទប់ជួល (Toggle Favorite):**
  ```dart
  static Future<void> logToggleFavorite({required String roomId, required bool isFavorite}) async {
    await analytics.logEvent(
      name: "toggle_favorite",
      parameters: {
        "room_id": roomId,
        "action": isFavorite ? "save" : "unsave",
      },
    );
  }
  ```

![រូបភាពទី ០៧: រូបភាពបង្ហាញពី Event Dashboard ក្នុង Firebase Analytics Console](screenshots/image_07.png)
*រូបភាពទី ០៧៖ រូបភាពបង្ហាញពី Event Dashboard ក្នុង Firebase Analytics Console*

---

## VIII. ការតាមដាន និងវិភាគគ្រប់ទម្រង់ Form ទាំងអស់ក្នុង App (Form Analytics)

នៅក្នុងកម្មវិធី RoomFinder KH យើងបានរៀបចំមុខងារតាមដានគ្រប់ Form Submission ដើម្បីត្រួតពិនិត្យថា តើ User អាចបំពេញ Form បានជោគជ័យ ឬជួបបញ្ហា ValidationError ត្រង់ចំណុចណា៖

### តារាងទម្រង់ Form ដែលបាន Track ចូល Firebase Analytics៖
| ល.រ | ឈ្មោះទម្រង់ Form (`form_name`) | ទីតាំង Controller/View | Parameters ដែលបានបញ្ជូន | គោលបំណង |
|:---:|---|---|---|---|
| 1 | `login_form` | `LoginController` | `success`, `role`, `error_message` | តាមដានការ Login របស់ User |
| 2 | `register_form` | `RegisterController` | `success`, `role`, `error_message` | តាមដានការចុះឈ្មោះបង្កើតគណនីថ្មី |
| 3 | `visit_request_form`| `RequestVisitDialog` | `property_id`, `room_id`, `requested_date`, `success` | តាមដានការស្នើសុំណាត់ជួបមើលបន្ទប់ |
| 4 | `review_form` | `PropertyDetailController`| `property_id`, `rating`, `success` | តាមដានការវាយតម្លៃផ្កាយ (Review & Rating) |
| 5 | `pricing_settings_form`| `OwnerPricingView` | `rent_price`, `electricity`, `water`, `exchange_rate` | តាមដានការកំណត់ថ្លៃឈ្នួល និងថ្លៃទឹកភ្លើង |
| 6 | `add_room_form` | `OwnerRoomsView` / Controller | `room_number`, `floor`, `price`, `success` | តាមដានការបន្ថែមបន្ទប់ជួលថ្មី |
| 7 | `add_floor_form` | `OwnerFloorsView` | `floor_name`, `success`, `error_message` | តាមដានការបង្កើតជាន់អាគារថ្មី |
| 8 | `add_tenant_form` | `OwnerTenantsView` | `tenant_name`, `room_number`, `success` | តាមដានការបញ្ចូលព័ត៌មានអ្នកជួលបន្ទប់ |
| 9 | `avatar_upload_form`| `Student & Owner Profile` | `user_role`, `source` (camera/gallery), `success`| តាមដានការ Upload រូបថត Profile |
| 10| `search_form` | `StudentSearchController` | `keyword`, `result_count`, `success` | តាមដានពាក្យគន្លឹះដែលនិស្សិតស្វែងរក |

### ឧទាហរណ៍កូដ Implementation ក្នុង `RegisterController`:
```dart
// lib/modules/register/register_controller.dart
if (phoneController.text.trim().isEmpty) {
  AppFirebaseService.logRegisterForm(
    success: false, 
    role: selectedRole.value, 
    errorMessage: "Missing phone number",
  );
  // ...
  return;
}

// ពេល Register ជោគជ័យ
AppFirebaseService.logRegisterForm(success: true, role: selectedRole.value);
```

![រូបភាពទី ០៨: រូបភាពបង្ហាញពីទម្រង់ Form ក្នុង App (ការអនុវត្ត Form Analytics លើ Login Form)](screenshots/image_08.png)
*រូបភាពទី ០៨៖ រូបភាពបង្ហាញពីទម្រង់ Form ក្នុង App (ការអនុវត្ត Form Analytics លើ Login Form)*

---

## IX. ការធ្វើតេស្តសាកល្បងជាមួយ Firebase DebugView (Testing & Verification)

Firebase Analytics តាមធម្មតាធ្វើការប្រមូលផ្តុំទិន្នន័យ (Batching) និងបញ្ជូនទិន្នន័យម្តងរៀងរាល់ ១ ម៉ោងម្តង។ ដើម្បីធ្វើតេស្តផ្ទៀងផ្ទាត់ Event ភ្លាមៗ (Real-time Testing) យើងបានប្រើប្រាស់មុខងារ **Firebase DebugView**។

### ១. បញ្ជា Command បើកដំណើរការ DebugView លើ Android Device / Emulator
បើក Terminal ឬ Command Prompt រួចវាយបញ្ជាដូចខាងក្រោម៖
```bash
adb shell setprop debug.firebase.analytics.app com.dinsarenkh.demo_access_refresh_token_app
```

### ២. បញ្ជា Command បិទ DebugView ពេលធ្វើតេស្តរួចរាល់
```bash
adb shell setprop debug.firebase.analytics.app .none.
```

### ៣. លទ្ធផលក្នុង Firebase DebugView
នៅពេលយើងដំណើរការ App និងធ្វើសកម្មភាពផ្សេងៗដូចជា Login, ចូលមើលបន្ទប់ជួល, បង្កើតបន្ទប់ជួលថ្មី ឬផ្លាស់ប្តូរតម្លៃ Remote Config នោះ Event នីមួយៗរួមជាមួយ Parameters ទាំងអស់នឹងបង្ហាញឡើងភ្លាមៗក្នុងផ្ទាំង DebugView Timeline។

![រូបភាពទី ០៩: រូបភាពបង្ហាញពីការកំណត់ Command បើកដំណើរការ Firebase DebugView លើ Android Terminal](screenshots/image_09.png)
*រូបភាពទី ០៩៖ រូបភាពបង្ហាញពីការកំណត់ Command បើកដំណើរការ Firebase DebugView លើ Android Terminal*

![រូបភាពទី ១០: រូបភាពបង្ហាញពីការបំពេញ Form និង Upload Profile Avatar ក្នុង App](screenshots/image_10.png)
*រូបភាពទី ១០៖ រូបភាពបង្ហាញពីការបំពេញ Form និង Upload Profile Avatar ក្នុង App (Avatar Upload Form Analytics)*

---

## X. សេចក្តីសន្និដ្ឋាន និងផលប្រយោជន៍ទទួលបាន (Conclusion)

តាមរយៈការអនុវត្តជាក់ស្តែងលើការដាក់បញ្ចូលប្រព័ន្ធ Google Firebase ទៅក្នុងកម្មវិធីទូរស័ព្ទ **RoomFinder KH** ក្រុមការងារយើងខ្ញុំទទួលបាននូវអត្ថប្រយោជន៍យ៉ាងច្រើនរួមមាន៖

1. **ការគ្រប់គ្រង App ប្រកបដោយភាពបត់បែន (High Flexibility):** តាមរយៈ **Firebase Remote Config** យើងអាចធ្វើបច្ចុប្បន្នភាពលើអត្រាប្តូរប្រាក់រៀល និងបិទបើកមុខងារបន្ទាន់ៗបានភ្លាមៗ ដោយមិនបាច់ Compile និង Deploy App ឡើងវិញឡើយ។
2. **ការយល់ដឹងពីតម្រូវការអ្នកប្រើប្រាស់ (Data-Driven Insights):** **Firebase Analytics** ជួយឱ្យយើងដឹងយ៉ាងច្បាស់អំពីអាកប្បកិរិយារបស់និស្សិត និងម្ចាស់ផ្ទះជួល ដូចជាបន្ទប់ណាដែលមានការចាប់អារម្មណ៍ច្រើន តំបន់ណាដែលត្រូវបានស្វែងរកញឹកញាប់។
3. **ការកែលម្អគុណភាព App (Quality Assurance):** ការតាមដានលើ Form Submissions ជួយឱ្យយើងមើលឃើញនូវចំណុចខ្វះខាត និង Error messages ដែល User ជួបប្រទះញឹកញាប់ ដើម្បីកែលម្អប្រព័ន្ធឱ្យកាន់តែមានស្ថិរភាព និងងាយស្រួលប្រើប្រាស់។

---

**កាលបរិច្ឆេទរៀបចំ:** ថ្ងៃទី ៣០ ខែកញ្ញា ឆ្នាំ ២០២៦  
**និស្សិតរៀបចំ:** និស្សិតជំនាញវិទ្យាសាស្ត្រកុំព្យូទ័រ (BBU)

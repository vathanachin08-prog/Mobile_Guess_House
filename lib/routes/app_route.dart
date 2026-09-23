import 'package:get/get.dart';
import 'app_route_name.dart';

// Splash & Auth
import '../modules/splash/splash_binding.dart';
import '../modules/splash/splash_view.dart';
import '../modules/login/login_binding.dart';
import '../modules/login/login_view.dart';
import '../modules/register/register_binding.dart';
import '../modules/register/register_view.dart';

// Student
import '../modules/student/student_main_controller.dart';
import '../modules/student/student_main_view.dart';
import '../modules/student/property_detail/property_detail_binding.dart';
import '../modules/student/property_detail/property_detail_view.dart';
import '../modules/student/room_detail/room_detail_view.dart';
import '../modules/student/favorites/favorites_view.dart';
import '../modules/student/visit_requests/visit_requests_view.dart';
import '../modules/student/profile/student_profile_view.dart';

// Owner
import '../modules/owner/owner_main_controller.dart';
import '../modules/owner/owner_main_view.dart';
import '../modules/owner/dashboard/owner_dashboard_view.dart';
import '../modules/owner/floors/owner_floors_view.dart';
import '../modules/owner/rooms/owner_rooms_view.dart';
import '../modules/owner/tenants/owner_tenants_view.dart';
import '../modules/owner/invoices/owner_invoices_view.dart';
import '../modules/owner/pricing/owner_pricing_view.dart';
import '../modules/owner/membership/owner_membership_view.dart';

// Legacy Demo
import '../modules/post/post_binding.dart';
import '../modules/post/post_form_binding.dart';
import '../modules/post/post_form_view.dart';
import '../modules/post/post_view.dart';

class AppRoute {
  AppRoute._();

  static List<GetPage> getAllRoutes() {
    return [
      // Splash & Auth
      GetPage(
        name: AppRouteName.splash,
        page: () => const SplashView(),
        binding: SplashBinding(),
      ),
      GetPage(
        name: AppRouteName.login,
        page: () => const LoginView(),
        binding: LoginBinding(),
      ),
      GetPage(
        name: AppRouteName.register,
        page: () => const RegisterView(),
        binding: RegisterBinding(),
      ),

      // Student Experience
      GetPage(
        name: AppRouteName.studentMain,
        page: () => const StudentMainView(),
        binding: StudentMainBinding(),
      ),
      GetPage(
        name: AppRouteName.home,
        page: () => const StudentMainView(),
        binding: StudentMainBinding(),
      ),
      GetPage(
        name: AppRouteName.propertyDetail,
        page: () => const PropertyDetailView(),
        binding: PropertyDetailBinding(),
      ),
      GetPage(
        name: AppRouteName.roomDetail,
        page: () => const RoomDetailView(),
      ),
      GetPage(
        name: AppRouteName.favorites,
        page: () => const FavoritesView(),
      ),
      GetPage(
        name: AppRouteName.visitRequests,
        page: () => const VisitRequestsView(),
      ),
      GetPage(
        name: AppRouteName.profile,
        page: () => const StudentProfileView(),
      ),

      // Owner Experience
      GetPage(
        name: AppRouteName.ownerMain,
        page: () => const OwnerMainView(),
        binding: OwnerMainBinding(),
      ),
      GetPage(
        name: AppRouteName.ownerDashboard,
        page: () => const OwnerDashboardView(),
      ),
      GetPage(
        name: AppRouteName.ownerFloors,
        page: () => const OwnerFloorsView(),
      ),
      GetPage(
        name: AppRouteName.ownerRooms,
        page: () => const OwnerRoomsView(),
      ),
      GetPage(
        name: AppRouteName.ownerTenants,
        page: () => const OwnerTenantsView(),
      ),
      GetPage(
        name: AppRouteName.ownerInvoices,
        page: () => const OwnerInvoicesView(),
      ),
      GetPage(
        name: AppRouteName.ownerPricing,
        page: () => const OwnerPricingView(),
      ),
      GetPage(
        name: AppRouteName.ownerMembership,
        page: () => const OwnerMembershipView(),
      ),

      // Legacy Demo
      GetPage(
        name: AppRouteName.adminPost,
        page: () => PostView(),
        binding: PostBinding(),
      ),
      GetPage(
        name: AppRouteName.adminPostForm,
        page: () => PostFormView(),
        binding: PostFormBinding(),
      ),
    ];
  }
}
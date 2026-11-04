import 'package:get/get.dart';
import 'app_route_name.dart';
import '../core/middleware/auth_middleware.dart';

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

// Chat
import '../modules/chat/chat_list_view.dart';
import '../modules/chat/chat_detail_view.dart';

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
import '../modules/owner/profile/owner_profile_view.dart';
import '../modules/owner/visit_requests/owner_visit_requests_view.dart';
import '../modules/owner/visit_requests/owner_visit_requests_binding.dart';

// Legacy Demo
import '../modules/post/post_binding.dart';
import '../modules/post/post_form_binding.dart';
import '../modules/post/post_form_view.dart';
import '../modules/post/post_view.dart';

// Management Portal (Products & Employees)
import '../modules/portal/portal_binding.dart';
import '../modules/portal/portal_view.dart';
import '../modules/employee/employee_binding.dart';
import '../modules/employee/employee_list_view.dart';
import '../modules/employee/employee_form_binding.dart';
import '../modules/employee/employee_form_view.dart';
import '../modules/product/product_binding.dart';
import '../modules/product/product_list_view.dart';

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
        middlewares: [GuestGuard()],
      ),
      GetPage(
        name: AppRouteName.register,
        page: () => const RegisterView(),
        binding: RegisterBinding(),
        middlewares: [GuestGuard()],
      ),

      // Student Experience
      GetPage(
        name: AppRouteName.studentMain,
        page: () => const StudentMainView(),
        binding: StudentMainBinding(),
        middlewares: [StudentGuard()],
      ),
      GetPage(
        name: AppRouteName.home,
        page: () => const StudentMainView(),
        binding: StudentMainBinding(),
        middlewares: [StudentGuard()],
      ),
      GetPage(
        name: AppRouteName.propertyDetail,
        page: () => const PropertyDetailView(),
        binding: PropertyDetailBinding(),
        middlewares: [StudentGuard()],
      ),
      GetPage(
        name: AppRouteName.roomDetail,
        page: () => const RoomDetailView(),
        middlewares: [StudentGuard()],
      ),
      GetPage(
        name: AppRouteName.favorites,
        page: () => const FavoritesView(),
        middlewares: [StudentGuard()],
      ),
      GetPage(
        name: AppRouteName.visitRequests,
        page: () => const VisitRequestsView(),
        middlewares: [StudentGuard()],
      ),
      GetPage(
        name: AppRouteName.profile,
        page: () => const StudentProfileView(),
        middlewares: [StudentGuard()],
      ),

      // Chat
      GetPage(
        name: AppRouteName.chatList,
        page: () => const ChatListView(),
        middlewares: [AuthGuard()],
      ),
      GetPage(
        name: AppRouteName.chatDetail,
        page: () => const ChatDetailView(),
        middlewares: [AuthGuard()],
      ),

      // Owner Experience
      GetPage(
        name: AppRouteName.ownerMain,
        page: () => const OwnerMainView(),
        binding: OwnerMainBinding(),
        middlewares: [OwnerGuard()],
      ),
      GetPage(
        name: AppRouteName.ownerDashboard,
        page: () => const OwnerDashboardView(),
        middlewares: [OwnerGuard()],
      ),
      GetPage(
        name: AppRouteName.ownerFloors,
        page: () => const OwnerFloorsView(),
        middlewares: [OwnerGuard()],
      ),
      GetPage(
        name: AppRouteName.ownerRooms,
        page: () => const OwnerRoomsView(),
        middlewares: [OwnerGuard()],
      ),
      GetPage(
        name: AppRouteName.ownerTenants,
        page: () => const OwnerTenantsView(),
        middlewares: [OwnerGuard()],
      ),
      GetPage(
        name: AppRouteName.ownerInvoices,
        page: () => const OwnerInvoicesView(),
        middlewares: [OwnerGuard()],
      ),
      GetPage(
        name: AppRouteName.ownerPricing,
        page: () => const OwnerPricingView(),
        middlewares: [OwnerGuard()],
      ),
      GetPage(
        name: AppRouteName.ownerMembership,
        page: () => const OwnerMembershipView(),
        middlewares: [OwnerGuard()],
      ),
      GetPage(
        name: AppRouteName.ownerProfile,
        page: () => const OwnerProfileView(),
        middlewares: [OwnerGuard()],
      ),
      GetPage(
        name: AppRouteName.ownerVisitRequests,
        page: () => const OwnerVisitRequestsView(),
        binding: OwnerVisitRequestsBinding(),
        middlewares: [OwnerGuard()],
      ),

      // Legacy Demo
      GetPage(
        name: AppRouteName.adminPost,
        page: () => PostView(),
        binding: PostBinding(),
        middlewares: [OwnerGuard()],
      ),
      GetPage(
        name: AppRouteName.adminPostForm,
        page: () => PostFormView(),
        binding: PostFormBinding(),
        middlewares: [OwnerGuard()],
      ),

      // Management Portal (Products, Employees & Profile)
      GetPage(
        name: AppRouteName.portal,
        page: () => const PortalView(),
        binding: PortalBinding(),
        middlewares: [AuthGuard()],
      ),
      GetPage(
        name: AppRouteName.employeeList,
        page: () => const EmployeeListView(),
        binding: EmployeeBinding(),
        middlewares: [AuthGuard()],
      ),
      GetPage(
        name: AppRouteName.employeeForm,
        page: () => const EmployeeFormView(),
        binding: EmployeeFormBinding(),
        middlewares: [AuthGuard()],
      ),
      GetPage(
        name: AppRouteName.productList,
        page: () => const ProductListView(),
        binding: ProductBinding(),
        middlewares: [AuthGuard()],
      ),
    ];
  }
}

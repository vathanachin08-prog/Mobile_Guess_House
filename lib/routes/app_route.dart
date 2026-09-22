import 'package:demo_access_refresh_token_app/routes/app_route_name.dart';
import 'package:get/get.dart';

import '../modules/home/home_binding.dart';
import '../modules/home/home_view.dart';
import '../modules/login/login_binding.dart';
import '../modules/login/login_view.dart';
import '../modules/post/post_binding.dart';
import '../modules/post/post_form_binding.dart';
import '../modules/post/post_form_view.dart';
import '../modules/post/post_view.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/splash/splash_view.dart';

class AppRoute {
  AppRoute._();
  static List<GetPage> getAllRoutes(){
    return[
      GetPage(name: AppRouteName.splash, page: () => SplashView(), binding: SplashBinding()),
      GetPage(name: AppRouteName.home, page: () => HomeView(), binding: HomeBinding()),
      GetPage(
        name: AppRouteName.login,
        page: () => LoginView(),
        binding: LoginBinding(),
      ),
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
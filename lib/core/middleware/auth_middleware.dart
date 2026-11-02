import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../data/local/token_store_local.dart';
import '../../routes/app_route_name.dart';

/// Route guard for Owner routes.
/// Prevents unauthenticated users and students from accessing owner views.
class OwnerGuard extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    if (!TokenStoreLocal.hasToken()) {
      return const RouteSettings(name: AppRouteName.login);
    }
    if (!TokenStoreLocal.isOwner()) {
      return const RouteSettings(name: AppRouteName.studentMain);
    }
    return null;
  }
}

/// Route guard for Student routes.
/// Prevents unauthenticated users and owners from accessing student views.
class StudentGuard extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    if (!TokenStoreLocal.hasToken()) {
      return const RouteSettings(name: AppRouteName.login);
    }
    if (TokenStoreLocal.isOwner()) {
      return const RouteSettings(name: AppRouteName.ownerMain);
    }
    return null;
  }
}

/// Route guard for shared authenticated routes (e.g. Chat).
/// Prevents unauthenticated users from accessing.
class AuthGuard extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    if (!TokenStoreLocal.hasToken()) {
      return const RouteSettings(name: AppRouteName.login);
    }
    return null;
  }
}

/// Route guard for guest routes (Login, Register).
/// Redirects already logged-in users to their authorized home screen.
class GuestGuard extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    if (TokenStoreLocal.hasToken()) {
      if (TokenStoreLocal.isOwner()) {
        return const RouteSettings(name: AppRouteName.ownerMain);
      } else {
        return const RouteSettings(name: AppRouteName.studentMain);
      }
    }
    return null;
  }
}


class ConstantUri {
  // Use localhost for Windows/Web, 10.0.2.2 for Android emulator, or LAN IP for physical device
  static String baseUri = "http://localhost:30033";

  // Auth
  static String get login => "$baseUri/api/oauth/token";
  static String get register => "$baseUri/api/oauth/register";
  static String get refreshToken => "$baseUri/api/oauth/refresh";

  // Legacy demo
  static String get getAllPostPath => "$baseUri/api/app/post";

  // Public Rental Endpoints
  static String get publicProperties => "$baseUri/api/public/properties";
  static String publicPropertyDetail(dynamic id) => "$baseUri/api/public/properties/$id";
  static String publicRoomDetail(dynamic id) => "$baseUri/api/public/rooms/$id";
  static String publicReviews(dynamic propertyId) => "$baseUri/api/public/properties/$propertyId/reviews";

  // Owner & Authenticated Property/Room Endpoints
  static String get properties => "$baseUri/api/app/properties";
  static String get myProperties => "$baseUri/api/app/properties/my";
  static String propertyDetail(dynamic id) => "$baseUri/api/app/properties/$id";
  static String propertyRooms(dynamic propertyId) => "$baseUri/api/app/properties/$propertyId/rooms";
  static String roomDetail(dynamic id) => "$baseUri/api/app/rooms/$id";

  // Student Favorites
  static String get favorites => "$baseUri/api/app/favorites";
  static String deleteFavorite(dynamic id) => "$baseUri/api/app/favorites/$id";

  // Visit Requests
  static String get visitRequests => "$baseUri/api/app/visit-requests";
  static String get myVisitRequests => "$baseUri/api/app/visit-requests/my";
  static String ownerVisitRequests(dynamic propertyId) => "$baseUri/api/app/owner/visit-requests/$propertyId";
  static String acceptVisitRequest(dynamic id) => "$baseUri/api/app/visit-requests/$id/accept";
  static String rejectVisitRequest(dynamic id) => "$baseUri/api/app/visit-requests/$id/reject";
  static String cancelVisitRequest(dynamic id) => "$baseUri/api/app/visit-requests/$id/cancel";
  static String completeVisitRequest(dynamic id) => "$baseUri/api/app/visit-requests/$id/complete";

  // Reviews & Reports
  static String propertyReviews(dynamic propertyId) => "$baseUri/api/app/properties/$propertyId/reviews";
  static String propertyReports(dynamic propertyId) => "$baseUri/api/app/properties/$propertyId/reports";
}
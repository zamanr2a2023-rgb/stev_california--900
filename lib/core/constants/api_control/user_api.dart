import 'package:renizo/core/constants/api_control/global_api.dart';

class UserApi {
  static final String _base_api = "$api/users";
  static final String me = "$_base_api/me";
  static final String updateTown = "$_base_api/me/town";
  static final String townApi = "$api/towns/all";

  // ✅ Bookings (Customer)
  static final String bookingsMe = "$api/bookings/me";
  static final String createBooking = "$api/bookings";
  static String bookingById(String id) => "$api/bookings/$id";

  // ✅ Customer Home Screen
  static Uri customerHomeUri(String townId) {
    return Uri.parse("$api/customer/home").replace(
      queryParameters: {'townId': townId},
    );
  }

  // ✅ Search All (providers + services)
  static Uri searchUri({
    required String q,
    required String townId,
    String type = 'all',
  }) {
    return Uri.parse("$api/search").replace(
      queryParameters: {
        'q': q,
        'townId': townId,
        'type': type,
      },
    );
  }

  // ✅ Payment methods (customer) – GET list, POST add, PATCH default, DELETE
  static final String paymentMethods = "$api/payments/methods";
  static String paymentMethodSetDefault(String id) =>
      "$api/payments/methods/$id/default";
  static String paymentMethodById(String id) => "$api/payments/methods/$id";

  // ✅ Payments (customer)
  static final String paymentConfig = "$api/payments/config";
  static final String paymentIntent = "$api/payments/intent";

  // ✅ Booking price quote (customer)
  static final String bookingsQuote = "$api/bookings/quote";

  // ✅ Cabinet requests (customer)
  static final String cabinetRequests = "$api/cabinet-requests";
  static final String cabinetRequestsMe = "$api/cabinet-requests/me";
  static String cabinetRequestById(String id) => "$api/cabinet-requests/$id";
  static String cabinetRequestAcceptQuote(String id) =>
      "$api/cabinet-requests/$id/accept-quote";
  static String cabinetRequestCancel(String id) =>
      "$api/cabinet-requests/$id/cancel";
}

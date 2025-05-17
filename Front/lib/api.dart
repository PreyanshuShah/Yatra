const String baseUrl = "http://127.0.0.1:8000/auth/";

class APIEndpoints {

  static const String register = "${baseUrl}auth/register/";
  static const String login = "${baseUrl}auth/login/";
  static const String refreshToken = "${baseUrl}auth/refresh/";
  static const String protected = "${baseUrl}auth/protected/";


  static const String userProfile = "${baseUrl}auth/user-profile/";
  static const String changePassword = "${baseUrl}auth/change-password/";
  static const String passwordResetRequest = "${baseUrl}auth/password-reset-request/";


  static const String addVehicle = "${baseUrl}auth/add-vehicle/";
  static const String listVehicles = "${baseUrl}auth/list-vehicles/";
  static String vehicleDetail(int vehicleId) => "${baseUrl}auth/vehicle/$vehicleId/";
  static const String userVehicles = "${baseUrl}auth/user-vehicles/";
  static String updateVehicle(int vehicleId) => "${baseUrl}auth/update-vehicle/$vehicleId/";
  static String deleteVehicle(int vehicleId) => "${baseUrl}auth/delete-vehicle/$vehicleId/";
  static const String markVehicleUnavailable = "${baseUrl}auth/mark-vehicle-unavailable/";


  static String addFeedback(int vehicleId) => "${baseUrl}auth/feedback/add/$vehicleId/";
  static String listFeedback(int vehicleId) => "${baseUrl}auth/feedback/list/$vehicleId/";
  static const String myVehiclesFeedbacks = "${baseUrl}auth/my-vehicles-feedbacks/";

 
  static const String sendNotification = "${baseUrl}auth/send-notification/";
  static const String getNotifications = "${baseUrl}auth/notifications/";
  static String markNotificationAsRead(int notificationId) => "${baseUrl}auth/notifications/read/$notificationId/";


  static const String userTransactions = "${baseUrl}auth/user-transactions/";
  static const String verifyKhaltiPayment = "${baseUrl}auth/verify-khalti-epayment/";
  static const String khaltiPaymentSuccess = "${baseUrl}auth/payment/success/";


  static const String listPendingVehicles = "${baseUrl}auth/admin/pending-vehicles/";
  static String approveVehicle(int vehicleId) => "${baseUrl}auth/admin/approve-vehicle/$vehicleId/";


  static const String myBookings = "${baseUrl}auth/bookings/my/";
}

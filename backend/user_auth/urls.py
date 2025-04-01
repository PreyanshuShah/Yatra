from django.urls import path

from .views import delete_vehicle, khalti_payment_success, update_vehicle

from .views import (
    register, login, refresh_token, protected_view, password_reset_request,
    add_vehicle, list_vehicles, user_profile, user_transactions, user_vehicles,
    VehicleListView, VehicleDetailView, add_feedback, list_feedback, my_vehicles_feedbacks,
    send_notification, get_notifications, mark_notification_as_read,
    change_password, verify_khalti_epayment,  # ✅ Just once!
)

urlpatterns = [
    # ✅ Auth
    path("register/", register, name="register"),
    path("login/", login, name="login"),
    path("refresh/", refresh_token, name="refresh"),
    path("protected/", protected_view, name="protected"),

    # ✅ Profile
    path("user-profile/", user_profile, name="user_profile"),
    path("change-password/", change_password, name="change_password"),
    path("password-reset-request/", password_reset_request, name="password_reset_request"),

    # ✅ Vehicle
    path("add-vehicle/", add_vehicle, name="add_vehicle"),
    path("list-vehicles/", VehicleListView.as_view(), name="list_vehicles"),
    path("vehicle/<int:pk>/", VehicleDetailView.as_view(), name="vehicle_detail"),
    path("user-vehicles/", user_vehicles, name="user_vehicles"),

    # ✅ Feedback
    path("feedback/add/<int:vehicle_id>/", add_feedback, name="add_feedback"),
    path("feedback/list/<int:vehicle_id>/", list_feedback, name="list_feedback"),
    path("my-vehicles-feedbacks/", my_vehicles_feedbacks, name="my_vehicles_feedbacks"),

    # ✅ Notifications
    path("send-notification/", send_notification, name="send_notification"),
    path("notifications/", get_notifications, name="get_notifications"),
    path("notifications/read/<int:notification_id>/", mark_notification_as_read, name="mark_notification_as_read"),

    # ✅ Payments
   
    path("user-transactions/", user_transactions, name="user_transactions"),


    path("verify-khalti-epayment/", verify_khalti_epayment, name="verify_khalti_epayment"),
    path("verify-khalti-epayment/", verify_khalti_epayment, name="verify_khalti_epayment"),
    path("payment/success/", khalti_payment_success, name="payment-success"),


    path('update-vehicle/<int:vehicle_id>/', update_vehicle),
    path("delete-vehicle/<int:vehicle_id>/", delete_vehicle),




]

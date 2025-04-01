from django.contrib.auth.models import User
from django.contrib.auth import authenticate, update_session_auth_hash
from django.core.mail import send_mail
from django.conf import settings
from django.utils.http import urlsafe_base64_encode
from django.utils.encoding import force_bytes
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework_simplejwt.tokens import RefreshToken # type: ignore
from rest_framework import generics, permissions
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt


import requests # type: ignore
import json
import random
import string

from .models import Notification, Vehicle, Feedback, Profile, Payment
from .serializers import NotificationSerializer, VehicleSerializer, FeedbackSerializer, ProfileSerializer

# JWT Token Generation
def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        "refresh": str(refresh),
        "access": str(refresh.access_token),
    }

# Register API
@api_view(["POST"])
def register(request):
    username = request.data.get("username")
    password = request.data.get("password")
    email = request.data.get("email", "")

    if not username or not password:
        return Response({"error": "Username and password are required"}, status=400)

    if User.objects.filter(username=username).exists():
        return Response({"error": "Username already taken"}, status=400)

    if User.objects.filter(email=email).exists():
        return Response({"error": "Email is already in use"}, status=400)

    user = User.objects.create_user(username=username, password=password, email=email)
    return Response({"message": "User registered successfully", "user": username})

# Login API
@api_view(["POST"])
def login(request):
    username = request.data.get("username")
    password = request.data.get("password")
    user = authenticate(username=username, password=password)
    if user:
        tokens = get_tokens_for_user(user)
        return Response({"message": "Login successful", "user": username, "tokens": tokens})
    return Response({"error": "Invalid credentials"}, status=401)

# Password Reset
@api_view(["POST"])
def password_reset_request(request):
    email = request.data.get("email")
    try:
        user = User.objects.get(email=email)
        new_password = ''.join(random.choices(string.ascii_letters + string.digits, k=10))
        user.set_password(new_password)
        user.save()
        send_mail("Your New Password", f"Your new password is: {new_password}", settings.EMAIL_HOST_USER, [email])
        return Response({"message": "A new password has been sent to your email!"})
    except User.DoesNotExist:
        return Response({"error": "User with this email not found"}, status=404)

# Token Refresh
@api_view(["POST"])
def refresh_token(request):
    refresh = request.data.get("refresh")
    if not refresh:
        return Response({"error": "Refresh token is required"}, status=400)
    try:
        new_token = RefreshToken(refresh)
        return Response({"access": str(new_token.access_token)})
    except Exception:
        return Response({"error": "Invalid refresh token"}, status=401)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def protected_view(request):
    return Response({"message": f"Hello {request.user.username}, you are authenticated!"})

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def add_vehicle(request):
    user = request.user
    model = request.data.get("model")
    location = request.data.get("location")
    address = request.data.get("address")
    phone_number = request.data.get("phone_number")
    price = request.data.get("price")
    time_period = request.data.get("time_period")
    license_document = request.FILES.get("license_document")
    vehicle_image = request.FILES.get("vehicle_image")

    if not model or not location or not address or not phone_number or not price or not time_period or not vehicle_image:
        return Response({"error": "All fields are required"}, status=400)

    try:
        vehicle = Vehicle.objects.create(
            user=user,
            model=model,
            location=location,
            address=address,
            phone_number=phone_number,
            price=price,
            time_period=time_period,
            license_document=license_document,
            vehicle_image=vehicle_image,
        )
        serializer = VehicleSerializer(vehicle)
        return Response({"message": "Vehicle added successfully!", "vehicle": serializer.data}, status=201)
    except Exception as e:
        return Response({"error": str(e)}, status=500)

@api_view(["GET"])
def list_vehicles(request):
    vehicles = Vehicle.objects.all()
    serializer = VehicleSerializer(vehicles, many=True, context={'request': request})
    return Response(serializer.data)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def user_vehicles(request):
    vehicles = Vehicle.objects.filter(user=request.user)
    serializer = VehicleSerializer(vehicles, many=True, context={'request': request})
    return Response(serializer.data)

class VehicleListView(generics.ListAPIView):
    queryset = Vehicle.objects.all().prefetch_related('feedbacks')
    serializer_class = VehicleSerializer
    permission_classes = [permissions.AllowAny]

class VehicleDetailView(generics.RetrieveAPIView):
    queryset = Vehicle.objects.all().prefetch_related('feedbacks')
    serializer_class = VehicleSerializer
    permission_classes = [permissions.AllowAny]

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def add_feedback(request, vehicle_id):
    user = request.user
    comment = request.data.get("comment")
    rating = request.data.get("rating")

    if not comment or not rating:
        return Response({"error": "Comment and rating are required."}, status=400)

    try:
        vehicle = Vehicle.objects.get(id=vehicle_id)
        feedback = Feedback.objects.create(user=user, vehicle=vehicle, comment=comment, rating=rating)
        return Response({"message": "Feedback added successfully!", "feedback": FeedbackSerializer(feedback).data}, status=201)
    except Vehicle.DoesNotExist:
        return Response({"error": "Vehicle not found."}, status=404)
    


@api_view(["GET"])
def list_feedback(request, vehicle_id):
    try:
        vehicle = Vehicle.objects.get(id=vehicle_id)
        feedbacks = vehicle.feedbacks.all()
        return Response(FeedbackSerializer(feedbacks, many=True).data, status=200)
    except Vehicle.DoesNotExist:
        return Response({"error": "Vehicle not found."}, status=404)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def my_vehicles_feedbacks(request):
    vehicles = Vehicle.objects.filter(user=request.user)
    feedbacks = Feedback.objects.filter(vehicle__in=vehicles)
    serializer = FeedbackSerializer(feedbacks, many=True)
    return Response(serializer.data)

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def mark_notification_as_read(request, notification_id):
    try:
        notification = Notification.objects.get(id=notification_id, user=request.user)
        notification.is_read = True
        notification.save()
        return Response({"message": "Notification marked as read!"})
    except Notification.DoesNotExist:
        return Response({"error": "Notification not found"}, status=404)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def get_notifications(request):
    notifications = Notification.objects.filter(user=request.user).order_by("-created_at")
    serializer = NotificationSerializer(notifications, many=True)
    return Response(serializer.data)

@api_view(["POST"])
@permission_classes([IsAdminUser])
def send_notification(request):
    user_id = request.data.get("user_id")
    message = request.data.get("message")

    if not message:
        return Response({"error": "Message cannot be empty"}, status=400)

    if user_id:
        try:
            user = User.objects.get(id=user_id)
            Notification.objects.create(user=user, message=message)
            return Response({"message": "Notification sent successfully!"})
        except User.DoesNotExist:
            return Response({"error": "User not found"}, status=404)
    else:
        users = User.objects.all()
        for user in users:
            Notification.objects.create(user=user, message=message)
        return Response({"message": "Notification sent to all users!"})

@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def user_profile(request):
    user = request.user
    profile, _ = Profile.objects.get_or_create(user=user)

    if request.method == "POST":
        profile_image = request.FILES.get("profile_image")
        if profile_image:
            profile.profile_image = profile_image
            profile.save()
        return JsonResponse({"message": "Profile updated successfully!"})

    serializer = ProfileSerializer(profile, context={"request": request})
    return JsonResponse({
        "username": user.username,
        "email": user.email,
        "profile_image": request.build_absolute_uri(profile.profile_image.url) if profile.profile_image else "",
        "created_at": profile.created_at.strftime('%Y-%m-%d %H:%M:%S'),
    })

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def change_password(request):
    user = request.user
    current_password = request.data.get("current_password")
    new_password = request.data.get("new_password")

    if not current_password or not new_password:
        return Response({"error": "Both current and new passwords are required."}, status=400)

    if not user.check_password(current_password):
        return Response({"error": "Current password is incorrect."}, status=400)

    user.set_password(new_password)
    user.save()
    update_session_auth_hash(request, user)

    return Response({"message": "Password changed successfully!"}, status=200)



@api_view(["GET"])
@permission_classes([IsAuthenticated])
def user_transactions(request):
    transactions = Payment.objects.filter(user=request.user).order_by("-paid_at")
    data = [
        {
            "vehicle": t.vehicle.model,
            "amount": t.amount / 100,
            "transaction_id": t.transaction_id,
            "mobile": t.mobile,
            "paid_at": t.paid_at.strftime("%Y-%m-%d %H:%M:%S")
        }
        for t in transactions
    ]
    return Response({"transactions": data})


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def verify_khalti_epayment(request):
    try:
        user = request.user
        pidx = request.data.get("pidx")
        vehicle_id = request.data.get("vehicle_id")

        print("📥 Incoming payment verification request")
        print("➡️ User:", user.username)
        print("➡️ pidx:", pidx)
        print("➡️ vehicle_id:", vehicle_id)

        if not pidx or not vehicle_id:
            return Response({"error": "Missing pidx or vehicle_id"}, status=400)

      
        url = "https://a.khalti.com/api/v2/epayment/lookup/"
        headers = {"Authorization": f"Key {settings.KHALTI_SECRET_KEY}"}
        payload = {"pidx": pidx}

        response = requests.post(url, headers=headers, json=payload)

        print("📦 Khalti Response Status:", response.status_code)
        print("📦 Khalti Response:", response.text)

        if response.status_code == 200:
            data = response.json()

            if data.get("status") != "Completed":
                return Response({"error": "Payment not completed", "status": data.get("status")}, status=400)

            transaction_id = data.get("transaction_id") or data.get("idx") or pidx

            if Payment.objects.filter(transaction_id=transaction_id).exists():
                return Response({"error": "Duplicate transaction"}, status=400)

            try:
                vehicle = Vehicle.objects.get(id=vehicle_id)
            except Vehicle.DoesNotExist:
                return Response({"error": "Vehicle not found"}, status=404)

            Payment.objects.create(
                user=user,
                vehicle=vehicle,
                amount=data["total_amount"],
                transaction_id=transaction_id,
                mobile=data.get("mobile")  # Returns None if 'mobile' is missing, avoids crash
                

            )

            return Response({
                "message": "✅ Payment verified successfully!",
                "transaction_id": transaction_id
            })

        return Response({
            "error": "Khalti verification failed",
            "response": response.text
        }, status=response.status_code)

    except Exception as e:
        print("❌ Exception during payment verification:", str(e))
        return Response({"error": f"Server error: {str(e)}"}, status=500)


from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt

@csrf_exempt
def khalti_payment_success(request):
    return HttpResponse("""
        <html>
        <head>
            <title>Payment Success</title>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    background-color: #e0f7fa;
                    font-family: 'Segoe UI', sans-serif;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    text-align: center;
                }
                .container {
                    background-color: white;
                    padding: 30px 20px;
                    border-radius: 16px;
                    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
                    width: 90%;
                    max-width: 400px;
                }
                .emoji {
                    font-size: 64px;
                    margin-bottom: 15px;
                }
                h1 {
                    font-size: 28px;
                    color: #00796b;
                    margin-bottom: 10px;
                }
                p {
                    font-size: 16px;
                    color: #555;
                    margin-bottom: 20px;
                }
                a.button {
                    display: inline-block;
                    padding: 12px 24px;
                    background-color: #00796b;
                    color: white;
                    text-decoration: none;
                    border-radius: 8px;
                    font-weight: bold;
                    transition: background-color 0.2s ease;
                }
                a.button:hover {
                    background-color: #004d40;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="emoji">✅</div>
                <h1>Payment Successful</h1>
                <p>Your transaction was completed successfully.</p>
                <a class="button" href="myapp://home">Return to App</a>
            </div>
        </body>
        </html>
    """)

@api_view(["PUT"])
@permission_classes([IsAuthenticated])
def update_vehicle(request, vehicle_id):
    try:
        vehicle = Vehicle.objects.get(id=vehicle_id, user=request.user)
    except Vehicle.DoesNotExist:
        return Response({"error": "Vehicle not found or unauthorized"}, status=404)

    data = request.data
    vehicle.model = data.get("model", vehicle.model)
    vehicle.location = data.get("location", vehicle.location)
    vehicle.address = data.get("address", vehicle.address)
    vehicle.phone_number = data.get("phone_number", vehicle.phone_number)
    vehicle.price = data.get("price", vehicle.price)
    vehicle.time_period = data.get("time_period", vehicle.time_period)

    if request.FILES.get("license_document"):
        vehicle.license_document = request.FILES["license_document"]
    if request.FILES.get("vehicle_image"):
        vehicle.vehicle_image = request.FILES["vehicle_image"]

    vehicle.save()
    return Response({"message": "Vehicle updated successfully!"})

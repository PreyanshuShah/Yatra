from django.contrib.auth.models import User
from django.contrib.auth import authenticate, update_session_auth_hash
from django.core.mail import send_mail
from django.conf import settings
from django.utils.http import urlsafe_base64_encode
from django.utils.encoding import force_bytes
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from rest_framework_simplejwt.tokens import RefreshToken 
from rest_framework import generics, permissions
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.core.mail import send_mail
from .models import Notification, Payment, Vehicle  
from datetime import datetime
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
import requests
from django.conf import settings
from django.shortcuts import get_object_or_404

import requests #
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

from django.contrib.auth.models import User
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status

@api_view(["POST"])
def register(request):
    username = request.data.get("username")
    password = request.data.get("password")
    email = request.data.get("email")

    if not username or not password:
        return Response({"error": "Username and password are required"}, status=400)

    if User.objects.filter(username=username).exists():
        return Response({"error": "Username already taken"}, status=400)

    if User.objects.filter(email=email).exists():
        return Response({"error": "Email is already in use"}, status=400)

    user = User.objects.create_user(username=username, password=password, email=email)
    
  
    return Response({"message": "User registered successfully", "user": username}, status=status.HTTP_201_CREATED)



@api_view(["POST"])
def login(request):
    username = request.data.get("username")
    password = request.data.get("password")
    user = authenticate(username=username, password=password)

    if user:
        tokens = get_tokens_for_user(user)
        return Response({
            "message": "Login successful",
            "user": {
                "id": user.id,
                "username": user.username,
                "email": user.email
            },
            "tokens": tokens
        })

    return Response({"error": "Invalid credentials"}, status=401)


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

from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
import re
from .models import Vehicle
from .serializers import VehicleSerializer
from datetime import datetime

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

    #
    phone_pattern = r'^\+?[0-9]{10,15}$'
    if not re.match(phone_pattern, phone_number):
        return Response({"error": "Invalid phone number format."}, status=400)

  
    if price is None:
        return Response({"error": "Price is required."}, status=400)
    try:
        price = float(price)
        if price <= 0:
            raise ValueError
    except ValueError:
        return Response({"error": "Invalid price. Price must be a positive number."}, status=400)

    try:
        start_date_str, end_date_str = time_period.split(" to ")
        start_date = datetime.strptime(start_date_str, "%Y-%m-%d")
        end_date = datetime.strptime(end_date_str, "%Y-%m-%d")
        if start_date >= end_date:
            raise ValueError
    except (ValueError, TypeError):
        return Response({"error": "Invalid time period format. It must be 'YYYY-MM-DD to YYYY-MM-DD'."}, status=400)


    if not all([model, location, address, phone_number, price, time_period, vehicle_image, license_document]):
        return Response({"error": "All fields including image and license document are required."}, status=400)

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
            is_available=True,
            is_approved=False
        )

        serializer = VehicleSerializer(vehicle)
        return Response({
            "message": "Your vehicle listing has been submitted for review. It will be visible after admin approval.",
            "vehicle": serializer.data
        }, status=201)

    except Exception as e:
        return Response({"error": str(e)}, status=500)




@api_view(["GET"])
def list_vehicles(request):

    vehicles = Vehicle.objects.filter( is_approved=True)
    serializer = VehicleSerializer(vehicles, many=True, context={'request': request})
    return Response(serializer.data)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def user_vehicles(request):
    vehicles = Vehicle.objects.filter(user=request.user)
    serializer = VehicleSerializer(vehicles, many=True, context={'request': request})
    return Response(serializer.data)

class VehicleListView(generics.ListAPIView):
    serializer_class = VehicleSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        return Vehicle.objects.filter(is_available=True, is_approved=True).prefetch_related('feedbacks')



class VehicleDetailView(generics.RetrieveAPIView):
    serializer_class = VehicleSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        return Vehicle.objects.filter(is_available=True, is_approved=True).prefetch_related('feedbacks')



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
            "vehicle_id": t.vehicle.id,
            "vehicle": t.vehicle.model,
            "amount": t.amount / 100,
            "transaction_id": t.transaction_id,
            "mobile": t.mobile,
            "paid_at": t.paid_at.strftime("%Y-%m-%d %H:%M:%S")
        }
        for t in transactions
    ]
    return Response({"transactions": data})





from django.core.mail import EmailMultiAlternatives
from django.shortcuts import get_object_or_404
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import Notification, Payment, Vehicle
import requests
from django.conf import settings
from datetime import datetime

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def verify_khalti_epayment(request):
    try:
        user = request.user
        pidx = request.data.get("pidx")
        vehicle_id = request.data.get("vehicle_id")

        if not pidx or not vehicle_id:
            return Response({"error": "Missing pidx or vehicle_id"}, status=400)

        vehicle = get_object_or_404(Vehicle, id=vehicle_id)

        # Prevent booking own vehicle
        if vehicle.user == user:
            return Response({"error": "You cannot book your own vehicle."}, status=403)

        # Verify Khalti payment
        url = "https://a.khalti.com/api/v2/epayment/lookup/"
        headers = {"Authorization": f"Key {settings.KHALTI_SECRET_KEY}"}
        payload = {"pidx": pidx}

        resp = requests.post(url, headers=headers, json=payload)
        if resp.status_code != 200:
            return Response(
                {"error": "Khalti verification failed", "response": resp.text},
                status=resp.status_code,
            )

        data = resp.json()
        if data.get("status") != "Completed":
            return Response(
                {"error": "Payment not completed", "status": data.get("status")},
                status=400,
            )

        transaction_id = data.get("transaction_id") or data.get("idx") or pidx
        if Payment.objects.filter(transaction_id=transaction_id).exists():
            return Response({"error": "Duplicate transaction"}, status=400)

        # Save payment
        Payment.objects.create(
            user=user,
            vehicle=vehicle,
            amount=data["total_amount"],
            transaction_id=transaction_id,
            mobile=data.get("mobile"),
        )

        # Create in-app notification
        Notification.objects.create(
            user=user,
            message=f"Booking confirmed for vehicle: {vehicle.model}!"
        )

        # Prepare email content
        year = datetime.now().year
        subject = "✅ Booking Confirmed! Yatra Trip Details Inside 🚗🎉"
        text_content = (
            f"Dear {user.username},\n\n"
            f"Your booking for '{vehicle.model}' is confirmed!\n\n"
            f"Amount Paid: Rs. {int(data['total_amount'])/100}\n"
            f"Transaction ID: {transaction_id}\n\n"
            "Thank you for choosing Yatra!"
        )
        html_content = f"""
        <html>
          <body style="font-family:Arial,sans-serif;background:#f4f4f4;padding:20px;">
            <div style="max-width:600px;margin:auto;background:#fff;border-radius:8px;
                        box-shadow:0 2px 5px rgba(0,0,0,0.1);overflow:hidden;">
              <div style="background:#00ACC1;color:#fff;padding:20px;text-align:center;">
                <h1 style="margin:0;font-size:24px;">Booking Confirmed!</h1>
              </div>
              <div style="padding:20px;color:#333;">
                <p>Hi <strong>{user.username}</strong>,</p>
                <p>Your booking for <strong>{vehicle.model}</strong> has been confirmed.</p>
                <table width="100%" cellpadding="0" cellspacing="0" 
                       style="border-collapse:collapse;margin:20px 0;">
                  <tr>
                    <td style="padding:8px;border:1px solid #ddd;"><strong>Amount Paid</strong></td>
                    <td style="padding:8px;border:1px solid #ddd;">रू {int(data['total_amount'])/100:.2f}</td>
                  </tr>
                  <tr>
                    <td style="padding:8px;border:1px solid #ddd;"><strong>Transaction ID</strong></td>
                    <td style="padding:8px;border:1px solid #ddd;">{transaction_id}</td>
                  </tr>
                </table>
                <p style="text-align:center;">
                  <a href="http://your-app-url.com/bookings/{vehicle.id}/" 
                     style="display:inline-block;padding:12px 24px;border-radius:4px;
                            background:#00ACC1;color:#fff;text-decoration:none;
                            font-weight:bold;">
                    View Booking Details
                  </a>
                </p>
                <p>Thank you for choosing <strong>Yatra</strong>! Have a great trip.</p>
              </div>
              <div style="background:#f0f0f0;color:#888;padding:12px;text-align:center;
                          font-size:12px;">
                © {year} Yatra. All rights reserved.
              </div>
            </div>
          </body>
        </html>
        """

        # Send multipart email
        msg = EmailMultiAlternatives(
            subject,
            text_content,
            settings.EMAIL_HOST_USER,
            [user.email],
        )
        msg.attach_alternative(html_content, "text/html")
        msg.send(fail_silently=True)

        return Response({
            "message": "Payment verified successfully!",
            "transaction_id": transaction_id
        })

    except Exception as e:
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


@api_view(["DELETE"])
@permission_classes([IsAuthenticated])
def delete_vehicle(request, vehicle_id):
    try:
        vehicle = Vehicle.objects.get(id=vehicle_id, user=request.user)
        vehicle.delete()
        return Response({"message": "Vehicle deleted successfully!"})
    except Vehicle.DoesNotExist:
        return Response({"error": "Vehicle not found"}, status=404)


from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import Vehicle

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def mark_vehicle_unavailable(request):
    vehicle_id = request.data.get("vehicle_id")

    if not vehicle_id:
        return Response({"error": "Vehicle ID not provided"}, status=400)

    try:
        vehicle = Vehicle.objects.get(id=vehicle_id)
        vehicle.is_available = False
        vehicle.save()
        return Response({"message": "Vehicle marked as unavailable"}, status=200)
    except Vehicle.DoesNotExist:
        return Response({"error": "Vehicle not found"}, status=404)
    

@api_view(["POST"])
@permission_classes([IsAdminUser])
def approve_vehicle(request, vehicle_id):
    try:
        vehicle = Vehicle.objects.get(id=vehicle_id)
        vehicle.is_approved = True
        vehicle.save()

        # Optional: notify the user
        Notification.objects.create(
            user=vehicle.user,
            message=f"Your vehicle '{vehicle.model}' has been approved!"
        )

        return Response({"message": "Vehicle approved successfully!"})
    except Vehicle.DoesNotExist:
        return Response({"error": "Vehicle not found"}, status=404)

    
@api_view(["GET"])
@permission_classes([IsAdminUser])
def list_pending_vehicles(request):
    vehicles = Vehicle.objects.filter(is_approved=False)
    serializer = VehicleSerializer(vehicles, many=True, context={'request': request})
    return Response(serializer.data)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def my_bookings(request):
    bookings = Payment.objects.filter(user=request.user).select_related('vehicle').order_by("-paid_at")
    data = [
        {
            "vehicle_model": b.vehicle.model,
            "vehicle_image": request.build_absolute_uri(b.vehicle.vehicle_image.url) if b.vehicle.vehicle_image else None,
            "location": b.vehicle.location,
            "address": b.vehicle.address,
            "amount_paid": b.amount / 100,
            "transaction_id": b.transaction_id,
            "paid_at": b.paid_at.strftime("%Y-%m-%d %H:%M:%S")
        }
        for b in bookings
    ]
    return Response(data)

from django.shortcuts import get_object_or_404
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from datetime import datetime
from .models import Vehicle

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def check_availability(request):
    """
    Returns {"available": true} if:
      - The requested start/end are within vehicle.time_period
      - The vehicle is still marked available (not already rented)
    Otherwise returns {"available": false, "error": "..."}.
    """
    vehicle_id     = request.data.get("vehicle_id")
    start_str      = request.data.get("start_date")
    end_str        = request.data.get("end_date")

    if not all([vehicle_id, start_str, end_str]):
        return Response({"available": False, "error": "Missing fields"}, status=400)

    vehicle = get_object_or_404(Vehicle, id=vehicle_id)

    # Parse vehicle availability window
    try:
        avail_start_str, avail_end_str = vehicle.time_period.split(" to ")
        avail_start = datetime.strptime(avail_start_str, "%Y-%m-%d").date()
        avail_end   = datetime.strptime(avail_end_str,   "%Y-%m-%d").date()

        req_start   = datetime.strptime(start_str, "%Y-%m-%d").date()
        req_end     = datetime.strptime(end_str,   "%Y-%m-%d").date()
    except Exception:
        return Response({"available": False, "error": "Invalid date format"}, status=400)

  
    if req_start < avail_start or req_end > avail_end:
        return Response({
            "available": False,
            "error": "Requested dates outside vehicle's available period"
        }, status=200)

    if hasattr(vehicle, "available") and not vehicle.available:
        return Response({
            "available": False,
            "error": "Vehicle is no longer available"
        }, status=200)

    return Response({"available": True}, status=200)


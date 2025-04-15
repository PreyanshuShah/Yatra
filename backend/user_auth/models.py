from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator, MaxValueValidator




class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    profile_image = models.ImageField(upload_to="profile_images/", blank=True, null=True)  # ✅ Image upload field
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.user.username





from django.db import models
from django.contrib.auth.models import User

class Payment(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    vehicle = models.ForeignKey("Vehicle", on_delete=models.CASCADE)
    amount = models.IntegerField()  
    transaction_id = models.CharField(max_length=50, unique=True)
    # models.py
    mobile = models.CharField(max_length=15, null=True, blank=True)

    paid_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Payment {self.transaction_id} - {self.amount} NPR by {self.user.username}"



class Vehicle(models.Model):
    id = models.AutoField(primary_key=True)  # ✅ Explicitly define ID
    user = models.ForeignKey(User, on_delete=models.CASCADE, db_index=True)  # ✅ Indexed for better performance
    model = models.CharField(max_length=100)
    location = models.CharField(max_length=255)
    address = models.TextField()
    phone_number = models.CharField(max_length=15)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    time_period = models.CharField(max_length=50, default="")  # ✅ Prevents null issues
    license_document = models.FileField(upload_to="documents/", blank=True, null=True)  # ✅ Optional field
    vehicle_image = models.ImageField(upload_to="vehicles/")
    created_at = models.DateTimeField(auto_now_add=True)
    is_available = models.BooleanField(default=True)


    def __str__(self):
        return f"{self.model} - {self.user.username} - {self.price}"

    class Meta:
        ordering = ["-created_at"]  # ✅ Orders by latest firsts

# ✅ Feedback Models
class Feedback(models.Model):
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name="feedbacks", db_index=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="user_feedbacks") 
    comment = models.TextField()
    rating = models.IntegerField(default=5, validators=[MinValueValidator(1), MaxValueValidator(5)])  
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.vehicle.model} - {self.rating}⭐"

    class Meta:
        ordering = ["-created_at"]  
 
class Notification(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="notifications")
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Notification for {self.user.username}"

    class Meta:
        ordering = ["-created_at"]  # Show latest notifications first


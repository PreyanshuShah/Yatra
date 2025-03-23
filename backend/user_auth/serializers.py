from rest_framework import serializers
from .models import Vehicle, Feedback

class FeedbackSerializer(serializers.ModelSerializer):
    user = serializers.ReadOnlyField(source='user.username')  # Show username instead of user ID

    class Meta:
        model = Feedback
        fields = ['id', 'user', 'comment', 'rating', 'created_at']

class VehicleSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(read_only=True)  # ✅ Ensure id is included
    feedbacks = FeedbackSerializer(many=True, read_only=True)  # ✅ Include feedbacks
    license_document = serializers.FileField(required=False, allow_null=True)  # ✅ Include license_document field

    class Meta:
        model = Vehicle
        fields = [
            'id', 'model', 'location', 'address', 'phone_number', 
            'price', 'time_period', 'vehicle_image', 'license_document', 'feedbacks'
        ]

    def to_representation(self, instance):
        """Customize response: Only admins can see license_document"""
        representation = super().to_representation(instance)

        # ✅ Check if request context exists
        request = self.context.get('request')
        if request and not request.user.is_staff:
            # ❌ Remove license_document if user is NOT an admin
            representation.pop('license_document', None)

        return representation

from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ["id", "message", "is_read", "created_at"]


from rest_framework import serializers
from .models import Profile

class ProfileSerializer(serializers.ModelSerializer):
    user = serializers.ReadOnlyField(source="user.username")
    profile_image = serializers.ImageField(required=False)  # ✅ Accepts image upload

    class Meta:
        model = Profile
        fields = ["user", "profile_image", "created_at"]

from rest_framework import serializers
from .models import Payment

class PaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Payment
        fields = '__all__'

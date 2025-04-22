from rest_framework import serializers
from .models import Vehicle, Feedback, Notification, Profile, Payment


# ✅ Feedback Serializer
class FeedbackSerializer(serializers.ModelSerializer):
    user = serializers.ReadOnlyField(source='user.username')  # Show username instead of user ID

    class Meta:
        model = Feedback
        fields = ['id', 'user', 'comment', 'rating', 'created_at']


# ✅ Vehicle Serializer
class VehicleSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(read_only=True)
    feedbacks = FeedbackSerializer(many=True, read_only=True)
    license_document = serializers.FileField(required=False, allow_null=True)

    # ✅ Add this line
    owner_id = serializers.IntegerField(source='user.id', read_only=True)

    is_approved = serializers.BooleanField(read_only=True)
    is_available = serializers.BooleanField(read_only=True)
    created_at = serializers.DateTimeField(read_only=True)
    owner_id = serializers.IntegerField(source='user.id', read_only=True)


    class Meta:
        model = Vehicle
        fields = [
            'id', 'model', 'location', 'address', 'phone_number',
            'price', 'time_period', 'vehicle_image', 'license_document',
            'feedbacks', 'is_approved', 'is_available', 'created_at',
            'owner_id'  # ✅ Include in fields list
        ]

    def to_representation(self, instance):
        """Customize response: Only admins can see license_document"""
        representation = super().to_representation(instance)
        request = self.context.get('request')
        if request and not request.user.is_staff:
            representation.pop('license_document', None)
        return representation


# ✅ Notification Serializer
class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ["id", "message", "is_read", "created_at"]


# ✅ Profile Serializer
class ProfileSerializer(serializers.ModelSerializer):
    user = serializers.ReadOnlyField(source="user.username")
    profile_image = serializers.ImageField(required=False)

    class Meta:
        model = Profile
        fields = ["user", "profile_image", "created_at"]


# ✅ Payment Serializer
class PaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Payment
        fields = '__all__'

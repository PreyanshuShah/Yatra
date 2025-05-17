from rest_framework import serializers
from .models import Vehicle, Feedback, Notification, Profile, Payment


class FeedbackSerializer(serializers.ModelSerializer):
    user = serializers.ReadOnlyField(source='user.username')  

    class Meta:
        model = Feedback
        fields = ['id', 'user', 'comment', 'rating', 'created_at']



class VehicleSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(read_only=True)
    feedbacks = FeedbackSerializer(many=True, read_only=True)
    license_document = serializers.FileField(required=False, allow_null=True)


    owner_id = serializers.IntegerField(source='user.id', read_only=True)
    is_approved = serializers.BooleanField(read_only=True)
   
    created_at = serializers.DateTimeField(read_only=True)
    owner_id = serializers.IntegerField(source='user.id', read_only=True)


    class Meta:
        model = Vehicle
        fields = [
            'id', 'model', 'location', 'address', 'phone_number',
            'price', 'time_period', 'vehicle_image', 'license_document',
            'feedbacks', 'is_approved', 'is_available', 'created_at',
            'owner_id' 
        ]

    def to_representation(self, instance):
        """Customize response: Only admins can see license_document"""
        representation = super().to_representation(instance)
        request = self.context.get('request')
        if request and not request.user.is_staff:
            representation.pop('license_document', None)
        return representation



class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ["id", "message", "is_read", "created_at"]



class ProfileSerializer(serializers.ModelSerializer):
    user = serializers.ReadOnlyField(source="user.username")
    profile_image = serializers.ImageField(required=False)

    class Meta:
        model = Profile
        fields = ["user", "profile_image", "created_at"]



class PaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Payment
        fields = '__all__'

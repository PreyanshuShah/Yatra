from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils.safestring import mark_safe
from .models import Profile, Vehicle, Feedback, Notification  # ✅ Import Notification

### ✅ Custom Inline Feedback (To show Feedbacks inside Vehicle Admin Panel)
class FeedbackInline(admin.TabularInline):
    model = Feedback
    extra = 1  # ✅ Allows adding a new feedback directly in Vehicle Admin

### ✅ Customize Vehicle Admin Panel
@admin.register(Vehicle)
class VehicleAdmin(admin.ModelAdmin):
    list_display = ('model', 'user', 'formatted_price', 'location', 'address', 
                    'phone_number', 'time_period', 'created_at', 'view_image', 'view_license', 'delete_button')  
    search_fields = ('model', 'user__username', 'location', 'address', 'phone_number', 'price')  
    list_filter = ('location', 'created_at', 'price')  
    ordering = ('-created_at',)  
    inlines = [FeedbackInline]  # ✅ Shows feedback inside Vehicle details
    actions = ['delete_selected']  # ✅ Enables bulk delete option

    # ✅ Format price with currency sign
    def formatted_price(self, obj):
        return f"${obj.price}"
    formatted_price.short_description = "Price"

    # ✅ Show Vehicle Image in Admin
    def view_image(self, obj):
        if obj.vehicle_image:
            return format_html('<img src="{}" width="80" height="50" style="border-radius:8px;"/>', obj.vehicle_image.url)
        return "No Image"
    view_image.short_description = "Vehicle Image"

    # ✅ Show License Document Preview (PDF/Image)
    def view_license(self, obj):
        if obj.license_document:
            file_url = obj.license_document.url
            if file_url.endswith(('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg')):  
                return format_html('<img src="{}" width="80" height="50" style="border-radius:8px;"/>', file_url)
            elif file_url.endswith('.pdf'):  
                return format_html('<a href="{}" target="_blank">📄 View PDF</a>', file_url)
            else:  
                return format_html('<a href="{}" target="_blank">📂 Download File</a>', file_url)
        return "No Document"
    view_license.short_description = "License Document"

    # ✅ Add Delete Button for Each Vehicle
    def delete_button(self, obj):
        delete_url = reverse('admin:%s_%s_delete' % (obj._meta.app_label, obj._meta.model_name), args=[obj.pk])
        return format_html('<a class="button" href="{}" style="color:red;">❌ Delete</a>', delete_url)
    delete_button.short_description = "Delete"

### ✅ Customize Feedback Admin Panel
@admin.register(Feedback)
class FeedbackAdmin(admin.ModelAdmin):
    list_display = ('user', 'vehicle', 'colored_rating', 'comment', 'created_at', 'delete_button')  
    search_fields = ('user__username', 'vehicle__model', 'comment')  
    list_filter = ('rating', 'created_at')  
    ordering = ('-created_at',)  
    actions = ['delete_selected']  # ✅ Enables bulk delete option

    # ✅ Add color indicators for ratings
    def colored_rating(self, obj):
        colors = {1: "red", 2: "orange", 3: "yellow", 4: "lightgreen", 5: "green"}
        return format_html(
            '<span style="color:{}; font-weight: bold;">{} ⭐</span>',
            colors.get(obj.rating, "black"),
            obj.rating,
        )
    colored_rating.short_description = "Rating"

    # ✅ Add Delete Button for Each Feedback
    def delete_button(self, obj):
        delete_url = reverse('admin:%s_%s_delete' % (obj._meta.app_label, obj._meta.model_name), args=[obj.pk])
        return format_html('<a class="button" href="{}" style="color:red;">❌ Delete</a>', delete_url)
    delete_button.short_description = "Delete"

### ✅ Customize Profile Admin Panel
@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'created_at', 'profile_link', 'delete_button')  
    search_fields = ('user__username',)  
    ordering = ('-created_at',)  
    actions = ['delete_selected']  # ✅ Enables bulk delete option

    # ✅ Generate Profile Link for Admin
    def profile_link(self, obj):
        return format_html('<a href="/admin/auth/user/{}/change/">View User</a>', obj.user.id)
    profile_link.short_description = "Profile Link"

    # ✅ Add Delete Button for Each Profile
    def delete_button(self, obj):
        delete_url = reverse('admin:%s_%s_delete' % (obj._meta.app_label, obj._meta.model_name), args=[obj.pk])
        return format_html('<a class="button" href="{}" style="color:red;">❌ Delete</a>', delete_url)
    delete_button.short_description = "Delete"

from django.contrib import admin
from .models import Notification

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ("user", "message", "is_read", "created_at")
    search_fields = ("user__username", "message")
    list_filter = ("is_read", "created_at")
    ordering = ("-created_at",)
    actions = ["mark_all_as_read", "send_notification"]

    def mark_all_as_read(self, request, queryset):
        queryset.update(is_read=True)
        self.message_user(request, "Selected notifications marked as read.")
    mark_all_as_read.short_description = "Mark selected as read"

    def send_notification(self, request, queryset):
        from django.contrib.auth.models import User
        message = "New notification from Admin Panel"
        users = User.objects.all()
        for user in users:
            Notification.objects.create(user=user, message=message)
        self.message_user(request, "Notification sent to all users!")
    send_notification.short_description = "Send Notification to All Users"

from django.contrib import admin
from .models import Payment

@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ('user', 'vehicle', 'amount', 'transaction_id', 'mobile', 'paid_at')
    search_fields = ('transaction_id', 'user__username', 'vehicle__model')

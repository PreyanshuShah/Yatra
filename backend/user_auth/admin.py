from django.contrib import admin, messages
from django.utils.html import format_html
from django.urls import reverse, path
from django.http import HttpResponseRedirect
from django.shortcuts import render, get_object_or_404
from .models import Profile, Vehicle, Feedback, Notification, Payment
from .admin_forms import NotificationForm
from django.contrib.auth.models import User


class FeedbackInline(admin.TabularInline):
    model = Feedback
    extra = 1

@admin.register(Vehicle)
class CustomVehicleAdmin(admin.ModelAdmin):
    list_display = (
        'model', 'user', 'formatted_price', 'location', 'address',
        'phone_number', 'time_period', 'created_at', 'view_image',
        'view_license', 'is_available', 'is_approved',  
        'approve_button', 'send_notification_button', 'delete_button'
    )
    search_fields = ('model', 'user__username', 'location', 'address', 'phone_number', 'price')
    list_filter = ('location', 'created_at', 'price', 'is_approved')
    ordering = ('-created_at',)
    inlines = [FeedbackInline]
    actions = ['delete_selected']

    def formatted_price(self, obj):
        return f"Rs. {obj.price}"
    formatted_price.short_description = "Price"

    def view_image(self, obj):
        if obj.vehicle_image:
            return format_html('<img src="{}" width="80" height="50" style="border-radius:8px;"/>', obj.vehicle_image.url)
        return "No Image"
    view_image.short_description = "Vehicle Image"

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

    def delete_button(self, obj):
        delete_url = reverse('admin:%s_%s_delete' % (obj._meta.app_label, obj._meta.model_name), args=[obj.pk])
        return format_html('<a class="button" href="{}" style="color:red;"> Delete</a>', delete_url)
    delete_button.short_description = "Delete"

    def send_notification_button(self, obj):
        send_url = reverse('admin:send_vehicle_notification', args=[obj.pk])
        return format_html('<a class="button" href="{}" style="color:blue;">📩 Notify</a>', send_url)
    send_notification_button.short_description = "Notify User"

    def approve_button(self, obj):
        if not obj.is_approved:
            approve_url = reverse('admin:approve_vehicle', args=[obj.pk])
            return format_html('<a class="button" href="{}" style="color:green;">Approve</a>', approve_url)
        return "✔️ Approved"
    approve_button.short_description = "Approve"

    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path('send-notification/<int:vehicle_id>/', self.admin_site.admin_view(self.send_vehicle_notification), name='send_vehicle_notification'),
            path('approve-vehicle/<int:vehicle_id>/', self.admin_site.admin_view(self.approve_vehicle), name='approve_vehicle'),
        ]
        return custom_urls + urls

    def send_vehicle_notification(self, request, vehicle_id):
        vehicle = get_object_or_404(Vehicle, pk=vehicle_id)
        user = vehicle.user

        if request.method == 'POST':
            form = NotificationForm(request.POST)
            if form.is_valid():
                Notification.objects.create(
                    user=user,
                    message=form.cleaned_data['message']
                )
                self.message_user(request, f"Notification sent to {user.username}.", level=messages.SUCCESS)
                return HttpResponseRedirect(reverse('admin:user_auth_vehicle_changelist'))
        else:
            form = NotificationForm(initial={
                'message': f"Hello {user.username}, regarding your vehicle: {vehicle.model}"
            })

        return render(request, 'admin/send_vehicle_notification.html', {
            'form': form,
            'vehicle': vehicle,
            'title': f"Send Notification to {user.username}"
        })

    def approve_vehicle(self, request, vehicle_id):
        vehicle = get_object_or_404(Vehicle, pk=vehicle_id)
        vehicle.is_approved = True
        vehicle.save()

        Notification.objects.create(
            user=vehicle.user,
            message=f"Your vehicle '{vehicle.model}' has been approved and is now live!"
        )

        self.message_user(request, f"✅ Vehicle '{vehicle.model}' approved!", level=messages.SUCCESS)
        return HttpResponseRedirect(reverse('admin:user_auth_vehicle_changelist'))


@admin.register(Feedback)
class FeedbackAdmin(admin.ModelAdmin):
    list_display = ('user', 'vehicle', 'colored_rating', 'comment', 'created_at', 'delete_button')
    search_fields = ('user__username', 'vehicle__model', 'comment')
    list_filter = ('rating', 'created_at')
    ordering = ('-created_at',)
    actions = ['delete_selected']

    def colored_rating(self, obj):
        colors = {1: "red", 2: "orange", 3: "yellow", 4: "lightgreen", 5: "green"}
        return format_html(
            '<span style="color:{}; font-weight: bold;">{} ⭐</span>',
            colors.get(obj.rating, "black"),
            obj.rating,
        )
    colored_rating.short_description = "Rating"

    def delete_button(self, obj):
        delete_url = reverse('admin:%s_%s_delete' % (obj._meta.app_label, obj._meta.model_name), args=[obj.pk])
        return format_html('<a class="button" href="{}" style="color:red;">❌ Delete</a>', delete_url)
    delete_button.short_description = "Delete"

# Profile Admin
@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'created_at', 'profile_link', 'delete_button')
    search_fields = ('user__username',)
    ordering = ('-created_at',)
    actions = ['delete_selected']

    def profile_link(self, obj):
        return format_html('<a href="/admin/auth/user/{}/change/">View User</a>', obj.user.id)
    profile_link.short_description = "Profile Link"

    def delete_button(self, obj):
        delete_url = reverse('admin:%s_%s_delete' % (obj._meta.app_label, obj._meta.model_name), args=[obj.pk])
        return format_html('<a class="button" href="{}" style="color:red;">❌ Delete</a>', delete_url)
    delete_button.short_description = "Delete"

# Notification Admin
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
        message = "New notification from Admin Panel"
        users = User.objects.all()
        for user in users:
            Notification.objects.create(user=user, message=message)
        self.message_user(request, "Notification sent to all users!")
    send_notification.short_description = "Send Notification to All Users"

# Payment Admin
@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ('user', 'vehicle', 'amount', 'transaction_id', 'mobile', 'paid_at')
    search_fields = ('transaction_id', 'user__username', 'vehicle__model')

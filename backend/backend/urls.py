from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse
from django.conf import settings
from django.conf.urls.static import static

# ✅ Define a simple API home endpoint
def home(request):
    return JsonResponse({"message": "Welcome to the Django API!"})

urlpatterns = [
    path("admin/", admin.site.urls),
    path("auth/", include("user_auth.urls")),  # ✅ Your Authentication API
    path("", home),  # ✅ Default API response
]

# ✅ Serve Media Files in Development Mode
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

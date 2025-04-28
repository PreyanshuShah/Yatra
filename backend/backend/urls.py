from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse
from django.conf import settings
from django.conf.urls.static import static


def home(request):
    return JsonResponse({"message": "Welcome to the Django API!"})

urlpatterns = [
    path("admin/", admin.site.urls),
    path("auth/", include("user_auth.urls")),  
    path("", home),  
]


if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

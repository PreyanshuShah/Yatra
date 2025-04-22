import os
from pathlib import Path
from datetime import timedelta


BASE_DIR = Path(__file__).resolve().parent.parent


SECRET_KEY = 'your-secret-key'


DEBUG = True


ALLOWED_HOSTS = ['*']





INSTALLED_APPS = [
    # Default Django apps
    'django.contrib.auth',
    'django.contrib.admin',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'jazzmin',  

    # Third-party apps
    'corsheaders',  
    'rest_framework',
    'rest_framework_simplejwt',  
    'allauth',
    'allauth.account',
    'allauth.socialaccount',  

    # Your custom apps
    'user_auth',  # ✅ Your authentication app
]

SITE_ID = 1  # ✅ Required for Django authentication

# ✅ Middleware
MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',  # ✅ Must be before SecurityMiddleware
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'allauth.account.middleware.AccountMiddleware',  # ✅ Add this for Django Allauth
]

# ✅ CORS (Cross-Origin Requests) - Required for Flutter Web & Mobile
CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_METHODS = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
CORS_ALLOW_HEADERS = ["*"]

# ✅ Root URL configuration
ROOT_URLCONF = 'backend.urls'

# ✅ Templates
TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

# ✅ WSGI Application
WSGI_APPLICATION = 'backend.wsgi.application'
# DATABASES = {
#     'default': {
#         'ENGINE': 'django.db.backends.mysql',
#         'NAME': 'backend_db',
#         'USER': 'root',
#         'PASSWORD': '9807',  # Make sure this matches your MySQL password
#         'HOST': 'localhost',
#         'PORT': '3306',
       
#     }
# }

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'fyp',
        'USER': 'root',
        'PASSWORD': 'root',  # Make sure this matches your MySQL password
        'HOST': 'localhost',
        'PORT': '3307',
       
    }
}


# ✅ Password Validation
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
]

# ✅ Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# ✅ Static & Media Files
STATIC_URL = '/static/'
STATICFILES_DIRS = [os.path.join(BASE_DIR, "static")]
STATIC_ROOT = os.path.join(BASE_DIR, "staticfiles")
MEDIA_ROOT = os.path.join(BASE_DIR, "media")
MEDIA_URL = "/media/"

# ✅ Default Auto Field
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# ✅ Enable Email Backend for Password Reset
EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
EMAIL_HOST = "smtp.gmail.com"
EMAIL_PORT = 587
EMAIL_USE_TLS = True
EMAIL_HOST_USER = "preyanshushah@gmail.com"
EMAIL_HOST_PASSWORD = "wenp wcqd ztdm ypxr"

# ✅ Allow Large File Uploads for Vehicle Images & Documents
DATA_UPLOAD_MAX_MEMORY_SIZE = 5242880  # ✅ Allows files up to 5MB
FILE_UPLOAD_MAX_MEMORY_SIZE = 10485760  # ✅ Allows files up to 10MB

# ✅ Django REST Framework Configuration with JWT Authentication
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.AllowAny',  # ✅ Allows unauthenticated access
    ),
}

# ✅ JWT Token Security Configuration
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(days=3),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'AUTH_HEADER_TYPES': ('Bearer',),
}

KHALTI_SECRET_KEY = "76696163503e4c65bd22cc09a85af655"
KHALTI_PUBLIC_KEY = "120a2140f1d14502adf70fa75e5565b2"

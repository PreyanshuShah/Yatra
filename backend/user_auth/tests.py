from rest_framework.test import APITestCase
from rest_framework import status
from django.contrib.auth.models import User
from django.urls import reverse
from django.core.files.uploadedfile import SimpleUploadedFile

class VehicleTest(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="newuser", password="newpassword123", email="newuser@example.com"
        )

        # Log in the user to get access token
        login_url = reverse('login')  
        data = {
            "username": "newuser",
            "password": "newpassword123",
        }

        response = self.client.post(login_url, data, format='json')

    
        if 'tokens' in response.data and 'access' in response.data['tokens']:
            self.access_token = response.data['tokens']['access']
        else:
            self.fail(f"Login failed, no access token found. Response data: {response.data}")

    def test_add_vehicle(self):
        url = reverse('add_vehicle')  

    
        license_document = SimpleUploadedFile(
            "license_document.pdf", b"fake license document content", content_type="application/pdf"
        )
        vehicle_image = SimpleUploadedFile(
            "vehicle_image.jpg", b"fake vehicle image content", content_type="image/jpeg"
        )

        # Vehicle data
        data = {
            "model": "Toyota Corolla",
            "location": "Kathmandu",
            "address": "Some address",
            "phone_number": "1234567890",
            "price": "1000",
            "time_period": "24 hours",
            "license_document": license_document,
            "vehicle_image": vehicle_image,
        }

        response = self.client.post(
            url, data, format='multipart', HTTP_AUTHORIZATION=f'Bearer {self.access_token}'
        )

        # Print the response data for debugging purposes
        print(response.data)

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['message'], "Vehicle added successfully!")

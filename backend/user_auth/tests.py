from rest_framework.test import APITestCase
from rest_framework import status
from django.contrib.auth.models import User
from django.core.files.uploadedfile import SimpleUploadedFile
from .models import Vehicle

class VehicleTests(APITestCase):

    def setUp(self):
        # Create a user
        self.user = User.objects.create_user(username='testuser', password='password123')
        
        # Log in to get the token
        response = self.client.post('/auth/login/', {'username': 'testuser', 'password': 'password123'})
        self.token = response.data['tokens']['access']  # Make sure the response includes the access token
        self.client.credentials(HTTP_AUTHORIZATION='Bearer ' + self.token)  # Pass the token in the headers

    def test_add_vehicle_success(self):
        """Test adding a vehicle with image and document."""
        
        # Create fake file data for the image and document
        vehicle_image = SimpleUploadedFile("test_image.jpg", b"file_content", content_type="image/jpeg")
        license_document = SimpleUploadedFile("test_license.pdf", b"file_content", content_type="application/pdf")
        
        # Prepare the data for vehicle creation
        data = {
            'model': 'Test Vehicle',
            'location': 'Kathmandu',
            'address': 'Test Address',
            'phone_number': '1234567890',
            'price': '1000.00',
            'time_period': '2023-01-01 to 2023-12-31',
            'vehicle_image': vehicle_image,
            'license_document': license_document
        }

        # Send POST request to add vehicle
        response = self.client.post('/auth/add-vehicle/', data, format='multipart')

        # Use response.json() to access the data
        response_data = response.json()

        # Assert the response status is HTTP 201 Created
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('vehicle', response_data)
        self.assertEqual(response_data['message'], "Vehicle added successfully!")

    def test_add_vehicle_invalid_data(self):
        """Test adding a vehicle without required fields (e.g., missing image)."""
        
        # Prepare data without vehicle image
        data = {
            'model': 'Test Vehicle',
            'location': 'Kathmandu',
            'address': 'Test Address',
            'phone_number': '1234567890',
            'price': '1000.00',
            'time_period': '2023-01-01 to 2023-12-31',
        }

        # Send POST request without vehicle image
        response = self.client.post('/auth/add-vehicle/', data, format='multipart')

        # Use response.json() to access the error
        response_data = response.json()

        # Print the error message
        print(f"Add Vehicle Invalid Data Error: {response_data.get('error', 'Unknown error')}")
        
        # Assert the response status is HTTP 400 Bad Request
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response_data)

    def test_add_vehicle_missing_fields(self):
        """Test adding a vehicle with missing required fields."""
        
        # Create fake file data for the image and document
        vehicle_image = SimpleUploadedFile("test_image.jpg", b"file_content", content_type="image/jpeg")
        license_document = SimpleUploadedFile("test_license.pdf", b"file_content", content_type="application/pdf")
        
        # Prepare data with missing price
        data = {
            'model': 'Test Vehicle',
            'location': 'Kathmandu',
            'address': 'Test Address',
            'phone_number': '1234567890',
            'time_period': '2023-01-01 to 2023-12-31',
            'vehicle_image': vehicle_image,
            'license_document': license_document
        }

        # Send POST request with missing price
        response = self.client.post('/auth/add-vehicle/', data, format='multipart')

        # Use response.json() to access the error
        response_data = response.json()

        # Print the error message
        print(f"Add Vehicle Missing Fields Error: {response_data.get('error', 'Unknown error')}")
        
        # Assert the response status is HTTP 400 Bad Request
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response_data)

    def test_add_vehicle_invalid_phone_number(self):
        """Test adding a vehicle with an invalid phone number."""
        
        # Create fake file data for the image and document
        vehicle_image = SimpleUploadedFile("test_image.jpg", b"file_content", content_type="image/jpeg")
        license_document = SimpleUploadedFile("test_license.pdf", b"file_content", content_type="application/pdf")
        
        # Prepare data with an invalid phone number
        data = {
            'model': 'Test Vehicle',
            'location': 'Kathmandu',
            'address': 'Test Address',
            'phone_number': '12345',  # Invalid phone number
            'price': '1000.00',
            'time_period': '2023-01-01 to 2023-12-31',
            'vehicle_image': vehicle_image,
            'license_document': license_document
        }

        # Send POST request with invalid phone number
        response = self.client.post('/auth/add-vehicle/', data, format='multipart')

        # Use response.json() to access the error
        response_data = response.json()

        # Print the error message
        print(f"Add Vehicle Invalid Phone Number Error: {response_data.get('error', 'Unknown error')}")
        
        # Assert the response status is HTTP 400 Bad Request
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response_data)

    def test_add_vehicle_missing_image(self):
        """Test adding a vehicle without a vehicle image."""
        
        # Create fake file data for the license document (but no vehicle image)
        license_document = SimpleUploadedFile("test_license.pdf", b"file_content", content_type="application/pdf")
        
        # Prepare data without vehicle image
        data = {
            'model': 'Test Vehicle',
            'location': 'Kathmandu',
            'address': 'Test Address',
            'phone_number': '1234567890',
            'price': '1000.00',
            'time_period': '2023-01-01 to 2023-12-31',
            'license_document': license_document
        }

        # Send POST request without vehicle image
        response = self.client.post('/auth/add-vehicle/', data, format='multipart')

        # Use response.json() to access the error
        response_data = response.json()

        # Print the error message
        print(f"Add Vehicle Missing Image Error: {response_data.get('error', 'Unknown error')}")
        
        # Assert the response status is HTTP 400 Bad Request
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response_data)

    def test_admin_approval_of_vehicle(self):
        """Test if admin can approve a vehicle after it's added by a normal user."""
        
        # Create vehicle as normal user
        vehicle_image = SimpleUploadedFile("test_image.jpg", b"file_content", content_type="image/jpeg")
        license_document = SimpleUploadedFile("test_license.pdf", b"file_content", content_type="application/pdf")
        
        data = {
            'model': 'Test Vehicle',
            'location': 'Kathmandu',
            'address': 'Test Address',
            'phone_number': '1234567890',
            'price': '1000.00',
            'time_period': '2023-01-01 to 2023-12-31',
            'vehicle_image': vehicle_image,
            'license_document': license_document
        }

        # Add vehicle
        response = self.client.post('/auth/add-vehicle/', data, format='multipart')
        vehicle_id = response.json()['vehicle']['id']  # Get the vehicle id from the response

        # Admin login
        self.client.credentials(HTTP_AUTHORIZATION='Bearer ' + self.get_admin_token())  # Log in as admin

        # Admin approves vehicle
        approval_response = self.client.post(f'/auth/approve-vehicle/{vehicle_id}/', {})
        
        # Assert 200 OK response
        self.assertEqual(approval_response.status_code, status.HTTP_200_OK)
        self.assertIn('message', approval_response.json())
        self.assertEqual(approval_response.json()['message'], "Vehicle approved successfully!")

    def test_view_vehicle_feedback(self):
        """Test if feedback can be viewed for a specific vehicle."""
        
        # Create vehicle as normal user
        vehicle_image = SimpleUploadedFile("test_image.jpg", b"file_content", content_type="image/jpeg")
        license_document = SimpleUploadedFile("test_license.pdf", b"file_content", content_type="application/pdf")
        
        data = {
            'model': 'Test Vehicle',
            'location': 'Kathmandu',
            'address': 'Test Address',
            'phone_number': '1234567890',
            'price': '1000.00',
            'time_period': '2023-01-01 to 2023-12-31',
            'vehicle_image': vehicle_image,
            'license_document': license_document
        }

        response = self.client.post('/auth/add-vehicle/', data, format='multipart')
        vehicle_id = response.json()['vehicle']['id']  # Get the vehicle id from the response
        
        # Add feedback
        feedback_data = {
            'comment': 'Great vehicle!',
            'rating': 5
        }

        self.client.post(f'/auth/add-feedback/{vehicle_id}/', feedback_data)
        
        # Fetch feedback for the vehicle
        feedback_response = self.client.get(f'/auth/list-feedback/{vehicle_id}/')
        
        self.assertEqual(feedback_response.status_code, status.HTTP_200_OK)
        self.assertIn('feedback', feedback_response.json())

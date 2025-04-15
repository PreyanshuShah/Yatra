from django.db import transaction
from django.test import TransactionTestCase
from django.contrib.auth.models import User
from rest_framework import status
from rest_framework.test import APIClient
from django.urls import reverse

class UserSignupTestCase(TransactionTestCase):
    def setUp(self):
        # Ensure you have a clean state for each test
        self.client = APIClient()

    def test_signup_success(self):
        data = {
            'username': 'newuser',
            'password': 'newpassword123',
            'email': 'newuser@example.com'
        }

        # Check if the registration process works
        response = self.client.post(reverse('register'), data, format='json')
        
        # Print the response data for debugging purposes
        print("Response Data on Signup Success:", response.data)
        
        # Expect successful creation of a user
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['message'], 'User registered successfully')
        user = User.objects.get(username='newuser')
        self.assertEqual(user.email, 'newuser@example.com')

    def test_signup_existing_username(self):
        # Ensure to test for pre-created users with the same username
        User.objects.create_user(username='existinguser', password='password123', email='existing@example.com')

        data = {
            'username': 'existinguser',
            'password': 'newpassword123',
            'email': 'newemail@example.com'
        }

        response = self.client.post(reverse('register'), data, format='json')

        # Print the response data for debugging purposes
        print("Response Data on Existing Username Signup:", response.data)
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data['error'], 'Username already taken')

    def test_signup_missing_fields(self):
        data = {
            'password': 'password123',
            'email': 'missinguser@example.com'
        }

        response = self.client.post(reverse('register'), data, format='json')

        # Print the response data for debugging purposes
        print("Response Data on Missing Fields Signup:", response.data)

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data['error'], 'Username and password are required')

    def test_signup_email_already_taken(self):
        # Pre-create a user with the same email
        User.objects.create_user(username='user1', password='password123', email='duplicate@example.com')

        data = {
            'username': 'user2',
            'password': 'password123',
            'email': 'duplicate@example.com'
        }

        response = self.client.post(reverse('register'), data, format='json')

        # Print the response data for debugging purposes
        print("Response Data on Email Taken Signup:", response.data)

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data['error'], 'Email is already in use')

    def tearDown(self):
        # Ensure test data is properly cleaned up
        User.objects.all().delete()
























from django.db import transaction
from django.test import TransactionTestCase
from django.contrib.auth.models import User
from rest_framework import status
from rest_framework.test import APIClient
from django.urls import reverse

class UserLoginTestCase(TransactionTestCase):
    def setUp(self):
        # Create a user for login tests
        self.user = User.objects.create_user(username='testuser', password='testpassword123', email='testuser@example.com')
        self.client = APIClient()

    def test_login_success(self):
        data = {
            'username': 'testuser',
            'password': 'testpassword123'
        }

        # Use reverse to dynamically generate the login URL
        response = self.client.post(reverse('login'), data, format='json')

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['message'], 'Login successful')
        self.assertEqual(response.data['user'], 'testuser')

    def test_login_invalid_username(self):
        data = {
            'username': 'nonexistentuser',
            'password': 'testpassword123'
        }
        response = self.client.post(reverse('login'), data, format='json')

        # Expecting 401 Unauthorized for invalid credentials
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        self.assertEqual(response.data['error'], 'Invalid credentials')

    def tearDown(self):
        # Clean up the user data after tests
        self.user.delete()

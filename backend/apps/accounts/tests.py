from django.contrib.auth.models import User
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status

from .models import Team, TeamMembership


class TeamModelTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user("testuser", password="testpass123")
        self.team = Team.objects.create(name="Test Team")
        TeamMembership.objects.create(
            user=self.user, team=self.team, role=TeamMembership.Role.OWNER
        )

    def test_team_str(self):
        self.assertEqual(str(self.team), "Test Team")

    def test_membership_str(self):
        m = TeamMembership.objects.first()
        self.assertIn("testuser", str(m))


class AccountsAPITest(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            "testuser", password="testpass123", email="test@example.com"
        )
        self.client.force_authenticate(user=self.user)
        self.team = Team.objects.create(name="Test Team")
        TeamMembership.objects.create(
            user=self.user, team=self.team, role=TeamMembership.Role.OWNER
        )

    def test_me_endpoint(self):
        response = self.client.get("/api/auth/me/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["username"], "testuser")

    def test_list_teams(self):
        response = self.client.get("/api/auth/teams/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)

    def test_create_team(self):
        response = self.client.post("/api/auth/teams/", {"name": "New Team"})
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(
            TeamMembership.objects.filter(
                user=self.user, team__name="New Team", role="owner"
            ).exists()
        )

    def test_jwt_login(self):
        client = APIClient()
        response = client.post(
            "/api/auth/login/",
            {"username": "testuser", "password": "testpass123"},
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)
        self.assertIn("refresh", response.data)

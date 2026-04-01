from django.contrib.auth.models import User
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status

from apps.accounts.models import Team, TeamMembership
from .models import Project, ProjectStatus, TechnicalCard


class ProjectAPITest(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user("testuser", password="testpass123")
        self.client.force_authenticate(user=self.user)

        self.team = Team.objects.create(name="Test Team")
        TeamMembership.objects.create(
            user=self.user, team=self.team, role=TeamMembership.Role.OWNER
        )

        self.status_dev = ProjectStatus.objects.create(
            name="В разработке", color="#F59E0B", order=1, team=self.team
        )

    def test_create_project(self):
        response = self.client.post(
            "/api/projects/",
            {
                "title": "Test Project",
                "description": "A test project",
                "status": self.status_dev.id,
                "team": self.team.id,
            },
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        # Technical card should be auto-created
        project = Project.objects.get(id=response.data["id"])
        self.assertTrue(hasattr(project, "technical_card"))

    def test_list_projects(self):
        Project.objects.create(
            title="P1", team=self.team, status=self.status_dev
        )
        response = self.client.get("/api/projects/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)

    def test_project_detail_includes_card(self):
        project = Project.objects.create(
            title="P1", team=self.team, status=self.status_dev
        )
        TechnicalCard.objects.create(
            project=project,
            github_url="https://github.com/test/repo",
            domain_name="test.com",
        )
        response = self.client.get(f"/api/projects/{project.id}/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("technical_card", response.data)
        self.assertEqual(response.data["technical_card"]["domain_name"], "test.com")

    def test_update_technical_card(self):
        project = Project.objects.create(title="P1", team=self.team)
        TechnicalCard.objects.create(project=project)
        response = self.client.patch(
            f"/api/projects/{project.id}/card/",
            {"domain_name": "example.com", "budget_required": "25000.00"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["domain_name"], "example.com")

    def test_filter_by_status(self):
        Project.objects.create(title="P1", team=self.team, status=self.status_dev)
        status_prod = ProjectStatus.objects.create(
            name="В проде", color="#10B981", order=3, team=self.team
        )
        Project.objects.create(title="P2", team=self.team, status=status_prod)

        response = self.client.get(f"/api/projects/?status={self.status_dev.id}")
        self.assertEqual(len(response.data["results"]), 1)
        self.assertEqual(response.data["results"][0]["title"], "P1")

    def test_list_statuses(self):
        response = self.client.get("/api/statuses/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)

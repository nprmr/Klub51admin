from django.contrib.auth.models import User
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status

from apps.accounts.models import Team, TeamMembership
from apps.projects.models import Project
from .models import Page, PageBlock


class PageAPITest(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user("testuser", password="testpass123")
        self.client.force_authenticate(user=self.user)

        self.team = Team.objects.create(name="Test Team")
        TeamMembership.objects.create(
            user=self.user, team=self.team, role=TeamMembership.Role.OWNER
        )
        self.project = Project.objects.create(title="Test Project", team=self.team)

    def test_create_page(self):
        response = self.client.post(
            "/api/pages/",
            {"project": self.project.id, "title": "Test Page"},
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        page = Page.objects.get(id=response.data["id"])
        self.assertEqual(page.created_by, self.user)

    def test_list_pages(self):
        Page.objects.create(
            project=self.project, title="Page 1", created_by=self.user
        )
        response = self.client.get(f"/api/pages/?project={self.project.id}")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)

    def test_page_detail_with_blocks(self):
        page = Page.objects.create(
            project=self.project, title="Page 1", created_by=self.user
        )
        PageBlock.objects.create(
            page=page,
            block_type="heading1",
            content={"text": "Hello World"},
            order=0,
        )
        PageBlock.objects.create(
            page=page,
            block_type="text",
            content={"text": "Some content here"},
            order=1,
        )
        response = self.client.get(f"/api/pages/{page.id}/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["blocks"]), 2)

    def test_reorder_blocks(self):
        page = Page.objects.create(
            project=self.project, title="Page 1", created_by=self.user
        )
        b1 = PageBlock.objects.create(page=page, block_type="text", order=0)
        b2 = PageBlock.objects.create(page=page, block_type="text", order=1)

        response = self.client.post(
            f"/api/pages/{page.id}/reorder_blocks/",
            {"block_ids": [b2.id, b1.id]},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        b1.refresh_from_db()
        b2.refresh_from_db()
        self.assertEqual(b2.order, 0)
        self.assertEqual(b1.order, 1)

    def test_nested_pages(self):
        parent = Page.objects.create(
            project=self.project, title="Parent", created_by=self.user
        )
        Page.objects.create(
            project=self.project,
            title="Child",
            parent=parent,
            created_by=self.user,
        )
        response = self.client.get(f"/api/pages/{parent.id}/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["children"]), 1)
        self.assertEqual(response.data["children"][0]["title"], "Child")

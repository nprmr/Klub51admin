from datetime import timedelta

from django.db.models import Q
from django.utils import timezone
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.pages.models import Page
from apps.pages.serializers import PageListSerializer
from apps.projects.models import Project, TechnicalCard
from apps.projects.serializers import ProjectListSerializer


class SearchView(APIView):
    """Global search across projects and pages."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        q = request.query_params.get("q", "").strip()
        if len(q) < 2:
            return Response({"projects": [], "pages": []})

        user_teams = request.user.team_memberships.values_list("team_id", flat=True)

        projects = Project.objects.filter(
            team_id__in=user_teams
        ).filter(
            Q(title__icontains=q)
            | Q(description__icontains=q)
            | Q(technical_card__domain_name__icontains=q)
            | Q(technical_card__notes__icontains=q)
        ).select_related("status").distinct()[:20]

        pages = Page.objects.filter(
            project__team_id__in=user_teams
        ).filter(
            Q(title__icontains=q)
        ).select_related("project")[:20]

        return Response({
            "projects": ProjectListSerializer(projects, many=True).data,
            "pages": PageListSerializer(pages, many=True).data,
        })


class DomainExpirationView(APIView):
    """List domains expiring within N days."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        days = int(request.query_params.get("days", 30))
        user_teams = request.user.team_memberships.values_list("team_id", flat=True)
        threshold = timezone.now().date() + timedelta(days=days)

        cards = TechnicalCard.objects.filter(
            project__team_id__in=user_teams,
            domain_expires__isnull=False,
            domain_expires__lte=threshold,
        ).select_related("project").order_by("domain_expires")

        results = []
        today = timezone.now().date()
        for card in cards:
            days_left = (card.domain_expires - today).days
            results.append({
                "project_id": card.project.id,
                "project_title": card.project.title,
                "domain_name": card.domain_name,
                "domain_registrar": card.domain_registrar,
                "domain_expires": card.domain_expires.isoformat(),
                "days_left": days_left,
                "is_expired": days_left < 0,
            })

        return Response(results)

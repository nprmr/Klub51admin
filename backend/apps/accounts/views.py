from django.contrib.auth.models import User
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Team, TeamMembership
from .serializers import (
    TeamCreateSerializer,
    TeamMembershipSerializer,
    TeamSerializer,
    UserSerializer,
)


class MeView(APIView):
    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)


class TeamViewSet(viewsets.ModelViewSet):
    serializer_class = TeamSerializer

    def get_queryset(self):
        return Team.objects.filter(
            memberships__user=self.request.user
        ).prefetch_related("memberships__user")

    def get_serializer_class(self):
        if self.action == "create":
            return TeamCreateSerializer
        return TeamSerializer

    def perform_create(self, serializer):
        team = serializer.save()
        TeamMembership.objects.create(
            user=self.request.user,
            team=team,
            role=TeamMembership.Role.OWNER,
        )

    @action(detail=True, methods=["get"])
    def members(self, request, pk=None):
        team = self.get_object()
        memberships = team.memberships.select_related("user")
        serializer = TeamMembershipSerializer(memberships, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=["post"])
    def add_member(self, request, pk=None):
        team = self.get_object()
        username = request.data.get("username")
        role = request.data.get("role", TeamMembership.Role.EDITOR)

        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            return Response(
                {"error": "User not found"}, status=status.HTTP_404_NOT_FOUND
            )

        membership, created = TeamMembership.objects.get_or_create(
            user=user, team=team, defaults={"role": role}
        )
        if not created:
            return Response(
                {"error": "User already in team"}, status=status.HTTP_400_BAD_REQUEST
            )

        return Response(
            TeamMembershipSerializer(membership).data,
            status=status.HTTP_201_CREATED,
        )

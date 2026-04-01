from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Project, ProjectStatus, TechnicalCard, TechnicalCardCustomField
from .serializers import (
    ProjectCreateUpdateSerializer,
    ProjectDetailSerializer,
    ProjectListSerializer,
    ProjectStatusSerializer,
    TechnicalCardCustomFieldSerializer,
    TechnicalCardSerializer,
)


class ProjectStatusViewSet(viewsets.ModelViewSet):
    serializer_class = ProjectStatusSerializer

    def get_queryset(self):
        return ProjectStatus.objects.filter(
            team__memberships__user=self.request.user
        )


class ProjectViewSet(viewsets.ModelViewSet):
    filterset_fields = ["status", "team"]
    search_fields = ["title", "description"]
    ordering_fields = ["title", "created_at", "updated_at"]

    def get_queryset(self):
        return (
            Project.objects.filter(team__memberships__user=self.request.user)
            .select_related("status", "technical_card")
            .prefetch_related("pages")
        )

    def get_serializer_class(self):
        if self.action in ("create", "update", "partial_update"):
            return ProjectCreateUpdateSerializer
        if self.action == "retrieve":
            return ProjectDetailSerializer
        return ProjectListSerializer

    def perform_create(self, serializer):
        project = serializer.save()
        TechnicalCard.objects.create(project=project)

    @action(detail=True, methods=["get", "patch"])
    def card(self, request, pk=None):
        project = self.get_object()
        card, _ = TechnicalCard.objects.get_or_create(project=project)

        if request.method == "PATCH":
            serializer = TechnicalCardSerializer(card, data=request.data, partial=True)
            serializer.is_valid(raise_exception=True)
            serializer.save()
            return Response(serializer.data)

        serializer = TechnicalCardSerializer(card)
        return Response(serializer.data)

    @action(detail=True, url_path="card/fields", methods=["get", "post"])
    def card_fields(self, request, pk=None):
        project = self.get_object()
        card, _ = TechnicalCard.objects.get_or_create(project=project)

        if request.method == "POST":
            serializer = TechnicalCardCustomFieldSerializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            serializer.save(card=card)
            return Response(serializer.data, status=status.HTTP_201_CREATED)

        fields = card.custom_fields.all()
        serializer = TechnicalCardCustomFieldSerializer(fields, many=True)
        return Response(serializer.data)


class TechnicalCardCustomFieldViewSet(viewsets.ModelViewSet):
    serializer_class = TechnicalCardCustomFieldSerializer

    def get_queryset(self):
        return TechnicalCardCustomField.objects.filter(
            card__project__team__memberships__user=self.request.user
        )

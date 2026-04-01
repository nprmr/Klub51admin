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
    filterset_fields = ["status", "team", "is_archived", "is_favorite"]
    search_fields = ["title", "description"]
    ordering_fields = ["title", "created_at", "updated_at", "order"]

    def get_queryset(self):
        qs = (
            Project.objects.filter(team__memberships__user=self.request.user)
            .select_related("status", "technical_card")
            .prefetch_related("pages")
        )
        # By default hide archived projects unless explicitly requested
        if self.request.query_params.get("is_archived") is None:
            qs = qs.filter(is_archived=False)
        return qs

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

    @action(detail=True, methods=["post"])
    def archive(self, request, pk=None):
        project = self.get_object()
        project.is_archived = not project.is_archived
        project.save(update_fields=["is_archived"])
        return Response({"is_archived": project.is_archived})

    @action(detail=True, methods=["post"])
    def favorite(self, request, pk=None):
        project = self.get_object()
        project.is_favorite = not project.is_favorite
        project.save(update_fields=["is_favorite"])
        return Response({"is_favorite": project.is_favorite})

    @action(detail=True, methods=["post"])
    def duplicate(self, request, pk=None):
        project = self.get_object()
        new_project = Project.objects.create(
            title=f"{project.title} (копия)",
            description=project.description,
            status=project.status,
            team=project.team,
            icon=project.icon,
        )
        # Copy technical card
        old_card = getattr(project, "technical_card", None)
        if old_card:
            TechnicalCard.objects.create(
                project=new_project,
                github_url=old_card.github_url,
                appstore_url=old_card.appstore_url,
                figma_url=old_card.figma_url,
                domain_name=old_card.domain_name,
                domain_registrar=old_card.domain_registrar,
                domain_expires=old_card.domain_expires,
                budget_required=old_card.budget_required,
                budget_currency=old_card.budget_currency,
                ad_cabinet_url=old_card.ad_cabinet_url,
                notes=old_card.notes,
            )
        else:
            TechnicalCard.objects.create(project=new_project)
        serializer = ProjectDetailSerializer(new_project)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

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

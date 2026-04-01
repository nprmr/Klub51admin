from django.db import models
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Page, PageBlock
from .serializers import (
    BlockReorderSerializer,
    PageBlockSerializer,
    PageCreateUpdateSerializer,
    PageDetailSerializer,
    PageListSerializer,
)


class PageViewSet(viewsets.ModelViewSet):
    filterset_fields = ["project", "parent"]
    search_fields = ["title"]

    def get_queryset(self):
        return (
            Page.objects.filter(
                project__team__memberships__user=self.request.user
            )
            .select_related("project", "created_by")
            .prefetch_related("blocks", "children")
        )

    def get_serializer_class(self):
        if self.action in ("create", "update", "partial_update"):
            return PageCreateUpdateSerializer
        if self.action == "retrieve":
            return PageDetailSerializer
        return PageListSerializer

    @action(detail=True, methods=["post"])
    def reorder_blocks(self, request, pk=None):
        page = self.get_object()
        serializer = BlockReorderSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        block_ids = serializer.validated_data["block_ids"]
        for order, block_id in enumerate(block_ids):
            PageBlock.objects.filter(id=block_id, page=page).update(order=order)

        return Response({"status": "ok"})


class PageBlockViewSet(viewsets.ModelViewSet):
    serializer_class = PageBlockSerializer

    def get_queryset(self):
        return PageBlock.objects.filter(
            page__project__team__memberships__user=self.request.user
        )

    def perform_create(self, serializer):
        page_id = self.request.data.get("page")
        page = Page.objects.get(
            id=page_id,
            project__team__memberships__user=self.request.user,
        )
        max_order = page.blocks.aggregate(
            max_order=models.Max("order")
        )["max_order"] or 0
        serializer.save(page=page, order=max_order + 1)

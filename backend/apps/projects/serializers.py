from rest_framework import serializers

from .models import Project, ProjectStatus, TechnicalCard, TechnicalCardCustomField


class ProjectStatusSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProjectStatus
        fields = ["id", "name", "color", "order", "team"]


class TechnicalCardCustomFieldSerializer(serializers.ModelSerializer):
    class Meta:
        model = TechnicalCardCustomField
        fields = ["id", "label", "value", "field_type", "order"]


class TechnicalCardSerializer(serializers.ModelSerializer):
    custom_fields = TechnicalCardCustomFieldSerializer(many=True, read_only=True)

    class Meta:
        model = TechnicalCard
        fields = [
            "id",
            "github_url",
            "appstore_url",
            "figma_url",
            "domain_name",
            "domain_registrar",
            "domain_expires",
            "budget_required",
            "budget_currency",
            "ad_cabinet_url",
            "notes",
            "custom_fields",
            "updated_at",
        ]


class ProjectListSerializer(serializers.ModelSerializer):
    status_name = serializers.CharField(source="status.name", read_only=True, default=None)
    status_color = serializers.CharField(source="status.color", read_only=True, default=None)
    page_count = serializers.SerializerMethodField()

    class Meta:
        model = Project
        fields = [
            "id",
            "title",
            "description",
            "icon",
            "status",
            "status_name",
            "status_color",
            "team",
            "is_archived",
            "is_favorite",
            "order",
            "page_count",
            "created_at",
            "updated_at",
        ]

    def get_page_count(self, obj):
        return obj.pages.count()


class ProjectDetailSerializer(serializers.ModelSerializer):
    status_name = serializers.CharField(source="status.name", read_only=True, default=None)
    status_color = serializers.CharField(source="status.color", read_only=True, default=None)
    technical_card = TechnicalCardSerializer(read_only=True)

    class Meta:
        model = Project
        fields = [
            "id",
            "title",
            "description",
            "icon",
            "status",
            "status_name",
            "status_color",
            "team",
            "is_archived",
            "is_favorite",
            "order",
            "technical_card",
            "created_at",
            "updated_at",
        ]


class ProjectCreateUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Project
        fields = ["id", "title", "description", "icon", "status", "team", "is_archived", "is_favorite", "order"]

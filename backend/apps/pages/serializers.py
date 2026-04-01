from rest_framework import serializers

from .models import Page, PageBlock


class PageBlockSerializer(serializers.ModelSerializer):
    class Meta:
        model = PageBlock
        fields = ["id", "block_type", "content", "order", "created_at", "updated_at"]


class PageListSerializer(serializers.ModelSerializer):
    children_count = serializers.SerializerMethodField()

    class Meta:
        model = Page
        fields = [
            "id",
            "title",
            "icon",
            "parent",
            "order",
            "children_count",
            "created_at",
            "updated_at",
        ]

    def get_children_count(self, obj):
        return obj.children.count()


class PageDetailSerializer(serializers.ModelSerializer):
    blocks = PageBlockSerializer(many=True, read_only=True)
    children = PageListSerializer(many=True, read_only=True)

    class Meta:
        model = Page
        fields = [
            "id",
            "project",
            "title",
            "icon",
            "parent",
            "order",
            "blocks",
            "children",
            "created_by",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["created_by"]


class PageCreateUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Page
        fields = ["id", "project", "title", "icon", "parent", "order"]

    def create(self, validated_data):
        validated_data["created_by"] = self.context["request"].user
        return super().create(validated_data)


class BlockReorderSerializer(serializers.Serializer):
    block_ids = serializers.ListField(child=serializers.IntegerField())

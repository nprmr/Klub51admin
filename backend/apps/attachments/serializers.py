from rest_framework import serializers

from .models import Attachment


class AttachmentSerializer(serializers.ModelSerializer):
    url = serializers.SerializerMethodField()

    class Meta:
        model = Attachment
        fields = [
            "id",
            "original_name",
            "content_type",
            "size",
            "url",
            "project",
            "uploaded_at",
        ]
        read_only_fields = ["original_name", "content_type", "size", "uploaded_at"]

    def get_url(self, obj):
        request = self.context.get("request")
        if request and obj.file:
            return request.build_absolute_uri(obj.file.url)
        return None


class AttachmentUploadSerializer(serializers.Serializer):
    file = serializers.FileField()
    project = serializers.IntegerField(required=False)

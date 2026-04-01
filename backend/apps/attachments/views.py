from rest_framework import parsers, status, viewsets
from rest_framework.response import Response

from apps.projects.models import Project

from .models import Attachment
from .serializers import AttachmentSerializer, AttachmentUploadSerializer


class AttachmentViewSet(viewsets.ModelViewSet):
    serializer_class = AttachmentSerializer
    parser_classes = [parsers.MultiPartParser, parsers.FormParser]

    def get_queryset(self):
        qs = Attachment.objects.filter(
            uploaded_by__team_memberships__team__memberships__user=self.request.user
        )
        project_id = self.request.query_params.get("project")
        if project_id:
            qs = qs.filter(project_id=project_id)
        return qs.distinct()

    def create(self, request, *args, **kwargs):
        upload_serializer = AttachmentUploadSerializer(data=request.data)
        upload_serializer.is_valid(raise_exception=True)

        uploaded_file = upload_serializer.validated_data["file"]
        project_id = upload_serializer.validated_data.get("project")

        project = None
        if project_id:
            project = Project.objects.filter(
                id=project_id,
                team__memberships__user=request.user,
            ).first()

        attachment = Attachment.objects.create(
            file=uploaded_file,
            original_name=uploaded_file.name,
            content_type=uploaded_file.content_type or "application/octet-stream",
            size=uploaded_file.size,
            uploaded_by=request.user,
            project=project,
        )

        serializer = AttachmentSerializer(attachment, context={"request": request})
        return Response(serializer.data, status=status.HTTP_201_CREATED)

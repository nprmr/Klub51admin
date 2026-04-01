from django.conf import settings
from django.db import models


class Attachment(models.Model):
    file = models.FileField(upload_to="attachments/%Y/%m/")
    original_name = models.CharField(max_length=500)
    content_type = models.CharField(max_length=100)
    size = models.PositiveIntegerField()
    uploaded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="attachments",
    )
    project = models.ForeignKey(
        "projects.Project",
        on_delete=models.CASCADE,
        related_name="attachments",
        null=True,
        blank=True,
    )
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-uploaded_at"]

    def __str__(self):
        return self.original_name

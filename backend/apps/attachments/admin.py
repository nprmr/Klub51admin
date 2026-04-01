from django.contrib import admin

from .models import Attachment


@admin.register(Attachment)
class AttachmentAdmin(admin.ModelAdmin):
    list_display = ["original_name", "content_type", "size", "uploaded_by", "project", "uploaded_at"]
    list_filter = ["content_type", "project"]
    search_fields = ["original_name"]

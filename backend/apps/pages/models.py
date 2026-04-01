from django.conf import settings
from django.db import models

from apps.projects.models import Project


class Page(models.Model):
    project = models.ForeignKey(
        Project,
        on_delete=models.CASCADE,
        related_name="pages",
    )
    title = models.CharField(max_length=500)
    icon = models.CharField(max_length=10, blank=True)
    parent = models.ForeignKey(
        "self",
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="children",
    )
    order = models.IntegerField(default=0)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["order", "title"]

    def __str__(self):
        return self.title


class PageBlock(models.Model):
    class BlockType(models.TextChoices):
        TEXT = "text", "Текст"
        HEADING1 = "heading1", "Заголовок 1"
        HEADING2 = "heading2", "Заголовок 2"
        HEADING3 = "heading3", "Заголовок 3"
        BULLET_LIST = "bullet_list", "Маркированный список"
        NUMBERED_LIST = "numbered_list", "Нумерованный список"
        TODO = "todo", "Чек-лист"
        TABLE = "table", "Таблица"
        CODE = "code", "Код"
        QUOTE = "quote", "Цитата"
        DIVIDER = "divider", "Разделитель"
        IMAGE = "image", "Изображение"

    page = models.ForeignKey(
        Page,
        on_delete=models.CASCADE,
        related_name="blocks",
    )
    block_type = models.CharField(
        max_length=20,
        choices=BlockType.choices,
        default=BlockType.TEXT,
    )
    content = models.JSONField(default=dict)
    order = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["order"]

    def __str__(self):
        return f"{self.block_type} block (page: {self.page.title})"

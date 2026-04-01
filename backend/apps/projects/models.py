from django.db import models

from apps.accounts.models import Team


class ProjectStatus(models.Model):
    name = models.CharField(max_length=100)
    color = models.CharField(max_length=7, default="#6B7280")
    order = models.IntegerField(default=0)
    team = models.ForeignKey(
        Team,
        on_delete=models.CASCADE,
        related_name="statuses",
    )

    class Meta:
        ordering = ["order", "name"]
        verbose_name_plural = "Project statuses"

    def __str__(self):
        return self.name


class Project(models.Model):
    title = models.CharField(max_length=300)
    description = models.TextField(blank=True)
    status = models.ForeignKey(
        ProjectStatus,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="projects",
    )
    team = models.ForeignKey(
        Team,
        on_delete=models.CASCADE,
        related_name="projects",
    )
    icon = models.CharField(max_length=10, blank=True)
    is_archived = models.BooleanField(default=False)
    is_favorite = models.BooleanField(default=False)
    order = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-is_favorite", "order", "-updated_at"]

    def __str__(self):
        return self.title


class TechnicalCard(models.Model):
    project = models.OneToOneField(
        Project,
        on_delete=models.CASCADE,
        related_name="technical_card",
    )
    github_url = models.URLField(blank=True)
    appstore_url = models.URLField(blank=True)
    figma_url = models.URLField(blank=True)
    domain_name = models.CharField(max_length=253, blank=True)
    domain_registrar = models.CharField(max_length=200, blank=True)
    domain_expires = models.DateField(null=True, blank=True)
    budget_required = models.DecimalField(
        max_digits=12, decimal_places=2, null=True, blank=True
    )
    budget_currency = models.CharField(max_length=3, default="RUB")
    ad_cabinet_url = models.URLField(blank=True)
    notes = models.TextField(blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Card: {self.project.title}"


class TechnicalCardCustomField(models.Model):
    class FieldType(models.TextChoices):
        TEXT = "text", "Текст"
        URL = "url", "Ссылка"
        DATE = "date", "Дата"
        NUMBER = "number", "Число"

    card = models.ForeignKey(
        TechnicalCard,
        on_delete=models.CASCADE,
        related_name="custom_fields",
    )
    label = models.CharField(max_length=200)
    value = models.TextField()
    field_type = models.CharField(
        max_length=10,
        choices=FieldType.choices,
        default=FieldType.TEXT,
    )
    order = models.IntegerField(default=0)

    class Meta:
        ordering = ["order"]

    def __str__(self):
        return f"{self.label}: {self.value}"

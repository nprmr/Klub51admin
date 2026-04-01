from django.contrib import admin

from .models import Project, ProjectStatus, TechnicalCard, TechnicalCardCustomField


class TechnicalCardCustomFieldInline(admin.TabularInline):
    model = TechnicalCardCustomField
    extra = 0


class TechnicalCardInline(admin.StackedInline):
    model = TechnicalCard
    extra = 0


@admin.register(ProjectStatus)
class ProjectStatusAdmin(admin.ModelAdmin):
    list_display = ["name", "color", "order", "team"]
    list_filter = ["team"]
    ordering = ["order"]


@admin.register(Project)
class ProjectAdmin(admin.ModelAdmin):
    list_display = ["title", "status", "team", "icon", "updated_at"]
    list_filter = ["status", "team"]
    search_fields = ["title", "description"]
    inlines = [TechnicalCardInline]


@admin.register(TechnicalCard)
class TechnicalCardAdmin(admin.ModelAdmin):
    list_display = ["project", "domain_name", "domain_expires", "budget_required"]
    search_fields = ["project__title", "domain_name"]
    inlines = [TechnicalCardCustomFieldInline]

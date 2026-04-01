from django.contrib import admin

from .models import Page, PageBlock


class PageBlockInline(admin.TabularInline):
    model = PageBlock
    extra = 0
    ordering = ["order"]


@admin.register(Page)
class PageAdmin(admin.ModelAdmin):
    list_display = ["title", "project", "parent", "order", "created_by", "updated_at"]
    list_filter = ["project"]
    search_fields = ["title"]
    inlines = [PageBlockInline]


@admin.register(PageBlock)
class PageBlockAdmin(admin.ModelAdmin):
    list_display = ["page", "block_type", "order", "updated_at"]
    list_filter = ["block_type", "page__project"]

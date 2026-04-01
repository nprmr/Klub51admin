from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import ProjectStatusViewSet, ProjectViewSet, TechnicalCardCustomFieldViewSet

router = DefaultRouter()
router.register(r"projects", ProjectViewSet, basename="project")
router.register(r"statuses", ProjectStatusViewSet, basename="status")
router.register(r"custom-fields", TechnicalCardCustomFieldViewSet, basename="custom-field")

urlpatterns = [
    path("", include(router.urls)),
]

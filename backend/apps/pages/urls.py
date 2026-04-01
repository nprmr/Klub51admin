from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import PageBlockViewSet, PageViewSet

router = DefaultRouter()
router.register(r"pages", PageViewSet, basename="page")
router.register(r"blocks", PageBlockViewSet, basename="block")

urlpatterns = [
    path("", include(router.urls)),
]

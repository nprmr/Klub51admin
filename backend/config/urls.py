from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    path("admin/", admin.site.urls),
    # Auth
    path("api/auth/login/", TokenObtainPairView.as_view(), name="token_obtain"),
    path("api/auth/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("api/auth/", include("apps.accounts.urls")),
    # API
    path("api/", include("apps.projects.urls")),
    path("api/", include("apps.pages.urls")),
    path("api/", include("apps.attachments.urls")),
    path("api/", include("apps.search.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

from django.urls import path

from .views import DomainExpirationView, SearchView

urlpatterns = [
    path("search/", SearchView.as_view(), name="search"),
    path("domains/expiring/", DomainExpirationView.as_view(), name="domains-expiring"),
]

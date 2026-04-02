from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .auth_views import (
    AppleAuthView,
    AuthProvidersView,
    ConnectedAccountsView,
    GitHubAuthView,
    GoogleAuthView,
    OTPRequestView,
    OTPVerifyView,
    SSOCallbackView,
    SSOConfigView,
)
from .views import MeView, TeamViewSet

router = DefaultRouter()
router.register(r"teams", TeamViewSet, basename="team")

urlpatterns = [
    path("me/", MeView.as_view(), name="me"),
    # Email OTP
    path("otp/request/", OTPRequestView.as_view(), name="otp-request"),
    path("otp/verify/", OTPVerifyView.as_view(), name="otp-verify"),
    # Social auth — token exchange
    path("social/github/", GitHubAuthView.as_view(), name="social-github"),
    path("social/google/", GoogleAuthView.as_view(), name="social-google"),
    path("social/apple/", AppleAuthView.as_view(), name="social-apple"),
    # SSO / OIDC
    path("sso/config/", SSOConfigView.as_view(), name="sso-config"),
    path("sso/callback/", SSOCallbackView.as_view(), name="sso-callback"),
    # Connected accounts
    path("connected-accounts/", ConnectedAccountsView.as_view(), name="connected-accounts"),
    # Providers info
    path("providers/", AuthProvidersView.as_view(), name="auth-providers"),
    # Teams
    path("", include(router.urls)),
]

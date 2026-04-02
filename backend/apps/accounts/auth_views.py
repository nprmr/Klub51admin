"""
Authentication views:
- Email OTP (passwordless) — send code, verify code
- Social auth (GitHub, Apple, Google) — token exchange
- SSO/OIDC
- Connected accounts management
"""

import json
import os
import urllib.parse
import urllib.request

import jwt
from django.conf import settings
from django.contrib.auth.models import User
from django.core.mail import send_mail
from django.template.loader import render_to_string
from rest_framework import serializers, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from allauth.socialaccount.models import SocialAccount

from .models import EmailOTP


def get_tokens_for_user(user):
    """Generate JWT token pair for a user."""
    refresh = RefreshToken.for_user(user)
    return {
        "access": str(refresh.access_token),
        "refresh": str(refresh),
        "user": {
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "first_name": user.first_name,
            "last_name": user.last_name,
        },
    }


# =============================================================================
# Email OTP Auth (passwordless)
# =============================================================================


class OTPRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()


class OTPRequestView(APIView):
    """
    Step 1: Send a 6-digit OTP code to the given email.
    Creates user if not exists (lazy registration).
    """

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = OTPRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data["email"].lower()

        # Rate limit: max 1 OTP per email per minute
        from django.utils import timezone
        from datetime import timedelta

        recent = EmailOTP.objects.filter(
            email=email,
            is_used=False,
            created_at__gte=timezone.now() - timedelta(minutes=1),
        ).exists()
        if recent:
            return Response(
                {"detail": "Код уже отправлен. Подождите минуту перед повторной отправкой."},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )

        otp = EmailOTP.generate(email)

        # Send email
        subject = f"Код входа в Klub51: {otp.code}"
        message = f"Ваш код для входа: {otp.code}\n\nКод действителен 10 минут."

        try:
            send_mail(
                subject=subject,
                message=message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[email],
                fail_silently=False,
            )
        except Exception:
            # In dev mode with console backend this won't fail,
            # but log it in production
            pass

        return Response({"detail": "Код отправлен на email"})


class OTPVerifySerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.CharField(max_length=6, min_length=6)


class OTPVerifyView(APIView):
    """
    Step 2: Verify OTP code and return JWT tokens.
    Auto-creates user if they don't exist yet.
    """

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = OTPVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data["email"].lower()
        code = serializer.validated_data["code"]

        # Find the latest unused OTP for this email
        otp = (
            EmailOTP.objects.filter(email=email, is_used=False)
            .order_by("-created_at")
            .first()
        )

        if otp is None or not otp.verify(code):
            return Response(
                {"error": "Неверный или истёкший код"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Get or create user
        user, created = User.objects.get_or_create(
            email=email,
            defaults={"username": email.split("@")[0]},
        )
        # Ensure username uniqueness if auto-created
        if created and User.objects.filter(username=user.username).count() > 1:
            user.username = f"{user.username}_{user.pk}"
            user.save(update_fields=["username"])

        return Response(
            get_tokens_for_user(user),
            status=status.HTTP_200_OK if not created else status.HTTP_201_CREATED,
        )


# =============================================================================
# Social Auth — Token Exchange
# =============================================================================


class SocialAuthSerializer(serializers.Serializer):
    access_token = serializers.CharField(required=False)
    id_token = serializers.CharField(required=False)
    code = serializers.CharField(required=False)

    def validate(self, data):
        if not any([data.get("access_token"), data.get("id_token"), data.get("code")]):
            raise serializers.ValidationError(
                "Необходимо передать access_token, id_token или code"
            )
        return data


class BaseSocialAuthView(APIView):
    """Base view for social auth token exchange."""

    permission_classes = [AllowAny]
    provider = None

    def post(self, request):
        serializer = SocialAuthSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        try:
            user = self.authenticate_social(
                request,
                access_token=data.get("access_token"),
                id_token=data.get("id_token"),
                code=data.get("code"),
            )
        except Exception as e:
            return Response(
                {"error": f"Ошибка авторизации: {str(e)}"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if user is None:
            return Response(
                {"error": "Не удалось авторизоваться через провайдер"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response(get_tokens_for_user(user))

    def authenticate_social(self, request, access_token=None, id_token=None, code=None):
        raise NotImplementedError

    def _find_or_create_user(self, provider, uid, email, extra_data, first_name="", last_name=""):
        """Shared logic: find by social account, then by email, or create."""
        try:
            social = SocialAccount.objects.get(provider=provider, uid=uid)
            return social.user
        except SocialAccount.DoesNotExist:
            pass

        if email:
            user, _ = User.objects.get_or_create(
                email=email.lower(),
                defaults={
                    "username": email.split("@")[0],
                    "first_name": first_name,
                    "last_name": last_name,
                },
            )
        else:
            user = User.objects.create_user(
                username=f"{provider}_{uid[:8]}",
                first_name=first_name,
                last_name=last_name,
            )

        SocialAccount.objects.create(
            user=user, provider=provider, uid=uid, extra_data=extra_data,
        )
        return user


class GitHubAuthView(BaseSocialAuthView):
    """Exchange GitHub access_token for JWT tokens."""

    provider = "github"

    def authenticate_social(self, request, access_token=None, **kwargs):
        req = urllib.request.Request(
            "https://api.github.com/user",
            headers={
                "Authorization": f"Bearer {access_token}",
                "Accept": "application/json",
            },
        )
        with urllib.request.urlopen(req) as resp:
            github_user = json.loads(resp.read())

        github_id = str(github_user["id"])
        email = github_user.get("email", "")
        login = github_user.get("login", "")

        if not email:
            req2 = urllib.request.Request(
                "https://api.github.com/user/emails",
                headers={
                    "Authorization": f"Bearer {access_token}",
                    "Accept": "application/json",
                },
            )
            with urllib.request.urlopen(req2) as resp2:
                emails = json.loads(resp2.read())
            primary = next((e for e in emails if e.get("primary")), None)
            email = primary["email"] if primary else emails[0]["email"]

        name = github_user.get("name", "") or ""
        parts = name.split()
        return self._find_or_create_user(
            provider="github",
            uid=github_id,
            email=email,
            extra_data=github_user,
            first_name=parts[0] if parts else "",
            last_name=" ".join(parts[1:]) if len(parts) > 1 else "",
        )


class GoogleAuthView(BaseSocialAuthView):
    """Exchange Google id_token or access_token for JWT tokens."""

    provider = "google"

    def authenticate_social(self, request, id_token=None, access_token=None, **kwargs):
        if id_token:
            req = urllib.request.Request(
                f"https://oauth2.googleapis.com/tokeninfo?id_token={id_token}"
            )
            with urllib.request.urlopen(req) as resp:
                google_user = json.loads(resp.read())
            google_id = google_user["sub"]
        else:
            req = urllib.request.Request(
                "https://www.googleapis.com/oauth2/v2/userinfo",
                headers={"Authorization": f"Bearer {access_token}"},
            )
            with urllib.request.urlopen(req) as resp:
                google_user = json.loads(resp.read())
            google_id = google_user["id"]

        return self._find_or_create_user(
            provider="google",
            uid=google_id,
            email=google_user.get("email", ""),
            extra_data=google_user,
            first_name=google_user.get("given_name", ""),
            last_name=google_user.get("family_name", ""),
        )


class AppleAuthView(BaseSocialAuthView):
    """Exchange Apple id_token for JWT tokens."""

    provider = "apple"

    def authenticate_social(self, request, id_token=None, **kwargs):
        if not id_token:
            return None

        try:
            payload = jwt.decode(id_token, options={"verify_signature": False})
        except jwt.DecodeError:
            return None

        apple_id = payload.get("sub", "")
        if not apple_id:
            return None

        return self._find_or_create_user(
            provider="apple",
            uid=apple_id,
            email=payload.get("email", ""),
            extra_data=payload,
            first_name=request.data.get("first_name", ""),
            last_name=request.data.get("last_name", ""),
        )


# =============================================================================
# SSO / OIDC
# =============================================================================


class SSOConfigView(APIView):
    """Returns SSO/OIDC provider configuration for the client."""

    permission_classes = [AllowAny]

    def get(self, request):
        return Response({
            "enabled": bool(os.environ.get("SSO_OIDC_ISSUER")),
            "issuer": os.environ.get("SSO_OIDC_ISSUER", ""),
            "client_id": os.environ.get("SSO_OIDC_CLIENT_ID", ""),
            "authorization_endpoint": os.environ.get("SSO_OIDC_AUTH_ENDPOINT", ""),
            "token_endpoint": os.environ.get("SSO_OIDC_TOKEN_ENDPOINT", ""),
            "scopes": os.environ.get("SSO_OIDC_SCOPES", "openid email profile"),
        })


class SSOCallbackView(APIView):
    """Exchange SSO/OIDC authorization code or id_token for JWT tokens."""

    permission_classes = [AllowAny]

    def post(self, request):
        code = request.data.get("code")
        id_token_value = request.data.get("id_token")

        if not code and not id_token_value:
            return Response(
                {"error": "Необходимо передать code или id_token"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if id_token_value:
            return self._handle_id_token(id_token_value)

        return self._handle_code(code)

    def _handle_id_token(self, id_token_value):
        try:
            payload = jwt.decode(id_token_value, options={"verify_signature": False})
        except jwt.DecodeError:
            return Response(
                {"error": "Недействительный id_token"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        sub = payload.get("sub", "")
        if not sub:
            return Response(
                {"error": "Отсутствует sub в токене"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        email = payload.get("email", "")
        name = payload.get("name", "")

        try:
            social = SocialAccount.objects.get(provider="oidc", uid=sub)
            user = social.user
        except SocialAccount.DoesNotExist:
            if email:
                user, _ = User.objects.get_or_create(
                    email=email.lower(),
                    defaults={
                        "username": email.split("@")[0],
                        "first_name": name.split()[0] if name else "",
                        "last_name": " ".join(name.split()[1:]) if name else "",
                    },
                )
            else:
                user = User.objects.create_user(username=f"sso_{sub[:8]}")
            SocialAccount.objects.create(
                user=user, provider="oidc", uid=sub, extra_data=payload,
            )

        return Response(get_tokens_for_user(user))

    def _handle_code(self, code):
        token_endpoint = os.environ.get("SSO_OIDC_TOKEN_ENDPOINT")
        client_id = os.environ.get("SSO_OIDC_CLIENT_ID")
        client_secret = os.environ.get("SSO_OIDC_CLIENT_SECRET")
        redirect_uri = os.environ.get("SSO_OIDC_REDIRECT_URI", "")

        if not all([token_endpoint, client_id, client_secret]):
            return Response(
                {"error": "SSO не настроен на сервере"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        token_data = urllib.parse.urlencode({
            "grant_type": "authorization_code",
            "code": code,
            "client_id": client_id,
            "client_secret": client_secret,
            "redirect_uri": redirect_uri,
        }).encode()

        try:
            req = urllib.request.Request(
                token_endpoint,
                data=token_data,
                headers={"Content-Type": "application/x-www-form-urlencoded"},
            )
            with urllib.request.urlopen(req) as resp:
                token_response = json.loads(resp.read())
        except Exception as e:
            return Response(
                {"error": f"Ошибка обмена кода: {str(e)}"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        received_id_token = token_response.get("id_token")
        if not received_id_token:
            return Response(
                {"error": "id_token не получен от провайдера"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return self._handle_id_token(received_id_token)


# =============================================================================
# Connected Accounts
# =============================================================================


class ConnectedAccountsView(APIView):
    """List and manage connected social accounts."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        accounts = SocialAccount.objects.filter(user=request.user)
        return Response([
            {
                "id": acc.id,
                "provider": acc.provider,
                "uid": acc.uid,
                "extra_data": {
                    "email": acc.extra_data.get("email", ""),
                    "name": acc.extra_data.get("name", acc.extra_data.get("login", "")),
                    "avatar": acc.extra_data.get("avatar_url", acc.extra_data.get("picture", "")),
                },
            }
            for acc in accounts
        ])

    def delete(self, request):
        """Disconnect a social account."""
        provider = request.data.get("provider")
        if not provider:
            return Response(
                {"error": "Укажите provider"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        social_count = SocialAccount.objects.filter(user=request.user).count()
        if social_count <= 1 and not request.user.email:
            return Response(
                {"error": "Нельзя отключить единственный способ входа"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        deleted, _ = SocialAccount.objects.filter(
            user=request.user, provider=provider,
        ).delete()

        if deleted == 0:
            return Response(
                {"error": "Аккаунт не найден"},
                status=status.HTTP_404_NOT_FOUND,
            )

        return Response({"detail": f"Аккаунт {provider} отключён"})


# =============================================================================
# Auth providers info (for the login screen)
# =============================================================================


class AuthProvidersView(APIView):
    """Returns available authentication providers for the client."""

    permission_classes = [AllowAny]

    def get(self, request):
        providers = {
            "email": True,
            "github": bool(os.environ.get("GITHUB_CLIENT_ID")),
            "apple": bool(os.environ.get("APPLE_CLIENT_ID")),
            "google": bool(os.environ.get("GOOGLE_CLIENT_ID")),
            "sso": bool(os.environ.get("SSO_OIDC_ISSUER")),
        }

        client_ids = {}
        if providers["github"]:
            client_ids["github"] = os.environ.get("GITHUB_CLIENT_ID")
        if providers["google"]:
            client_ids["google"] = os.environ.get("GOOGLE_CLIENT_ID")
        if providers["apple"]:
            client_ids["apple"] = os.environ.get("APPLE_CLIENT_ID")

        return Response({
            "providers": providers,
            "client_ids": client_ids,
        })

import random
import string
from datetime import timedelta

from django.conf import settings
from django.db import models
from django.utils import timezone


class EmailOTP(models.Model):
    """One-time password sent via email for passwordless auth."""

    email = models.EmailField(db_index=True)
    code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    is_used = models.BooleanField(default=False)
    attempts = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"OTP for {self.email}"

    @classmethod
    def generate(cls, email: str) -> "EmailOTP":
        """Create a new OTP for the given email, invalidating old ones."""
        cls.objects.filter(email=email.lower(), is_used=False).update(is_used=True)
        code = "".join(random.choices(string.digits, k=6))
        return cls.objects.create(email=email.lower(), code=code)

    @property
    def is_expired(self) -> bool:
        ttl = getattr(settings, "OTP_TTL_MINUTES", 10)
        return timezone.now() > self.created_at + timedelta(minutes=ttl)

    @property
    def is_valid(self) -> bool:
        return not self.is_used and not self.is_expired and self.attempts < 5

    def verify(self, code: str) -> bool:
        if not self.is_valid:
            return False
        self.attempts += 1
        if self.code == code:
            self.is_used = True
            self.save(update_fields=["is_used", "attempts"])
            return True
        self.save(update_fields=["attempts"])
        return False


class Team(models.Model):
    name = models.CharField(max_length=200)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class TeamMembership(models.Model):
    class Role(models.TextChoices):
        OWNER = "owner", "Владелец"
        EDITOR = "editor", "Редактор"
        VIEWER = "viewer", "Читатель"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="team_memberships",
    )
    team = models.ForeignKey(
        Team,
        on_delete=models.CASCADE,
        related_name="memberships",
    )
    role = models.CharField(
        max_length=10,
        choices=Role.choices,
        default=Role.EDITOR,
    )
    joined_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("user", "team")
        ordering = ["joined_at"]

    def __str__(self):
        return f"{self.user.username} → {self.team.name} ({self.role})"

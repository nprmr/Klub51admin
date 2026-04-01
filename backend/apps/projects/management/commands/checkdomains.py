from datetime import timedelta

from django.core.management.base import BaseCommand
from django.utils import timezone

from apps.projects.models import TechnicalCard


class Command(BaseCommand):
    help = "Check for expiring domains and print warnings"

    def add_arguments(self, parser):
        parser.add_argument(
            "--days",
            type=int,
            default=30,
            help="Number of days to look ahead (default: 30)",
        )

    def handle(self, *args, **options):
        days = options["days"]
        threshold = timezone.now().date() + timedelta(days=days)
        today = timezone.now().date()

        cards = TechnicalCard.objects.filter(
            domain_expires__isnull=False,
            domain_expires__lte=threshold,
        ).select_related("project").order_by("domain_expires")

        if not cards.exists():
            self.stdout.write(self.style.SUCCESS(
                f"No domains expiring within {days} days."
            ))
            return

        self.stdout.write(self.style.WARNING(
            f"\nDomains expiring within {days} days:\n"
        ))

        for card in cards:
            days_left = (card.domain_expires - today).days
            if days_left < 0:
                style = self.style.ERROR
                label = f"EXPIRED {abs(days_left)} days ago"
            elif days_left <= 7:
                style = self.style.ERROR
                label = f"{days_left} days left"
            else:
                style = self.style.WARNING
                label = f"{days_left} days left"

            self.stdout.write(style(
                f"  [{label}] {card.domain_name} "
                f"({card.project.title}) — "
                f"expires {card.domain_expires} "
                f"@ {card.domain_registrar}"
            ))

        self.stdout.write(f"\nTotal: {cards.count()} domain(s)")

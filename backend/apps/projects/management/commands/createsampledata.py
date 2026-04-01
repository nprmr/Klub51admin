from django.contrib.auth.models import User
from django.core.management.base import BaseCommand

from apps.accounts.models import Team, TeamMembership
from apps.pages.models import Page, PageBlock
from apps.projects.models import Project, ProjectStatus, TechnicalCard


class Command(BaseCommand):
    help = "Create sample data for development"

    def handle(self, *args, **options):
        # Create superuser if not exists
        admin, created = User.objects.get_or_create(
            username="admin",
            defaults={"email": "admin@klub51.app", "is_staff": True, "is_superuser": True},
        )
        if created:
            admin.set_password("admin")
            admin.save()
            self.stdout.write(self.style.SUCCESS("Created admin user (password: admin)"))

        # Create team
        team, _ = Team.objects.get_or_create(name="Klub51 Studio")
        TeamMembership.objects.get_or_create(
            user=admin, team=team, defaults={"role": "owner"}
        )

        # Create statuses
        statuses_data = [
            ("На обсуждении", "#3B82F6", 0),
            ("В разработке", "#F59E0B", 1),
            ("Тестирование", "#8B5CF6", 2),
            ("В проде", "#10B981", 3),
            ("Архив", "#6B7280", 4),
        ]
        statuses = {}
        for name, color, order in statuses_data:
            s, _ = ProjectStatus.objects.get_or_create(
                name=name, team=team, defaults={"color": color, "order": order}
            )
            statuses[name] = s

        # Create projects
        projects_data = [
            ("Klub51 Admin", "🛠", "В разработке", "Внутренняя система управления проектами"),
            ("MyApp iOS", "📱", "В проде", "iOS приложение для клиентов"),
            ("Новый маркетплейс", "📬", "На обсуждении", "Идея маркетплейса для локальных производителей"),
        ]
        for title, icon, status_name, desc in projects_data:
            project, created = Project.objects.get_or_create(
                title=title,
                team=team,
                defaults={
                    "icon": icon,
                    "status": statuses[status_name],
                    "description": desc,
                },
            )
            if created:
                TechnicalCard.objects.create(project=project)
                self.stdout.write(f"  Created project: {title}")

        # Add tech card data to MyApp
        myapp = Project.objects.filter(title="MyApp iOS", team=team).first()
        if myapp:
            card = myapp.technical_card
            card.github_url = "https://github.com/nprmr/myapp-ios"
            card.appstore_url = "https://apps.apple.com/app/myapp/id123456789"
            card.figma_url = "https://figma.com/file/abc123"
            card.domain_name = "myapp.ru"
            card.domain_registrar = "REG.RU"
            card.domain_expires = "2027-06-15"
            card.budget_required = 50000
            card.ad_cabinet_url = "https://ads.apple.com"
            card.notes = "Основной продукт, приоритет в поддержке"
            card.save()

        # Create sample pages
        if myapp:
            page, created = Page.objects.get_or_create(
                project=myapp,
                title="Roadmap Q2 2026",
                defaults={"icon": "🗺", "created_by": admin},
            )
            if created:
                PageBlock.objects.create(
                    page=page, block_type="heading1",
                    content={"text": "Roadmap Q2 2026"}, order=0,
                )
                PageBlock.objects.create(
                    page=page, block_type="text",
                    content={"text": "Основные направления работы на второй квартал."}, order=1,
                )
                PageBlock.objects.create(
                    page=page, block_type="todo",
                    content={"text": "Обновить дизайн главного экрана", "checked": False}, order=2,
                )
                PageBlock.objects.create(
                    page=page, block_type="todo",
                    content={"text": "Интеграция с Apple Pay", "checked": True}, order=3,
                )
                PageBlock.objects.create(
                    page=page, block_type="todo",
                    content={"text": "Push-уведомления", "checked": False}, order=4,
                )
                self.stdout.write(f"  Created page with blocks: {page.title}")

        self.stdout.write(self.style.SUCCESS("\nSample data created successfully!"))

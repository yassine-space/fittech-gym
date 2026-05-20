import secrets
from django.core.management.base import BaseCommand
from django.utils import timezone
from fitapi.models import GymDailyToken


class Command(BaseCommand):
    help = "Generate a daily gym token"

    def handle(self, *args, **kwargs):
        today = timezone.now().date()
        token = secrets.token_urlsafe(32)

        obj, created = GymDailyToken.objects.get_or_create(
            date=today,
            defaults={"token": token},
        )

        if created:
            self.stdout.write(f"Token generated for {today}: {obj.token}")
        else:
            self.stdout.write(f"Token already exists for {today}: {obj.token}")
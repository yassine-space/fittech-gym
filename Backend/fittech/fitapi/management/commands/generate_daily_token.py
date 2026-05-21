import secrets
from django.core.management.base import BaseCommand
from django.utils import timezone
from fitapi.models import GymDailyToken, MembreSubscription


class Command(BaseCommand):
    help = "Generate a daily gym token and expire outdated subscriptions"

    def handle(self, *args, **kwargs):
        today = timezone.now().date()

        # 1. Generate daily token
        token = secrets.token_urlsafe(32)
        obj, created = GymDailyToken.objects.get_or_create(
            date=today,
            defaults={"token": token},
        )
        if created:
            self.stdout.write(f"Token generated for {today}: {obj.token}")
        else:
            self.stdout.write(f"Token already exists for {today}: {obj.token}")

        # 2. Expire outdated subscriptions
        expired_count = MembreSubscription.objects.filter(
            status="active",
            end_date__lt=today,
        ).update(status="expired")

        self.stdout.write(f"{expired_count} subscription(s) marked as expired.")
import secrets
from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from fitapi.models import GymDailyToken, MembreSubscription, Notification


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

        # 3. Notify members whose subscription expires in 3 days
        warning_date = today + timedelta(days=3)
        expiring_subs = MembreSubscription.objects.filter(
            status="active",
            end_date=warning_date,
        ).select_related("membre__user")

        notif_count = 0
        for sub in expiring_subs:
            # Avoid duplicate notifications
            already_notified = Notification.objects.filter(
                user=sub.membre.user,
                notification_type="subscription_expiry",
                created_at__date=today,
            ).exists()

            if not already_notified:
                Notification.objects.create(
                    user=sub.membre.user,
                    notification_type="subscription_expiry",
                    title="Subscription expiring soon",
                    body=f"Your subscription expires on {sub.end_date}. Renew it to keep access.",
                )
                notif_count += 1

        self.stdout.write(f"{notif_count} expiry warning notification(s) sent.")
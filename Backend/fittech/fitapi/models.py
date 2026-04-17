# Create your models here.
import uuid
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
from django.utils import timezone
from datetime import date 

# ─────────────────────────────────────────
# Custom User Manager
# ─────────────────────────────────────────
class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError("Email is required")
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        return self.create_user(email, password, **extra_fields)


# ─────────────────────────────────────────
# User
# ─────────────────────────────────────────
class User(AbstractBaseUser, PermissionsMixin):
    groups = models.ManyToManyField(
        "auth.Group",
        related_name="fitapi_users",
        blank=True,
        help_text="The groups this user belongs to.",
        verbose_name="groups",
    )
    user_permissions = models.ManyToManyField(
        "auth.Permission",
        related_name="fitapi_users",
        blank=True,
        help_text="Specific permissions for this user.",
        verbose_name="user permissions",
    )

    ROLE_CHOICES = [
        ("admin", "Admin"),
        ("membre", "Membre"),
        ("coach", "Coach"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=20, blank=True, null=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default="membre")
    profile_photo = models.ImageField(upload_to="profile_photos/", blank=True, null=True)
    created_at = models.DateTimeField(default=timezone.now)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["first_name", "last_name"]

    objects = UserManager()

    def __str__(self):
        return f"{self.first_name} {self.last_name} ({self.email})"


# ─────────────────────────────────────────
# Membre
# ─────────────────────────────────────────
class Membre(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="membre_profile")
    date_of_birth = models.DateField(blank=True, null=True)
    health_goal = models.TextField(blank=True, null=True)
    medical_restrictions = models.TextField(blank=True, null=True)
    join_date = models.DateField(default=date.today)

    def __str__(self):
        return f"Membre: {self.user.first_name} {self.user.last_name}"


# ─────────────────────────────────────────
# Coach
# ─────────────────────────────────────────
class Coach(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="coach_profile")
    specialties = models.TextField(blank=True, null=True)
    biography = models.TextField(blank=True, null=True)
    years_of_experience = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=False)
    def __str__(self):
        return f"Coach: {self.user.first_name} {self.user.last_name}"


# ─────────────────────────────────────────
# Subscription Plan
# ─────────────────────────────────────────
class SubscriptionPlan(models.Model):
    PLAN_TYPE_CHOICES = [
        ("monthly", "Monthly"),
        ("weekly", "Weekly"),
        ("yearly", "Yearly"),
        ("sessions", "Sessions Pack"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    type = models.CharField(max_length=20, choices=PLAN_TYPE_CHOICES)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    sessions_count = models.PositiveIntegerField(default=0)
    duration_days = models.PositiveIntegerField(default=30)
    auto_renew = models.BooleanField(default=False)
    created_at = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return f"{self.name} - {self.type}"


# ─────────────────────────────────────────
# Membre Subscription
# ─────────────────────────────────────────
class MembreSubscription(models.Model):
    STATUS_CHOICES = [
        ("active", "Active"),
        ("expired", "Expired"),
        ("paused", "Paused"),
        ("cancelled", "Cancelled"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    membre = models.ForeignKey(Membre, on_delete=models.CASCADE, related_name="subscriptions")
    plan = models.ForeignKey(SubscriptionPlan, on_delete=models.PROTECT, related_name="subscriptions")
    start_date = models.DateField()
    end_date = models.DateField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="active")
    remaining_sessions = models.PositiveIntegerField(default=0)
    pause_days_used = models.PositiveIntegerField(default=0)

    def __str__(self):
        return f"{self.membre} - {self.plan.name} ({self.status})"


# ─────────────────────────────────────────
# Payment
# ─────────────────────────────────────────
class Payment(models.Model):
    PAYMENT_METHOD_CHOICES = [
        ("cash", "Cash"),
        ("card", "Card"),
        ("transfer", "Bank Transfer"),
        ("online", "Online"),
    ]

    PAYMENT_STATUS_CHOICES = [
        ("paid", "Paid"),
        ("pending", "Pending"),
        ("failed", "Failed"),
        ("refunded", "Refunded"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    membre = models.ForeignKey(Membre, on_delete=models.CASCADE, related_name="payments")
    subscription = models.ForeignKey(MembreSubscription, on_delete=models.SET_NULL, null=True, related_name="payments")
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    payment_method = models.CharField(max_length=20, choices=PAYMENT_METHOD_CHOICES)
    payment_status = models.CharField(max_length=20, choices=PAYMENT_STATUS_CHOICES, default="pending")
    payment_date = models.DateTimeField(default=timezone.now)
    invoice_number = models.CharField(max_length=100, unique=True, blank=True, null=True)

    def __str__(self):
        return f"Payment #{self.invoice_number} - {self.membre} ({self.payment_status})"

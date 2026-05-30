# Create your models here.
import uuid
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
from django.utils import timezone
from datetime import date 
import secrets
from django.core.validators import MinValueValidator, MaxValueValidator
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
    is_online = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    archived_at = models.DateTimeField(blank=True, null=True)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["first_name", "last_name"]

    objects = UserManager()

    def __str__(self):
        return f"{self.first_name} {self.last_name} ({self.email})"


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
# Membre
# ─────────────────────────────────────────
class Membre(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="membre_profile")
    date_of_birth = models.DateField(blank=True, null=True)
    health_goal = models.TextField(blank=True, null=True)
    medical_restrictions = models.TextField(blank=True, null=True)
    join_date = models.DateField(default=date.today)
    coach = models.ForeignKey(Coach,on_delete=models.SET_NULL,null=True,blank=True,related_name="assigned_membres",)

    def __str__(self):
        return f"Membre: {self.user.first_name} {self.user.last_name}"


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
    PLAN_TIER_CHOICES = [
        ("basic", "Basic"),
        ("advanced", "Advanced"),
        ("full", "Full Options"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    type = models.CharField(max_length=20, choices=PLAN_TYPE_CHOICES)
    tier = models.CharField(max_length=20, choices=PLAN_TIER_CHOICES, default="basic")
    price = models.DecimalField(max_digits=10, decimal_places=2)
    sessions_count = models.PositiveIntegerField(default=0)
    duration_days = models.PositiveIntegerField(default=30)
    auto_renew = models.BooleanField(default=False)
    created_at = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return f"{self.name} - {self.type} - {self.tier}"


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


class PasswordResetToken(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="reset_tokens")
    token = models.CharField(max_length=64, unique=True)
    created_at = models.DateTimeField(default=timezone.now)
    is_used = models.BooleanField(default=False)

    def is_valid(self):
        from datetime import timedelta
        expiry = self.created_at + timedelta(hours=1)
        return not self.is_used and timezone.now() < expiry

    def __str__(self):
        return f"Reset token for {self.user.email}"
    

class Course(models.Model):
    LEVEL_CHOICES = [
        ("beginner", "Beginner"),
        ("intermediate", "Intermediate"),
        ("advanced", "Advanced"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    coach = models.ForeignKey("Coach", on_delete=models.CASCADE, related_name="courses")
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    level_required = models.CharField(max_length=20, choices=LEVEL_CHOICES, default="beginner")
    max_participants = models.PositiveIntegerField()
    duration_minutes = models.PositiveIntegerField()
    date_time = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title


class CourseReservation(models.Model):
    STATUS_CHOICES = [
        ("confirmed", "Confirmed"),
        ("cancelled", "Cancelled"),
        ("attended", "Attended"),
        ("no_show", "No Show"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    course = models.ForeignKey(Course, on_delete=models.CASCADE, related_name="reservations")
    membre = models.ForeignKey("Membre", on_delete=models.CASCADE, related_name="reservations")
    reservation_status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="confirmed")
    reservation_date = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("course", "membre")  # one reservation per membre per course

    def __str__(self):
        return f"{self.membre} → {self.course}"


class CourseWaitlist(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    course = models.ForeignKey(Course, on_delete=models.CASCADE, related_name="waitlist")
    membre = models.ForeignKey("Membre", on_delete=models.CASCADE, related_name="waitlist_entries")
    position = models.PositiveIntegerField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("course", "membre")
        ordering = ["position"]

    def __str__(self):
        return f"{self.membre} waiting #{self.position} for {self.course}"
    


class CoachReview(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    coach = models.ForeignKey("Coach", on_delete=models.CASCADE, related_name="reviews")
    membre = models.ForeignKey("Membre", on_delete=models.CASCADE, related_name="reviews")
    rating = models.PositiveSmallIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    comment = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ("coach", "membre")

    def __str__(self):
        return f"{self.membre} → {self.coach} ({self.rating}★)"


class CoachCertificate(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    coach = models.ForeignKey("Coach", on_delete=models.CASCADE, related_name="certificates")
    title = models.CharField(max_length=255)
    issuing_organization = models.CharField(max_length=255)
    issue_date = models.DateField()
    file = models.FileField(upload_to="certificates/")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.title} — {self.coach}"
    


class GymDailyToken(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    token = models.CharField(max_length=64, unique=True)
    date = models.DateField(unique=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Token for {self.date}"


class GymEntry(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    membre = models.ForeignKey("Membre", on_delete=models.CASCADE, related_name="gym_entries")
    date = models.DateField()
    entered_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("membre", "date")  # one entry per member per day

    def __str__(self):
        return f"{self.membre} — {self.date}"
    


class Conversation(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    coach = models.ForeignKey("Coach", on_delete=models.CASCADE, related_name="conversations")
    membre = models.ForeignKey("Membre", on_delete=models.CASCADE, related_name="conversations")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("coach", "membre")

    def __str__(self):
        return f"{self.coach} ↔ {self.membre}"


class Message(models.Model):
    MESSAGE_TYPE_CHOICES = [
        ("text", "Text"),
        ("image", "Image"),
        ("file", "File"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name="messages")
    sender = models.ForeignKey("User", on_delete=models.CASCADE, related_name="sent_messages")
    message_type = models.CharField(max_length=10, choices=MESSAGE_TYPE_CHOICES, default="text")
    content = models.TextField(blank=True)
    file = models.FileField(upload_to="chat/files/", blank=True, null=True)
    is_read = models.BooleanField(default=False)
    deleted_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]

    def __str__(self):
        return f"{self.sender} → {self.conversation} ({self.message_type})"
    



class Machine(models.Model):
    MACHINE_TYPE_CHOICES = [
        ("machine", "Machine"),
        ("free_weight", "Free Weight"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    type = models.CharField(max_length=20, choices=MACHINE_TYPE_CHOICES)
    description = models.TextField(blank=True)
    created_by = models.ForeignKey("User", on_delete=models.SET_NULL, null=True, related_name="machines_created")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} ({self.type})"


class WorkoutLog(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    membre = models.ForeignKey("Membre", on_delete=models.CASCADE, related_name="workout_logs")
    machine = models.ForeignKey(Machine, on_delete=models.CASCADE, related_name="workout_logs")
    notes = models.TextField(blank=True)
    logged_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-logged_at"]

    def __str__(self):
        return f"{self.membre} — {self.machine} @ {self.logged_at.date()}"


class WorkoutSet(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    workout_log = models.ForeignKey(WorkoutLog, on_delete=models.CASCADE, related_name="sets")
    set_number = models.PositiveIntegerField()
    reps = models.PositiveIntegerField()
    weight_kg = models.DecimalField(max_digits=5, decimal_places=2)

    class Meta:
        ordering = ["set_number"]
        unique_together = ("workout_log", "set_number")

    def __str__(self):
        return f"Set {self.set_number} — {self.reps} reps @ {self.weight_kg}kg"




class Notification(models.Model):
    NOTIFICATION_TYPE_CHOICES = [
        ("waitlist_promotion", "Waitlist Promotion"),
        ("subscription_expiry", "Subscription Expiry Warning"),
        ("coach_assignment", "Coach Assignment"),
        ("new_message", "New Message"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey("User", on_delete=models.CASCADE, related_name="notifications")
    notification_type = models.CharField(max_length=30, choices=NOTIFICATION_TYPE_CHOICES)
    title = models.CharField(max_length=255)
    body = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user} — {self.notification_type} ({'read' if self.is_read else 'unread'})"


class MachineReport(models.Model):
    SEVERITY_CHOICES = [
        ("minor", "Minor"),
        ("major", "Major"),
        ("urgent", "Urgent"),
    ]

    STATUS_CHOICES = [
        ("pending", "Pending"),
        ("in_progress", "In Progress"),
        ("resolved", "Resolved"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    machine = models.ForeignKey(Machine, on_delete=models.CASCADE, related_name="reports")
    reported_by = models.ForeignKey("User", on_delete=models.CASCADE, related_name="machine_reports")
    description = models.TextField()
    severity = models.CharField(max_length=10, choices=SEVERITY_CHOICES)
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default="pending")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ("machine", "reported_by")
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.machine} — {self.severity} ({self.status})"
    

# ─────────────────────────────────────────
class ChargilyCheckout(models.Model):
 
    class LOCALE(models.TextChoices):
        FRENCH  = "fr", "French"
        ARABIC  = "ar", "Arabic"
        ENGLISH = "en", "English"
 
    class CHARGILY_METHOD(models.TextChoices):
        EDAHABIA = "edahabia", "EDAHABIA (Algerie Poste)"
        CIB      = "cib",      "CIB (SATIM)"
 
    # One Chargily session per Payment
    payment = models.OneToOneField(
        Payment,
        on_delete=models.CASCADE,
        related_name="chargily_checkout",
    )
 
    # Filled after Chargily API responds successfully
    chargily_id   = models.CharField(max_length=200, unique=True, null=True, blank=True)
    checkout_url  = models.URLField(null=True, blank=True)
 
    chargily_method = models.CharField(
        max_length=20,
        choices=CHARGILY_METHOD.choices,
        default=CHARGILY_METHOD.EDAHABIA,
    )
    locale = models.CharField(
        max_length=2,
        choices=LOCALE.choices,
        default=LOCALE.FRENCH,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
 
    def __str__(self):
        return f"ChargilyCheckout → Payment #{self.payment.invoice_number} [{self.payment.payment_status}]"        

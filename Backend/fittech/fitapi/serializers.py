from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from django.db import transaction
from .models import User, Membre, Coach, SubscriptionPlan, MembreSubscription, Payment


# ─────────────────────────────────────────
# User Serializers
# ─────────────────────────────────────────
class UserSerializer(serializers.ModelSerializer):
    """Read-only user info (safe to expose in responses)"""

    class Meta:
        model = User
        fields = [
            "id", "first_name", "last_name", "email",
            "phone", "role", "profile_photo", "created_at", "is_active"
        ]
        read_only_fields = ["id", "created_at","role"]


class RegisterSerializer(serializers.ModelSerializer):
    """
    One-shot registration:
    - Always creates a User
    - If role == 'membre'  → also creates a Membre profile
    - If role == 'coach'   → also creates a Coach profile (is_active=False until admin approves)

    Membre fields (optional): date_of_birth, health_goal, medical_restrictions
    Coach  fields (optional): specialties, biography, years_of_experience
    """

    password  = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True, required=True, label="Confirm Password")
    profile_photo = serializers.ImageField(required=False, allow_null=True)
    # ── Membre-specific fields ──
    date_of_birth        = serializers.DateField(required=False, allow_null=True)
    health_goal          = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    medical_restrictions = serializers.CharField(required=False, allow_blank=True, allow_null=True)

    # ── Coach-specific fields ──
    specialties          = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    biography            = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    years_of_experience  = serializers.IntegerField(required=False, min_value=0, default=0)

    class Meta:
        model = User
        fields = [
            # user core
            "id", "first_name", "last_name", "email", "phone", "role",
            "password", "password2", "profile_photo",
            # membre
            "date_of_birth", "health_goal", "medical_restrictions",
            # coach
            "specialties", "biography", "years_of_experience",
        ]
        read_only_fields = ["id"]

    def validate(self, attrs):
        if attrs["password"] != attrs["password2"]:
            raise serializers.ValidationError({"password": "Passwords do not match."})

        role = attrs.get("role", "membre")
        if role not in ("membre", "coach"):
            raise serializers.ValidationError(
                {"role": "Registration is only allowed for 'membre' or 'coach' roles."}
            )
        return attrs

    @transaction.atomic
    def create(self, validated_data):
        # ── Pop non-User fields ──
        validated_data.pop("password2")

        membre_fields = {
            "date_of_birth":        validated_data.pop("date_of_birth", None),
            "health_goal":          validated_data.pop("health_goal", None),
            "medical_restrictions": validated_data.pop("medical_restrictions", None),
        }
        coach_fields = {
            "specialties":         validated_data.pop("specialties", None),
            "biography":           validated_data.pop("biography", None),
            "years_of_experience": validated_data.pop("years_of_experience", 0),
        }

        # ── Create User ──
        user = User.objects.create_user(**validated_data)

        # ── Create linked profile ──
        if user.role == "membre":
            Membre.objects.create(user=user, **{k: v for k, v in membre_fields.items() if v is not None})

        elif user.role == "coach":
            Coach.objects.create(
                user=user,
                is_active=False,   # pending admin approval
                **{k: v for k, v in coach_fields.items() if v is not None}
            )

        return user


class ChangePasswordSerializer(serializers.Serializer):
    """Used for changing user password"""

    old_password  = serializers.CharField(write_only=True, required=True)
    new_password  = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    new_password2 = serializers.CharField(write_only=True, required=True, label="Confirm New Password")

    def validate(self, attrs):
        if attrs["new_password"] != attrs["new_password2"]:
            raise serializers.ValidationError({"new_password": "New passwords do not match."})
        return attrs


# ─────────────────────────────────────────
# Membre Serializers
# ─────────────────────────────────────────
class MembreSerializer(serializers.ModelSerializer):
    """Full membre details"""

    user = UserSerializer(read_only=True)

    class Meta:
        model = Membre
        fields = [
            "id", "user", "date_of_birth", "health_goal",
            "medical_restrictions", "join_date"
        ]
        read_only_fields = ["id", "join_date"]


class MembreCreateSerializer(serializers.ModelSerializer):
    """Used when creating/updating a membre profile"""

    class Meta:
        model = Membre
        fields = [
            "id", "user", "date_of_birth", "health_goal",
            "medical_restrictions", "join_date"
        ]
        read_only_fields = ["id", "join_date"]


# ─────────────────────────────────────────
# Coach Serializers
# ─────────────────────────────────────────
class CoachSerializer(serializers.ModelSerializer):
    """Full coach details — is_active is read-only here (use CoachActivateSerializer to change it)"""

    user = UserSerializer(read_only=True)

    class Meta:
        model = Coach
        fields = [
            "id", "user", "specialties", "biography",
            "years_of_experience", "is_active"
        ]
        read_only_fields = ["id", "is_active"]   # mutated only by admin via dedicated endpoint


class CoachCreateSerializer(serializers.ModelSerializer):
    """Used when creating/updating a coach profile (admin)"""

    class Meta:
        model = Coach
        fields = [
            "id", "user", "specialties", "biography",
            "years_of_experience", "is_active"
        ]
        read_only_fields = ["id"]


class CoachActivateSerializer(serializers.ModelSerializer):
    """
    Admin-only: flip is_active on a coach profile.
    PATCH /coaches/<pk>/activate/
    """

    class Meta:
        model = Coach
        fields = ["id", "is_active"]
        read_only_fields = ["id"]


# ─────────────────────────────────────────
# Subscription Plan Serializers
# ─────────────────────────────────────────
class SubscriptionPlanSerializer(serializers.ModelSerializer):
    """Full subscription plan details"""

    class Meta:
        model = SubscriptionPlan
        fields = [
            "id", "name", "type", "price", "sessions_count",
            "duration_days", "auto_renew", "created_at"
        ]
        read_only_fields = ["id", "created_at"]


# ─────────────────────────────────────────
# Membre Subscription Serializers
# ─────────────────────────────────────────
class MembreSubscriptionSerializer(serializers.ModelSerializer):
    """Full subscription details with nested info"""

    membre = MembreSerializer(read_only=True)
    plan   = SubscriptionPlanSerializer(read_only=True)

    class Meta:
        model = MembreSubscription
        fields = [
            "id", "membre", "plan", "start_date", "end_date",
            "status", "remaining_sessions", "pause_days_used"
        ]
        read_only_fields = ["id"]


class MembreSubscriptionCreateSerializer(serializers.ModelSerializer):
    """Used when creating/updating a subscription"""

    class Meta:
        model = MembreSubscription
        fields = [
            "id", "membre", "plan", "start_date", "end_date",
            "status", "remaining_sessions", "pause_days_used"
        ]
        read_only_fields = ["id"]

    def validate(self, attrs):
        if attrs["start_date"] >= attrs["end_date"]:
            raise serializers.ValidationError({"end_date": "End date must be after start date."})
        return attrs


# ─────────────────────────────────────────
# Payment Serializers
# ─────────────────────────────────────────
class PaymentSerializer(serializers.ModelSerializer):
    """Full payment details with nested info"""

    membre       = MembreSerializer(read_only=True)
    subscription = MembreSubscriptionSerializer(read_only=True)

    class Meta:
        model = Payment
        fields = [
            "id", "membre", "subscription", "amount", "payment_method",
            "payment_status", "payment_date", "invoice_number"
        ]
        read_only_fields = ["id", "payment_date"]


class PaymentCreateSerializer(serializers.ModelSerializer):
    """Used when creating a payment"""

    class Meta:
        model = Payment
        fields = [
            "id", "membre", "subscription", "amount", "payment_method",
            "payment_status", "payment_date", "invoice_number"
        ]
        read_only_fields = ["id", "payment_date"]

    def validate_amount(self, value):
        if value <= 0:
            raise serializers.ValidationError("Amount must be greater than 0.")
        return value
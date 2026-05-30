from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from django.db import transaction
from .models import CoachCertificate, Conversation, Machine, MachineReport, Message, Notification, User, Membre, Coach, SubscriptionPlan, MembreSubscription, Payment,Course, CourseReservation, CourseWaitlist, CoachReview, WorkoutLog, WorkoutSet


# ─────────────────────────────────────────
# User Serializers
# ─────────────────────────────────────────
class UserSerializer(serializers.ModelSerializer):
    """Read-only user info (safe to expose in responses)"""

    class Meta:
        model = User
        fields = [
            "id", "first_name", "last_name", "email",
            "phone", "role", "profile_photo", "created_at", "is_active","archived_at"
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


class CoachReviewSerializer(serializers.ModelSerializer):
    class Meta:
        model = CoachReview
        fields = ["id", "coach", "membre", "rating", "comment", "created_at", "updated_at"]
        read_only_fields = ["id", "created_at", "updated_at"]

    def validate(self, data):
        membre = data["membre"]
        coach = data["coach"]

        # Check the membre attended at least one course with this coach
        attended = CourseReservation.objects.filter(
            membre=membre,
            course__coach=coach,
            reservation_status="attended",
        ).exists()

        if not attended:
            raise serializers.ValidationError(
                "You can only review a coach after attending one of their courses."
            )

        return data


class CoachCertificateSerializer(serializers.ModelSerializer):
    class Meta:
        model = CoachCertificate
        fields = ["id", "coach", "title", "issuing_organization", "issue_date", "file", "created_at"]
        read_only_fields = ["id", "created_at"]
# ─────────────────────────────────────────
# Subscription Plan Serializers
# ─────────────────────────────────────────
class SubscriptionPlanSerializer(serializers.ModelSerializer):
    """Full subscription plan details"""

    class Meta:
        model = SubscriptionPlan
        fields = [
            "id", "name", "type", "price","tier", "sessions_count",
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
        read_only_fields = ["id","created_at", "remaining_sessions"]

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
    


class ForgotPasswordSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)

class ResetPasswordSerializer(serializers.Serializer):
    token = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, validators=[validate_password])
    new_password2 = serializers.CharField(required=True)

    def validate(self, attrs):
        if attrs["new_password"] != attrs["new_password2"]:
            raise serializers.ValidationError({"new_password": "Passwords do not match."})
        return attrs
    
class CourseSerializer(serializers.ModelSerializer):
    spots_remaining = serializers.SerializerMethodField()

    class Meta:
        model = Course
        fields = [
            "id", "coach", "title", "description", "level_required",
            "max_participants", "duration_minutes", "date_time",
            "created_at", "spots_remaining",
        ]
        read_only_fields = ["id", "created_at"]

    def get_spots_remaining(self, obj):
        confirmed = obj.reservations.filter(reservation_status="confirmed").count()
        return max(0, obj.max_participants - confirmed)


class CourseReservationSerializer(serializers.ModelSerializer):
    class Meta:
        model = CourseReservation
        fields = ["id", "course", "membre", "reservation_status", "reservation_date"]
        read_only_fields = ["id", "reservation_date"]

    def validate(self, data):
        course = data["course"]
        membre = data.get("membre")

        # Check for duplicate reservation
        if CourseReservation.objects.filter(course=course, membre=membre).exists():
            raise serializers.ValidationError("This membre already has a reservation for this course.")

        # Check capacity
        confirmed_count = course.reservations.filter(reservation_status="confirmed").count()
        if confirmed_count >= course.max_participants:
            raise serializers.ValidationError(
                "Course is full. The membre should be added to the waitlist."
            )

        return data


class CourseWaitlistSerializer(serializers.ModelSerializer):
    class Meta:
        model = CourseWaitlist
        fields = ["id", "course", "membre", "position", "created_at"]
        read_only_fields = ["id", "position", "created_at"]

    def validate(self, data):
        if CourseWaitlist.objects.filter(course=data["course"], membre=data["membre"]).exists():
            raise serializers.ValidationError("This membre is already on the waitlist.")
        return data

    def create(self, validated_data):
        course = validated_data["course"]
        last_position = CourseWaitlist.objects.filter(course=course).count()
        validated_data["position"] = last_position + 1
        return super().create(validated_data)
    


class MessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = ["id", "conversation", "sender", "message_type", "content", "file", "is_read", "deleted_at", "created_at"]
        read_only_fields = ["id", "sender", "is_read", "deleted_at", "created_at"]

    def validate(self, data):
        message_type = data.get("message_type", "text")
        content = data.get("content", "")
        file = data.get("file")

        if message_type == "text" and not content:
            raise serializers.ValidationError("Text messages require content.")

        if message_type in ("image", "file") and not file:
            raise serializers.ValidationError("Image and file messages require a file.")

        return data


class ConversationSerializer(serializers.ModelSerializer):
    last_message = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = ["id", "coach", "membre", "created_at", "last_message"]
        read_only_fields = ["id", "created_at"]

    def get_last_message(self, obj):
        message = obj.messages.filter(deleted_at__isnull=True).last()
        if message:
            return {
                "content": message.content if message.message_type == "text" else f"[{message.message_type}]",
                "created_at": message.created_at.isoformat(),
                "is_read": message.is_read,
            }
        return None
    


class MachineSerializer(serializers.ModelSerializer):
    class Meta:
        model = Machine
        fields = ["id", "name", "type", "description", "created_by", "created_at"]
        read_only_fields = ["id", "created_by", "created_at"]


class WorkoutSetSerializer(serializers.ModelSerializer):
    class Meta:
        model = WorkoutSet
        fields = ["id", "set_number", "reps", "weight_kg"]
        read_only_fields = ["id","set_number"]


class WorkoutLogSerializer(serializers.ModelSerializer):
    sets = WorkoutSetSerializer(many=True)

    class Meta:
        model = WorkoutLog
        fields = ["id", "membre", "machine", "notes", "logged_at", "sets"]
        read_only_fields = ["id", "logged_at","membre"]

    def create(self, validated_data):
        sets_data = validated_data.pop("sets")
        workout_log = WorkoutLog.objects.create(**validated_data)
        for i, set_data in enumerate(sets_data, start=1):
            WorkoutSet.objects.create(
                workout_log=workout_log,
                set_number=i,
                **set_data
            )
        return workout_log


class WorkoutProgressSerializer(serializers.ModelSerializer):
    """Used for progress tracking — one entry per log with max weight of that session."""
    max_weight_kg = serializers.SerializerMethodField()

    class Meta:
        model = WorkoutLog
        fields = ["id", "logged_at", "max_weight_kg", "sets"]

    def get_max_weight_kg(self, obj):
        weights = obj.sets.values_list("weight_kg", flat=True)
        return max(weights) if weights else 0
    



class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ["id", "notification_type", "title", "body", "is_read", "created_at"]
        read_only_fields = ["id", "notification_type", "title", "body", "created_at"]




class MachineReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = MachineReport
        fields = ["id", "machine", "reported_by", "description", "severity", "status", "created_at", "updated_at"]
        read_only_fields = ["id", "reported_by", "status", "created_at", "updated_at"]

    def validate_machine(self, value):
        if value.type != "machine":
            raise serializers.ValidationError("Only physical machines can be reported, not free weight exercises.")
        return value


class MachineReportStatusSerializer(serializers.ModelSerializer):
    """Used by admin to update status only."""
    class Meta:
        model = MachineReport
        fields = ["status"]

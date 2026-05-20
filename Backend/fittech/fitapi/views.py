from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView, PermissionDenied
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from django.shortcuts import get_object_or_404
from django.core.mail import send_mail
from django.conf import settings
import secrets
from django.utils import timezone

from .models import CoachCertificate, GymDailyToken, GymEntry, User, Membre, Coach, SubscriptionPlan, MembreSubscription, Payment,PasswordResetToken,Course, CourseReservation, CourseWaitlist, CoachReview
from .serializers import (
    UserSerializer,
    RegisterSerializer,
    ChangePasswordSerializer,
    MembreSerializer,
    MembreCreateSerializer,
    CoachSerializer,
    CoachCreateSerializer,
    CoachActivateSerializer,
    SubscriptionPlanSerializer,
    MembreSubscriptionSerializer,
    MembreSubscriptionCreateSerializer,
    PaymentSerializer,
    PaymentCreateSerializer,
    ForgotPasswordSerializer,
    ResetPasswordSerializer,
    CourseSerializer, 
    CourseReservationSerializer, 
    CourseWaitlistSerializer,
    CoachReviewSerializer,
    CoachCertificateSerializer,
)
from django.db import transaction

# ─────────────────────────────────────────
# Permissions
# ─────────────────────────────────────────

class IsAdmin(permissions.BasePermission):
    """Only admin users."""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == "admin"


class IsCoach(permissions.BasePermission):
    """Only active coach users."""
    def has_permission(self, request, view):
        if not (request.user.is_authenticated and request.user.role == "coach"):
            return False
        # block inactive (not yet approved) coaches
        coach = getattr(request.user, "coach_profile", None)
        return coach is not None and coach.is_active


class IsAdminOrCoach(permissions.BasePermission):
    """Admin, or an approved coach."""
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        if request.user.role == "admin":
            return True
        if request.user.role == "coach":
            coach = getattr(request.user, "coach_profile", None)
            return coach is not None and coach.is_active
        return False


class IsOwnerOrAdmin(permissions.BasePermission):
    """Object-level: owner or admin."""
    def has_object_permission(self, request, view, obj):
        if request.user.role == "admin":
            return True
        return getattr(obj, "user", obj) == request.user


# ─────────────────────────────────────────
# Auth Views
# ─────────────────────────────────────────

class RegisterView(generics.CreateAPIView):
    """
    POST /auth/register/
    Public — creates User + Membre or Coach profile in one request.

    Membre payload example:
    {
        "first_name": "Ali", "last_name": "Ben", "email": "ali@example.com",
        "phone": "0550000000", "role": "membre",
        "password": "Str0ng!", "password2": "Str0ng!",
        "date_of_birth": "1995-06-15", "health_goal": "Lose weight"
    }

    Coach payload example:
    {
        "first_name": "Sara", "last_name": "Coach", "email": "sara@example.com",
        "phone": "0660000000", "role": "coach",
        "password": "Str0ng!", "password2": "Str0ng!",
        "specialties": "Yoga, Pilates", "years_of_experience": 5
    }
    Note: coach accounts start inactive — admin must approve via PATCH /coaches/<pk>/activate/
    """
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        refresh = RefreshToken.for_user(user)

        # Build profile data for the response
        profile = None
        if user.role == "membre":
            membre = getattr(user, "membre_profile", None)
            profile = MembreSerializer(membre).data if membre else None
        elif user.role == "coach":
            coach = getattr(user, "coach_profile", None)
            profile = CoachSerializer(coach).data if coach else None

        return Response(
            {
                "user": UserSerializer(user).data,
                "profile": profile,
                "refresh": str(refresh),
                "access": str(refresh.access_token),
                # remind frontend if coach needs approval
                **({"pending_approval": True} if user.role == "coach" else {}),
            },
            status=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    """
    POST /auth/login/
    Returns JWT tokens on valid credentials.
    Coaches that are not yet approved receive a clear error.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email    = request.data.get("email")
        password = request.data.get("password")

        if not email or not password:
            return Response(
                {"detail": "Email and password are required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = authenticate(request, email=email, password=password)
        if not user:
            return Response(
                {"detail": "Invalid credentials."},
                status=status.HTTP_401_UNAUTHORIZED,
            )
        if not user.is_active:
            return Response(
                {"detail": "Account is disabled."},
                status=status.HTTP_403_FORBIDDEN,
            )

        # Block unapproved coaches from logging in
        if user.role == "coach":
            coach = getattr(user, "coach_profile", None)
            if coach and not coach.is_active:
                return Response(
                    {"detail": "Your coach account is pending admin approval."},
                    status=status.HTTP_403_FORBIDDEN,
                )

        refresh = RefreshToken.for_user(user)
        return Response(
            {
                "user": UserSerializer(user).data,
                "refresh": str(refresh),
                "access": str(refresh.access_token),
            }
        )


class LogoutView(APIView):
    """
    POST /auth/logout/
    Blacklists the provided refresh token.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        try:
            token = RefreshToken(request.data.get("refresh"))
            token.blacklist()
            return Response({"detail": "Logged out successfully."}, status=status.HTTP_205_RESET_CONTENT)
        except Exception:
            return Response({"detail": "Invalid or expired token."}, status=status.HTTP_400_BAD_REQUEST)


class ChangePasswordView(APIView):
    """
    PUT /auth/change-password/
    Authenticated user changes their own password.
    Requires refresh token in payload to invalidate existing sessions.
    """
    permission_classes = [permissions.IsAuthenticated]

    def put(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = request.user
        if not user.check_password(serializer.validated_data["old_password"]):
            return Response(
                {"old_password": "Incorrect password."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user.set_password(serializer.validated_data["new_password"])
        user.save()

        # Invalidate current refresh token to force re-login
        try:
            refresh = RefreshToken(request.data.get("refresh"))
            refresh.blacklist()
        except Exception:
            pass  # already invalid or not provided, no problem

        return Response({
            "detail": "Password updated successfully. Please log in again."
        })

class ForgotPasswordView(APIView):
    """
    POST /auth/forgot-password/
    Sends a password reset link to the user's email.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = ForgotPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data["email"]

        # always return 200 even if email doesn't exist (security best practice)
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({"detail": "If this email exists you will receive a reset link."})

        # invalidate old tokens
        PasswordResetToken.objects.filter(user=user, is_used=False).update(is_used=True)

        # generate new token
        token = secrets.token_urlsafe(32)
        PasswordResetToken.objects.create(user=user, token=token)

        # build reset link
        reset_link = f"{settings.FRONTEND_URL}/reset-password?token={token}"

        # send email
        send_mail(
            subject="Reset your FitTech password",
            message=f"Hi {user.first_name},\n\nClick the link below to reset your password:\n{reset_link}\n\nThis link expires in 1 hour.\n\nIf you didn't request this, ignore this email.",
            from_email=settings.EMAIL_HOST_USER,
            recipient_list=[email],
            fail_silently=False,
        )

        return Response({"detail": "If this email exists you will receive a reset link."})


class ResetPasswordView(APIView):
    """
    POST /auth/reset-password/
    Validates token and sets new password.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = ResetPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        token_str = serializer.validated_data["token"]

        try:
            reset_token = PasswordResetToken.objects.select_related("user").get(token=token_str)
        except PasswordResetToken.DoesNotExist:
            return Response({"detail": "Invalid or expired token."}, status=status.HTTP_400_BAD_REQUEST)

        if not reset_token.is_valid():
            return Response({"detail": "Invalid or expired token."}, status=status.HTTP_400_BAD_REQUEST)

        user = reset_token.user
        user.set_password(serializer.validated_data["new_password"])
        user.save()

        # mark token as used
        reset_token.is_used = True
        reset_token.save()

        return Response({"detail": "Password reset successfully. You can now log in."})


class MeView(generics.RetrieveUpdateAPIView):
    """
    GET /auth/me/   — retrieve own profile
    PUT /auth/me/   — update own profile
    """
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user


# ─────────────────────────────────────────
# User Views  (admin only)
# ─────────────────────────────────────────

class UserListView(generics.ListAPIView):
    """GET /users/ — Admin: list all users."""
    queryset = User.objects.all().order_by("-created_at")
    serializer_class = UserSerializer
    permission_classes = [IsAdmin]


class UserDetailView(generics.RetrieveUpdateDestroyAPIView):
    """GET/PUT/DELETE /users/<pk>/ — Admin only."""
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAdmin]


# ─────────────────────────────────────────
# Membre Views
# ─────────────────────────────────────────

class MembreListCreateView(generics.ListCreateAPIView):
    """
    GET  /membres/   — list all membres (admin/coach)
    POST /membres/   — create a membre profile (admin)
    """
    def get_queryset(self):
        user = self.request.user

        if user.role == "admin":
            return Membre.objects.select_related("user").all()

        if user.role == "coach":
            coach = user.coach_profile
            reserved_ids = CourseReservation.objects.filter(
                course__coach=coach,
            ).values_list("membre_id", flat=True).distinct()

            return Membre.objects.select_related("user").filter(
                id__in=reserved_ids
            )

        return Membre.objects.none()

    def get_serializer_class(self):
        return MembreCreateSerializer if self.request.method == "POST" else MembreSerializer

    def get_permissions(self):
        return [IsAdmin()] if self.request.method == "POST" else [IsAdminOrCoach()]


class MembreDetailView(generics.RetrieveUpdateDestroyAPIView):
    """GET/PUT/DELETE /membres/<pk>/"""
    queryset = Membre.objects.select_related("user").all()

    def get_serializer_class(self):
        return MembreCreateSerializer if self.request.method in ("PUT", "PATCH") else MembreSerializer

    def get_permissions(self):
        return [IsAdmin()] if self.request.method in ("PUT", "PATCH", "DELETE") else [IsAdminOrCoach()]


class MyMembreProfileView(generics.RetrieveUpdateAPIView):
    """GET/PUT /membres/me/ — membre's own profile."""
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_class(self):
        return MembreCreateSerializer if self.request.method in ("PUT", "PATCH") else MembreSerializer

    def get_object(self):
        return get_object_or_404(Membre, user=self.request.user)


# ─────────────────────────────────────────
# Coach Views
# ─────────────────────────────────────────

class CoachListCreateView(generics.ListCreateAPIView):
    """
    GET  /coaches/   — list coaches (authenticated)
    POST /coaches/   — create a coach profile manually (admin)
    """
    queryset = Coach.objects.select_related("user").all()

    def get_serializer_class(self):
        return CoachCreateSerializer if self.request.method == "POST" else CoachSerializer

    def get_permissions(self):
        return [IsAdmin()] if self.request.method == "POST" else [permissions.IsAuthenticated()]


class CoachDetailView(generics.RetrieveUpdateDestroyAPIView):
    """GET/PUT/DELETE /coaches/<pk>/"""
    queryset = Coach.objects.select_related("user").all()

    def get_serializer_class(self):
        return CoachCreateSerializer if self.request.method in ("PUT", "PATCH") else CoachSerializer

    def get_permissions(self):
        return [IsAdmin()] if self.request.method in ("PUT", "PATCH", "DELETE") else [permissions.IsAuthenticated()]


class MyCoachProfileView(generics.RetrieveUpdateAPIView):
    """GET/PUT /coaches/me/ — coach's own profile."""
    permission_classes = [IsCoach]

    def get_serializer_class(self):
        return CoachCreateSerializer if self.request.method in ("PUT", "PATCH") else CoachSerializer

    def get_object(self):
        return get_object_or_404(Coach, user=self.request.user)


class CoachActivateView(APIView):
    """
    PATCH /coaches/<pk>/activate/
    Admin only — approve or deactivate a coach account.

    Payload: { "is_active": true }
    """
    permission_classes = [IsAdmin]

    def patch(self, request, pk):
        coach = get_object_or_404(Coach, pk=pk)
        serializer = CoachActivateSerializer(coach, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()

        action = "approved" if coach.is_active else "deactivated"
        return Response(
            {
                "detail": f"Coach has been {action}.",
                "coach": CoachSerializer(coach).data,
            }
        )


class PendingCoachListView(generics.ListAPIView):
    """
    GET /coaches/pending/
    Admin only — list all coaches awaiting approval.
    """
    serializer_class = CoachSerializer
    permission_classes = [IsAdmin]

    def get_queryset(self):
        return Coach.objects.select_related("user").filter(is_active=False)


class CoachReviewListCreateView(generics.ListCreateAPIView):
    serializer_class = CoachReviewSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return CoachReview.objects.filter(coach=self.kwargs["coach_pk"])


class CoachReviewDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = CoachReviewSerializer
    permission_classes = [IsOwnerOrAdmin]

    def get_queryset(self):
        return CoachReview.objects.filter(coach=self.kwargs["coach_pk"])

    def get_permissions(self):
        if self.request.method == "GET":
            return [permissions.IsAuthenticated()]
        return [IsOwnerOrAdmin()]


class CoachCertificateListCreateView(generics.ListCreateAPIView):
    serializer_class = CoachCertificateSerializer

    def get_queryset(self):
        return CoachCertificate.objects.filter(coach=self.kwargs["coach_pk"])

    def get_permissions(self):
        if self.request.method == "GET":
            return [permissions.IsAuthenticated()]
        return [IsCoach()]


class CoachCertificateDetailView(generics.RetrieveDestroyAPIView):
    serializer_class = CoachCertificateSerializer

    def get_queryset(self):
        return CoachCertificate.objects.filter(coach=self.kwargs["coach_pk"])

    def get_permissions(self):
        if self.request.method == "GET":
            return [permissions.IsAuthenticated()]
        return [IsCoach()]
    


class CoachAssignedMembresView(generics.ListAPIView):
    """
    GET /coaches/me/membres/ — directly assigned membres (full profile)
    """
    permission_classes = [IsCoach]
    serializer_class = MembreSerializer

    def get_queryset(self):
        coach = get_object_or_404(Coach, user=self.request.user)
        return Membre.objects.select_related("user").filter(coach=coach)
    

# ─────────────────────────────────────────
# Subscription Plan Views
# ─────────────────────────────────────────

class SubscriptionPlanListCreateView(generics.ListCreateAPIView):
    """GET /plans/ — authenticated | POST /plans/ — admin"""
    queryset = SubscriptionPlan.objects.all().order_by("price")
    serializer_class = SubscriptionPlanSerializer

    def get_permissions(self):
        return [IsAdmin()] if self.request.method == "POST" else [permissions.IsAuthenticated()]


class SubscriptionPlanDetailView(generics.RetrieveUpdateDestroyAPIView):
    """GET/PUT/DELETE /plans/<pk>/"""
    queryset = SubscriptionPlan.objects.all()
    serializer_class = SubscriptionPlanSerializer

    def get_permissions(self):
        return [IsAdmin()] if self.request.method in ("PUT", "PATCH", "DELETE") else [permissions.IsAuthenticated()]


# ─────────────────────────────────────────
# Membre Subscription Views
# ─────────────────────────────────────────

class MembreSubscriptionListCreateView(generics.ListCreateAPIView):
    """GET /subscriptions/ | POST /subscriptions/ — admin"""

    def get_queryset(self):
        user = self.request.user
        qs = MembreSubscription.objects.select_related("membre__user", "plan")
        if user.role in ("admin", "coach"):
            return qs.all()
        return qs.filter(membre__user=user)

    def get_serializer_class(self):
        return MembreSubscriptionCreateSerializer if self.request.method == "POST" else MembreSubscriptionSerializer

    def get_permissions(self):
        return [IsAdmin()] if self.request.method == "POST" else [permissions.IsAuthenticated()]
    
    def perform_create(self, serializer):
        plan = serializer.validated_data["plan"]
        remaining = 0 if plan.tier == "full" else plan.sessions_count
        subscription = serializer.save(remaining_sessions=remaining)
    # reset coach assignment on new subscription
        membre = subscription.membre
        membre.coach = None
        membre.save()

class MembreSubscriptionDetailView(generics.RetrieveUpdateDestroyAPIView):
    """GET/PUT/DELETE /subscriptions/<pk>/"""
    queryset = MembreSubscription.objects.select_related("membre__user", "plan").all()

    def get_serializer_class(self):
        return MembreSubscriptionCreateSerializer if self.request.method in ("PUT", "PATCH") else MembreSubscriptionSerializer

    def get_permissions(self):
        return [IsAdmin()] if self.request.method in ("PUT", "PATCH", "DELETE") else [permissions.IsAuthenticated()]


class MySubscriptionsView(generics.ListAPIView):
    """GET /subscriptions/me/"""
    serializer_class = MembreSubscriptionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return MembreSubscription.objects.select_related("membre__user", "plan").filter(
            membre__user=self.request.user
        )

class AssignCoachView(APIView):
    """
    POST /membres/me/assign-coach/   — assign a coach
    DELETE /membres/me/assign-coach/ — unassign (on plan renewal)
    """
    permission_classes = [permissions.IsAuthenticated]

    def _get_membre_and_validate_plan(self, request):
        membre = get_object_or_404(Membre, user=request.user)

        active_sub = MembreSubscription.objects.filter(
            membre=membre,
            status="active",
        ).select_related("plan").first()

        if not active_sub or active_sub.plan.tier != "full":
            raise PermissionDenied("Coach assignment requires an active full options plan.")

        return membre, active_sub

    def post(self, request):
        membre, active_sub = self._get_membre_and_validate_plan(request)

        if membre.coach is not None:
            return Response(
                {"detail": "You already have a coach. You can only switch after your plan ends."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        coach_id = request.data.get("coach")
        coach = get_object_or_404(Coach, pk=coach_id, is_active=True)

        membre.coach = coach
        membre.save()

        return Response({"detail": f"Coach assigned successfully."})

    def delete(self, request):
        membre, _ = self._get_membre_and_validate_plan(request)
        membre.coach = None
        membre.save()
        return Response({"detail": "Coach unassigned."})
# ─────────────────────────────────────────
# Payment Views
# ─────────────────────────────────────────

class PaymentListCreateView(generics.ListCreateAPIView):
    """GET /payments/ | POST /payments/ — admin"""

    def get_queryset(self):
        user = self.request.user
        qs = Payment.objects.select_related("membre__user", "subscription__plan")
        if user.role in ("admin", "coach"):
            return qs.all()
        return qs.filter(membre__user=user)

    def get_serializer_class(self):
        return PaymentCreateSerializer if self.request.method == "POST" else PaymentSerializer

    def get_permissions(self):
        return [IsAdmin()] if self.request.method == "POST" else [permissions.IsAuthenticated()]


class PaymentDetailView(generics.RetrieveUpdateAPIView):
    """GET/PUT /payments/<pk>/ — no DELETE (financial records)"""
    queryset = Payment.objects.select_related("membre__user", "subscription__plan").all()

    def get_serializer_class(self):
        return PaymentCreateSerializer if self.request.method in ("PUT", "PATCH") else PaymentSerializer

    def get_permissions(self):
        return [IsAdmin()] if self.request.method in ("PUT", "PATCH") else [permissions.IsAuthenticated()]


class MyPaymentsView(generics.ListAPIView):
    """GET /payments/me/"""
    serializer_class = PaymentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Payment.objects.select_related("membre__user", "subscription__plan").filter(
            membre__user=self.request.user
        )
    
# Course Views
class CourseListCreateView(generics.ListCreateAPIView):
    queryset = Course.objects.all()
    serializer_class = CourseSerializer

    def get_permissions(self):
        if self.request.method == "POST":
            return [IsAdminOrCoach()]
        return [permissions.IsAuthenticated()]


class CourseDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Course.objects.all()
    serializer_class = CourseSerializer

    def get_permissions(self):
        if self.request.method == "GET":
            return [permissions.IsAuthenticated()]
        return [IsAdminOrCoach()]


class CourseReservationListCreateView(generics.ListCreateAPIView):
    serializer_class = CourseReservationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        if self.request.user.role == "admin":
            return CourseReservation.objects.all()
        return CourseReservation.objects.filter(membre__user=self.request.user)


class CourseReservationDetailView(generics.RetrieveUpdateAPIView):
    queryset = CourseReservation.objects.all()
    serializer_class = CourseReservationSerializer
    permission_classes = [IsOwnerOrAdmin]


class CancelReservationView(APIView):
    """
    PATCH /reservations/<pk>/cancel/
    Cancels a reservation and promotes the first waitlist entry.
    """
    permission_classes = [IsOwnerOrAdmin]

    def patch(self, request, pk):
        reservation = get_object_or_404(CourseReservation, pk=pk)

        with transaction.atomic():
            reservation.reservation_status = "cancelled"
            reservation.save()

            # Promote next person from waitlist
            next_entry = (
                CourseWaitlist.objects.filter(course=reservation.course)
                .order_by("position")
                .first()
            )
            if next_entry:
                CourseReservation.objects.create(
                    course=reservation.course,
                    membre=next_entry.membre,
                    reservation_status="confirmed",
                )
                next_entry.delete()
                # Re-number remaining waitlist positions
                for i, entry in enumerate(
                    CourseWaitlist.objects.filter(course=reservation.course).order_by("position"),
                    start=1,
                ):
                    entry.position = i
                    entry.save()

        return Response({"detail": "Reservation cancelled."})


class CourseWaitlistListCreateView(generics.ListCreateAPIView):
    serializer_class = CourseWaitlistSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        if self.request.user.role == "admin":
            return CourseWaitlist.objects.all()
        return CourseWaitlist.objects.filter(membre__user=self.request.user)


class CourseWaitlistDetailView(generics.RetrieveDestroyAPIView):
    queryset = CourseWaitlist.objects.all()
    serializer_class = CourseWaitlistSerializer
    permission_classes = [IsOwnerOrAdmin]



class GymCheckInView(APIView):
    """
    POST /gym/checkin/
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        token = request.data.get("token")
        today = timezone.now().date()

        # 1. validate token
        daily_token = GymDailyToken.objects.filter(date=today).first()
        if not daily_token or daily_token.token != token:
            return Response(
                {"detail": "Invalid or expired QR code."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # 2. get membre
        membre = get_object_or_404(Membre, user=request.user)

        # 3. check active subscription
        active_sub = MembreSubscription.objects.filter(
            membre=membre,
            status="active",
        ).select_related("plan").first()

        if not active_sub:
            return Response(
                {"detail": "No active subscription."},
                status=status.HTTP_403_FORBIDDEN,
            )

        # 4. check already entered today (basic/advanced only)
        if active_sub.plan.tier != "full":
            already_entered = GymEntry.objects.filter(membre=membre, date=today).exists()
            if already_entered:
                return Response(
                    {"detail": "You have already checked in today."},
                    status=status.HTTP_403_FORBIDDEN,
                )

        # 5. log entry
        GymEntry.objects.get_or_create(membre=membre, date=today)

        # 6. decrease session for basic/advanced
        if active_sub.plan.tier != "full":
            active_sub.remaining_sessions -= 1
            if active_sub.remaining_sessions <= 0:
                active_sub.remaining_sessions = 0
                active_sub.status = "expired"
            active_sub.save()

        return Response({"detail": "Check-in successful. Welcome!"})
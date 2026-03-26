# Create your views here.
from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from django.shortcuts import get_object_or_404

from .models import User, Membre, Coach, SubscriptionPlan, MembreSubscription, Payment
from .serializers import (
    UserSerializer,
    RegisterSerializer,
    ChangePasswordSerializer,
    MembreSerializer,
    MembreCreateSerializer,
    CoachSerializer,
    CoachCreateSerializer,
    SubscriptionPlanSerializer,
    MembreSubscriptionSerializer,
    MembreSubscriptionCreateSerializer,
    PaymentSerializer,
    PaymentCreateSerializer,
)


# ─────────────────────────────────────────
# Permissions
# ─────────────────────────────────────────

class IsAdmin(permissions.BasePermission):
    """Only admin users."""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == "admin"


class IsCoach(permissions.BasePermission):
    """Only coach users."""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == "coach"


class IsAdminOrCoach(permissions.BasePermission):
    """Admin or coach users."""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in ("admin", "coach")


class IsOwnerOrAdmin(permissions.BasePermission):
    """Object-level: owner or admin."""
    def has_object_permission(self, request, view, obj):
        if request.user.role == "admin":
            return True
        # obj is a Membre or Coach — check linked user
        return getattr(obj, "user", obj) == request.user


# ─────────────────────────────────────────
# Auth Views
# ─────────────────────────────────────────

class RegisterView(generics.CreateAPIView):
    """
    POST /auth/register/
    Public endpoint — create a new user account.
    """
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        refresh = RefreshToken.for_user(user)
        return Response(
            {
                "user": UserSerializer(user).data,
                "refresh": str(refresh),
                "access": str(refresh.access_token),
            },
            status=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    """
    POST /auth/login/
    Returns JWT tokens on valid credentials.
    """
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = request.data.get("email")
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
            refresh_token = request.data.get("refresh")
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response({"detail": "Logged out successfully."}, status=status.HTTP_205_RESET_CONTENT)
        except Exception:
            return Response({"detail": "Invalid or expired token."}, status=status.HTTP_400_BAD_REQUEST)


class ChangePasswordView(APIView):
    """
    PUT /auth/change-password/
    Authenticated user changes their own password.
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
        return Response({"detail": "Password updated successfully."})


class MeView(generics.RetrieveUpdateAPIView):
    """
    GET  /auth/me/   — retrieve own profile
    PUT  /auth/me/   — update own profile
    """
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user


# ─────────────────────────────────────────
# User Views  (admin only)
# ─────────────────────────────────────────

class UserListView(generics.ListAPIView):
    """
    GET /users/
    Admin: list all users.
    """
    queryset = User.objects.all().order_by("-created_at")
    serializer_class = UserSerializer
    permission_classes = [IsAdmin]


class UserDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET    /users/<pk>/
    PUT    /users/<pk>/
    DELETE /users/<pk>/
    Admin: retrieve, update, or deactivate a user.
    """
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAdmin]


# ─────────────────────────────────────────
# Membre Views
# ─────────────────────────────────────────

class MembreListCreateView(generics.ListCreateAPIView):
    """
    GET  /membres/       — list all membres (admin/coach)
    POST /membres/       — create a membre profile (admin)
    """
    queryset = Membre.objects.select_related("user").all()

    def get_serializer_class(self):
        if self.request.method == "POST":
            return MembreCreateSerializer
        return MembreSerializer

    def get_permissions(self):
        if self.request.method == "POST":
            return [IsAdmin()]
        return [IsAdminOrCoach()]


class MembreDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET    /membres/<pk>/
    PUT    /membres/<pk>/
    DELETE /membres/<pk>/
    """
    queryset = Membre.objects.select_related("user").all()

    def get_serializer_class(self):
        if self.request.method in ("PUT", "PATCH"):
            return MembreCreateSerializer
        return MembreSerializer

    def get_permissions(self):
        if self.request.method in ("PUT", "PATCH", "DELETE"):
            return [IsAdmin()]
        return [IsAdminOrCoach()]


class MyMembreProfileView(generics.RetrieveUpdateAPIView):
    """
    GET /membres/me/   — membre retrieves their own profile
    PUT /membres/me/   — membre updates their own profile
    """
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_class(self):
        if self.request.method in ("PUT", "PATCH"):
            return MembreCreateSerializer
        return MembreSerializer

    def get_object(self):
        return get_object_or_404(Membre, user=self.request.user)


# ─────────────────────────────────────────
# Coach Views
# ─────────────────────────────────────────

class CoachListCreateView(generics.ListCreateAPIView):
    """
    GET  /coaches/   — list all coaches (authenticated)
    POST /coaches/   — create a coach profile (admin)
    """
    queryset = Coach.objects.select_related("user").all()

    def get_serializer_class(self):
        if self.request.method == "POST":
            return CoachCreateSerializer
        return CoachSerializer

    def get_permissions(self):
        if self.request.method == "POST":
            return [IsAdmin()]
        return [permissions.IsAuthenticated()]


class CoachDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET    /coaches/<pk>/
    PUT    /coaches/<pk>/
    DELETE /coaches/<pk>/
    """
    queryset = Coach.objects.select_related("user").all()

    def get_serializer_class(self):
        if self.request.method in ("PUT", "PATCH"):
            return CoachCreateSerializer
        return CoachSerializer

    def get_permissions(self):
        if self.request.method in ("PUT", "PATCH", "DELETE"):
            return [IsAdmin()]
        return [permissions.IsAuthenticated()]


class MyCoachProfileView(generics.RetrieveUpdateAPIView):
    """
    GET /coaches/me/   — coach retrieves their own profile
    PUT /coaches/me/   — coach updates their own profile
    """
    permission_classes = [IsCoach]

    def get_serializer_class(self):
        if self.request.method in ("PUT", "PATCH"):
            return CoachCreateSerializer
        return CoachSerializer

    def get_object(self):
        return get_object_or_404(Coach, user=self.request.user)


# ─────────────────────────────────────────
# Subscription Plan Views
# ─────────────────────────────────────────

class SubscriptionPlanListCreateView(generics.ListCreateAPIView):
    """
    GET  /plans/   — list all plans (authenticated)
    POST /plans/   — create a plan (admin only)
    """
    queryset = SubscriptionPlan.objects.all().order_by("price")
    serializer_class = SubscriptionPlanSerializer

    def get_permissions(self):
        if self.request.method == "POST":
            return [IsAdmin()]
        return [permissions.IsAuthenticated()]


class SubscriptionPlanDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET    /plans/<pk>/
    PUT    /plans/<pk>/
    DELETE /plans/<pk>/
    Admin only for mutations.
    """
    queryset = SubscriptionPlan.objects.all()
    serializer_class = SubscriptionPlanSerializer

    def get_permissions(self):
        if self.request.method in ("PUT", "PATCH", "DELETE"):
            return [IsAdmin()]
        return [permissions.IsAuthenticated()]


# ─────────────────────────────────────────
# Membre Subscription Views
# ─────────────────────────────────────────

class MembreSubscriptionListCreateView(generics.ListCreateAPIView):
    """
    GET  /subscriptions/   — list subscriptions
    POST /subscriptions/   — assign a subscription to a membre (admin)
    """

    def get_queryset(self):
        user = self.request.user
        if user.role == "admin":
            return MembreSubscription.objects.select_related("membre__user", "plan").all()
        if user.role == "coach":
            return MembreSubscription.objects.select_related("membre__user", "plan").all()
        # membre sees only their own
        return MembreSubscription.objects.select_related("membre__user", "plan").filter(
            membre__user=user
        )

    def get_serializer_class(self):
        if self.request.method == "POST":
            return MembreSubscriptionCreateSerializer
        return MembreSubscriptionSerializer

    def get_permissions(self):
        if self.request.method == "POST":
            return [IsAdmin()]
        return [permissions.IsAuthenticated()]


class MembreSubscriptionDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET    /subscriptions/<pk>/
    PUT    /subscriptions/<pk>/
    DELETE /subscriptions/<pk>/
    """
    queryset = MembreSubscription.objects.select_related("membre__user", "plan").all()

    def get_serializer_class(self):
        if self.request.method in ("PUT", "PATCH"):
            return MembreSubscriptionCreateSerializer
        return MembreSubscriptionSerializer

    def get_permissions(self):
        if self.request.method in ("PUT", "PATCH", "DELETE"):
            return [IsAdmin()]
        return [permissions.IsAuthenticated()]


class MySubscriptionsView(generics.ListAPIView):
    """
    GET /subscriptions/me/
    Membre retrieves their own subscriptions.
    """
    serializer_class = MembreSubscriptionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return MembreSubscription.objects.select_related("membre__user", "plan").filter(
            membre__user=self.request.user
        )


# ─────────────────────────────────────────
# Payment Views
# ─────────────────────────────────────────

class PaymentListCreateView(generics.ListCreateAPIView):
    """
    GET  /payments/   — list payments
    POST /payments/   — record a payment (admin)
    """

    def get_queryset(self):
        user = self.request.user
        if user.role in ("admin", "coach"):
            return Payment.objects.select_related("membre__user", "subscription__plan").all()
        return Payment.objects.select_related("membre__user", "subscription__plan").filter(
            membre__user=user
        )

    def get_serializer_class(self):
        if self.request.method == "POST":
            return PaymentCreateSerializer
        return PaymentSerializer

    def get_permissions(self):
        if self.request.method == "POST":
            return [IsAdmin()]
        return [permissions.IsAuthenticated()]


class PaymentDetailView(generics.RetrieveUpdateAPIView):
    """
    GET /payments/<pk>/
    PUT /payments/<pk>/   — admin can update payment status
    No deletion — payments are financial records.
    """
    queryset = Payment.objects.select_related("membre__user", "subscription__plan").all()

    def get_serializer_class(self):
        if self.request.method in ("PUT", "PATCH"):
            return PaymentCreateSerializer
        return PaymentSerializer

    def get_permissions(self):
        if self.request.method in ("PUT", "PATCH"):
            return [IsAdmin()]
        return [permissions.IsAuthenticated()]


class MyPaymentsView(generics.ListAPIView):
    """
    GET /payments/me/
    Membre retrieves their own payment history.
    """
    serializer_class = PaymentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Payment.objects.select_related("membre__user", "subscription__plan").filter(
            membre__user=self.request.user
        )
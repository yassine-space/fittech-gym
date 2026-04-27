from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    # Auth
    RegisterView,
    LoginView,
    LogoutView,
    ChangePasswordView,
    MeView,
    ResetPasswordView,
    ForgotPasswordView,
    # Users
    UserListView,
    UserDetailView,
    # Membres
    MembreListCreateView,
    MembreDetailView,
    MyMembreProfileView,
    # Coaches
    CoachListCreateView,
    CoachDetailView,
    MyCoachProfileView,
    CoachActivateView,
    PendingCoachListView,
    # Subscription Plans
    SubscriptionPlanListCreateView,
    SubscriptionPlanDetailView,
    # Membre Subscriptions
    MembreSubscriptionListCreateView,
    MembreSubscriptionDetailView,
    MySubscriptionsView,
    # Payments
    PaymentListCreateView,
    PaymentDetailView,
    MyPaymentsView,
    #Courses
    CourseListCreateView, CourseDetailView,
    CourseReservationListCreateView, CourseReservationDetailView, CancelReservationView,
    CourseWaitlistListCreateView, CourseWaitlistDetailView,
)

urlpatterns = [

    # ─────────────────────────────────────────
    # Auth
    # ─────────────────────────────────────────
    path("auth/register/",          RegisterView.as_view(),        name="auth-register"),
    path("auth/login/",             LoginView.as_view(),           name="auth-login"),
    path("auth/logout/",            LogoutView.as_view(),          name="auth-logout"),
    path("auth/token/refresh/",     TokenRefreshView.as_view(),    name="auth-token-refresh"),
    path("auth/change-password/",   ChangePasswordView.as_view(),  name="auth-change-password"),
    path("auth/me/",                MeView.as_view(),              name="auth-me"),
    path("auth/forgot-password/", ForgotPasswordView.as_view(), name="auth-forgot-password"),
    path("auth/reset-password/",  ResetPasswordView.as_view(),  name="auth-reset-password"),
    # ─────────────────────────────────────────
    # Users  (admin only)
    # ─────────────────────────────────────────
    path("users/",                  UserListView.as_view(),        name="user-list"),
    path("users/<uuid:pk>/",        UserDetailView.as_view(),      name="user-detail"),

    # ─────────────────────────────────────────
    # Membres
    # ─────────────────────────────────────────
    path("membres/",                MembreListCreateView.as_view(), name="membre-list"),
    path("membres/me/",             MyMembreProfileView.as_view(),  name="membre-me"),
    path("membres/<uuid:pk>/",      MembreDetailView.as_view(),     name="membre-detail"),

    # ─────────────────────────────────────────
    # Coaches
    # ─────────────────────────────────────────
    path("coaches/",                CoachListCreateView.as_view(),  name="coach-list"),
    path("coaches/me/",             MyCoachProfileView.as_view(),   name="coach-me"),
    path("coaches/<uuid:pk>/",      CoachDetailView.as_view(),      name="coach-detail"),
    path("coaches/<uuid:pk>/activate/", CoachActivateView.as_view(), name="coach-activate"),
    path("coaches/pending/",        PendingCoachListView.as_view(), name="coach-pending"),

    # ─────────────────────────────────────────
    # Subscription Plans
    # ─────────────────────────────────────────
    path("plans/",                  SubscriptionPlanListCreateView.as_view(),  name="plan-list"),
    path("plans/<uuid:pk>/",        SubscriptionPlanDetailView.as_view(),      name="plan-detail"),

    # ─────────────────────────────────────────
    # Membre Subscriptions
    # ─────────────────────────────────────────
    path("subscriptions/",          MembreSubscriptionListCreateView.as_view(), name="subscription-list"),
    path("subscriptions/me/",       MySubscriptionsView.as_view(),              name="subscription-me"),
    path("subscriptions/<uuid:pk>/", MembreSubscriptionDetailView.as_view(),    name="subscription-detail"),

    # ─────────────────────────────────────────
    # Payments
    # ─────────────────────────────────────────
    path("payments/",               PaymentListCreateView.as_view(),  name="payment-list"),
    path("payments/me/",            MyPaymentsView.as_view(),         name="payment-me"),
    path("payments/<uuid:pk>/",     PaymentDetailView.as_view(),      name="payment-detail"),
    # Courses
    path("courses/", CourseListCreateView.as_view()),
    path("courses/<uuid:pk>/", CourseDetailView.as_view()),

    # Reservations
    path("reservations/", CourseReservationListCreateView.as_view()),
    path("reservations/<uuid:pk>/", CourseReservationDetailView.as_view()),
    path("reservations/<uuid:pk>/cancel/", CancelReservationView.as_view()),

    # Waitlist
    path("waitlist/", CourseWaitlistListCreateView.as_view()),
    path("waitlist/<uuid:pk>/", CourseWaitlistDetailView.as_view()),
]
from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    # Auth
    AssignCoachView,
    CoachAssignedMembresView,
    CoachReviewDetailView,
    CoachReviewListCreateView,
    CoachCertificateListCreateView,
    CoachCertificateDetailView,
    ConversationListCreateView,
    GymCheckInView,
    MachineDetailView,
    MachineListCreateView,
    MachineReportStatusUpdateView,
    MarkAttendanceView,
    MessageDeleteView,
    MessageListCreateView,
    NotificationMarkReadView,
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
    WorkoutLogDetailView,
    WorkoutLogListCreateView,
    WorkoutProgressView,
    NotificationListView,
    NotificationMarkAllReadView,
    MachineReportListCreateView,
     # Chargily Pay ← new
    InitiateChargilyPaymentView,
    ChargilyWebhookView,
    ChargilySuccessView,
    ChargilyFailureView,
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
    path("membres/",                MembreListCreateView.as_view(), name="membre-list"),  #for the coaches to see the list of reserved membres and admin to see all membres
    path("membres/me/assign-coach/", AssignCoachView.as_view()),
    path("membres/me/",             MyMembreProfileView.as_view(),  name="membre-me"),
    path("membres/<uuid:pk>/",      MembreDetailView.as_view(),     name="membre-detail"),

    # ─────────────────────────────────────────
    # Coaches
    # ─────────────────────────────────────────
    path("coaches/",                CoachListCreateView.as_view(),  name="coach-list"),
    path("coaches/me/",             MyCoachProfileView.as_view(),   name="coach-me"),
    path("coaches/me/membres/", CoachAssignedMembresView.as_view(), name="coach-assigned-membres"),  #list of membres assigned to the coach
    path("coaches/<uuid:pk>/",      CoachDetailView.as_view(),      name="coach-detail"),
    path("coaches/<uuid:pk>/activate/", CoachActivateView.as_view(), name="coach-activate"),
    path("coaches/pending/",        PendingCoachListView.as_view(), name="coach-pending"),
    path("coaches/<uuid:coach_pk>/reviews/", CoachReviewListCreateView.as_view()),
    path("coaches/<uuid:coach_pk>/reviews/<uuid:pk>/", CoachReviewDetailView.as_view()),
    path("coaches/<uuid:coach_pk>/certificates/", CoachCertificateListCreateView.as_view()),
    path("coaches/<uuid:coach_pk>/certificates/<uuid:pk>/", CoachCertificateDetailView.as_view()),

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
    path("courses/", CourseListCreateView.as_view(), name="course-list"),
    path("courses/<uuid:pk>/", CourseDetailView.as_view(), name="course-detail"),

    # Reservations
    path("reservations/", CourseReservationListCreateView.as_view(), name="reservation-list"),
    path("reservations/<uuid:pk>/", CourseReservationDetailView.as_view(), name="reservation-detail"),
    path("reservations/<uuid:pk>/cancel/", CancelReservationView.as_view()),
    path("gym/checkin/", GymCheckInView.as_view()),
    path("reservations/<uuid:pk>/mark-attended/", MarkAttendanceView.as_view()),
    # Waitlist
    path("waitlist/", CourseWaitlistListCreateView.as_view(), name="waitlist-list"),
    path("waitlist/<uuid:pk>/", CourseWaitlistDetailView.as_view(), name="waitlist-detail"),

    # Chat

    path("conversations/", ConversationListCreateView.as_view(), name="conversation-list"),
    path("conversations/<uuid:conversation_id>/messages/", MessageListCreateView.as_view(), name="message-list"),
    path("conversations/<uuid:conversation_id>/messages/<uuid:pk>/delete/", MessageDeleteView.as_view(), name="message-delete"),



    # Workout Logs
    path("machines/", MachineListCreateView.as_view(), name="machine-list"),
    path("machines/<uuid:pk>/", MachineDetailView.as_view(), name="machine-detail"),
    path("workouts/", WorkoutLogListCreateView.as_view(), name="workout-list"),
    path("workouts/progress/", WorkoutProgressView.as_view(), name="workout-progress"),  # before workouts/<pk>/
    path("workouts/<uuid:pk>/", WorkoutLogDetailView.as_view(), name="workout-detail"),
    # Notifications
    path("notifications/", NotificationListView.as_view()),
    path("notifications/read-all/", NotificationMarkAllReadView.as_view()),  # before <pk>
    path("notifications/<uuid:pk>/read/", NotificationMarkReadView.as_view()),
    # Reports
    path("machine-reports/", MachineReportListCreateView.as_view()),
    path("machine-reports/<uuid:pk>/status/", MachineReportStatusUpdateView.as_view()),

     # ─────────────────────────────────────────
    # 1) Mobile app calls this → gets checkout_url to open in WebView
    path("payments/chargily/initiate/", InitiateChargilyPaymentView.as_view(), name="chargily-initiate"),
    # 2) Chargily calls this server-to-server to update payment status
    path("payments/chargily/webhook/",  ChargilyWebhookView.as_view(),          name="chargily-webhook"),
    # 3) Chargily redirects user's browser to one of these after payment
    path("payments/chargily/success/",  ChargilySuccessView.as_view(),          name="chargily-success"),
    path("payments/chargily/failure/",  ChargilyFailureView.as_view(),          name="chargily-failure"),
 



]
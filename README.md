# 🏋️ Performance Lab — Fitness Coaching Platform

A full-stack fitness coaching application built with **Flutter** (mobile) and **Django REST Framework** (backend). It connects coaches with members, manages courses, subscriptions, and payments — all in one place.

---

## 📱 Screenshots

> _Add your screenshots here_

---

## 🧱 Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter (Dart) |
| State Management | Provider |
| Navigation | go_router |
| Backend | Django + Django REST Framework |
| Auth | JWT (SimpleJWT) |
| Database | PostgreSQL (or SQLite for dev) |
| Email | Django `send_mail` |

---

## ✨ Features

### 👤 Authentication
- Register as a **Member** or **Coach**
- JWT login / logout / token refresh
- Change password (invalidates existing sessions)
- Forgot & reset password via email link

### 🏃 Members
- Personal profile with health goals and medical restrictions
- Subscription management (Basic / Advanced / Full Options plans)
- Course reservations and waitlist
- Assign a coach (requires Full Options plan)

### 🧑‍🏫 Coaches
- Coach dashboard with clients overview
- Create, edit, and delete courses
- View enrolled members per course
- Upload certificates
- Receive reviews from members who attended courses
- Account requires **admin approval** before login is allowed

### 📚 Courses
- Create courses with level (Beginner / Intermediate / Advanced), date, time, duration, and capacity
- Real-time spots remaining tracking
- Automatic waitlist promotion on cancellation
- Filter by level and tab between Upcoming / Ended

### 💳 Subscriptions & Payments
- Multiple plan types: Monthly, Weekly, Yearly, Sessions Pack
- Tiers: Basic, Advanced, Full Options
- Payment records with invoice numbers

### 🔑 Admin
- Approve or deactivate coach accounts
- Full CRUD on users, plans, subscriptions, and payments

---

## 📂 Project Structure

```
.
├── mobile/                         # Flutter app
│   ├── core/
│   │   ├── models/                 # Dart data models
│   │   └── providers/              # Provider state management
│   ├── features/
│   │   └── coach/
│   │       └── screens/            # Coach-specific screens
│   │           ├── clients_screen.dart
│   │           ├── courses_screen.dart
│   │           ├── programs_screen.dart
│   │           ├── messages_screen.dart
│   │           ├── profile_screen.dart
│   │           ├── coach_dashboard.dart
│   │           └── member_detail_screen.dart
│   └── navigation/
│       └── pages.dart
│
└── backend/                        # Django project
    └── fitapi/
        ├── models.py               # Database models
        ├── serializers.py          # DRF serializers
        ├── views.py                # API views & permissions
        └── urls.py                 # URL routing
```

---

## 🗄️ Database Models

| Model | Description |
|-------|-------------|
| `User` | Custom user with roles: `admin`, `membre`, `coach` |
| `Coach` | Coach profile linked to User; requires admin activation |
| `Membre` | Member profile with health data and coach assignment |
| `Course` | Fitness class created by a coach |
| `CourseReservation` | Member booking for a course |
| `CourseWaitlist` | Auto-promoted waitlist per course |
| `SubscriptionPlan` | Plan templates (type + tier + price) |
| `MembreSubscription` | Active subscription for a member |
| `Payment` | Payment record tied to a subscription |
| `CoachReview` | Member review after attending a course |
| `CoachCertificate` | Coach credentials with file upload |
| `PasswordResetToken` | Time-limited token for password reset |

---

## 🔌 API Endpoints

### Auth
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register/` | Register member or coach |
| POST | `/auth/login/` | Login and receive JWT tokens |
| POST | `/auth/logout/` | Blacklist refresh token |
| POST | `/auth/token/refresh/` | Refresh access token |
| PUT | `/auth/change-password/` | Change password |
| GET/PUT | `/auth/me/` | Get or update own user info |
| POST | `/auth/forgot-password/` | Send reset email |
| POST | `/auth/reset-password/` | Set new password via token |

### Members
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/membres/` | List members (admin/coach) |
| GET/PUT | `/membres/me/` | Own member profile |
| GET/PUT/DELETE | `/membres/<id>/` | Admin member management |
| POST/DELETE | `/membres/me/assign-coach/` | Assign or remove a coach |

### Coaches
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/coaches/` | List coaches |
| GET/PUT | `/coaches/me/` | Own coach profile |
| PATCH | `/coaches/<id>/activate/` | Admin: approve/deactivate |
| GET | `/coaches/pending/` | Admin: list pending coaches |
| GET/POST | `/coaches/<id>/reviews/` | List or create reviews |
| GET/POST | `/coaches/<id>/certificates/` | List or upload certificates |

### Courses
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET/POST | `/courses/` | List or create courses |
| GET/PUT/DELETE | `/courses/<id>/` | Course detail |
| GET/POST | `/reservations/` | List or create reservations |
| PATCH | `/reservations/<id>/cancel/` | Cancel + promote waitlist |
| GET/POST | `/waitlist/` | View or join waitlist |

### Plans & Payments
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET/POST | `/plans/` | Subscription plans |
| GET/POST | `/subscriptions/` | All subscriptions (admin) |
| GET | `/subscriptions/me/` | Own subscriptions |
| GET/POST | `/payments/` | All payments (admin) |
| GET | `/payments/me/` | Own payment history |

---

## 🚀 Getting Started

### Backend

```bash
# Clone the repo
git clone https://github.com/your-username/performance-lab.git
cd performance-lab/backend

# Create and activate a virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment variables
cp .env.example .env
# Edit .env: set SECRET_KEY, DATABASE_URL, EMAIL settings, FRONTEND_URL

# Apply migrations and run
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

### Mobile (Flutter)

```bash
cd performance-lab/mobile

# Install dependencies
flutter pub get

# Configure the API base URL in your environment/config file

# Run the app
flutter run
```

---


---

## 🔐 Permissions Summary

| Role | Capabilities |
|------|-------------|
| `admin` | Full access to all resources |
| `coach` | Manage own courses, view enrolled members, update own profile |
| `membre` | Book courses, manage own subscriptions and profile |

> **Note:** Coach accounts are inactive by default after registration. An admin must approve them via `PATCH /coaches/<id>/activate/` before they can log in.

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m 'Add some feature'`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

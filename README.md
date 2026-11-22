# SkillTrack — Student Skills, Placement & Web Portfolio Platform

<p align="center">
  <img src="assets/icons/app_icon.png" width="96" height="96" alt="SkillTrack Logo" onerror="this.style.display='none'"/>
</p>

<p align="center">
  <b>Build Skills. Track Progress. Ace Technical Interviews. Showcase Your Verified Portfolio.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.19+-02569B?logo=flutter&logoColor=white" alt="Flutter 3.19+"/>
  <img src="https://img.shields.io/badge/Dart-3.3+-0175C2?logo=dart&logoColor=white" alt="Dart 3.3+"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Web-4285F4?logo=googleplay&logoColor=white" alt="Android & Web"/>
  <img src="https://img.shields.io/badge/Architecture-Offline--First%20SQLite-003B57?logo=sqlite&logoColor=white" alt="Offline-First SQLite"/>
  <img src="https://img.shields.io/badge/Material%203-Lavender%20Light%20%26%20Dark-7C3AED" alt="Material 3 Lavender"/>
  <img src="https://img.shields.io/badge/Tests-119%20Passing-brightgreen?logo=checkmarx&logoColor=white" alt="119 Passing Tests"/>
  <img src="https://img.shields.io/badge/Analyzer-0%20Issues-brightgreen" alt="0 Analyzer Issues"/>
</p>

---

## 🌐 Live Web Demo & Sharable Student Card

- **Live Web Application**: [https://skill-track-ashy.vercel.app](https://skill-track-ashy.vercel.app)
- **Public Read-Only Portfolio URL**: `https://skill-track-ashy.vercel.app/#/p/{username}`
- **GitHub Repository**: [https://github.com/Naresh63-hub/SkillTrack](https://github.com/Naresh63-hub/SkillTrack)

---

## 🎯 About SkillTrack

**SkillTrack** is an offline-first personal career development and placement preparation application built with Flutter. Designed for engineering students and aspiring developers, SkillTrack empowers students to systematically master technical skills, prepare for competitive placement drives, simulate high-pressure verbal mock interviews, compile ATS-friendly resumes, and publish a **verified, sharable web portfolio** directly accessible by recruiters.

---

## ✨ Key Feature Highlights

### 1. 🎓 Sharable Public Web Portfolio & Verified Student Card
* **Public Read-Only URL**: Every student receives a unique public URL (`https://skill-track-ashy.vercel.app/#/p/username` or `/p/username`) to embed in resume headers, LinkedIn summaries, or emails.
* **Instant Visitor Access**: Recruiters and peers can view credentials and live demos without logging in, onboarding, or needing an account.
* **Live Deployment Launchers**: Direct action buttons to launch **Vercel** web apps, **Render** APIs, live demos, and **GitHub** repositories.
* **Verified Credentials Showcase**: Displays certificates with credential IDs, issuing bodies, completion dates, and official verification links.
* **1-Click Social Sharing**:
  * Clipboard URL copy with toast notification.
  * Direct WhatsApp sharing with formatted student card text.
  * LinkedIn and Twitter/X direct sharing.
* **Downloadable Portfolio PDF Summary**: Compiles a printable, high-resolution one-page student portfolio card.

### 2. 🎙️ Mock Interview Verbal Practice & AI STAR Evaluation
* **Countdown Pressure Timer**: Selectable 60s, 90s, or 120s countdown timers with pause/resume and quick `+30s` extensions to simulate real interview pressure.
* **Verbal Practice via Speech-to-Text**: Students speak answers out loud; the voice engine transcribes spoken responses in real-time.
* **3-Rubric Structured Evaluation**:
  1. **Communication & Structure**: Evaluates adherence to the **STAR method** (*Situation, Task, Action, Result*).
  2. **Technical Accuracy**: Verifies correctness, problem-solving reasoning, and depth.
  3. **Key Terminology Used**: Detects critical engineering terms, algorithms, and industry keywords.
* **Comprehensive Performance Report**: Final session analytics, strengths, areas for improvement, and role-specific recommended topics.

### 3. 🗺️ AI Career Roadmaps & Learning Paths
* **Curated Career Tracks**: Roadmaps for **Python Developer**, **Full Stack Developer**, **Flutter Developer**, **Data Analyst**, **AI/ML Engineer**, and **Java Developer**.
* **Hierarchical Milestone Nodes**: Clear progression (*Beginner*, *Intermediate*, *Advanced*) with estimated completion days and curated documentation links.
* **One-Click Topic Import**: Directly imports roadmap milestones into personal skill tracking.

### 4. 📝 Study Notes & Future Planner Hub
* **Markdown Notes**: Rich study notes with custom tags, color coding, and quick pinning.
* **Weekly Plans & Schedule**: Interactive 7-day schedule with activity streaks, day-by-day task lists, and habit tracking.
* **Smart Reminders**: Scheduled notifications with advance alert options (15 min, 30 min, 1 hour before deadlines) using `flutter_local_notifications`.

### 5. 🏅 Certificates & Document Management
* **In-App Document Viewer**: Interactive PDF and image certificate viewer with pan and zoom capabilities.
* **Dual-Mode Document Sharing**: Share certificate files directly as PDF attachments or broadcast pre-formatted achievement cards to WhatsApp and other social apps.
* **Persistent Document Storage**: Uploaded certificates and PDFs are securely saved to device app storage with offline access.

### 6. 🚀 Project Portfolio & GitHub Repository Sync
* **Full Project Showcase**: Record short taglines, architecture notes, key features, problems solved, and lessons learned.
* **GitHub Integration**: Caches public repositories, stargazers, forks, commit history, and primary languages.
* **Multi-Link Support**: Manage distinct URLs for GitHub repositories, Vercel deployments, Render backends, and live web apps.

### 7. 💼 Comprehensive Placement Preparation
* **Coding (DSA)**: Standard SDE sheets (Arrays, Two Pointers, Trees, Graphs, DP) with problem counters, difficulty tiers, and practice links.
* **Core Computer Science**: Dedicated tracking for DBMS, Operating Systems, Computer Networks, and Object-Oriented Programming (OOP).
* **Aptitude**: Quantitative Aptitude, Logical Reasoning, and Verbal Ability practice logging with accuracy analytics.
* **Interview QA Bank**: Searchable technical and HR questions with structured answer frameworks.
* **Job Application Pipeline**: Visual status pipeline tracking applications from *Applied* to *Online Assessment*, *Interview*, *Selected*, or *Rejected*.

### 8. 📄 ATS Resume Builder
* **Dynamic Data Sync**: Compiles education, technical skills, projects, verified certificates, and achievements into an ATS-compliant layout.
* **One-Click Vector PDF Generation**: Produces crisp, professional multi-page vector PDFs using `pdf` and `printing`.
* **Instant Export & Print**: Built-in PDF preview with native sharing, downloading, and printing capabilities.

### 9. 🎨 Modern Material 3 Themes & High-Contrast Pickers
* **Lavender Light Theme**: Clean `#F5F3FF` canvas with rich purple `#7C3AED` accents, soft lavender `#EDE9FE` cards, and high-contrast typography.
* **Dark Purple Theme**: Developer-focused `#100B16` dark background with `#8B5CF6` highlights.
* **High-Contrast Date & Time Pickers**: Fully customized `DatePickerTheme` and `TimePickerTheme` ensuring clear readability of calendar dates, weekday headers, and clock dials across both themes.

### 10. 🔒 Offline-First Architecture & Data Integrity
* **100% Offline Capability**: Runs completely without internet using local SQLite databases.
* **Atomic Backup & Restore**: One-click JSON backup export and encrypted JSON restore with integrity checksum verification.
* **Optional Cloud Authentication**: Optional Supabase authentication with seamless guest mode fallback.

---

## 🏗️ Technical Architecture & Stack

```
lib/
├── core/
│   ├── config/          # Supabase & app configuration
│   ├── constants/       # AppColors (Lavender light & dark palette)
│   ├── database/        # DatabaseHelper (SQLite migrations & tables)
│   ├── notifications/   # NotificationService (Exact alarms & channels)
│   ├── theme/           # AppTheme (Material 3 with custom picker themes)
│   ├── utils/           # Date formatters, validators, streak calculator, document actions
│   └── widgets/         # CustomCard, search bar, progress bars, empty states
├── features/
│   ├── dashboard/       # Career score, weekly activity card, quick actions
│   ├── skills/          # Technical skills & career roadmaps
│   ├── projects/        # Project portfolio & deployment links
│   ├── tasks/           # Priority task manager & deadline filters
│   ├── placement/       # Coding DSA, Core CS, Aptitude, Interview QA, Applications
│   ├── mock_interview/  # Verbal practice, timer, 3-rubric STAR evaluation
│   ├── notes_planner/   # Study notes & future planner hub
│   ├── portfolio/       # Sharable web portfolio, student card, PDF exporter
│   ├── certificates/    # Certificate management & document viewer
│   ├── resume/          # ATS resume builder & vector PDF compiler
│   └── profile/         # Student profile, settings, backup & restore
├── models/              # Immutable domain data models with serialization
├── repositories/        # Repository pattern isolating SQLite queries
└── services/            # Mock interview AI, resume compiler, GitHub sync, auth
```

### Libraries & Dependencies

| Category | Packages |
| :--- | :--- |
| **Framework & UI** | `flutter`, `flutter_localizations`, Material 3 |
| **Persistence** | `sqflite`, `sqflite_common_ffi_web`, `shared_preferences`, `path` |
| **File Handling** | `file_picker`, `path_provider`, `image_picker` |
| **PDF & Printing** | `pdf`, `printing` |
| **Speech & Audio** | `speech_to_text` |
| **Visual Analytics**| `fl_chart` |
| **Notifications** | `flutter_local_notifications`, `timezone` |
| **Networking & Auth**| `http`, `url_launcher`, `supabase_flutter`, `cryptography` |

---

## 🚀 Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.19.0`)
* [Dart SDK](https://dart.dev/get-dart) (`>= 3.3.0`)
* Android Studio / VS Code with Flutter extension
* Java 17+ or Java 21 (for Android builds)

### 1. Clone the Repository
```bash
git clone https://github.com/Naresh63-hub/SkillTrack.git
cd SkillTrack
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run Code Analysis
```bash
flutter analyze --no-pub
```
*Zero warnings and zero errors reported.*

### 4. Execute the Automated Test Suite
```bash
flutter test
```
*All 119 unit and widget tests pass.*

### 5. Run the Application
* **Android**:
  ```bash
  flutter run -d android
  ```
* **Web**:
  ```bash
  flutter run -d chrome
  ```
* **Build Android APK**:
  ```bash
  flutter build apk --release
  ```
* **Build Web Bundle**:
  ```bash
  flutter build web --release
  ```

---

## 🧪 Testing & Quality Assurance

SkillTrack maintains an automated test suite covering unit logic, SQLite repository operations, and widget interactions:

```
test/
├── database/
│   └── database_test.dart               # In-memory SQLite CRUD tests
├── unit/
│   ├── ai_modules_test.dart             # Roadmaps & GitHub model tests
│   ├── app_install_test.dart            # Download & install link tests
│   ├── mock_interview_test.dart         # STAR rubrics & question grading tests
│   ├── modern_ui_and_backup_test.dart   # Backup encryption & checksum tests
│   ├── notification_service_test.dart   # Reminder scheduling & channel tests
│   ├── portfolio_test.dart              # Slug generation & PDF export tests
│   ├── progress_calculator_test.dart    # Preparation score formula tests
│   ├── roadmap_service_test.dart        # Roadmap node serialization tests
│   ├── streak_calculator_test.dart      # Daily streak calculation tests
│   ├── supabase_auth_test.dart          # Guest mode & auth service tests
│   ├── task_filtering_test.dart         # Today/Upcoming/Overdue task tests
│   └── validators_test.dart             # Input validation tests
└── widget/
    ├── app_install_widget_test.dart     # Download dialog widget tests
    ├── date_time_picker_theme_test.dart # High-contrast date & time picker tests
    ├── notes_planner_widget_test.dart   # Notes and study planner tests
    ├── portfolio_widget_test.dart       # Web portfolio & student card tests
    ├── roadmap_widget_test.dart         # Career roadmaps screen tests
    ├── skills_widget_test.dart          # Skill progress bar tests
    ├── tasks_widget_test.dart           # Task filtering & search bar tests
    └── weekly_plans_widget_test.dart    # Weekly schedule & activity card tests
```

---

## 📱 Deep Linking & Web Routing

| URL Pattern | Behavior |
| :--- | :--- |
| `https://skill-track-ashy.vercel.app/#/p/{username}` | Opens student's public read-only portfolio & student card |
| `https://skill-track-ashy.vercel.app/p/{username}` | Path-routed public student card |
| `io.supabase.skilltrack://login-callback/` | Deep link callback for Supabase OAuth login |

---

## 📄 License
Developed for student career development, academic curricula, and technical placement preparation.
Distributed under the [MIT License](LICENSE).

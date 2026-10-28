# SkillTrack — Student Skills & Placement Tracker

> **Build Skills. Track Progress. Get Placement Ready.**

SkillTrack is a complete, production-quality, offline-first personal career-development Android application designed for college students preparing for technical placements, internships, and skill evaluations.

---

## 🎯 Project Objective

SkillTrack answers five fundamental student career questions:
1. **What skills am I learning?** (Technical skill taxonomy across 12 categories, proficiency levels, and milestone tracking).
2. **Which certifications have I earned?** (Credential verification links, issuing bodies, and persistent PDF/image certificate storage).
3. **What projects have I built?** (Portfolio showcase with tech stack chips, problem-solving reflections, and GitHub/demo launchers).
4. **What should I accomplish today?** (Priority-based task manager with overdue alerts and daily/weekly habit counters).
5. **How prepared am I for placements?** (Dedicated preparation tracks for Coding/DSA, Core CS subjects, Aptitude, Interview QA, and Job Application pipeline).

---

## 🎨 Visual Identity & Theme

SkillTrack utilizes a developer-focused dark purple palette crafted with Flutter Material 3:

| Color Component | Hex Code | Purpose |
| :--- | :--- | :--- |
| **Main Background** | `#10091F` | Deep dark purple canvas |
| **Secondary Background** | `#170D35` | App bars, dialogs, and navigation shell |
| **Card Background** | `#21133F` | Rounded feature cards and list tiles |
| **Elevated Surface** | `#2E1065` | Progress accents and prominent banners |
| **Primary Accent** | `#8B5CF6` | Primary buttons and key highlights |
| **Bright Accent** | `#A855F7` | Progress indicators, sliders, and active chips |
| **Secondary Accent** | `#A78BFA` | Subtitles, links, and secondary badges |
| **Primary Text** | `#FFFFFF` | Readable high-contrast typography |
| **Secondary Text** | `#D4CBEA` | Explanatory descriptions and metadata |
| **Muted Text** | `#A69ABD` | Timestamps, placeholders, and subtle hints |

---

## 🛠️ Architecture & Tech Stack

SkillTrack strictly enforces an **offline-first local architecture** with **zero external cloud backend dependencies**:

- **Framework**: [Flutter](https://flutter.dev) (Material 3)
- **Language**: [Dart](https://dart.dev)
- **Structured Database**: `sqflite` (SQLite database with 11 relational tables, schema migrations, and indexed queries)
- **Settings & Preferences**: `shared_preferences`
- **File & Path Management**: `path_provider`, `file_picker` (documents copied to app-managed persistent storage)
- **Visual Analytics**: `fl_chart` (pie/donut task distribution, domain comparison bar charts)
- **Document Compilation**: `pdf` and `printing` (ATS-compliant resume compiler and interactive PDF viewer)
- **Reminders**: `flutter_local_notifications` (scheduled deadline alerts)
- **External Launchers**: `url_launcher` (verified GitHub repositories and job portals)

---

## 📱 Core Modules

### 1. Home Dashboard
- Dynamic Career Preparation Score (weighted average formula).
- 6 key metrics overview: Skills count, Certifications count, Projects count, Pending tasks, Completed tasks, Placement readiness rate.
- Quick action shortcuts (Add Skill, Add Certificate, Add Project, Add Task, Placement Prep, Build Resume).
- Upcoming deadlines with overdue alerts.
- Recently updated portfolio projects.

### 2. Technical Skills
- Categories: Programming Languages, Web, Mobile, Frameworks, Databases, DSA, Core CS, AI/ML, Developer Tools, Cloud/DevOps, Cybersecurity, Other.
- Proficiency levels: Beginner, Intermediate, Advanced, Expert.
- Independent progress slider (0% to 100%).
- Milestone target completion dates with automated overdue calculation.
- External documentation links and concept notes.

### 3. Certification Management
- Chronological credential repository.
- File attachment handling for certificate PDFs and images (copied into application document storage).
- Credential ID recording and online verification URL launcher.
- Categorization by domain and issuing body.

### 4. Project Portfolio
- Status management: *Planned*, *In Progress*, *Completed*, *On Hold*.
- Multi-technology tag classification.
- Structured project details: Short tagline, detailed architecture, key features bullet points, problems solved, lessons learned.
- GitHub repository and live demonstration links.

### 5. Tasks & Learning Goals
- Priority levels: *High*, *Medium*, *Low*.
- Tabbed filters: *All*, *Today*, *Upcoming*, *Overdue*, *Completed*.
- Quick completion toggle (saves completion timestamp).
- Daily & weekly learning targets with increment counters (e.g., "Solve 5 DSA problems").

### 6. Placement Preparation
- **Coding (DSA)**: 11 predefined topics (Arrays, Trees, DP, Graphs, etc.) + custom topics, solved/attempted problem counters, difficulty tags, and practice links.
- **Core Computer Science**: DBMS, OS, Computer Networks, OOP, Software Engineering, Architecture, and SQL notes.
- **Aptitude**: Quantitative Aptitude, Logical Reasoning, and Verbal Ability practice drill logging with accuracy tracking.
- **Interview QA**: Comprehensive question bank with structured STAR answers across Technical and HR categories.
- **Applications Pipeline**: Company tracking, role, application status (*Applied*, *Assessment*, *Interview*, *Selected*, *Rejected*), deadlines, and upcoming interview dates.

### 7. ATS Resume Builder
- Pulls live data from profile, education, skills, projects, certifications, and achievements.
- Editable fields prior to generation.
- One-click compilation to an ATS-friendly, multi-page vector PDF.
- Integrated preview, export, print, and share sheet.

### 8. Analytics & Performance
- Powered by `fl_chart`.
- Task completion donut chart.
- Placement preparation pillar comparisons.
- Project status distribution.
- Top skills mastery indicators.

### 9. Profile & Settings
- Comprehensive student profile fields (Degree, Branch, Semester, College, Links).
- Single-click **"Load Comprehensive Demo Data"** for college evaluations and presentations.
- **JSON Data Backup Export** and **Atomic JSON Restore**.
- Complete local database reset option.

---

## 🚀 Setup & Execution Guide

### Prerequisites
- Flutter SDK (version 3.19.0 or higher)
- Android SDK (API 34) and Java 17+ or Java 21

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Format Code
```bash
dart format .
```

### 3. Run Static Code Analysis
```bash
flutter analyze
```

### 4. Execute Automated Test Suite
```bash
flutter test
```

### 5. Build Debug APK
```bash
flutter build apk --debug
```
Output path: `build/app/outputs/flutter-apk/app-debug.apk`

---

## 📊 Verification & Test Results

SkillTrack includes automated tests verifying calculations, database operations, and widget rendering:

- **Unit Tests**:
  - `progress_calculator_test.dart`: Formula validation, edge cases, weighting.
  - `validators_test.dart`: URL, email, progress ranges, required strings.
  - `models_test.dart`: Serialization, copyWith, overdue date logic.
  - `task_filtering_test.dart`: Today, overdue, upcoming categorization.
- **Database Tests**:
  - `database_test.dart`: In-memory SQLite CRUD for skills, projects, tasks, certificates.
- **Widget Tests**:
  - `dashboard_widget_test.dart`: Score ring, metrics grid, quick actions.
  - `skills_widget_test.dart`: Progress bars, empty states, custom card taps.
  - `tasks_widget_test.dart`: Search bar input, section headers.

---

## 📄 License
Created for academic curriculum and portfolio submission.

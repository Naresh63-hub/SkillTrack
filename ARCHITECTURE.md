# SkillTrack — System Architecture & Database Specification

This document details the software architecture, design patterns, SQLite relational schema, and calculation formulas of **SkillTrack**.

---

## 🏛️ 1. Architecture Overview

SkillTrack implements a **Layered Local-First Architecture** ensuring complete decoupling between presentation (UI widgets), business logic, data models, and persistence.

```
lib/
├── main.dart                      # Application initialization & entrypoint
├── app.dart                       # Material 3 Theme setup & 5-tab IndexedStack shell
│
├── core/                          # Cross-cutting foundational modules
│   ├── constants/                 # Theme color palette, static strings, categories
│   ├── theme/                     # Material 3 ThemeData definition
│   ├── database/                  # SQLite singleton, migrations, & sample data
│   ├── notifications/             # Local notifications service & scheduling
│   ├── utils/                     # Validators, date formatting, progress formulas, file utils
│   └── widgets/                   # Reusable UI widgets (cards, progress bars, empty states)
│
├── models/                        # Domain entities with serialization & domain logic
│   ├── student_profile.dart
│   ├── skill.dart
│   ├── certificate.dart
│   ├── project.dart
│   ├── task_model.dart
│   ├── learning_goal.dart
│   ├── placement_topic.dart
│   ├── interview_question.dart
│   ├── job_application.dart
│   ├── education.dart
│   └── achievement.dart
│
├── repositories/                  # Data access layer abstracting SQLite queries
│   ├── profile_repository.dart
│   ├── skills_repository.dart
│   ├── certificates_repository.dart
│   ├── projects_repository.dart
│   ├── tasks_repository.dart
│   └── placement_repository.dart
│
├── services/                      # Business services
│   ├── resume_service.dart        # PDF document builder & ATS formatting
│   └── export_import_service.dart # Atomic JSON backup export & restore
│
└── features/                      # Domain feature modules (Screens + Widgets)
    ├── dashboard/                 # Overview metrics, score ring, quick actions
    ├── skills/                    # Skill management, category filters, progress sliders
    ├── certificates/              # Credential storage, file preview, verification links
    ├── projects/                  # Portfolio cards, tech tags, reflections, links
    ├── tasks/                     # Task planner, learning goals, priority scheduling
    ├── placement/                 # Coding DSA, Core CS, Aptitude, Interview QA, Applications
    ├── resume/                    # Resume customization & interactive PDF preview
    ├── analytics/                 # fl_chart analytics visualizations
    └── profile/                   # Student profile, JSON backups, demo data loader
```

---

## 🗄️ 2. SQLite Database Schema

The database `skilltrack_app.db` contains 11 normalized tables with foreign keys and indexes:

```sql
-- 1. student_profile
CREATE TABLE student_profile (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  city TEXT,
  college TEXT,
  degree TEXT,
  branch TEXT,
  current_semester TEXT,
  graduation_year TEXT,
  target_job_role TEXT,
  github_url TEXT,
  linkedin_url TEXT,
  portfolio_url TEXT,
  bio TEXT,
  updated_at TEXT NOT NULL
);

-- 2. skills
CREATE TABLE skills (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  proficiency_level TEXT NOT NULL,
  progress_percentage REAL NOT NULL DEFAULT 0.0,
  date_started TEXT,
  target_completion_date TEXT,
  learning_resource_url TEXT,
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE INDEX idx_skills_category ON skills (category);
CREATE INDEX idx_skills_progress ON skills (progress_percentage);

-- 3. certificates
CREATE TABLE certificates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  issuing_organization TEXT NOT NULL,
  category TEXT NOT NULL,
  completion_date TEXT NOT NULL,
  expiration_date TEXT,
  credential_id TEXT,
  verification_url TEXT,
  description TEXT,
  local_file_path TEXT,
  preview_image_path TEXT,
  created_at TEXT NOT NULL
);

-- 4. projects
CREATE TABLE projects (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  short_description TEXT NOT NULL,
  detailed_description TEXT,
  category TEXT NOT NULL,
  technologies TEXT NOT NULL,
  status TEXT NOT NULL,
  start_date TEXT,
  completion_date TEXT,
  github_url TEXT,
  live_demo_url TEXT,
  image_path TEXT,
  key_features TEXT,
  problems_solved TEXT,
  what_learned TEXT,
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE INDEX idx_projects_status ON projects (status);

-- 5. tasks
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  priority TEXT NOT NULL,
  creation_date TEXT NOT NULL,
  due_date TEXT NOT NULL,
  is_completed INTEGER NOT NULL DEFAULT 0,
  completed_at TEXT,
  reminder_date_time TEXT,
  related_skill_id INTEGER,
  related_project_id INTEGER,
  FOREIGN KEY (related_skill_id) REFERENCES skills (id) ON DELETE SET NULL,
  FOREIGN KEY (related_project_id) REFERENCES projects (id) ON DELETE SET NULL
);
CREATE INDEX idx_tasks_due_date ON tasks (due_date);
CREATE INDEX idx_tasks_is_completed ON tasks (is_completed);

-- 6. learning_goals
CREATE TABLE learning_goals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  goal_type TEXT NOT NULL,
  target_count INTEGER NOT NULL DEFAULT 1,
  current_count INTEGER NOT NULL DEFAULT 0,
  is_completed INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  target_date TEXT
);

-- 7. placement_topics
CREATE TABLE placement_topics (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  track TEXT NOT NULL,
  topic_name TEXT NOT NULL,
  category TEXT,
  problems_solved INTEGER NOT NULL DEFAULT 0,
  problems_attempted INTEGER NOT NULL DEFAULT 0,
  practice_links TEXT,
  notes TEXT,
  difficulty_level TEXT NOT NULL DEFAULT 'Medium',
  completion_status TEXT NOT NULL DEFAULT 'Not Started',
  updated_at TEXT NOT NULL
);
CREATE INDEX idx_placement_track ON placement_topics (track);
CREATE INDEX idx_placement_status ON placement_topics (completion_status);

-- 8. interview_questions
CREATE TABLE interview_questions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category TEXT NOT NULL,
  question TEXT NOT NULL,
  answer TEXT,
  status TEXT NOT NULL DEFAULT 'Not Started',
  updated_at TEXT NOT NULL
);
CREATE INDEX idx_interview_status ON interview_questions (status);

-- 9. job_applications
CREATE TABLE job_applications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  company_name TEXT NOT NULL,
  role TEXT NOT NULL,
  application_date TEXT NOT NULL,
  application_deadline TEXT,
  status TEXT NOT NULL DEFAULT 'Applied',
  job_description_url TEXT,
  required_skills TEXT,
  interview_date TEXT,
  notes TEXT,
  updated_at TEXT NOT NULL
);
CREATE INDEX idx_job_status ON job_applications (status);

-- 10. education
CREATE TABLE education (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  institution TEXT NOT NULL,
  degree TEXT NOT NULL,
  field_of_study TEXT NOT NULL,
  start_year TEXT NOT NULL,
  end_year TEXT NOT NULL,
  grade_or_cgpa TEXT,
  created_at TEXT NOT NULL
);

-- 11. achievements
CREATE TABLE achievements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT,
  date_achieved TEXT,
  created_at TEXT NOT NULL
);
```

---

## 📐 3. Progress Calculation Formulas

### Overall Career Preparation Score
The overall score is an equally weighted (25% each) aggregation of four core pillars:

$$\text{Career Readiness Score} = 0.25 \times S + 0.25 \times P + 0.25 \times T + 0.25 \times L$$

Where:
1. **$S$ (Skills Score)**:
   $$S = \frac{1}{N_{\text{skills}}} \sum_{i=1}^{N_{\text{skills}}} \text{progressPercentage}_i$$
   *(0.0% if $N_{\text{skills}} = 0$)*

2. **$P$ (Projects Score)**:
   Weighted completion score:
   - Completed: 100.0%
   - In Progress: 50.0%
   - On Hold: 25.0%
   - Planned: 10.0%
   $$P = \frac{\sum \text{weight}(\text{status}_i)}{N_{\text{projects}}}$$

3. **$T$ (Tasks Score)**:
   $$T = \frac{N_{\text{completed}}}{N_{\text{total tasks}}} \times 100.0$$

4. **$L$ (Placement Preparation Score)**:
   Arithmetic mean of four domain tracks:
   $$L = \frac{C_{\text{coding}} + C_{\text{core\_cs}} + C_{\text{aptitude}} + C_{\text{interview}}}{4}$$

---

## 🔒 4. File Safety & Privacy Model
- **Local Application Documents**: Certificate PDFs and images picked via `file_picker` are copied to `getApplicationDocumentsDirectory()/certificates/`. This ensures files survive Android cache purges.
- **Atomic Database Backup**: Export serializes all tables to clean formatted JSON. Import runs inside an atomic `db.transaction()` to prevent partial data corruption.
- **Zero Cloud Dependence**: Operates completely in airplane mode without network permissions for core storage.

# PulseTrack: Mobile Project & SLA Task Tracker

> **BSE Mobile Application Development (Formative Assignment 1)**  
> **Cohort 3 · Group 14**  
> **Target Platform:** Android (Flutter 3.x / Dart)  
> **Core Architecture:** SQLite (`sqflite`), Provider (`ChangeNotifier`), Pure Dart Domain Logic  

---

## 1. Quick Submission Directory

* **GitHub Repository:** [https://github.com/RobertNiyonkuru98/pulsetrack_14](https://github.com/RobertNiyonkuru98/pulsetrack_14)
* **Figma UI/UX Specification:** [PulseTrack 14 UI Kit](https://www.figma.com/design/BSZEuY95h2EebFMCprPVBY/PulseTrack_14?node-id=0-1&t=anfeM8bhKZtn3kw9-1)
* **Live Team Contribution Tracker:** [Group 14 Contribution Spreadsheet](https://docs.google.com/spreadsheets/d/1RouF3blnE4xgItQrqiC9bQpY1jUQK319lSEOJKKXtWU/edit?usp=sharing)
* **Recorded Video Demonstration:** [YouTube: PulseTrack Group 14 Walkthrough](https://youtu.be/hbqLiFWDFPQ)

---

## 2. Executive Product Overview

Standard task management apps operate as static timers. A user records a task, selects a calendar date, and the software remains inactive until the timestamp expires and turns red. Flagging a work item after the deadline has elapsed offers zero operational value to software teams.

PulseTrack functions as an active warning monitor for project milestones. It calculates the total allocated execution window, tracks elapsed time, and evaluates priority weighting. If half the allotted time window for a critical task has expired while work remains pending, PulseTrack immediately classifies the task as **At Risk**. The project lead inspects a centralized dashboard and identifies delivery bottlenecks before deadlines fail.

---

## 3. Application Architecture & File Layout

The codebase strictly decouples user interface rendering from persistent storage and business calculations:

```text
lib/
├── data/
│   ├── models/         # Pure Dart data entities: Task, Member, Activity, SlaStatus, SlaSettings
│   ├── repositories/   # SQLite query execution, relational joins, entity mapping
│   ├── db_helper.dart  # SQLite schema initialization, table indexes, version migrations
│   └── seed_data.dart  # Initial development dataset for demonstration
├── logic/
│   ├── sla_engine.dart # Pure Dart mathematical SLA rules and threshold checks
│   └── health_score.dart # Weighted project health score aggregation (0-100%)
├── screens/            # 10 production application screens
├── state/
│   └── app_state.dart  # Central ChangeNotifier store driving UI reactivity
├── theme/
│   ├── app_colors.dart # Centralized design tokens matching Figma specification
│   └── app_theme.dart  # Typography scales, button definitions, card elevations
└── widgets/            # Reusable components: TaskTile, SlaBadge, KpiCard, AppBottomNav
```

---

## 4. Screen Delivery Mapping

The assignment specification requires at least 6 core screens covering the primary user journey. Group 14 designed and built 10 functional screens to deliver a complete product workflow:

| Screen Number | Screen Name | Core User Journey Mapping | Primary Technical Implementation |
|---|---|---|---|
| **1** | **Sign In / User Selection** | Core Requirement: *Sign In / User Selection* | One-tap persona switching, credential validation, session storage in `SharedPreferences` |
| **2** | **Project Dashboard** | Core Requirement: *Project Dashboard* | Real-time SLA counters, Attention Queue, Project Health Gauge ring |
| **3** | **Task Feed & Explorer** | Core Requirement: *Task List* | Multi-state filter chips (All, On Track, At Risk, Overdue), keyword search, date sorting |
| **4** | **Task Detail View** | Core Requirement: *Task Details* | SLA breakdown card, dependency notes, inline status updates |
| **5** | **Create & Edit Task** | Core Requirement: *Create/Edit Task* | Form validation, date picker bounds checks, priority selector chips |
| **6** | **Team Directory** | Core Requirement: *Team Members/Profile* | Workload distribution metrics, team capacity status, member cards |
| **7** | **Member Profile Detail** | Supporting Product Screen | Individual delivery history, member-specific task assignment filter |
| **8** | **Application Settings** | Supporting Product Screen | User preference controls, notification switches, account exit action |
| **9** | **Sprint Analytics & Insights** | Supporting Product Screen | SQL aggregated task distribution, delivery velocity indicators |
| **10** | **Interactive SLA Rules** | Supporting Product Screen | Real-time threshold adjustment slider updating badges globally |

---

## 5. Mathematical SLA Engine & Project Health Logic

PulseTrack evaluates task urgency using deterministic, priority-weighted algorithms executed in `lib/logic/sla_engine.dart`.

### SLA State Machine
Every task is assigned exactly one of four operational states:
1. **Completed:** If task completion flag is true (`status == TaskStatus.completed`). Completed tasks remain green regardless of timestamps.
2. **At Risk (Blocker Escalation):** If a task is flagged as blocked (`status == TaskStatus.blocked`), it escalates directly to At Risk because blocked work cannot advance.
3. **Overdue:** If current system time surpasses task deadline (`now > dueDate`).
4. **At Risk (Imminent Deadline Buffer):** If remaining time is less than or equal to 24 hours, the system applies a hard safety buffer.
5. **At Risk (Priority Decay):** If remaining time percentage falls below the threshold configured for that priority class.
6. **On Track:** Default state when time elapsed remains within safe operational limits.

### Time Remaining Formula
$$\text{Remaining Percentage} = \frac{\text{dueDate} - \text{now}}{\text{dueDate} - \text{createdAt}}$$

### Priority Decay Thresholds
Higher priority items trigger risk warnings earlier in their lifecycle:
* **Critical Priority:** Escalates to At Risk when remaining time drops below **50%**.
* **High Priority:** Escalates to At Risk when remaining time drops below **40%**.
* **Medium Priority:** Escalates to At Risk when remaining time drops below **30%**.
* **Low Priority:** Escalates to At Risk when remaining time drops below **20%**.

### Project Health Score Formula
The dashboard ring gauge represents aggregate project health on a 0 to 100 scale:
$$\text{Health Score} = 100 \times \left( \frac{\sum_{i=1}^{N} W(T_i)}{N} \right)$$
* $\text{Weight for On Track or Completed } [W] = 1.0$
* $\text{Weight for At Risk } [W] = 0.5$
* $\text{Weight for Overdue } [W] = 0.0$

---

## 6. Technical Report: Engineering Challenges & Applied Solutions

### Problem 1: Decoupling SLA Mathematical Logic from Widget Rendering Cycles
* **The Challenge:** Computing remaining time ratios, date differences, and status weights directly inside widget `build()` methods caused frame drops during fast list scrolling on mobile devices.
* **The Solution:** We extracted all calculation rules into a standalone, stateless Dart class (`SlaEngine`). Statuses are evaluated once during data hydration and state transitions. The UI simply consumes pre-computed enums, keeping scroll performance pinned at 60 FPS.

### Problem 2: Relational Data Persistence vs Key-Value Storage
* **The Challenge:** Storing all application tasks as a single serialized JSON string inside `SharedPreferences` created severe performance bottlenecks when running dashboard counts, member workload group-bys, and status filtering.
* **The Solution:** We implemented SQLite via `sqflite` with indexed tables for `tasks`, `members`, and `activities`. Sorting and filtering execute directly inside SQLite B-trees before results reach the Dart runtime. `SharedPreferences` is reserved exclusively for the active user session ID string (`current_user_id`).

### Problem 3: Multi-Screen State Reactivity Without Prop-Drilling
* **The Challenge:** Adjusting threshold percentages on the Live SLA Rules screen required immediate visual badge updates across the Dashboard, Task List, and Detail views without rebuilding unrelated components.
* **The Solution:** We implemented the Provider package backed by an `AppState` class extending `ChangeNotifier`. UI screens subscribe to specific state slices via `context.watch<AppState>()`, while user mutations trigger `notifyListeners()`, repainting only the dependent badge widgets.

### Problem 4: Narrow Viewport Layout Overflows & Tap Target Constraints
* **The Challenge:** On narrow mobile displays (360pt width), the Task Details screen suffered layout overflows (exceeding horizontal bounds by up to 87px) because metadata tiles used unconstrained `Row` children alongside minimum 48px `PopupMenuButton` tap boundaries.
* **The Solution:** We wrapped text nodes in `Flexible` widgets with `TextOverflow.ellipsis` and replaced default icon wrappers with custom shrink-wrapped `InkWell` components. We introduced automated widget test cases driving 360pt and 412pt viewports to catch overflow regressions.

### Problem 5: Git Branch Collisions & Style Token Standardization
* **The Challenge:** Parallel feature development led to style divergence where individual team members hardcoded hex values (`#1D3B8B`, `#3B82F6`) directly inside screen files rather than referencing centralized theme definitions.
* **The Solution:** We refactored all interface code to consume a single design token file (`lib/theme/app_colors.dart`). We resolved merge divergences on `main` by standardizing all avatar and border indicators against `AppColors.primary`.

---

## 7. AI Usage Declaration & Reflection Matrix

In compliance with academic integrity guidelines, Group 14 explicitly declares all generative AI tool usage during development:

| Development Area | AI Assistance Utilized | Manual Human Engineering & Verification |
|---|---|---|
| **Database Setup** | Initial SQLite table creation queries and CRUD boilerplate patterns generated with ChatGPT | Designed relational foreign keys, cascade deletes, schema indexes, and entity data models |
| **Date Calculations** | Syntax validation for Dart `DateTime.difference()` using Claude | Designed priority percentage thresholds, safety cushion rules, and unit test suites |
| **Layout Troubleshooting** | Root-cause analysis of yellow overflow warnings using GitHub Copilot | Implemented `Flexible`, `Expanded`, and `SingleChildScrollView` layout hierarchies |
| **Demonstration Dataset** | Generated placeholder strings for task names and task descriptions | Balanced task timestamps manually to guarantee all 4 SLA states appear during testing |

### Explicit Verification Boundaries
* AI tools did not architect the state management flow or define database relationships.
* AI tools did not write the core grading report or design user journey flows.
* Every code snippet suggested by AI assistants was analyzed, modified to match project coding standards, and verified on an Android emulator prior to commit.

---

## 8. Team Ownership & Git Collaboration Structure

To ensure structured collaboration, work was distributed across individual feature branches before integration into `main`:

| Team Member | Official Role | Direct Code Responsibilities | Assigned Git Branch |
|---|---|---|---|
| **Robert Tony Mitali Niyonkuru** (`r.niyonkuru@alustudent.com`) | Lead System Architect & Core Engine Specialist | Base application skeleton, SQLite persistence layer (`db_helper.dart`), SLA Engine (`sla_engine.dart`), Project Health Score, Dashboard, Insights screen, Unit tests | `feat/robert-skeleton` |
| **Olowoyo Erioluwa Gideon** (`e.olowoyo@alustudent.com`) | Mobile Frontend Engineer | Primary Task Journey: `task_list_screen.dart`, `task_details_screen.dart`, `task_form_screen.dart`, `task_tile.dart`, Form validation test suite, Figma screen alignment | `feature/gideon-tasks-ui` |
| **Admire Kudakwashe Chagaresango** (`a.chagaresa@alustudent.com`) | Product Designer & Supporting Flows Engineer | Supporting User Journey: `sign_in_screen.dart`, `team_members_screen.dart`, `member_detail_screen.dart`, `profile_screen.dart`, `activity_log_screen.dart`, UI badges | `admire_tasks-ui` |

---

## 9. Setup, Execution & Testing Guide

### Prerequisites
* Flutter SDK (Version 3.19.0 or higher)
* Dart SDK (Version 3.3.0 or higher)
* Android Studio / VS Code with Flutter extension
* Active Android Emulator or physical Android device connected via ADB *(Notice: Per course rubric, web browser evaluation is invalid)*

### Terminal Commands
```bash
# 1. Clone repository
git clone https://github.com/RobertNiyonkuru98/pulsetrack_14.git

# 2. Navigate to project root
cd pulsetrack_14

# 3. Fetch dependencies
flutter pub get

# 4. Execute test suite
flutter test

# 5. Launch application on target device
flutter run
```

### Automated Test Verification
The project includes automated test coverage validating business logic and form constraints:
* `test/sla_engine_test.dart`: Validates mathematical ratio decay, safety buffer escalation, and blocker overrides.
* `test/health_score_test.dart`: Validates status weight formulas across multiple task combinations.
* `test/form_validation_test.dart`: Validates that empty task titles and invalid inputs trigger onscreen form error indicators.

---

## 10. References & Technical Literature

1. **Google LLC.** (2024). *Architecting Flutter apps with state management and Provider*. Flutter Documentation. Available at: [https://docs.flutter.dev/data-and-backend/state-mgmt/simple](https://docs.flutter.dev/data-and-backend/state-mgmt/simple).
2. **SQLite Development Team.** (2023). *Appropriate Uses For SQLite in Mobile Client Architectures*. SQLite Documentation. Available at: [https://www.sqlite.org/whentouse.html](https://www.sqlite.org/whentouse.html).
3. **Tekartik.** (2024). *sqflite: SQLite plugin for Flutter*. Pub.dev. Available at: [https://pub.dev/packages/sqflite](https://pub.dev/packages/sqflite).
4. **Martin, R. C.** (2018). *Clean Architecture: A Craftsman's Guide to Software Structure and Design*. Prentice Hall.
5. **Office of Government Commerce (UK).** (2011). *ITIL Service Design: Service Level Management and SLA Monitoring Frameworks*. The Stationery Office.
6. **Little, J. D. C.** (1961). *A Proof for the Queuing Formula: $L = \lambda W$*. Operations Research, 9(3), 383–387.

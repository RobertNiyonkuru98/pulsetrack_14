# PulseTrack — Mobile Project & SLA Task Tracker

> **BSE Mobile Application Development — Formative Assignment 1**  
> **Cohort 3 · Group 14**  
> **Stack:** Flutter · SQLite (`sqflite`) · Provider · Dart  

---

## 1. What PulseTrack Actually Does (In Plain English)

Most to-do apps are dumb countdown timers. They let you write down a task, give it a due date, and then do nothing until you miss the deadline and the text turns red. By then, it is already too late.

PulseTrack works like a speed camera for team deadlines. It checks how much total time you were given, how much of that time has burned away, and how critical the work is. If half the allotted window is gone on a mission-critical feature and nobody has touched it, PulseTrack flags it as **At Risk** immediately. 

In one screen, any team lead can open the app and see exactly which tasks need help before the deadline breaks.

---

## 2. Core Features & What We Built

We built **10 distinct screens** (the assignment rubric required a minimum of 6):

1. **Sign In & User Selection:** Simple credential validation plus instant one-tap login cards for active team members.
2. **Project Dashboard:** High-level status cards, attention queue, and the dynamic Project Health ring.
3. **Task Feed:** Filterable task list organized with pastel-tinted status cards, live search, and sorting.
4. **Task Details:** Deep-dive view showing handoff instructions, parameters grid, and the transparent SLA breakdown card.
5. **Create & Edit Task Form:** Form with real-time field validation, date pickers, priority segmented buttons, and assignee selectors.
6. **Team Directory:** Overview of all engineers and designers, displaying their current workload and capacity limits.
7. **Member Profile:** Individual breakdown of assigned tasks and personal SLA delivery history.
8. **App Preferences & Settings:** User profile management, alert channel settings, and account sign-out.
9. **Sprint Insights:** Visual bar charts breaking down team delivery velocity, active bottlenecks, and deadline schedules.
10. **Live SLA Rules & Thresholds:** Interactive sliders that let managers tune the "At Risk" percentage and watch badges flip across the app in real time.

---

## 3. The Math Behind the SLA Engine

Every task sits in one of four states: **On Track**, **At Risk**, **Overdue**, or **Completed**.

Instead of guessing, the app calculates status using this exact sequence:

1. If `status == Completed` &rarr; **Completed**
2. If `status == Blocked` &rarr; **At Risk** (blocked work cannot progress, so it escalates immediately)
3. If `now > dueDate` &rarr; **Overdue**
4. If `remainingTime <= 24 hours` &rarr; **At Risk** (hard safety net)
5. If `remainingPercentage <= threshold(priority)` &rarr; **At Risk**
6. Otherwise &rarr; **On Track**

### Priority Thresholds
Higher priority items trigger warnings much earlier in their lifecycle:

* **Critical Tasks:** Warns when remaining time drops below **50%** of the total window.
* **High Priority:** Warns when remaining time drops below **40%**.
* **Medium Priority:** Warns when remaining time drops below **30%**.
* **Low Priority:** Warns when remaining time drops below **20%**.

### The Project Health Score (0–100)
The ring gauge on the dashboard is computed directly from the health of all active tasks:
$$\text{Health Score} = 100 \times \text{Average}(\text{Status Weight})$$
* **Completed / On Track:** Weight = `1.0`
* **At Risk:** Weight = `0.5`
* **Overdue:** Weight = `0.0`

When you complete a task or resolve a blocker, the dashboard ring moves upward immediately.

---

## 4. Technical Architecture & Engineering Decisions

```text
lib/
├── data/
│   ├── models/         # Task, Member, Activity, SlaStatus, SlaSettings
│   ├── repositories/   # SQLite database queries and data mapping
│   ├── db_helper.dart  # Raw SQLite schema and table migrations
│   └── seed_data.dart  # Realistic initial sprint data
├── logic/
│   ├── sla_engine.dart # Pure Dart mathematical SLA calculation
│   └── health_score.dart
├── screens/            # 10 user-facing application screens
├── state/
│   └── app_state.dart  # Provider ChangeNotifier (Central app store)
├── theme/
│   ├── app_colors.dart # Single token file matching Figma specifications
│   └── app_theme.dart  # Typography, card shapes, and theme data
└── widgets/            # Reusable UI components (TaskTile, SlaBadge, KpiCard)
```

### Why SQLite (`sqflite`) Instead of SharedPreferences for Tasks?
Our application handles relational data. Members own tasks, tasks generate activity logs, and the Insights screen runs group-by calculations to show workload. 

Storing tasks in `SharedPreferences` would force us to serialize and deserialize a massive JSON array every time a screen opened, followed by sorting the entire array in Dart memory. SQLite lets us run indexed queries, sort by date directly in the engine, and scale without stuttering.

### Why SharedPreferences for User Session?
The active signed-in user is a single string (`member_id`). Writing SQL tables for one variable is overkill. We use `SharedPreferences` solely for persisting who is logged in.

### State Management with Provider
We chose `Provider` with a single `AppState` (`ChangeNotifier`). 
* State flows downward: screens call `context.watch<AppState>()` to react to data changes.
* Actions flow upward: widgets invoke methods like `state.saveTask()` or `state.changeTaskStatus()`.
* This eliminates constructor prop-drilling while avoiding the extreme ceremony of Bloc for a short-cycle project.

---

## 5. Team Ownership & Git Collaboration

To prevent merge conflicts during concurrent development, we enforced a strict **one file, one owner** policy. Robert built the base database, models, and router on `main` first. Each member then worked exclusively on their assigned screens in their own feature branch.

| Team Member | Official Role | Assigned Screens & Files | Git Branch |
|---|---|---|---|
| **Robert Tony Mitali Niyonkuru** (`r.niyonkuru@alustudent.com`) | Lead System Architect & Core Engine Specialist | Base skeleton, SQLite helper, SLA engine math, Dashboard, Insights screen, Unit tests | `feat/robert-skeleton` |
| **Olowoyo Erioluwa Gideon** (`e.olowoyo@alustudent.com`) | Mobile Frontend Engineer | Core Task Journey: `task_list_screen.dart`, `task_details_screen.dart`, `task_form_screen.dart`, `task_tile.dart`, Form validation tests, Figma UI overhaul | `feature/gideon-tasks-ui` |
| **Admire Kudakwashe Chagaresango** (`a.chagaresa@alustudent.com`) | Product Designer & Supporting Flows Engineer | `sign_in_screen.dart`, `team_members_screen.dart`, `member_detail_screen.dart`, `profile_screen.dart`, `activity_log_screen.dart`, Seed data, Shared badge widgets | `admire_tasks-ui` |

---

## 6. How to Run the Application

### Prerequisites
* Flutter SDK (3.x or higher)
* Android Studio / VS Code
* An active **Android Emulator** or connected **physical Android/iOS phone** *(Note: The course rubric strictly forbids web browser evaluation)*

### Setup Commands
```bash
# Clone the repository
git clone https://github.com/RobertNiyonkuru98/pulsetrack_14.git

# Enter the directory
cd pulsetrack_14

# Install all package dependencies
flutter pub get

# Run the test suite
flutter test

# Launch the app on your connected device/emulator
flutter run
```

---

## 7. Automated Tests Included

PulseTrack includes automated unit and widget tests to verify business logic and validation:
1. `test/sla_engine_test.dart`: Validates that the SLA engine calculates percentages correctly, escalates blocked tasks, and triggers At-Risk warnings at the exact configured thresholds.
2. `test/health_score_test.dart`: Verifies the weighted health score calculation across different SLA mixes.
3. `test/form_validation_test.dart`: Verifies that the task creation form blocks submission and displays error feedback when required fields are empty.

---

## 8. Graded Deliverables Summary

* **Public Repository:** [GitHub - RobertNiyonkuru98/pulsetrack_14](https://github.com/RobertNiyonkuru98/pulsetrack_14)
* **Figma Design Specification:** [Figma - PulseTrack_14](https://www.figma.com/design/BSZEuY95h2EebFMCprPVBY/PulseTrack_14?node-id=0-1&t=anfeM8bhKZtn3kw9-1)
* **Group Contribution Tracker:** [Google Sheet - Group 14 Contribution Tracker](https://docs.google.com/spreadsheets/d/1RouF3blnE4xgItQrqiC9bQpY1jUQK319lSEOJKKXtWU/edit?usp=sharing)
* **Branch Structure:** Clear individual branches with distributed commit histories across development days.
* **Screens Built:** 10 functional screens matching the Figma specification (`PulseTrack_14`).
* **Persistence Verified:** All data survives closing and restarting the application.

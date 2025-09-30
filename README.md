# 🟡 Komyut  

Komyut is a **mobile application** that modernizes public utility vehicle (PUV) services in Cebu City through secure, efficient, and convenient digital solutions.  

It integrates **cashless payments, automated fare computation, trip tracking, and safety features** to improve commuting for both passengers and drivers.  

---

## 🎯 Main Goals
- **Enhance Commuter Security** → Incident reporting for theft, harassment, or reckless driving.  
- **Guarantee Fair Fare Calculation** → Automated fare computation based on distance, government policies, and discounts.  
- **Enable Cashless Transactions** → Secure in-app wallet for seamless, cash-free payments.  
- **Improve Trip Monitoring** → QR-based trip logging for lost items, ride verification, and safety.  
- **Empower Users with Data** → Access to trip history, payment records, and driver ratings for transparency.  

---

## 📑 Table of Contents
- [Development Workflow](#-development-workflow)  
- [Branching Strategy](#-branching-strategy)  
  - [Branch Naming](#branch-naming)  
  - [Commit Guidelines](#commit-guidelines)  
- [Getting Started](#-getting-started)  
  - [Prerequisites](#prerequisites)  
  - [Setup](#setup)  
- [Local Development](#-local-development)  
  - [Setting Up Environment Variables](#setting-up-environment-variables)  
  - [Running the Local Backend](#running-the-local-backend)  
  - [Running the Frontend App](#running-the-frontend-app)  
- [Database Migrations](#-database-migrations)  
  - [Syncing Your Local Database](#syncing-your-local-database)  
  - [Creating a New Migration](#creating-a-new-migration)  
  - [Committing and Sharing Migrations](#committing-and-sharing-migrations)  
- [Stopping the Local Environment](#-stopping-the-local-environment)  

---

## 🔄 Development Workflow  

We use a **lightweight Gitflow-inspired workflow** to ensure **collaboration, accountability, and professional readiness**.  

1. **Issue Tracking**  
   - Every task/feature/bug must have a GitHub Issue.  
   - Assign issues to yourself before starting work.  

2. **Branching & Development**  
   - Branch from `develop`.  
   - Work on small, focused branches (1 issue = 1 branch).  

3. **Pull Requests (PRs)**  
   - Open PRs into `develop` once work is ready.  
   - At least **1 peer review** is required before merging.  
   - CI checks (formatting, linting, tests if available) must pass.  

4. **Testing & Integration**  
   - Test features locally before creating a PR.  
   - After merging into `develop`, all members should pull and test integration.  
   - Merge `develop` → `main` only when stable and tested.  

---

## 🌱 Branching Strategy  

### Main Branches
- **main** → production-ready, stable code (**protected**)  
- **develop** → staging / active development branch  

### Supporting Branches
- `feature/<lastname>-<short-description>` → new features  
- `fix/<lastname>-<short-description>` → bug fixes  
- `chore/<lastname>-<short-description>` → configs, setup, or maintenance  

---

### Branch Naming  

```bash
git checkout -b feature/<lastname>-<short-description>
````

**Examples:**

* `feature/raboy-landing-page`
* `fix/mactual-navbar-bug`

**Rules:**

* Always use **lowercase**.
* Keep names short and descriptive.
* Use **hyphens (-)** instead of spaces.

---

### Commit Guidelines

Format:

```bash
<prefix>(<scope>): <message> - <name>
```

**Examples:**

* `feat(auth): implement login with Supabase - Raboy`
* `fix(ui): resolve trip logging bug - Lim`
* `docs(readme): update setup instructions - Mactual`

**Rules:**

* Prefix must follow the commit prefix table.
* Use **lowercase** (except for names).
* Keep messages clear and concise.
* Scope is optional but recommended.

#### 📌 Commit Prefixes

| Prefix        | Meaning                                          |
| ------------- | ------------------------------------------------ |
| **feat:**     | A new feature                                    |
| **fix:**      | A bug fix                                        |
| **docs:**     | Documentation only changes                       |
| **style:**    | Code style changes (formatting, no logic change) |
| **refactor:** | Refactoring code (not a fix or feature)          |
| **test:**     | Adding or fixing tests                           |
| **chore:**    | Maintenance tasks (build, deps, configs, etc.)   |

---

## 🚀 Getting Started

### Prerequisites

* [Git](https://git-scm.com/)
* [Docker Desktop](https://www.docker.com/products/docker-desktop)
* [Supabase CLI](https://supabase.com/docs/guides/cli)

### Setup

Clone the repo:

```bash
git clone https://github.com/ShanRaboy11/komyut.git
cd komyut
```

---

## 🛠 Local Development

### Setting Up Environment Variables

```bash
# Windows
copy .env.example .env

# Mac/Linux
cp .env.example .env
```

Update `.env` with your Supabase URL and anon key.

---

### Running the Local Backend

```bash
supabase start
```

This provides API URL + keys → paste them into `.env`.

---

### Running the Frontend App

```bash
flutter pub get
flutter run
```

---

## 🗄 Database Migrations

### Syncing Your Local Database

```bash
supabase db reset
```

### Creating a New Migration

```bash
supabase migration new <descriptive_name>
```

Example:

```bash
supabase migration new create_trips_table
```

Edit the SQL file with schema changes, then reset DB to apply.

---

### Committing and Sharing Migrations

```bash
git add supabase/migrations
git commit -m "feat(db): add trips table - Raboy"
git push origin feature/<lastname>-<short-description>
```

Then open a PR into `develop`.

---

## 🛑 Stopping the Local Environment

```bash
supabase stop
```

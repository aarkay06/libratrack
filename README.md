# LibraTrack

A command-line library management system written in C++17.

LibraTrack handles book cataloguing, member management, loan tracking, fine calculation, search, and reporting. The codebase is deliberately small enough to navigate in a single session, but large enough to feel like a real multi-module project.

---

## Quick Start

**Linux / macOS / WSL:**
```bash
# 1. One-time setup — configures and builds everything
./setup.sh

# 2. After fixing a bug, check your work instantly
./check.sh <issue-number>
```

**Windows (PowerShell):**
```powershell
# 1. One-time setup
.\setup.ps1

# 2. After fixing a bug
.\check.ps1 <issue-number>
```

Examples:
```bash
./check.sh 1    # runs the test for Issue #01
./check.sh 42   # runs the test for Issue #42
```

`check.sh` / `check.ps1` rebuilds your code, runs the associated public test, and prints a clear **PASSED** or **FAILED** result with the exact assertion output so you know what to fix.

Requires CMake ≥ 3.16 and a C++17-capable compiler (GCC 9+, Clang 10+, MSVC 2019+).

---

## Manual Build

```bash
cmake -B build
cmake --build build
./build/libratrack
```

---

## Running All Public Tests at Once

```bash
cd build && ctest --output-on-failure
```

---

## Project Structure

```
include/        Header files for all modules
src/            Implementation files + main.cpp (interactive CLI)
tests/public/   Public test suite (one test per issue)
scripts/        Utility scripts (issue creation, etc.)
data/           Seed CSV data for books and members
```

---

## Contributing / Fixing Issues

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full workflow.

Short version:

1. Browse the open issues and pick one.
2. Create a branch: `git checkout -b fix/issue-NN-short-description`
3. Fix the bug described in the issue.
4. Build and run the public test to verify: `ctest --test-dir build -R IssueNN_Public`
5. Open a pull request with the title `Fix #NN: short description`.

---

## Module Overview

| Module | Files | Responsibility |
|--------|-------|----------------|
| Book | `include/Book.h`, `src/Book.cpp` | Book entity, ISBN validation, availability |
| Member | `include/Member.h`, `src/Member.cpp` | Member entity, loan limits, expiry |
| Loan | `include/Loan.h`, `src/Loan.cpp` | Loan record, due dates, overdue calculation |
| Catalog | `include/Catalog.h`, `src/Catalog.cpp` | Book collection, search, CRUD |
| FineCalculator | `include/FineCalculator.h`, `src/FineCalculator.cpp` | Overdue fine computation |
| ReportGenerator | `include/ReportGenerator.h`, `src/ReportGenerator.cpp` | Summaries and statistics reports |
| LoanManager | `include/LoanManager.h`, `src/LoanManager.cpp` | Checkout / return / renew orchestration |
| MemberManager | `include/MemberManager.h`, `src/MemberManager.cpp` | Member CRUD and queries |
| DateUtils | `include/DateUtils.h`, `src/DateUtils.cpp` | Date parsing, formatting, arithmetic |
| SearchEngine | `include/SearchEngine.h`, `src/SearchEngine.cpp` | Full-text and fuzzy search |
| NotificationService | `include/NotificationService.h`, `src/NotificationService.cpp` | Overdue notices and reminders |
| Statistics | `include/Statistics.h`, `src/Statistics.cpp` | Trend analysis and popularity metrics |

---

## License

MIT

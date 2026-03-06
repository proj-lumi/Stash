# Budget App – Architecture Summary

## Step 1: React UI → Flutter Mapping

### Layout
| React | Flutter |
|-------|--------|
| Root: `flex flex-col h-screen bg-[#D8F8D8] max-w-md mx-auto` | `MaterialApp` → `Scaffold(body: Column)` with `Container(constraints: BoxConstraints(maxWidth: 448))` centered, `DecorationBox` background `#D8F8D8` |
| Main: `flex-1 overflow-y-auto pb-20` | `Expanded(child: SingleChildScrollView)` with `padding: EdgeInsets.only(bottom: 80)` |
| Bottom nav: `fixed bottom-0 h-16` | `BottomNavigationBar` or `NavigationBar` (height 64) |

### Navigation
- **5 tabs:** Transactions, Add, Statistics, Budget, Accounts (bottom nav).
- **Tutorial & Settings:** Full-screen routes; Tutorial hides bottom nav (navigate from app bar or menu).

### Design Tokens (from `theme.css`)
- **Background:** `#D8F8D8` (mint); dark: `#091035`.
- **Foreground:** `#091035`; dark: `#D8F8D8`.
- **Primary:** `#236ABA`; accent/hover: `#1B3FF0`.
- **Secondary / border:** `#559F54`.
- **Destructive:** `#d4183d`.
- **Cards:** White, `borderRadius: 16` (rounded-2xl).
- **Typography:** Base 16; h1 2xl/500, h2 xl/500, h3 lg/500; line height 1.5.
- **Spacing:** Screen padding 16; card 16–24; gaps 8–16; bottom nav 64; content bottom padding 80.

### Components
- **AppBar:** White, border bottom `#559F54`, title foreground color.
- **Cards:** `Card` or `Container` with white bg, `BorderRadius.circular(16)`, padding 16–24.
- **Inputs:** White bg, border `#559F54`, focus ring `#236ABA`.
- **Buttons:** Primary filled `#236ABA`; secondary outline `#559F54`.
- **Charts:** fl_chart for pie (expense by category) and bar (income vs expense by month).

---

## Step 2: Folder Architecture & Data Layer

### Folder Structure

```
lib/
  core/
    theme/           # AppTheme, colors, text styles (from design tokens)
    utils/           # date helpers, formatters, constants
  data/
    models/          # Account, Category, Transaction (Isar collections)
    repositories/    # AccountRepository, CategoryRepository, TransactionRepository
    database/        # Isar init, schema registration
    settings/        # SettingsRepository (shared_preferences)
  features/
    transactions/    # list, add, month filter
    statistics/      # totals, pie chart, bar chart
    budget/          # category budgets, progress bars
    accounts/        # list, add, derived balance
    tutorial/        # static instructions
    settings/        # font size, dark mode, clear data
    shell/           # bottom nav, app shell, selected month state
  main.dart
```

### Data Layer Plan

1. **Isar (3 collections)**
   - **Account:** id, name, type, initialBalance. No stored balance; balance = initialBalance + sum(transactions for this account).
   - **Category:** id, name, monthlyBudget?. Seeded once; no user-created categories.
   - **Transaction:** id, amount, dateTime, type (income|expense|transfer), notes?, transferFee?; IsarLink&lt;Account&gt; account; IsarLink&lt;Category&gt;? category; IsarLink&lt;Account&gt;? relatedAccount. One row per transfer; transferFee counts as expense in stats.

2. **Settings (shared_preferences)**
   - Keys: `fontSize` (double), `colorMode` (string: "light" | "dark").
   - Load before `runApp` so theme uses them (async init or splash).

3. **Repositories**
   - **AccountRepository:** CRUD, get balance (initial + sum transactions).
   - **CategoryRepository:** getAll, update monthlyBudget, seed.
   - **TransactionRepository:** CRUD, stream by month, stats helpers (monthly income/expense by category, etc.).
   - **SettingsRepository:** read/write fontSize, colorMode.

4. **Month Filter**
   - Single selected (year, month) in app state (e.g. Riverpod). All stats, budget progress, and transaction list use it. Filter: `dateTime.year == selectedYear && dateTime.month == selectedMonth`.

5. **Clear Data**
   - One write transaction: delete all transactions, delete all accounts, reseed categories; do not clear shared_preferences.

---

## Implementation Order

1. **Phase 1:** Data models (Isar), database init, repositories, settings.
2. **Phase 2:** Core theme (load settings first), shell (bottom nav, month picker), main.
3. **Phase 3:** Transactions (list + add), then Statistics, Budget, Accounts.
4. **Phase 4:** Tutorial, Settings (font size, dark mode, Clear Data).

# Pantry Manager V5 - Implementation TODO

## Step 1: Core providers (Foundation)
- [x] Create tracking TODO.md
- [x] `lib/providers/pantry_provider.dart` baseline (CRUD, low-stock/expiry, structured ConsumptionRecord, fuzzy ingredient matching, consume/deduct)
- [x] `lib/providers/shopping_provider.dart` (SharedPreferences persistence, sections, generate shopping suggestions, move-to-pantry)
- [x] `lib/providers/recipe_provider.dart` (SharedPreferences persistence, CRUD, flexible ingredient matching, validation helpers)
- [x] `lib/providers/meal_planner_provider.dart` baseline (weekly schedule persistence + cooked/skipped statuses)
- [ ] Upgrade `lib/providers/meal_planner_provider.dart` with cook/consume deduction logic + ingredient insufficiency blocking
- [ ] Upgrade `lib/providers/pantry_provider.dart` with stronger structured deduction sources + batch validation UX helpers (if needed)
- [x] Wire providers in `lib/main.dart`

## Step 2: Shopping + Recipes + Meal Planner UI
- [x] Add shopping list screen with sections + Slidable + quick add + generate suggestions
- [ ] Add shopping item edit (quantity/unit) UI
- [ ] Add recipes screens (list/add/edit/detail)
- [ ] Add meal planner weekly calendar screen (breakfast/lunch/dinner slots)

## Step 3: Dashboard refactor
- [ ] Replace current `HomeScreen` with production-ready dashboard
  - [ ] Summary cards + insights cards (shopping, recipes, planned meals)
  - [ ] Search bar + filter chips
  - [ ] fl_chart charts (category distribution + weekly consumption)
  - [ ] Quick actions + empty states
  - [ ] Strong contrast styling (avoid faint greys)

## Step 4: Polishing + validation UX
- [ ] Recipe-to-pantry validation errors (missing/insufficient ingredients list)
- [ ] Block meal plan assignment if insufficient stock
- [ ] Confirm dialogs before deductions when cooking/consuming
- [ ] Expiry + low-stock screens polished UI
- [ ] Item detail screen with history sections

## Step 5: Verification
- [ ] `flutter run`
- [ ] Manual QA: consume/discard history, no negative stock, SharedPreferences backward compatibility
- [ ] Manual QA: recipe matching & meal planner validation


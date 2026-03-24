# Analysis: AI-Driven Development Improvements

> Based on research in `research/flutter-mcp-servers.md` and findings from practitioners using Claude Code + Flutter.

This document proposes concrete changes to the repository to make it optimally suited for AI-assisted development — specifically Claude Code, and the Dart/Flutter MCP ecosystem.

---

## 1. Project Memory: CLAUDE.md

`CLAUDE.md` already exists in the project root. It should be kept updated with:

- Architecture decisions as they're made (state management choice, package selections)
- Preferred package list with rationale (e.g., "Use `fl_chart`, not `charts_flutter`")
- Code style decisions (e.g., "trailing commas on all multi-line widget calls")
- Commands the AI should know (`flutter run -t lib/main_dev.dart`, etc.)
- Patterns to follow and patterns to avoid

**Action:** Update `CLAUDE.md` after each implementation ticket to reflect what was decided.

---

## 2. MCP Server Configuration (.mcp.json)

Add a `.mcp.json` file to the project root. Commit it to git so all contributors (human and AI) get the same server set automatically.

### Immediate Configuration (Works Before Flutter Upgrade)

```json
{
  "mcpServers": {
    "flutter-docs": {
      "command": "npx",
      "args": ["flutter-mcp"]
    }
  }
}
```

`flutter-mcp` provides real-time Flutter/Dart documentation lookup, preventing Claude from generating code with deprecated APIs. Requires only Node.js 16+ — no Flutter SDK version dependency.

### Post-Flutter-Upgrade Configuration (Dart 3.9+ required)

```json
{
  "mcpServers": {
    "dart": {
      "command": "dart",
      "args": ["mcp-server"]
    },
    "flutter-docs": {
      "command": "npx",
      "args": ["flutter-mcp"]
    },
    "flutter-inspector": {
      "command": "/path/to/flutter_inspector_mcp",
      "args": [
        "--dart-vm-host=localhost",
        "--dart-vm-port=8181",
        "--resources",
        "--images"
      ]
    }
  }
}
```

**Note on `flutter-inspector`:** Replace `/path/to/flutter_inspector_mcp` with the actual binary path from `make install` in the `mcp_flutter` repo. This path is machine-specific and should be documented in `CLAUDE.md` rather than hard-coded in `.mcp.json`. Alternatively, commit a wrapper script at `.claude/start-flutter-inspector.sh`.

---

## 3. Claude Code Hooks (.claude/settings.json)

Hooks are shell commands that fire automatically at Claude lifecycle events. They enforce quality gates without requiring the engineer to remember manual steps.

### Recommended Hooks for This Project

**`.claude/settings.json`** (commit to git — applies to all contributors):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "dart format \"$CLAUDE_PROJECT_DIR/lib\" \"$CLAUDE_PROJECT_DIR/test\" --line-length 80 2>/dev/null || true",
            "timeout": 30,
            "statusMessage": "Formatting Dart files..."
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cd \"$CLAUDE_PROJECT_DIR\" && flutter analyze 2>&1 | tail -5",
            "timeout": 120,
            "statusMessage": "Running flutter analyze..."
          }
        ]
      }
    ]
  }
}
```

**What these hooks do:**
- `PostToolUse (Edit|Write)` — runs `dart format` automatically after every file Claude writes or edits. Formatting is never skipped.
- `Stop` — runs `flutter analyze` before Claude finishes responding. Claude sees the output and can fix any issues it introduced before handing control back.

**`.claude/settings.local.json`** (gitignored — personal overrides):

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cd \"$CLAUDE_PROJECT_DIR\" && flutter test --coverage 2>&1 | tail -10",
            "timeout": 300,
            "statusMessage": "Running tests..."
          }
        ]
      }
    ]
  }
}
```

The test hook is personal (slow; not everyone wants it on every stop).

### Hook Reference for Flutter Projects

| Event | Flutter Use Case |
|---|---|
| `PostToolUse (Edit\|Write)` | Auto-format Dart files, auto-fix imports |
| `Stop` | Run `flutter analyze`, run tests, check coverage |
| `PreToolUse (Bash)` | Block `git push --force`, auto-approve `flutter pub get` |
| `SessionStart` | Print active Flutter version, remind about VPN/environment |
| `TaskCompleted` | Post a summary comment on the open PR |

---

## 4. Custom Slash Commands (.claude/commands/)

Custom slash commands let you encode repeatable multi-step workflows as prompts Claude executes on demand.

**Create `.claude/commands/` directory with:**

### `/flutter-check` — Run All Quality Checks

File: `.claude/commands/flutter-check.md`
```markdown
Run the following quality checks on this Flutter project and report any issues:

1. `dart format --output=none --set-exit-if-changed .` — check formatting
2. `flutter analyze --fatal-infos` — static analysis
3. `flutter test` — run the test suite
4. Report: pass/fail for each step, list any specific errors

Fix any issues found before reporting back.
```

### `/add-feature <description>` — Scaffold a New Feature

File: `.claude/commands/add-feature.md`
```markdown
Scaffold a new Flutter feature following the project's architecture (lib/features/).

Steps:
1. Read CLAUDE.md for architecture decisions and naming conventions
2. Plan the feature: domain model, repository method, Riverpod provider, screen widget, tests
3. Show the plan and get approval before writing any code
4. Implement each layer in order: model → repository → provider → UI
5. Write unit tests for the model and provider
6. Run `flutter analyze` to confirm zero warnings
```

### `/upgrade-widget <widget>` — Update a Single Widget to M3

File: `.claude/commands/upgrade-widget.md`
```markdown
Update the specified widget to use Material Design 3 patterns:
- Replace deprecated widgets (FlatButton → TextButton, RaisedButton → FilledButton/ElevatedButton)
- Use Theme.of(context).colorScheme instead of hardcoded colors
- Add const constructors where possible
- Add semantic labels for accessibility
- Run flutter analyze after changes
```

---

## 5. Dev Container for Safe Claude Code Execution

For running Claude Code with `--dangerously-skip-permissions` safely (no approval prompts for every file write), use a Docker dev container.

The `bizz84/claude-code-flutter-devcontainer` template provides:
- Flutter pre-installed in a Docker container
- Firewall rules permitting only Flutter-specific domains (`pub.dev`, `storage.googleapis.com`, `maven.google.com`, etc.)
- `claude --dangerously-skip-permissions` works safely within the container
- `flutter analyze` and `flutter test` work fully

**Source:** https://github.com/bizz84/claude-code-flutter-devcontainer

**Limitation:** `flutter run` (GUI) is not supported — dev container is for headless CI/analysis use cases.

---

## 6. Runtime Introspection Setup (Post Flutter Upgrade)

After the Flutter upgrade, add `mcp_toolkit` to the app for live AI introspection of the running app:

```dart
// lib/main_dev.dart only — not in main_prod.dart
import 'package:mcp_toolkit/mcp_toolkit.dart';
import 'dart:async';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      MCPToolkitBinding.instance
        ..initialize()
        ..initializeFlutterToolkit();
      runApp(const ExpenseTrackerApp());
    },
    (error, stack) {
      MCPToolkitBinding.instance.handleZoneError(error, stack);
    },
  );
}
```

This enables Claude to:
- Take a screenshot of the running app
- Read the widget tree to verify a layout fix worked
- Trigger hot reload after code changes
- Read runtime errors from the running app
- (Optionally) call custom tools you register — e.g., seed the DB with test data

---

## 7. AI-Optimised Development Workflow

### Recommended Session Pattern

1. **Start session** with a specific, scoped goal (e.g., "implement the category filter feature")
2. **Use Plan Mode first** (Shift+Tab twice in Claude Code) for any non-trivial feature. Claude proposes an implementation plan; you review and correct it before code is written. This prevents large amounts of incorrect code.
3. **Work in thin vertical slices**: model → repository → provider → one screen — not "implement the whole feature at once"
4. **Use the `flutter analyze` Stop hook** to catch issues immediately
5. **Commit at logical checkpoints** (after model, after repository, after UI) so each commit is reviewable and the session is resumable if interrupted

### Widget Development Pattern

Prevents widget trees from growing without structure:
1. First prompt: ask for **widget tree outline only** (names + hierarchy, no code)
2. Second prompt: **component responsibility** (what each widget shows/does)
3. Third prompt: **stateless scaffold** with explicit inputs (props, callbacks)
4. Fourth prompt: **styling** in a separate pass

### Plan-First for Architecture Decisions

Before implementing any new layer (repository pattern, Riverpod providers, etc.):
1. Ask Claude to read `CLAUDE.md` and relevant existing code
2. Ask for a written plan with file paths, class names, and method signatures
3. Approve or modify the plan before implementation begins

This keeps architecture consistent with the decisions already in `CLAUDE.md`.

---

## 8. Summary of Changes to Make

| Item | When | File/Location |
|---|---|---|
| Add `.mcp.json` with flutter-docs server | Now | `.mcp.json` |
| Add `.claude/settings.json` with format + analyze hooks | Now | `.claude/settings.json` |
| Add `.claude/settings.local.json` to `.gitignore` | Now | `.gitignore` |
| Add custom slash commands | Now | `.claude/commands/*.md` |
| Update `CLAUDE.md` after each implementation ticket | Ongoing | `CLAUDE.md` |
| Add full MCP stack (dart + flutter-inspector) | After Flutter upgrade | `.mcp.json` |
| Add `mcp_toolkit` to dev entry point | After Flutter upgrade | `lib/main_dev.dart` |
| Add custom MCP tools (seed DB, etc.) | After Flutter upgrade | `lib/main_dev.dart` |

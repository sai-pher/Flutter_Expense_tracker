# Research: Flutter MCP Servers

> Research date: March 2026. Sources: official Flutter/Dart docs, GitHub repositories, pub.dev.

MCP (Model Context Protocol) servers expose tools and resources to AI assistants like Claude Code. Several MCP servers now exist specifically for Dart and Flutter development. This document surveys the production-ready options.

---

## 1. Official Dart/Flutter MCP Server (by the Dart Team at Google)

**Status:** Experimental, officially supported. Introduced with Dart 3.9 / Flutter 3.35 beta.

**What it is:** The first-party MCP server for Flutter and Dart development, maintained by the Dart team at Google. It bridges the Dart SDK toolchain into any MCP-compatible AI client — giving the AI assistant the ability to run the analyzer, manage packages, introspect a running app, and more.

**Requirements:**
- Dart SDK 3.9+ / Flutter 3.35+ (beta channel)
- MCP client supporting stdio transport + Tools + Resources
- For project-scoped calls: client should also support Roots

### Setup for Claude Code

The fastest way — run from inside your Flutter project:

```bash
claude mcp add --transport stdio dart -- dart mcp-server
```

If the client claims Roots support but doesn't set them properly:
```bash
claude mcp add --transport stdio dart -- dart mcp-server --force-roots-fallback
```

Via `.mcp.json` in the project root (committed to git for team sharing):
```json
{
  "mcpServers": {
    "dart": {
      "command": "dart",
      "args": ["mcp-server"]
    }
  }
}
```

### Setup for Other Clients

**Cursor** (`.cursor/mcp.json`):
```json
{
  "mcpServers": {
    "dart": {
      "command": "dart",
      "args": ["mcp-server"]
    }
  }
}
```

**VS Code + GitHub Copilot:** Install Dart Code extension v3.116+. The server is auto-registered. Control with the `dart.mcpServer` setting.

**Firebase Studio / IDX** (`.idx/mcp.json`):
```json
{
  "mcpServers": {
    "dart-mcp-server": {
      "type": "local",
      "command": ["dart", "mcp-server"],
      "enabled": true
    }
  }
}
```

### Capabilities

| Tool | What it does |
|---|---|
| Analyze and fix errors | Runs `dart analyze`; applies `dart fix` suggestions |
| Resolve symbols | Confirms symbol existence; fetches documentation and signatures |
| Introspect running app | Reads widget tree, runtime state; triggers hot reload/restart |
| Search pub.dev | Finds packages by use case description |
| Manage dependencies | Adds/removes packages in `pubspec.yaml` via `dart pub add/remove` |
| Run tests | Executes `flutter test`; feeds results back to the AI |
| Format code | Runs `dart format` with project's analysis config |

### What It Enables in Practice

- Ask "fix the layout issue on the home screen" → AI calls the analyzer, reads the error, applies the fix, re-runs analysis to confirm
- Ask "find a good chart package for this app" → AI calls `pub_dev_search`, selects a package, adds it to pubspec, generates boilerplate
- A CI agent can call `flutter analyze` + `flutter test` on every PR and post results as a review comment
- Hot reload loop: AI edits code → hot reloads → inspects the running widget tree → iterates

### Limitations

- **Requires Dart 3.9+ / Flutter beta channel** — not available on stable as of March 2026
- Client must support both Tools and Resources for full feature set
- Explicitly experimental; API may change rapidly

**Sources:**
- https://docs.flutter.dev/ai/mcp-server
- https://dart.dev/tools/mcp-server
- https://blog.flutter.dev/supercharge-your-dart-flutter-development-experience-with-the-dart-mcp-server-2edcc8107b49

---

## 2. mcp_flutter — Flutter Inspector MCP Server

**Author:** Arenukvern (community, MIT license, security-reviewed by MseeP.ai)

**What it is:** Connects a **running Flutter app** to AI assistants in real time via the Dart VM Service protocol. The key differentiator: Flutter apps can register **custom MCP tools at runtime** using the `mcp_toolkit` pub package. Architecture: `AI Assistant ↔ MCP Server (Dart binary) ↔ Dart VM Service ↔ Flutter app`.

**Requirements:**
- Dart SDK 3.10.0+
- Flutter app running in **debug mode**
- macOS/iOS fully tested; Android partial; Web not supported

### Setup (Step-by-Step)

**Step 1: Build the MCP server binary**
```bash
git clone https://github.com/Arenukvern/mcp_flutter
cd mcp_flutter
make install
# Binary: mcp_flutter/mcp_server_dart/build/flutter_inspector_mcp
```

Or use Smithery (auto-install):
```bash
npx -y @smithery/cli install @Arenukvern/mcp_flutter --client claude
```

**Step 2: Add the toolkit to your Flutter app**
```bash
flutter pub add mcp_toolkit
```

**Step 3: Initialize in `main.dart`**
```dart
import 'package:mcp_toolkit/mcp_toolkit.dart';
import 'dart:async';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      MCPToolkitBinding.instance
        ..initialize()
        ..initializeFlutterToolkit();
      runApp(const MyApp());
    },
    (error, stack) {
      MCPToolkitBinding.instance.handleZoneError(error, stack);
    },
  );
}
```

**Step 4: Run Flutter with the VM service exposed**
```bash
flutter run --debug \
  --host-vmservice-port=8182 \
  --dds-port=8181 \
  --enable-vm-service \
  --disable-service-auth-codes
```

Note the VM service port printed in the console output — it must match the `--dart-vm-port` value below.

**Step 5: Configure Claude Code**
```bash
claude mcp add flutter-inspector \
  /path/to/flutter_inspector_mcp \
  -- --dart-vm-host=localhost --dart-vm-port=8181 --no-resources --images
```

Or via `.mcp.json`:
```json
{
  "mcpServers": {
    "flutter-inspector": {
      "command": "/path/to/mcp_flutter/mcp_server_dart/build/flutter_inspector_mcp",
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

**Key flags:**
| Flag | Effect |
|---|---|
| `--resources` | Enable MCP resources (use with Claude Code) |
| `--no-resources` | Disable resources (required for Cursor, Cline) |
| `--images` | Enable screenshot capture |
| `--dumps` | Enable dump RPCs (disabled by default — very high token cost) |

### Capabilities

| Tool | What it does |
|---|---|
| `get_app_errors` | Retrieves errors from the running app |
| `view_screenshot` | Captures a screenshot of the running app |
| `get_view_details` | Screen dimensions, pixel ratios, view hierarchy |
| Hot reload | Triggers Flutter hot reload |
| Widget tree inspection | Dumps render tree, layer tree, semantics tree, focus tree |
| Visual debugging | Toggle repaint rainbows, debug paint, etc. |
| Performance monitoring | Track widget rebuilds and repaints |
| Environment control | Override platform, brightness, time dilation |
| Dynamic custom tools | Register app-specific tools via `mcp_toolkit` at runtime |

### Custom Tool Registration (Advanced)

Your app can register custom MCP tools that are discoverable at runtime:

```dart
MCPToolkitBinding.instance.addEntries([
  MCPCallEntry(
    name: 'seed_test_data',
    description: 'Seeds the local database with sample expenses for testing',
    handler: (params) async {
      await ExpenseSeeder.seedAll();
      return MCPCallResult.success('Seeded 50 sample expenses');
    },
  ),
]);
```

This means your AI assistant can call your own app-specific commands (seed DB, clear state, navigate to a screen, etc.) directly.

### Troubleshooting

- Use `--no-resources` if you get null subtype errors in Claude Code
- Always restart Claude Code after changing `.mcp.json`
- If hot reload fails, ensure `--disable-service-auth-codes` is set when running Flutter

**Sources:**
- https://github.com/Arenukvern/mcp_flutter
- https://github.com/Arenukvern/mcp_flutter/blob/main/QUICK_START.md
- https://gist.github.com/lukemmtt/62c0889f7a959546702a973239382b12

---

## 3. flutter-mcp — Documentation MCP Server

**Author:** adamsmaka (community, open source)

**What it is:** A locally-running MCP server that feeds real-time Flutter/Dart documentation and pub.dev package information to AI assistants. Goal: eliminate hallucinated widgets and deprecated APIs by giving the AI access to actual, current Flutter docs for 50,000+ pub.dev packages. Runs 100% locally with SQLite caching.

**Requirements:** Node.js 16+, Python 3.10+ (auto-detected by the package)

### Setup

Quick start (no install required):
```bash
npx flutter-mcp
```

Global install:
```bash
npm install -g flutter-mcp
```

Claude Code `.mcp.json`:
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

### Capabilities

| Tool | What it does |
|---|---|
| `flutter_search` | Universal search across Flutter/Dart docs and pub.dev |
| `flutter_docs` | Fetches docs for any class, method, or package; auto-detects identifier type |
| `flutter_status` | Health check and cache statistics |

Version-specific docs: `@flutter_mcp provider:6.0.5`

### What It Solves

Without this server, Claude may generate code using:
- `RaisedButton` (deprecated since Flutter 2.0)
- `primaryColor` (deprecated in M3)
- API signatures that have changed between versions

With this server, Claude has access to the current API reference for whatever package version you're using.

**Availability:** No Flutter SDK version requirement — works with any Flutter project today.

**Source:** https://github.com/adamsmaka/flutter-mcp

---

## 4. DCM MCP Server (Dart Code Metrics)

**Author:** DCM team (commercial product, local execution)

**What it is:** An MCP server exposing DCM's 475+ code quality rules and automated fix capabilities to AI agents. Introduced in DCM 1.31.0 (August 2025). All analysis runs locally; no code is sent externally.

**Requirements:** DCM 1.31.0+ CLI installed

### Setup for Claude Code

```bash
# Project-scoped
claude mcp add --transport stdio --scope local dcm -- dcm start-mcp-server --force-roots-fallback --client=claude-code

# Machine-wide (all projects)
claude mcp add --transport stdio --scope user dcm -- dcm start-mcp-server --client=claude-code
```

Verify with: `claude mcp list` — should show `dcm: Connected`

Claude Desktop config (`claude_desktop_config.json`):
```json
{
  "mcpServers": {
    "dcm": {
      "command": "dcm",
      "args": ["start-mcp-server", "--client=claude-desktop"]
    }
  }
}
```

### Capabilities

- Run DCM analysis with 475+ configurable lint rules (beyond what `flutter analyze` provides)
- Apply only safe, deterministic auto-fixes
- Calculate code metrics (cyclomatic complexity, lines of code, coupling)
- Generate code quality reports

### What It Enables

An AI agent can: run DCM analysis → apply only safe fixes → hot reload → confirm the issue is resolved — all without leaving the Claude session. Particularly powerful for tech debt triage across a large codebase.

**Pricing:** Free for open-source projects. Paid plans for commercial use. See https://dcm.dev for current pricing.

**Sources:**
- https://dcm.dev/docs/ide-integrations/mcp-server/
- https://dcm.dev/blog/2025/08/25/agentic-code-quality-dcm-mcp/

---

## 5. Very Good CLI MCP Server

**Author:** Very Good Ventures (official VGV product, experimental)

**What it is:** `very_good_cli` includes an experimental `very_good mcp` command that exposes its Flutter/Dart project scaffolding capabilities via MCP.

```bash
dart pub global activate very_good_cli
very_good mcp  # starts the MCP server
```

**MCP tools exposed:** `create flutter_app`, `create dart_package`, `create flutter_package`, `create flutter_plugin`, `create flame_game`, `test`, `packages`

**What it enables:** Ask an AI assistant to scaffold a new VGV-opinionated Flutter app with clean architecture, full test coverage setup, and conventional commits — all from a prompt.

**Status:** Explicitly experimental.

**Source:** https://verygood.ventures/blog/7-mcp-servers-every-dart-and-flutter-developer-should-know/

---

## 6. Pub.dev Dart/Flutter MCP Packages

For building MCP-aware Flutter apps or custom servers:

| Package | Purpose |
|---|---|
| `mcp_server` | Build MCP servers in Dart; supports stdio/SSE/HTTP; Resources, Tools, Prompts |
| `mcp_client` | Build MCP clients in Dart; OAuth 2.1 auth support |
| `mcp_dart` | Full MCP SDK in Dart (client + server); all capabilities |
| `flutter_mcp` | Flutter plugin for building MCP-connected LLM agent apps with background services |
| `mcp_toolkit` | Companion to mcp_flutter; adds dynamic tool registration to your Flutter app |

---

## 7. What's Best for This Project

This project currently runs on Dart 2.1 (pre-null-safety). Availability by current state:

| MCP Server | Requires Flutter Upgrade? | Available Now? |
|---|---|---|
| Official `dart mcp-server` | Yes (needs Dart 3.9+) | No |
| mcp_flutter (Arenukvern) | Yes (needs Dart 3.10+, debug mode) | No |
| flutter-mcp docs server | No | **Yes** |
| DCM MCP server | No (DCM is standalone) | **Yes** |
| Very Good CLI MCP | No | **Yes** |

**Immediate recommendation:** Add `flutter-mcp` to `.mcp.json` now to prevent deprecated-API generation. Add the official `dart mcp-server` and `mcp_flutter` after completing the Flutter upgrade (Phase 1 of the modernization roadmap).

---

## Sources

- https://docs.flutter.dev/ai/mcp-server
- https://dart.dev/tools/mcp-server
- https://blog.flutter.dev/supercharge-your-dart-flutter-development-experience-with-the-dart-mcp-server-2edcc8107b49
- https://github.com/Arenukvern/mcp_flutter
- https://github.com/adamsmaka/flutter-mcp
- https://dcm.dev/docs/ide-integrations/mcp-server/
- https://verygood.ventures/blog/7-mcp-servers-every-dart-and-flutter-developer-should-know/
- https://pub.dev/packages/mcp_server
- https://pub.dev/packages/flutter_mcp

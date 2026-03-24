# SAI-0001: Flutter Modernisation – Research

## Summary

This work thread covers the initial research and analysis phase for modernising the `flutter_expense_tracker` repository. The project is an existing personal Flutter app built with an older Flutter/Dart SDK (~1.x era). The goal is to understand what is needed to bring it up to the latest stable Flutter version and align it with modern, production-ready open-source development patterns — ultimately making the repo well-suited for AI-driven development.

This ticket does **not** implement any changes to the app code. It produces the documentation and proposals that will guide subsequent implementation tickets.

## Scope

- Understand the current app purpose and code structure
- Research Flutter modernisation requirements (SDK, packages, Dart null safety)
- Research best-practice repo organisation for Flutter
- Research modern Flutter app architecture (local-only app)
- Research Flutter CI/CD patterns with GitHub (APK artifact publishing, changelogs, releases)
- Research modern Flutter testing practices
- Research modern UI/UX design and mocking tools for Flutter
- Research Flutter MCP servers and AI-assisted development tooling
- Produce analysis and proposal documents from the research
- Create Claude Code project configuration (`.mcp.json`, `.claude/settings.json`, custom slash commands)

## Working Directory

All documents for this ticket live in `ai/tickets/SAI-0001/`.

```
ai/tickets/SAI-0001/
├── README.md                  ← this file
├── research/
│   ├── flutter-version.md     ← Flutter SDK & package modernisation findings
│   ├── repo-organisation.md   ← Repo layout best practices
│   ├── app-architecture.md    ← Architecture patterns for local-only Flutter apps
│   ├── ci-cd.md               ← CI/CD and GitHub release patterns
│   ├── testing.md             ← Modern testing practices
│   ├── design-tools.md        ← Design & mocking tools for Flutter
│   ├── other-best-practices.md← Additional modern Flutter patterns
│   └── flutter-mcp-servers.md ← MCP servers for Flutter AI-assisted development
└── analysis/
    ├── synthesis.md           ← Summary of major findings
    ├── repo-structure.md      ← Proposal for repo reorganisation
    ├── flutter-update.md      ← What needs to change to update Flutter
    ├── ci-cd-proposal.md      ← CI/CD implementation plan
    └── ai-development.md      ← Improvements to support AI-driven dev
```

## Task Checklist

### Phase 0 – Init

- [x] Create `ai/tickets/SAI-0001/` working directory
- [x] Add this `README.md` with summary and task checklist
- [x] Analyse current app purpose and structure
- [x] Create `architecture.md` in project root
- [x] Create `CONTRIBUTING.md` in project root
- [x] Create `CLAUDE.md` in project root
- [x] Update repo `README.md`
- [x] Add `.github/PULL_REQUEST_TEMPLATE.md`
- [x] Add `.github/CODEOWNERS`
- [x] Create initial PR for review

### Phase 1 – Research

- [x] Research latest stable Flutter – gaps vs current project (`research/flutter-version.md`)
- [x] Research best practices for Flutter repo organisation (`research/repo-organisation.md`)
- [x] Research Flutter app architecture for local-only apps (`research/app-architecture.md`)
- [x] Research Flutter CI/CD & GitHub release patterns (`research/ci-cd.md`)
- [x] Research modern Flutter test practices (`research/testing.md`)
- [ ] Research modern design and mocking tools for Flutter (`research/design-tools.md`)
- [ ] Research other relevant Flutter best practices (`research/other-best-practices.md`)
- [x] Research Flutter MCP servers and AI dev tooling (`research/flutter-mcp-servers.md`)
- [ ] Commit and push Phase 1 research docs

### Phase 2 – Analysis

- [ ] Write synthesis and summary document (`analysis/synthesis.md`)
- [ ] Write repo structure proposal (`analysis/repo-structure.md`)
- [ ] Write Flutter update/refactor plan (`analysis/flutter-update.md`)
- [ ] Write CI/CD implementation proposal (`analysis/ci-cd-proposal.md`)
- [x] Write AI-driven development improvements doc (`analysis/ai-development.md`)
- [ ] Create Claude Code project config (`.mcp.json`, `.claude/settings.json`, `.claude/commands/`)
- [ ] Commit and push Phase 2 analysis docs
- [ ] Update PR for final review

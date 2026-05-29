# Contributing to Athens

Thank you for your interest in contributing! Athens is an open-source MIT-licensed project.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_HANDLE/athens.git`
3. Follow [docs/SETUP.md](docs/SETUP.md) to configure your environment
4. Create a feature branch: `git checkout -b feat/your-feature`

## Development Setup

```bash
# Flutter app
cd app
flutter pub get
flutter analyze    # must be clean
flutter test       # must pass

# Next.js web
cd web
npm ci
npm run build      # must succeed
```

## Submitting Changes

1. Keep PRs focused — one feature/fix per PR
2. Write or update tests for any new logic
3. Run `flutter analyze` and `flutter test` before opening a PR
4. Use conventional commits: `feat:`, `fix:`, `docs:`, `chore:`, `test:`
5. Open a PR against `main` with a clear description

## Code Style

- Flutter/Dart: follow `flutter analyze` rules (no warnings)
- TypeScript: strict mode
- SQL: lowercase keywords, meaningful names
- Commit messages: `<type>(<scope>): <subject>` — e.g. `feat(rank): add pair selector`

## Architecture Notes

- All external APIs (Spotify, Last.fm, MusicBrainz, iTunes) are behind interfaces.
  Add a `Fake<ApiName>` implementation for tests — no real network in tests.
- Domain logic (`lib/domain/`) must be pure Dart with no Flutter/IO dependencies.
- Supabase RLS must be maintained — never add a table without RLS policies.

## Reporting Issues

Open a GitHub issue with:
- What you expected vs. what happened
- Steps to reproduce
- Flutter/Dart version (`flutter --version`)

## License

By contributing you agree your work is released under the [MIT License](LICENSE).

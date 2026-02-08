# Conventional Commit Types

This document provides a detailed explanation of the supported conventional commit types.

- **`feat`**: (Feature) A new feature. This commit type should be used when you add a new capability to the codebase. It often correlates with a minor version bump.
  - **Example:** `feat: add user authentication`

- **`fix`**: (Bug Fix) A bug fix. This commit type should be used when you resolve a bug in the codebase. It often correlates with a patch version bump.
  - **Example:** `fix: correct typo in login page`

- **`docs`**: (Documentation) Documentation only changes. This includes changes to `README.md`, inline comments, or other documentation files.
  - **Example:** `docs: update installation instructions`

- **`refactor`**: (Refactoring) A code change that neither fixes a bug nor adds a feature. This includes changes that improve the code structure, readability, or maintainability without changing its external behavior.
  - **Example:** `refactor: extract user validation to a separate module`

- **`test`**: (Tests) Adding missing tests or correcting existing tests. This type is for changes that only affect the test suite.
  - **Example:** `test: add unit tests for user service`

- **`chore`**: (Chore) Other changes that don't modify `src` or `test` files. This can include build process changes, auxiliary tool changes, or library updates.
  - **Example:** `chore: update npm dependencies`

**Breaking Changes:**
If a commit introduces a breaking change, it should include `BREAKING CHANGE:` in the footer of the commit message, or append `!` after the type/scope.
  - **Example:** `feat!: send all commits to the changelog` or `feat(api): add new endpoint for users` with `BREAKING CHANGE: The /users endpoint now returns a different format.`

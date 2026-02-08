---
name: conventional-commit
description: Guide the user to create a Git commit message using Conventional Commits specification. Use this skill when the user explicitly asks to make a "conventional commit", "commit with conventional commits", or indicates they want to follow "conventional commit standards".
---

# Conventional Commit Skill

This skill guides you through the process of creating a Git commit message that adheres to the [Conventional Commits specification](https://www.conventionalcommits.org/en/v1.0.0/). This ensures consistent and readable commit history, facilitating automated changelog generation and semantic versioning.

## Workflow

Follow these steps to construct your conventional commit message:

1.  **Choose Commit Type:** Select the most appropriate type from the list below.
    *   `feat`: A new feature
    *   `fix`: A bug fix
    *   `docs`: Documentation only changes
    *   `refactor`: A code change that neither fixes a bug nor adds a feature
    *   `test`: Adding missing tests or correcting existing tests
    *   `chore`: Other changes that don't modify src or test files

    For a more detailed explanation of each type, refer to [commit-types.md](references/commit-types.md).

2.  **Provide Scope (Optional):** The scope is an optional phrase describing the part of the codebase affected. If applicable, specify a scope (e.g., `api`, `auth`, `parser`). If not, you can skip this.

3.  **Write Subject:** Provide a concise, imperative, present-tense subject line. It should be a brief summary of the change.

4.  **Write Body (Optional):** If the change requires more detailed explanation, provide a commit body. This can include the motivation for the change and contrast with previous behavior.

5.  **Declare Breaking Change (Optional):** If the commit introduces a breaking change (i.e., incompatible API changes), clearly state it. You can indicate it by adding `!` after the type/scope (e.g., `feat(api)!: remove old endpoint`) or by including `BREAKING CHANGE:` in the footer.

6.  **Add Footer (Optional):** Any other meta-information, such as issue tracking references (e.g., `Closes #123`), can be added here.

## Output

Upon collecting all necessary information, the skill will construct and provide the `git commit` command for you to review and execute. The skill **will not** execute the `git commit` command directly.

## Usage Example

**User:** "I want to commit a new feature to the authentication module."

**Gemini CLI:**
"What type of commit is this? (feat, fix, docs, refactor, test, chore)"

**User:** "feat"

**Gemini CLI:**
"Please provide an optional scope for this feature (e.g., `api`, `auth`, `parser`). If none, press Enter."

**User:** "auth"

**Gemini CLI:**
"Please provide a concise subject line for this commit."

**User:** "add user login functionality"

**Gemini CLI:**
"Please provide an optional body for the commit, explaining the motivation or details. If none, press Enter."

**User:** "(User provides a multi-line body)"

**Gemini CLI:**
"Does this commit introduce a breaking change? If yes, describe it. If no, press Enter."

**User:** "No"

**Gemini CLI:**
"Please provide any optional footer information (e.g., `Closes #123`). If none, press Enter."

**User:** "Fixes #456"

**Gemini CLI:**
"Here is your git commit command:
\`\`\`bash
git commit -m "feat(auth): add user login functionality" -m "This commit introduces new user login functionality.

Motivation for the change...

Fixes #456"
\`\`\`
"
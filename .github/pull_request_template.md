# <!-- Use the title to describe PR changes in the imperative mood --> #
  <!-- Remember this title will end up as the merge commit subject -->

## 🗣 Description ##

<!-- Describe the "what" of your changes in detail. -->
<!-- To avoid scope creep, limit changes to a single goal. -->

## 💭 Motivation and context ##

<!-- Why is this change required? -->
<!-- What problem does this change solve? How did you solve it? -->
<!-- Mention any related issue(s) here using appropriate keywords such -->
<!-- as "closes" or "resolves" to auto-close them on merge. -->

## 🧪 Testing ##

<!-- How did you test your changes? How could someone else test this PR? -->
<!-- Include details of your testing environment, and the tests you ran to -->
<!-- see how your change affects other areas of the code, etc. -->

<!--
## 📷 Screenshots (if appropriate) ##

Uncomment this section if a screenshot is needed.

-->

## ✅ Pre-approval checklist ##

<!-- Remove any of the following that do not apply. -->
<!-- Draft PRs may have one or more unchecked boxes. -->
<!-- If you're unsure about any of these, don't hesitate to ask. -->
<!-- We're here to help! -->

- [ ] This PR has an informative and human-readable title.
- [ ] PR targets the correct parent branch (e.g., main or release-name) for merge.
- [ ] Changes are limited to a single goal - *eschew scope creep!*
- [ ] Changes are sized such that they do not touch excessive number of files.
- [ ] *All* future TODOs are captured in issues, which are referenced in code comments.
- [ ] These code changes follow the ScubaGear [content style guide](https://github.com/cisagov/ScubaGear/blob/main/CONTENTSTYLEGUIDE.md).
- [ ] Related issues these changes resolve are linked preferably via [closing keywords](https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue#linking-a-pull-request-to-an-issue-using-a-keyword).
- [ ] All relevant type-of-change labels added.
- [ ] All relevant project fields are set.
- [ ] All relevant repo and/or project documentation updated to reflect these changes.
- [ ] Unit tests added/updated to cover PowerShell and Rego changes.
- [ ] Functional tests added/updated to cover PowerShell and Rego changes.
- [ ] All relevant functional tests passed.
- [ ] All automated checks (e.g., linting, static analysis, unit/smoke tests) passed.

## ✅ Pre-merge checklist ##

<!-- Remove any of the following that do not apply. -->
<!-- These boxes should remain unchecked until the pull request has been -->
<!-- approved. -->

- [ ] PR passed smoke test check.
- [ ] Feature branch has been rebased against changes from parent branch, as needed

  Use `Rebase branch` button below or use [this](https://www.digitalocean.com/community/tutorials/how-to-rebase-and-update-a-pull-request) reference to rebase from the command line.
- [ ] Resolved all merge conflicts on branch
- [ ] Notified merge coordinator that PR is ready for merge via comment mention

## ✅ Post-merge checklist ##

<!-- Remove any of the following that do not apply. -->
<!-- These boxes should remain unchecked until the pull request has been -->
<!-- approved. This section is for the merge coordinator to complete. -->
- [ ] Feature branch deleted after merge to clean up repository.
- [ ] Verified that all checks pass on parent branch (e.g., main or release-name) after merge.

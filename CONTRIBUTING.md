# Welcome #

We're so glad you're thinking about contributing to ScubaGear! If
you're unsure or hesitant to make a recommendation, just ask, submit
the issue, or pull request. The worst that can happen is that you'll
be politely asked to change something. We appreciate any sort of
contribution(s), and don't want a wall of rules to stifle innovation.

Before contributing, we encourage you to read our CONTRIBUTING policy
(you are here), our
[LICENSE](https://github.com/cisagov/ScubaGear/blob/main/LICENSE),
and our
[README](https://github.com/cisagov/ScubaGear/blob/main/README.md),
all of which are in this repository.

## Issues ##

If you want to report a bug or request a new feature, the most direct
method is to
[create an issue](https://github.com/cisagov/ScubaGear/issues) in
this repository. We recommend that you first search through existing
open and closed issues to check if your particular issue has already
been reported.

If it has then you might want to add a comment to the existing issue.

If it hasn't then feel free to create a new one.

Please follow the provided template and fill out all sections.
We have `Bug Report` and `Idea` templates.

## Pull Requests (PR) ##

If you choose to [submit a pull
request](https://github.com/cisagov/ScubaGear/pulls), it must pass
several style, format, and sanity checks in our continuous
integration (CI) pipeline before it can be merged. Your pull request
may fail these checks, and that's OK. If you want you can stop there
and wait for us to make the necessary corrections to ensure your code
passes the CI checks. If you would rather make the changes yourself
to pass the CI checks, please feel free to do so.

### PR assignee responsibilities

If you are assigned to a PR, whether you are an external contributor or a member of the core team, you are responsible for moving that PR through the review process.

PR assignees should:

1. Provide a clear and complete PR description that explains what changed and links the issue(s) the PR resolves, preferably with [closing keywords](https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue#linking-a-pull-request-to-an-issue-using-a-keyword).
2. Include testing instructions reviewers can follow. Examples include:
   - How to run Rego unit tests locally or in GitHub Actions for a new baseline implementation.
   - What PowerShell unit or functional tests were added for provider logic or key module changes, and how to run them locally or in GitHub Actions.
   - What configuration changes reviewers should make in a test tenant when validating different policy states.
   - A link to a recent workflow run when the PR changes CI, smoke tests, or other automation.
3. Assign the appropriate reviewers for the PR.
4. Collaborate with reviewers to resolve questions, requested changes, and outstanding comments.
5. Ensure all pre-approval, pre-merge, and post-merge checklist items in the PR template are completed.
6. After approval from two reviewers, merge your own PR when the repository workflow allows it.
    - If you are an external contributor, @mention one of the reviewers to merge your PR.

### Quality assurance and code reviews ##

All PRs will be tested, vetted, and reviewed by our team before being
merged to the main branch. Please stand by to address questions,
concerns, or improvement suggestions we may have about your PR.

## Public domain ##

This project is in the public domain within the United States, and
copyright and related rights in the work worldwide are waived through
the [CC0 1.0 Universal public domain
dedication](https://creativecommons.org/publicdomain/zero/1.0/).

All contributions to this project will be released under the CC0
dedication. By submitting a pull request, you are agreeing to comply
with this waiver of copyright interest.

# MegaLinter

[MegaLinter](https://megalinter.io/latest/) is "an Open-Source tool for CI/CD workflows that analyzes the consistency of your code, IAC, configuration, and scripts in your repository sources, to ensure all your projects sources are clean and formatted whatever IDE/toolbox is used by their developers, powered by OX Security."

It is a linter that calls other linters.

## Configuring MegaLinter

MegaLinter itself is configured via a `.mega-linter.yml` file that must be in the root directory of the repo when it runs.  Because we run the linter once per each type of file we lint, there are multiple of these config files in the `/MegaLinter` subdirectory.  These config files are copied into the root directory by the GitHub Action workflow right before running MegaLinter.

## Configuring Specific Linters

Each linter can also be configured, typically to ignore undesired checks.  How they are configured is up to each individual linter.

### yamllint

yamllint is a linter for YAML that is configured by a `.yamllint.yml` file that must be int he root directory.  It uses the disable value to disable undesired checks (e.g., `document-start: disable`).  Much like the MegaLinter config file, the yamllint config file is copies from the `/MegaLinter` subdirectory to the root directory by the GitHub Action workflow.
# Contributing

This project welcomes contributions and suggestions.

- [Submitting a Pull Request (PR)](#submitting-a-pull-request-pr)
- [Setting up the development environment](#setting-up-the-development-environment)
- [Running unit tests](#running-unit-tests)
- [Code style](#code-style)
- [Adding new features](#adding-new-features)
  - [Adding new azd environment variables](#adding-new-azd-environment-variables)

## Submitting a Pull Request (PR)

Before you submit your Pull Request (PR) consider the following guidelines:

- Search this repository's [pull requests](../../pulls) for an open or closed PR that relates to your submission. You don't want to duplicate effort.
- Make your changes in a new git branch or fork
- Follow [Code style conventions](#code-style)
- [Run the tests](#running-unit-tests) (and write new ones, if needed)
- Commit your changes using a descriptive commit message
- Push your branch/fork to GitHub
- In GitHub, create a pull request to the `main` branch of the repository
- Ask a maintainer to review your PR and address any comments they might have

## Setting up the development environment

Install the development dependencies:

```shell
python -m pip install -r requirements-dev.txt
```

Install the pre-commit hooks:

```shell
pre-commit install
```

## Running unit tests

Run the tests:

```shell
python -m pytest
```

If test snapshots need updating (and the changes are expected), you can update them by running:

```shell
python -m pytest --snapshot-update
```

Once tests are passing, generate a coverage report to make sure your changes are covered:

```shell
pytest --cov --cov-report=xml && \
diff-cover coverage.xml --html-report coverage_report.html && \
open coverage_report.html
```

## Code style

This codebase includes Python, Bicep, PowerShell, and Bash. Code should follow the standard conventions of each language.

For Python, you can enforce the conventions using `ruff` and `black`.

Run `ruff` to lint a file:

```shell
python -m ruff <path-to-file>
```

Run `black` to format a file:

```shell
python -m black <path-to-file>
```

If you followed the steps above to install the pre-commit hooks, then you can just wait for those hooks to run `ruff` and `black` for you.

## Adding new features

This project includes an [AGENTS.md](AGENTS.md) file that instructs GitHub Copilot (and other coding agents) how to generate code for common changes. Consult it, along with the suggestions below, before adding new features.

### Adding new azd environment variables

When adding new azd environment variables, please remember to update:

1. [main.parameters.json](./infra/main.parameters.json)
1. [appEnvVariables in main.bicep](./infra/main.bicep)
1. [ADO pipeline](.azdo/pipelines/azure-dev.yml)
1. [GitHub workflows](.github/workflows/azure-dev.yml)

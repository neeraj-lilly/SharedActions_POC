# About `.github` Directory

This directory contains GitHub related files. GitHub looks for certain file/path names for different purposes.

- `PULL_REQUEST_TEMPLATE`: pull request template is managed by this repo owner; see [Pull request guideline](../Documents/pull-request-guideline.md).
- `workflows`: it contains [GitHub Action](https://docs.github.com/en/actions/learn-github-actions) workflows, and is managed by the [DIGHCI](https://elilillyco.slack.com/archives/GNB92AUUX) team. It typically contains:
  - [Code check](workflows/ci.yml): when a PR is created or updated, this workflow will be executed automatically.
  - [Manual release](workflows/virtualrelease.yml): manually called from [Repo Actions](https://github.com/EliLillyCo/GCSP_VC_APP_IOS/actions/workflows/virtualrelease.yml) to generate release archives, e.g. iOS IPA, Android APK, etc.

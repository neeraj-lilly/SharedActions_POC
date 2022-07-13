# Usage

```
OVERVIEW: Pull request & code code for Lilly Together iOS.

USAGE: pull-request-checker <path> [--verbose] [--skip-unit-tests] [--head <head>] [--base <base>] --pr-title <pr-title> [--simulator-name <simulator-name>] [--simulator-os <simulator-os>] [--pr-number <pr-number>]

ARGUMENTS:
  <path>                  The path of the Xcode project. 

OPTIONS:
  --verbose               Verbose mode. 
  --skip-unit-tests       Skip unit tests. 
  --head <head>           Head branch. (default: HEAD)
  --base <base>           Base branch. (default: develop)
  --pr-title <pr-title>   Pull request title. 
  --simulator-name <simulator-name>
                          Simulator name. (default: iPhone 12)
  --simulator-os <simulator-os>
                          Simulator OS. (default: 14.4)
  --pr-number <pr-number> Post comments to pull request number, which can be
                          obtained from ${{ github.event.pull_request.number
                          }}. 
  --version               Show the version.
  -h, --help              Show help information.

```

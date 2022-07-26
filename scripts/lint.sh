#! /usr/bin/env sh

set -e

black --check app 
isort --check-only app
flake8 app
mypy app

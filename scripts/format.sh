#! /usr/bin/env sh

set -x

autoflake --ignore-init-module-imports --remove-all-unused-imports --recursive --remove-unused-variables --in-place app
black app
isort app
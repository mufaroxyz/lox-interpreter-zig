#!/bin/sh

set -e # Exit early if any commands fail

(
  cd "$(dirname "$0")" # Ensure compile steps are run within the repository directory
  zig build
)

exec $(dirname $0)/zig-out/bin/main "$@"

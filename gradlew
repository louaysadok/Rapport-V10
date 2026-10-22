#!/bin/bash

# This script wraps the Gradle wrapper located in the android directory.
cd "$(dirname "$0")/android" || exit 1
exec ./gradlew "$@"

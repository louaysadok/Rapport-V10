#!/bin/sh
# ---------------------------------------------------------------------------
# Gradle startup script for UN*X (Rapport+ wrapper)
# Auto-downloads gradle-wrapper.jar if missing.
# ---------------------------------------------------------------------------

APP_HOME=$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")/..
APP_HOME=$(cd "$APP_HOME" && pwd)

WRAPPER_JAR="$APP_HOME/gradle/wrapper/gradle-wrapper.jar"
WRAPPER_PROPS="$APP_HOME/gradle/wrapper/gradle-wrapper.properties"

DEFAULT_JVM_OPTS='-Xmx512m'

# Download wrapper jar if missing
if [ ! -f "$WRAPPER_JAR" ]; then
    echo "Downloading Gradle wrapper jar..."
    mkdir -p "$APP_HOME/gradle/wrapper"
    DIST_URL=$(grep 'distributionUrl' "$WRAPPER_PROPS" 2>/dev/null | cut -d'=' -f2- | tr -d ' ')
    if [ -z "$DIST_URL" ]; then
        DIST_URL="https://services.gradle.org/distributions/gradle-8.3-bin.zip"
    fi
    echo "Distribution URL: $DIST_URL"
    curl -sL --retry 3 --fail "$DIST_URL" -o /tmp/gradle-bin.zip || {
        echo "ERROR: Failed to download Gradle distribution from $DIST_URL"
        exit 1
    }
    unzip -q /tmp/gradle-bin.zip -d /tmp/gradle-dist || {
        echo "ERROR: Failed to unzip Gradle distribution"
        exit 1
    }
    JAR=$(find /tmp/gradle-dist -name "gradle-wrapper.jar" | head -1)
    if [ -z "$JAR" ]; then
        echo "ERROR: gradle-wrapper.jar not found in distribution"
        exit 1
    fi
    cp "$JAR" "$WRAPPER_JAR"
    echo "Gradle wrapper jar installed."
fi

# Determine the Java command
if [ -n "$JAVA_HOME" ]; then
    if [ -x "$JAVA_HOME/jre/sh/java" ]; then
        JAVACMD="$JAVA_HOME/jre/sh/java"
    else
        JAVACMD="$JAVA_HOME/bin/java"
    fi
    if [ ! -x "$JAVACMD" ]; then
        echo "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_HOME"
        exit 1
    fi
else
    JAVACMD="java"
    command -v java >/dev/null 2>&1 || {
        echo "ERROR: java is not installed or not in PATH."
        exit 1
    }
fi

exec "$JAVACMD" $DEFAULT_JVM_OPTS -classpath "$WRAPPER_JAR" org.gradle.wrapper.GradleWrapperMain "$@"

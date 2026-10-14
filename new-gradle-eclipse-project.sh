#!/bin/sh

set -eu

usage() {
    echo "usage: $0 NEW_PROJECT_DIRECTORY [PACKAGE_NAME] [TEMPLATE_DIRECTORY]" >&2
    echo "example: $0 ~/eclipse-workspace/hello org.ray.hello" >&2
    exit 2
}

[ "$#" -ge 1 ] && [ "$#" -le 3 ] || usage

projectDirectory=$1
projectName=$(basename "$projectDirectory")
defaultPackage=$(printf '%s' "$projectName" | tr '[:upper:]-' '[:lower:]_')
packageName=${2:-$defaultPackage}
templateDirectory=${3:-${GRADLE_ECLIPSE_TEMPLATE:-"$HOME/eclipse-workspace/project"}}

templateProjectName=gradle-eclipse-template
templatePackage=org.ray.template
templatePackageDirectory=org/ray/template

case "$projectName" in
    ""|*[!A-Za-z0-9._-]*)
        echo "error: project name must contain only letters, digits, dots, underscores, or hyphens" >&2
        exit 1
        ;;
esac

if ! printf '%s\n' "$packageName" | grep -Eq '^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*$'; then
    echo "error: invalid Java package name: $packageName" >&2
    exit 1
fi

if [ -e "$projectDirectory" ]; then
    echo "error: destination already exists: $projectDirectory" >&2
    exit 1
fi

[ -d "$templateDirectory" ] || {
    echo "error: Gradle Eclipse template not found: $templateDirectory" >&2
    echo "expected a checkout of https://github.com/rtayek/project.git" >&2
    exit 1
}

for requiredFile in \
    gradlew \
    gradlew.bat \
    gradle/wrapper/gradle-wrapper.jar \
    gradle/wrapper/gradle-wrapper.properties \
    build.gradle.kts \
    settings.gradle.kts \
    config/checkstyle/checkstyle.xml \
    config/pmd/pmd.xml \
    config/spotbugs/exclude.xml
do
    if [ ! -f "$templateDirectory/$requiredFile" ]; then
        echo "error: template file not found: $templateDirectory/$requiredFile" >&2
        exit 1
    fi
done

packageDirectory=$(printf '%s' "$packageName" | tr '.' '/')

mkdir -p "$projectDirectory"
cp -R "$templateDirectory/." "$projectDirectory/"

# Never clone repository identity or generated IDE/build output.
rm -rf \
    "$projectDirectory/.git" \
    "$projectDirectory/.gradle" \
    "$projectDirectory/build" \
    "$projectDirectory/bin" \
    "$projectDirectory/lib" \
    "$projectDirectory/.classpath" \
    "$projectDirectory/.project" \
    "$projectDirectory/.settings"

# Move the template package tree before replacing package declarations.
for sourceRoot in src tst; do
    oldPackageDirectory="$projectDirectory/$sourceRoot/$templatePackageDirectory"
    if [ -d "$oldPackageDirectory" ]; then
        newPackageDirectory="$projectDirectory/$sourceRoot/$packageDirectory"
        mkdir -p "$newPackageDirectory"
        cp -R "$oldPackageDirectory/." "$newPackageDirectory/"
        rm -rf "$projectDirectory/$sourceRoot/org"
    fi
done

# Replace template identity in ordinary text files.
find "$projectDirectory" -type f \
    ! -path '*/gradle-wrapper.jar' \
    -exec sh -c '
        for file do
            if grep -Iq . "$file" 2>/dev/null; then
                sed \
                    -e "s|gradle-eclipse-template|$1|g" \
                    -e "s|org\.ray\.template|$2|g" \
                    "$file" > "$file.tmp" && mv "$file.tmp" "$file"
            fi
        done
    ' sh "$projectName" "$packageName" {} +

chmod +x "$projectDirectory/gradlew"

(
    cd "$projectDirectory"
    ./gradlew eclipse check
    ./gradlew clean
)

echo
echo "Created and verified: $projectDirectory"
echo "Template: $templateDirectory"
echo "Verification: ./gradlew eclipse check"
echo "Eclipse: File -> Import -> General -> Existing Projects into Workspace"
echo "Leave 'Copy projects into workspace' unchecked."

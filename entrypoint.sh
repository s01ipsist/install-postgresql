#!/usr/bin/env bash

set -euo pipefail

echo "::group::setup-postgresql"

echo "Verifying version"

# Check if the input is an integer
if ! [[ "$INPUT_POSTGRESQL_VERSION" =~ ^[0-9]+$ ]]; then
    echo "Error: $INPUT_POSTGRESQL_VERSION is not a valid integer."
    exit 1
fi

# Check if the input is a supported version: https://www.postgresql.org/support/versioning/
if (( INPUT_POSTGRESQL_VERSION < 14 || INPUT_POSTGRESQL_VERSION > 18 )); then
    echo "Error: $INPUT_POSTGRESQL_VERSION is not between 14 and 18 (inclusive)."
    exit 1
fi

echo "Validated postgresql version: $INPUT_POSTGRESQL_VERSION"

echo "Installing postgresql..."

OS=$(uname -s)
echo "OS: $OS"

if [[ "$OS" == "Linux" ]]; then
    # Import the repository signing key (apt-key was removed in Ubuntu 26.04):
    sudo install -d -m 0755 /etc/apt/keyrings
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo tee /etc/apt/keyrings/pgdg.asc > /dev/null

    # Create the file repository configuration:
    sudo sh -c 'echo "deb [signed-by=/etc/apt/keyrings/pgdg.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

    # Update the package lists:
    sudo apt-get update

    # Install PostgreSQL
    sudo apt-get install -y "postgresql-$INPUT_POSTGRESQL_VERSION"
elif [[ "$OS" == "NT"* ]] || [[ "$OS" == "MINGW"* ]] || [[ "$OS" == *"MSYS"* ]]; then
    choco install "postgresql$INPUT_POSTGRESQL_VERSION" -y --no-progress --use-download-cache
elif [[ "$OS" == "Darwin" ]]; then
    HOMEBREW_NO_AUTO_UPDATE=1 brew install "postgresql@$INPUT_POSTGRESQL_VERSION"
else
    echo "Unsupported OS"
    exit 1
fi

echo "Installed postgresql"

echo "Updating PATH..."

if [[ "$OS" == "NT"* ]] || [[ "$OS" == "MINGW"* ]] || [[ "$OS" == *"MSYS"* ]]; then
    # shellcheck disable=SC2028
    echo "C:\\Program Files\\PostgreSQL\\$INPUT_POSTGRESQL_VERSION\\bin" >> "$GITHUB_PATH"
elif [[ "$OS" == "Darwin" ]]; then
    echo "$(brew --prefix postgresql@"${INPUT_POSTGRESQL_VERSION}")/bin" >> "$GITHUB_PATH"
else
    echo "/usr/lib/postgresql/$INPUT_POSTGRESQL_VERSION/bin" >> "$GITHUB_PATH"
fi

echo "Complete"

echo "::endgroup::"

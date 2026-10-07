#!/usr/bin/env bash
set -euo pipefail

# Configurable variables with defaults
PORT="${PORT:-3000}"
HOST_PORT="${HOST_PORT:-3000}"
IMAGE_NAME="${IMAGE_NAME:-stats-service}"
CONTAINER_NAME="${CONTAINER_NAME:-stats-service-app}"
APP_VERSION="${APP_VERSION:-1.0.0}"
echo "=================================================="
echo " Starting Build, Test & Run Pipeline"
echo " Image:          ${IMAGE_NAME}"
echo " Container:      ${CONTAINER_NAME}"
echo " Host Port:      ${HOST_PORT}"
echo " Container Port: ${PORT}"
echo " App Version: ${APP_VERSION}"
echo "=================================================="


# Step 1: Build Docker image
echo "==> Building Docker image..."
docker build -t "${IMAGE_NAME}" .

# Step 2: Run pytest unit tests inside the container
echo "==> Running pytest unit tests inside container..."
docker run --rm "${IMAGE_NAME}" pytest -v tests/
echo "==> Unit tests passed."

# Step 3: Remove existing container if running
if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}\$"; then
    echo "==> Removing existing container '${CONTAINER_NAME}'..."
    docker rm -f "${CONTAINER_NAME}" > /dev/null
fi

# Step 4: Run the application container
echo "==> Starting container '${CONTAINER_NAME}'..."
docker run -d \
    --name "${CONTAINER_NAME}" \
    -e PORT="${PORT}" \
    -e APP_VERSION="${APP_VERSION}" \
    -p "${HOST_PORT}:${PORT}" \
    "${IMAGE_NAME}"

# Wait for container startup
sleep 2

# Step 5: Verify health endpoint
echo "==> Verifying health status..."
if ! curl -s "http://localhost:${HOST_PORT}/healthz" | grep -q "healthy"; then
    echo "ERROR: Service did not start properly."
    docker logs "${CONTAINER_NAME}"
    exit 1
fi
echo "==> Service is healthy."

# Step 6: Run live curl validation tests
echo "==> Running live curl validation tests..."

test_curl() {
    local endpoint="$1"
    local payload="$2"
    local expected="$3"

    local result
    result=$(curl -s -X POST "http://localhost:${HOST_PORT}${endpoint}" \
        -H "Content-Type: application/json" \
        -d "${payload}")

    if [[ "${result}" == "${expected}" ]]; then
        echo "  [PASS] ${endpoint} with ${payload} -> ${result}"
    else
        echo "  [FAIL] ${endpoint} with ${payload} -> Got '${result}', expected '${expected}'"
        exit 1
    fi
}

test_curl "/mean" '[1,2,3,4,5]' "3"
test_curl "/mean" '[1.5,3,1,7,4.2]' "3.34"
test_curl "/stddev" '[1,2,3,4,5]' "1.414"
test_curl "/stddev" '[1.5,3,1,7,4.2]' "2.15"

echo "=================================================="
echo " All tests passed and container is running on port ${HOST_PORT}."
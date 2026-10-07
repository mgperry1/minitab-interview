#!/usr/bin/env bash
set -euo pipefail

# Configurable target host and port
HOST="${HOST:-localhost}"
HOST_PORT="${HOST_PORT:-3000}"
BASE_URL="http://${HOST}:${HOST_PORT}"

echo "=================================================="
echo " Running Live Curl Integration Tests against ${BASE_URL}"
echo "=================================================="

# Test counter
FAILURES=0

# Helper function to execute curl and assert result
assert_curl() {
    local method="$1"
    local endpoint="$2"
    local payload="$3"
    local expected="$4"

    echo -n "Testing ${method} ${endpoint} with ${payload} ... "

    # Execute curl and capture response
    local response
    response=$(curl -s -X "${method}" "${BASE_URL}${endpoint}" \
        -H "Content-Type: application/json" \
        -d "${payload}")

    if [[ "${response}" == "${expected}" ]]; then
        echo "PASS (Expected: '${expected}', Got: '${response}')"
    else
        echo "FAIL"
        echo "  Expected: '${expected}'"
        echo "  Got:      '${response}'"
        FAILURES=$((FAILURES + 1))
    fi
}

# Run assignment test cases
assert_curl "POST" "/mean" '[1,2,3,4,5]' "3"
assert_curl "POST" "/mean" '[1.5,3,1,7,4.2]' "3.34"
assert_curl "POST" "/stddev" '[1,2,3,4,5]' "1.414"
assert_curl "POST" "/stddev" '[1.5,3,1,7,4.2]' "2.15"

# Optional: Arbitrary ad-hoc test using shell variables passed at runtime
if [[ -n "${CUSTOM_ENDPOINT:-}" && -n "${CUSTOM_PAYLOAD:-}" && -n "${CUSTOM_EXPECTED:-}" ]]; then
    echo "Running custom test from shell variables..."
    assert_curl "POST" "${CUSTOM_ENDPOINT}" "${CUSTOM_PAYLOAD}" "${CUSTOM_EXPECTED}"
fi

echo "=================================================="
if [[ "${FAILURES}" -eq 0 ]]; then
    echo "All integration tests passed successfully!"
    exit 0
else
    echo "Tests completed with ${FAILURES} failure(s)."
    exit 1
fi
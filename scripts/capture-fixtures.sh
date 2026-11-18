#!/usr/bin/env bash
# Captures the running backend's real responses into app/test/fixtures/.
#
# Every Dart model test parses these files, so a field renamed in the backend
# fails a test instead of showing up as a null during the demo. Fixtures are
# generated, never hand-written: after any backend change, re-run this.
#
#   cd backend && npm start          # in one terminal (fresh start preferred)
#   scripts/capture-fixtures.sh      # in another
#
# BASE_URL overrides the default http://localhost:3000/api/v1.
#
# Capture against a freshly started backend so the values are reproducible.
# Side effects: one real ₹1,500 transfer, plus one transfer of the balance's
# paise (e.g. ₹0.75) so balance_whole_rupees.json holds a whole number.
# Restart the backend afterwards to get the seed balance back.
#
# All-or-nothing: responses go to a temporary folder first and replace the
# fixtures only when every capture succeeded.
set -euo pipefail
cd "$(dirname "$0")/.."

BASE_URL="${BASE_URL:-http://localhost:3000/api/v1}"
OUT="app/test/fixtures"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

TOKEN="mock_access_token_123"
JSON="Content-Type: application/json"
AUTH="Authorization: Bearer $TOKEN"
CURL=(curl -s --max-time 10)

for tool in curl uuidgen node; do
  command -v "$tool" >/dev/null || { echo "Needs $tool on PATH." >&2; exit 1; }
done

if ! "${CURL[@]}" -f -o /dev/null "$BASE_URL/health"; then
  echo "Backend not healthy at $BASE_URL. Start it with: cd backend && npm start" >&2
  exit 1
fi

# capture <file> <expected status> <curl args...>
# Saves the raw response body and stops on any other status.
capture() {
  local file="$1" expected="$2"
  shift 2
  local status
  status=$("${CURL[@]}" -o "$TMP/$file" -w '%{http_code}' "$@")
  if [[ "$status" != "$expected" ]]; then
    echo "FAILED $file: expected HTTP $expected, got $status" >&2
    cat "$TMP/$file" >&2 2>/dev/null || true
    echo -e "\nNo fixtures were changed." >&2
    exit 1
  fi
  echo "  $status  $file"
}

new_key() { uuidgen; }

echo "Capturing from $BASE_URL"

# --- Auth ---
capture login_success.json 200 -X POST "$BASE_URL/auth/login" -H "$JSON" \
  -d '{"email":"demo@jstack.co","password":"Demo@123"}'
capture login_401.json 401 -X POST "$BASE_URL/auth/login" -H "$JSON" \
  -d '{"email":"demo@jstack.co","password":"wrong-password"}'
capture login_400_validation.json 400 -X POST "$BASE_URL/auth/login" -H "$JSON" -d '{}'
capture profile.json 200 "$BASE_URL/users/profile" -H "$AUTH"
capture profile_401.json 401 "$BASE_URL/users/profile"

# --- Reads (before the transfers below change the balance) ---
capture balance.json 200 "$BASE_URL/wallet/balance" -H "$AUTH"
capture transactions.json 200 "$BASE_URL/transactions" -H "$AUTH"
capture transaction_details.json 200 "$BASE_URL/transactions/TXN10001" -H "$AUTH"
capture transaction_404.json 404 "$BASE_URL/transactions/NOPE" -H "$AUTH"
capture route_404.json 404 "$BASE_URL/no-such-route"

# --- Transfers ---
KEY=$(new_key)
capture transfer_success.json 200 -X POST "$BASE_URL/transactions/transfer" \
  -H "$AUTH" -H "$JSON" -H "Idempotency-Key: $KEY" \
  -d '{"beneficiaryName":"Rahul Sharma","mobileNumber":"9876543210","amount":1500,"remarks":"Dinner split"}'
# Same key, different amount.
capture transfer_409_idempotency_reuse.json 409 -X POST "$BASE_URL/transactions/transfer" \
  -H "$AUTH" -H "$JSON" -H "Idempotency-Key: $KEY" \
  -d '{"beneficiaryName":"Rahul Sharma","mobileNumber":"9876543210","amount":2000,"remarks":"Dinner split"}'
capture transfer_409_insufficient.json 409 -X POST "$BASE_URL/transactions/transfer" \
  -H "$AUTH" -H "$JSON" -H "Idempotency-Key: $(new_key)" \
  -d '{"beneficiaryName":"Rahul Sharma","mobileNumber":"9876543210","amount":99999999}'
capture transfer_400_validation.json 400 -X POST "$BASE_URL/transactions/transfer" \
  -H "$AUTH" -H "$JSON" -H "Idempotency-Key: $(new_key)" \
  -d '{"beneficiaryName":"","mobileNumber":"98765","amount":10.123,"remarks":42}'
capture transfer_400_missing_key.json 400 -X POST "$BASE_URL/transactions/transfer" \
  -H "$AUTH" -H "$JSON" \
  -d '{"beneficiaryName":"Rahul Sharma","mobileNumber":"9876543210","amount":1}'

# --- A balance in whole rupees (JSON sends 25450, not 25450.00) ---
# Send just the paise part of the current balance, then read it again.
capture balance_before_whole.json 200 "$BASE_URL/wallet/balance" -H "$AUTH"
PAISE=$(node -e 'const b = require(process.argv[1]).data.availableBalance; console.log(Math.round(b * 100) % 100)' "$TMP/balance_before_whole.json")
rm "$TMP/balance_before_whole.json"
if [[ "$PAISE" != "0" ]]; then
  AMOUNT=$(printf '0.%02d' "$PAISE")
  capture .transfer_paise.json 200 -X POST "$BASE_URL/transactions/transfer" \
    -H "$AUTH" -H "$JSON" -H "Idempotency-Key: $(new_key)" \
    -d "{\"beneficiaryName\":\"Fixture capture\",\"mobileNumber\":\"9876543210\",\"amount\":$AMOUNT}"
  rm "$TMP/.transfer_paise.json"
fi
capture balance_whole_rupees.json 200 "$BASE_URL/wallet/balance" -H "$AUTH"
if ! grep -qE '"availableBalance":[0-9]+[,}]' "$TMP/balance_whole_rupees.json"; then
  echo "FAILED balance_whole_rupees.json: balance is not a whole number." >&2
  echo "No fixtures were changed." >&2
  exit 1
fi

# Every capture succeeded: replace the fixtures in one go.
mkdir -p "$OUT"
rm -f "$OUT"/*.json
mv "$TMP"/*.json "$OUT"/
echo "Done: $(ls "$OUT"/*.json | wc -l | tr -d ' ') fixtures in $OUT"

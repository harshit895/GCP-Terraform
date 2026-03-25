CF_ZONE_ID=42905d476f14688256a3b98b173ce700
RECORD_NAME=feat/redis-test
RECORD_TARGET=st-uw-dev-alb-856161468.us-west-2.elb.amazonaws.com
CF_API_TOKEN=cfat_jMZM0TvvaZygRX6vUIqQwQWN57m5QKpXwUXorKPd40eb836f


EXISTING_ID=$(
  curl -sf -X GET \
    "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records?type=CNAME&name=${RECORD_NAME}&content=${RECORD_TARGET}" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" \
  | jq -r '.result[0].id // empty'
)

if [ -n "${EXISTING_ID}" ]; then
  echo "::notice::DNS already exists, skipping: ${RECORD_NAME} → ${RECORD_TARGET}"
  exit 0
fi

# Create new record
RESP=$(
  curl -sf -X POST \
    "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"CNAME\",\"name\":\"${RECORD_NAME}\",\"content\":\"${RECORD_TARGET}\",\"proxied\":true}"
)
echo "API response: $RESP"
echo "::notice::Created DNS: ${RECORD_NAME} → ${RECORD_TARGET}"
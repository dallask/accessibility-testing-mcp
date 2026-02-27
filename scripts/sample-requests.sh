#!/usr/bin/env bash
# Sample MCP requests for the accessibility-testing-mcp HTTP server.
# Usage: ./scripts/sample-requests.sh [BASE_URL]
# Default BASE_URL: http://localhost:3000/mcp

BASE_URL="${1:-http://localhost:3000/mcp}"
HEADERS=(-H "Content-Type: application/json" -H "Accept: application/json, text/event-stream")

echo "=== 1. Initialize ==="
curl -s -X POST "$BASE_URL" "${HEADERS[@]}" -d '{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "initialize",
  "params": {
    "protocolVersion": "2024-11-05",
    "capabilities": {},
    "clientInfo": { "name": "sample-client", "version": "1.0" }
  }
}'
echo -e "\n"

echo "=== 2. List tools ==="
curl -s -X POST "$BASE_URL" "${HEADERS[@]}" -d '{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/list"
}'
echo -e "\n"

echo "=== 3. Call analyze_url (https://example.com) ==="
curl -s -X POST "$BASE_URL" "${HEADERS[@]}" -d '{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "tools/call",
  "params": {
    "name": "analyze_url",
    "arguments": { "url": "https://example.com" }
  }
}'
echo -e "\n"

echo "=== 4. List resources ==="
curl -s -X POST "$BASE_URL" "${HEADERS[@]}" -d '{
  "jsonrpc": "2.0",
  "id": 4,
  "method": "resources/list"
}'
echo -e "\n"

echo "=== 5. Call get_rules ==="
curl -s -X POST "$BASE_URL" "${HEADERS[@]}" -d '{
  "jsonrpc": "2.0",
  "id": 5,
  "method": "tools/call",
  "params": { "name": "get_rules" }
}'
echo -e "\n"

echo "Done."

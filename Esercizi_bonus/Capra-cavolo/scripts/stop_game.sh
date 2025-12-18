#!/bin/bash
echo "🧹 Pulizia in corso..."
docker rm -f lupo capra cavolo contadino 2>/dev/null
docker network rm riva_sx riva_dx 2>/dev/null
echo "✅ Tutto pulito."
#!/usr/bin/env bash
set -euo pipefail

PLIST_SRC="dev.homelab.minikube-tunnel.plist"
PLIST_DST="/Library/LaunchDaemons/${PLIST_SRC}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "ERROR: must be run as root (sudo $0)" >&2
  exit 1
fi

cat > "${PLIST_DST}" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>dev.homelab.minikube-tunnel</string>

  <key>ProgramArguments</key>
  <array>
    <string>/opt/homebrew/bin/minikube</string>
    <string>tunnel</string>
    <string>--cleanup</string>
  </array>

  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key>
    <string>/Users/lucas</string>
  </dict>

  <key>RunAtLoad</key>
  <true/>

  <key>KeepAlive</key>
  <true/>

  <key>StandardOutPath</key>
  <string>/var/log/minikube-tunnel.log</string>

  <key>StandardErrorPath</key>
  <string>/var/log/minikube-tunnel.log</string>
</dict>
</plist>
EOF

chmod 644 "${PLIST_DST}"
chown root:wheel "${PLIST_DST}"

# Unload if already loaded (ignore error if not loaded)
launchctl unload "${PLIST_DST}" 2>/dev/null || true
launchctl load -w "${PLIST_DST}"

echo "Installed and loaded ${PLIST_DST}"
echo "Logs: /var/log/minikube-tunnel.log"
echo "Note: tunnel will fail/retry until minikube is running — that is expected."
echo ""
echo "IMPORTANT (qemu2 driver): LoadBalancer EXTERNAL-IP stays as the ClusterIP, not 127.0.0.1."
echo "Get the correct IP for /etc/hosts with:"
echo "  kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.clusterIP}'"
echo "Then: sudo sed -i '' 's/^127.0.0.1 .*local.*/<clusterIP> argo.homelab prom.homelab graf.homelab alman.homelab s3.homelab/' /etc/hosts"

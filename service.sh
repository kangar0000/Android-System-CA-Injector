#!/system/bin/sh
MODDIR=${0%/*}
# LOG_FILE="/cache/magisk.log"
LOG_FILE="/data/local/tmp/auto-ca.log"

exec > "$LOG_FILE" 2>&1
set -x

log -t auto-ca-inject "===== Starting CA injection ====="

USER_CERT_DIR="/data/misc/user/0/cacerts-added"
TMP_CERT_DIR="/data/local/tmp/tmp-ca-copy"
TARGET_DIR="/system/etc/security/cacerts"

sleep 50

[ -d "$USER_CERT_DIR" ] || {
    log -t auto-ca-inject "No user CA dir found"
    exit 0
}

USER_CERT_COUNT=$(ls "$USER_CERT_DIR" | wc -l)
[ "$USER_CERT_COUNT" -eq 0 ] && {
    log -t auto-ca-inject "No user certs to inject"
    exit 0
}

log -t auto-ca-inject "$USER_CERT_COUNT user cert(s) found"

mkdir -p -m 700 "$TMP_CERT_DIR"
cp /apex/com.android.conscrypt/cacerts/* "$TMP_CERT_DIR"

mount -t tmpfs tmpfs "$TARGET_DIR"

# Copy the existing certs back into the tmpfs, so we keep trusting them
mv "$TMP_CERT_DIR"/* "$TARGET_DIR"

cp "$USER_CERT_DIR"/* "$TARGET_DIR"

chown root:root "$TARGET_DIR"/*
chmod 644 "$TARGET_DIR"/*
chcon u:object_r:system_file:s0 "$TARGET_DIR"/*

# Inject into Zygote mount namespaces
ZYGOTE_PIDS="$(pidof zygote zygote64)"
for Z_PID in $ZYGOTE_PIDS; do
    [ -n "$Z_PID" ] && {
        log -t auto-ca-inject "Mounting to Zygote PID $Z_PID"
        nsenter --mount="/proc/$Z_PID/ns/mnt" -- \
            /bin/mount --bind "$TARGET_DIR" /apex/com.android.conscrypt/cacerts
    }
done

# Inject into all Zygote child app PIDs
APP_PIDS=$(echo "$ZYGOTE_PIDS" | xargs -n1 ps -o PID -P | grep -v PID)
for PID in $APP_PIDS; do
    log -t auto-ca-inject "Mounting to app PID $PID"
    nsenter --mount="/proc/$PID/ns/mnt" -- \
        /bin/mount --bind "$TARGET_DIR" /apex/com.android.conscrypt/cacerts &
done
wait

log -t auto-ca-inject "===== CA injection completed ====="

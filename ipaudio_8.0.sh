#!/bin/sh
#setup command=wget https://github.com/emil237/ipaudio/raw/refs/heads/main/ipaudio_8.0.sh -O - | /bin/sh

version=8.0
TEMPATH="/tmp"
PLUGINPATH="/usr/lib/enigma2/python/Plugins/Extensions/IPAudio"
CHECK="/tmp/check"
BINDIR="/usr/bin/"
ARMBIN="/tmp/ipaudio/bin/arm/gst1.0-ipaudio"
FFPPLAYERA="/tmp/ipaudio/bin/arm/ff4/ff-ipaudio"
MIPSBIN="/tmp/ipaudio/bin/mips/gst1.0-ipaudio"
FFPPLAYERM="/tmp/ipaudio/bin/mips/ff4/ff-ipaudio"
IPAUDIO="/tmp/ipaudio/usr/*"
PLAYLIST="/tmp/ipaudio/etc/ipaudio.json"
ASOUND="/tmp/ipaudio/etc/asound.conf"

uname -m > "$CHECK" 2>/dev/null || true

killall -9 gst1.0-ipaudio 2>/dev/null || true
killall -9 ff-ipaudio 2>/dev/null || true

if [ -f /var/lib/dpkg/status ]; then
    STATUS="/var/lib/dpkg/status"
    OS="DreamOS"
else
    STATUS="/var/lib/opkg/status"
    OS="Opensource"
fi

echo "Checking depends (non-blocking)..."

check_dep() {
    dep="$1"
    if grep -q "$dep" "$STATUS" 2>/dev/null; then
        echo "[OK] $dep installed"
        return 0
    else
        echo "[MISSING] $dep"
        return 1
    fi
}

install_dep() {
    pkg="$1"
    echo "Installing $pkg ..."
    if [ "$OS" = "DreamOS" ]; then
        apt-get install -y "$pkg" 2>/dev/null || true
    else
        opkg install "$pkg" 2>/dev/null || true
    fi
}

if [ "$OS" = "DreamOS" ]; then
    apt-get update 2>/dev/null || true
else
    opkg update 2>/dev/null || true
fi

DEPS="
gstreamer1.0-plugins-base-volume
gstreamer1.0-plugins-good-ossaudio
gstreamer1.0-plugins-good-mpg123
gstreamer1.0-plugins-good-equalizer
ffmpeg
alsa-plugins
"

for dep in $DEPS; do
    check_dep "$dep" || install_dep "$dep"
done

echo "Dependency check completed (script will continue regardless)."

ffmpeg_version=$(ffmpeg -version 2>/dev/null | sed -n "s/.* version \([^ ]*\).*/\1/p;" || true)
major=$(echo "$ffmpeg_version" | cut -d. -f1)

if [ "$major" -ge 5 ] 2>/dev/null; then
    echo "[ FFmpeg 5 detected ]"
    FFPPLAYERA="/tmp/ipaudio/bin/arm/ff-ipaudio"
    FFPPLAYERM="/tmp/ipaudio/bin/mips/ff-ipaudio"
else
    echo "[ Warning ] FFmpeg < 5 detected — continuing anyway"
fi

rm -rf "$PLUGINPATH" 2>/dev/null || true
rm -f /usr/bin/gst1.0-ipaudio 2>/dev/null || true
rm -f /usr/bin/ff-ipaudio 2>/dev/null || true

cd "$TEMPATH" 2>/dev/null || true
wget -q "https://github.com/emil237/ipaudio/raw/refs/heads/main/ipaudio_8.0.tar.gz" 2>/dev/null || true
tar -xzf ipaudio_8.0.tar.gz -C / 2>/dev/null || true
rm -f ipaudio_8.0.tar.gz 2>/dev/null || true

CPU=$(cat "$CHECK" 2>/dev/null || echo unknown)

if echo "$CPU" | grep -qi "mips"; then
    echo "[ MIPS detected ]"
    cp -a "$MIPSBIN" "$BINDIR" 2>/dev/null || true
    cp -a "$FFPPLAYERM" "$BINDIR" 2>/dev/null || true
elif echo "$CPU" | grep -qi "armv7l"; then
    echo "[ ARMv7 detected ]"
    cp -a "$ARMBIN" "$BINDIR" 2>/dev/null || true
    cp -a "$FFPPLAYERA" "$BINDIR" 2>/dev/null || true
else
    echo "[ Warning ] Unsupported CPU — continuing anyway"
fi

chmod 0775 /usr/bin/gst1.0-ipaudio 2>/dev/null || true
chmod 0775 /usr/bin/ff-ipaudio 2>/dev/null || true

mkdir -p /etc/enigma2/ipaudio 2>/dev/null || true

if [ ! -f /etc/enigma2/ipaudio/ipaudio.json ]; then
    cp -a "$PLAYLIST" /etc/enigma2/ipaudio/ 2>/dev/null || true
fi

if [ ! -f /etc/asound.conf ]; then
    cp -a "$ASOUND" /etc 2>/dev/null || true
fi

rm -rf /tmp/ipaudio 2>/dev/null || true
rm -f "$CHECK" 2>/dev/null || true

echo ""
echo "#########################################################"
echo "#      IPAudio $version INSTALLED (NON-STOP MODE)       #"
echo "#########################################################"

if [ "$OS" = "DreamOS" ]; then
    systemctl restart enigma2 2>/dev/null || true
else
    killall -9 enigma2 2>/dev/null || true
    sleep 2
    systemctl restart enigma2 2>/dev/null || \
    restart enigma2 2>/dev/null || \
    /etc/init.d/enigma2 restart 2>/dev/null || true
fi

exit 0



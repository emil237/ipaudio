#!/bin/sh
#setup command=wget https://github.com/emil237/ipaudio/raw/refs/heads/main/ipaudio_8.0.sh -O - | /bin/sh

version=8.0
TEMPATH='/tmp'
PLUGINPATH='/usr/lib/enigma2/python/Plugins/Extensions/IPAudio'
CHECK='/tmp/check'
BINDIR='/usr/bin/'
ARMBIN='/tmp/ipaudio/bin/arm/gst1.0-ipaudio'
FFPPLAYERA='/tmp/ipaudio/bin/arm/ff4/ff-ipaudio'
MIPSBIN='/tmp/ipaudio/bin/mips/gst1.0-ipaudio'
FFPPLAYERM='/tmp/ipaudio/bin/mips/ff4/ff-ipaudio'
IPAUDIO='/tmp/ipaudio/usr/*'
PLAYLIST='/tmp/ipaudio/etc/ipaudio.json'
ASOUND='/tmp/ipaudio/etc/asound.conf'

uname -m > $CHECK

# kill players
killall -9 gst1.0-ipaudio 2>/dev/null
killall -9 ff-ipaudio 2>/dev/null

# check system type
if [ -f /var/lib/dpkg/status ]; then
    STATUS='/var/lib/dpkg/status'
    OS='DreamOS'
else
    STATUS='/var/lib/opkg/status'
    OS='Opensource'
fi

echo "Checking depends (non-blocking)..."

check_dep() {
    dep=$1
    if grep -q "$dep" "$STATUS"; then
        echo "[OK] $dep installed"
        return 0
    else
        echo "[MISSING] $dep"
        return 1
    fi
}

install_dep() {
    pkg=$1
    echo "Installing $pkg ..."
    if [ "$OS" = "DreamOS" ]; then
        apt-get install -y $pkg 2>/dev/null || true
    else
        opkg install $pkg 2>/dev/null || true
    fi
}

# update feeds (non-blocking)
if [ "$OS" = "DreamOS" ]; then
    apt-get update 2>/dev/null || true
else
    opkg update 2>/dev/null || true
fi

# list of deps
DEPS="
gstreamer1.0-plugins-base-volume
gstreamer1.0-plugins-good-ossaudio
gstreamer1.0-plugins-good-mpg123
gstreamer1.0-plugins-good-equalizer
ffmpeg
alsa-plugins
"

# try installing missing deps without stopping script
for dep in $DEPS; do
    check_dep "$dep" || install_dep "$dep"
done

echo "Dependency check completed (script will continue regardless)."

# ffmpeg version check (non-blocking)
ffmpeg_version=$(ffmpeg -version 2>/dev/null | sed -n "s/.* version \([^ ]*\).*/\1/p;")
IFS='.' read -r -a version_array <<< "$ffmpeg_version"

if [[ ${version_array[0]} -ge 5 ]]; then
    echo "[ FFmpeg 5 detected ]"
    FFPPLAYERA="/tmp/ipaudio/bin/arm/ff-ipaudio"
    FFPPLAYERM="/tmp/ipaudio/bin/mips/ff-ipaudio"
else
    echo "[ Warning ] FFmpeg < 5 detected — continuing anyway"
fi

# remove old version
rm -rf $PLUGINPATH 2>/dev/null
rm -f /usr/bin/gst1.0-ipaudio 2>/dev/null
rm -f /usr/bin/ff-ipaudio 2>/dev/null

# download plugin
cd $TEMPATH
wget -q "https://github.com/emil237/ipaudio/raw/refs/heads/main/ipaudio_8.0.tar.gz" || true
tar -xzf ipaudio_8.0.tar.gz -C / 2>/dev/null || true
rm -f ipaudio_8.0.tar.gz

# CPU architecture
CHECK_CONTENT=$(cat $CHECK)

if echo "$CHECK_CONTENT" | grep -qi 'mips'; then
    echo "[ MIPS detected ]"
    cp -a $MIPSBIN $BINDIR 2>/dev/null
    cp -a $FFPPLAYERM $BINDIR 2>/dev/null
elif echo "$CHECK_CONTENT" | grep -qi 'armv7l'; then
    echo "[ ARMv7l detected ]"
    cp -a $ARMBIN $BINDIR 2>/dev/null
    cp -a $FFPPLAYERA $BINDIR 2>/dev/null
else
    echo "[ Warning ] Unsupported CPU — continuing anyway"
fi

chmod 0775 /usr/bin/gst1.0-ipaudio 2>/dev/null
chmod 0775 /usr/bin/ff-ipaudio 2>/dev/null

mkdir -p /etc/enigma2/ipaudio

[ ! -f /etc/enigma2/ipaudio/ipaudio.json ] && cp -a $PLAYLIST /etc/enigma2/ipaudio/ 2>/dev/null
[ ! -f /etc/asound.conf ] && cp -a $ASOUND /etc 2>/dev/null

rm -r /tmp/ipaudio 2>/dev/null
rm -f $CHECK 2>/dev/null

echo ""
echo "#########################################################"
echo "#      IPAudio $version INSTALLED (NON-STOP MODE)       #"
echo "#########################################################"

if [ "$OS" = "DreamOS" ]; then
    systemctl restart enigma2 2>/dev/null || true
else
    killall -9 enigma2 2>/dev/null
    sleep 2
    systemctl restart enigma2 2>/dev/null || restart enigma2 2>/dev/null || /etc/init.d/enigma2 restart 2>/dev/null || true
fi

exit 0


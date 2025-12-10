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
uname -m >$CHECK

# kill player if in use
ps_out=$(ps -ef | grep gst1.0-ipaudio | grep -v 'grep' | grep -v $0)
result=$(echo $ps_out | grep "gst1.0-ipaudio")
if [[ "$result" != "" ]]; then
    killall -9 gst1.0-ipaudio
fi

ps_out=$(ps -ef | grep ff-ipaudio | grep -v 'grep' | grep -v $0)
result=$(echo $ps_out | grep "ff-ipaudio")
if [[ "$result" != "" ]]; then
    killall -9 ff-ipaudio
fi

# check depends packages
if [ -f /var/lib/dpkg/status ]; then
    STATUS='/var/lib/dpkg/status'
    OS='DreamOS'
else
    STATUS='/var/lib/opkg/status'
    OS='Opensource'
fi

if grep -q 'gstreamer1.0-plugins-base-volume' $STATUS; then
    gstVol='Installed'
fi

if grep -q 'gstreamer1.0-plugins-good-ossaudio' $STATUS; then
    gstOss='Installed'
fi

if grep -q 'gstreamer1.0-plugins-good-mpg123' $STATUS; then
    gstMp3='Installed'
fi

if grep -q 'gstreamer1.0-plugins-good-equalizer' $STATUS; then
    equalizer='Installed'
fi

if grep -q 'ffmpeg' $STATUS; then
    ffmpeg='Installed'
fi

if grep -q 'alsa-plugins' $STATUS; then
    alsaPlug='Installed'
fi

if [ "$gstVol" = "Installed" ] && [ "$gstOss" = "Installed" ] && [ "$gstMp3" = "Installed" ] && [ "$equalizer" = "Installed" ] && [ "$ffmpeg" = "Installed" ] && [ "$alsaPlug" = "Installed" ]; then
    echo ""
else
    if [ $OS = "DreamOS" ]; then
        echo "=========================================================================="
        echo "Some Depends Need to Be downloaded From Feeds ...."
        echo "=========================================================================="
        echo "apt update ..."
        echo "========================================================================"
        apt-get update
        echo " Downloading gstreamer1.0-plugins-base-volume ......"
        apt-get install gstreamer1.0-plugins-base-volume -y
        echo "========================================================================"
        echo " Downloading gstreamer1.0-plugins-good-ossaudio ......"
        apt-get install gstreamer1.0-plugins-good-ossaudio -y
        echo "========================================================================"
        echo " Downloading gstreamer1.0-plugins-good-mpg123 ......"
        apt-get install gstreamer1.0-plugins-good-mpg123 -y
        echo "========================================================================"
        echo " Downloading gstreamer1.0-plugins-good-equalizer ......"
        apt-get install gstreamer1.0-plugins-good-equalizer -y
        echo "========================================================================"
        echo " Downloading ffmpeg ......"
        apt-get install ffmpeg -y
        echo "========================================================================"
        echo " Downloading alsa-plugins ......"
        apt-get install alsa-plugins -y
        echo "========================================================================"
    else
        echo "=========================================================================="
        echo "Some Depends Need to Be downloaded From Feeds ...."
        echo "=========================================================================="
        echo "Opkg Update ..."
        echo "========================================================================"
        opkg update
        echo " Downloading gstreamer1.0-plugins-base-volume ......"
        opkg install gstreamer1.0-plugins-base-volume
        echo "========================================================================"
        echo " Downloading gstreamer1.0-plugins-good-ossaudio ......"
        opkg install gstreamer1.0-plugins-good-ossaudio
        echo "========================================================================"
        echo " Downloading gstreamer1.0-plugins-good-mpg123 ......"
        opkg install gstreamer1.0-plugins-good-mpg123
        echo "========================================================================"
        echo " Downloading gstreamer1.0-plugins-good-equalizer ......"
        opkg install gstreamer1.0-plugins-good-equalizer
        echo "========================================================================"
        echo " Downloading ffmpeg ......"
        opkg install ffmpeg
        echo "========================================================================"
        echo " Downloading alsa-plugins ......"
        opkg install alsa-plugins
        echo "========================================================================"
    fi
fi

if grep -q 'gstreamer1.0-plugins-base-volume' $STATUS; then
    echo ""
else
    echo "#########################################################"
    echo "#  gstreamer1.0-plugins-base-volume Not found in feed   #"
    echo "#         IPaudio has not been installed                #"
    echo "#########################################################"
    rm -r /tmp/ipaudio >/dev/null 2>&1
    rm -f $CHECK >/dev/null 2>&1
    exit 1
fi

if grep -q 'alsa-plugins' $STATUS; then
    echo ""
else
    echo "#########################################################"
    echo "#         alsa-plugins Not found in feed                #"
    echo "#         IPaudio has not been installed                #"
    echo "#########################################################"
    rm -r /tmp/ipaudio >/dev/null 2>&1
    rm -f $CHECK >/dev/null 2>&1
    exit 1
fi

if grep -q 'ffmpeg' $STATUS; then
    echo ""
else
    echo "#########################################################"
    echo "#            FFmpeg Not found in feed                   #"
    echo "#         IPaudio has not been installed                #"
    echo "#########################################################"
    rm -r /tmp/ipaudio >/dev/null 2>&1
    rm -f $CHECK >/dev/null 2>&1
    exit 1
fi

ffmpeg_version=$(ffmpeg -version 2>&1 | sed -n "s/.* version \([^ ]*\).*/\1/p;")
IFS='.' read -r -a version_array <<<"$ffmpeg_version"
if [[ ${version_array[0]} -ge 5 ]]; then
    echo "[ FFmpeg 5 detected ]"
    FFPPLAYERA="/tmp/ipaudio/bin/arm/ff-ipaudio"
    FFPPLAYERM="/tmp/ipaudio/bin/mips/ff-ipaudio"
elif [[ "$ffmpeg_version" =~ ^n[4-9] ]]; then
    echo "[ FFmpeg 4 detected ]"
else
    echo "#########################################################"
    echo "#          FFmpeg version is below 4.x.x                #"
    echo "#         IPaudio has not been installed                #"
    echo "#########################################################"
    rm -r /tmp/ipaudio >/dev/null 2>&1
    rm -f $CHECK >/dev/null 2>&1
    exit 1
fi

# remove old version
rm -rf $PLUGINPATH >/dev/null 2>&1
rm -f /usr/bin/gst1.0-ipaudio >/dev/null 2>&1
rm -f /usr/bin/ff-ipaudio >/dev/null 2>&1

cd $TEMPATH
set -e
wget -q "https://github.com/emil237/ipaudio/raw/refs/heads/main/ipaudio_8.0.tar.gz"

tar -xzf ipaudio_8.0.tar.gz -C /
set +e
rm -f ipaudio_8.0.tar.gz
cd ..

# تصحيح أمر grep هنا - إزالة cat الزائد
CHECK_CONTENT=$(cat $CHECK)
if echo "$CHECK_CONTENT" | grep -qi 'mips'; then
    echo "[ Your device is MIPS ]"
    cp -a $MIPSBIN $BINDIR
    cp -a $FFPPLAYERM $BINDIR
    chmod 0775 /usr/bin/gst1.0-ipaudio
    chmod 0775 /usr/bin/ff-ipaudio
elif echo "$CHECK_CONTENT" | grep -qi 'armv7l'; then
    echo "[ Your device is armv7l ]"
    cp -a $ARMBIN $BINDIR
    cp -a $FFPPLAYERA $BINDIR
    chmod 0775 /usr/bin/gst1.0-ipaudio
    chmod 0775 /usr/bin/ff-ipaudio
else
    echo "###############################"
    echo "## Your stb is not supported ##"
    echo "###############################"
    rm -r /tmp/ipaudio
    rm -f $CHECK
    exit 1
fi

# إنشاء مجلد إذا لم يكن موجوداً
mkdir -p /etc/enigma2/ipaudio

if [ ! -f /etc/enigma2/ipaudio/ipaudio.json ]; then
    cp -a $PLAYLIST /etc/enigma2/ipaudio/
fi

if [ ! -f /etc/asound.conf ]; then
    echo "Sending asound.conf to /etc"
    cp -a $ASOUND /etc
fi

rm -r /tmp/ipaudio
rm -f $CHECK

echo ""
sync
echo "#########################################################"
echo "#          IPAudio $version INSTALLED SUCCESSFULLY      #"
echo "#                BY ZIKO - support on                   #"
echo "#########################################################"
echo "#           your Device will RESTART Now                #"
echo "#########################################################"

# إعادة تشغيل enigma2
if [ "$OS" = 'DreamOS' ]; then
    systemctl restart enigma2
else
    killall -9 enigma2
    sleep 2
    systemctl restart enigma2 2>/dev/null || restart enigma2 2>/dev/null || /etc/init.d/enigma2 restart 2>/dev/null
fi

exit 0

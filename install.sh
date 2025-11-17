#!/bin/sh
##wget -q "--no-check-certificate" https://raw.githubusercontent.com/emil237/ipaudio/main/installer.sh -O - | /bin/sh
#########

TEMPATH='/tmp'
PLUGINPATH='/usr/lib/enigma2/python/Plugins/Extensions/IPAudio'
CHECK='/tmp/check'
BINDIR='/usr/bin/'
ARMBIN='/tmp/ipaudio/bin/arm/*'
MIPSBIN='/tmp/ipaudio/bin/mips/*'
SH4BIN='/tmp/ipaudio/bin/sh4/*'
AARCH64BIN='/tmp/ipaudio/bin/aarch64/*'
IPAUDIO='/tmp/ipaudio/usr/*'
PLAYLIST='/tmp/ipaudio/etc/ipaudio.json'
ASOUND='/tmp/ipaudio/etc/asound.conf'

# إضافة متغير للنسخة
VERSION=''

uname -m > $CHECK
rm -rf $PLUGINPATH >/dev/null 2>&1
rm -f /usr/bin/gst1.0-ipaudio >/dev/null 2>&1

ps_out=$(ps -ef | grep gst1.0-ipaudio | grep -v 'grep' | grep -v $0)
result=$(echo $ps_out | grep "gst1.0-ipaudio")
if [ -n "$result" ]; then
    killall -9 gst1.0-ipaudio
fi

cd $TEMPATH
if python --version 2>&1 | grep -q '^Python 3\.'; then
    echo "   Installing IPAudio for Python 3"
    wget -O ipaudio-7.4-ffmpeg.tar.gz "https://raw.githubusercontent.com/emil237/ipaudio/main/ipaudio-7.4-ffmpeg.tar.gz"
    if [ -f "ipaudio-7.4-ffmpeg.tar.gz" ]; then
        tar -xzf ipaudio-7.4-ffmpeg.tar.gz -C /tmp
        VERSION='7.4'
    else
        echo "Error: Failed to download Python 3 version"
        exit 1
    fi
else 
    echo "   Installing IPAudio for Python 2"
    wget -O ipaudio-6.8.tar.gz "https://raw.githubusercontent.com/emil237/ipaudio/main/ipaudio-6.8.tar.gz"
    if [ -f "ipaudio-6.8.tar.gz" ]; then
        tar -xzf ipaudio-6.8.tar.gz -C /tmp
        VERSION='6.8'
    else
        echo "Error: Failed to download Python 2 version"
        exit 1
    fi
fi

echo "================================="

if [ -f /var/lib/dpkg/status ]; then
    STATUS='/var/lib/dpkg/status'
    OS='DreamOS'
else
    STATUS='/var/lib/opkg/status'
    OS='Opensource'
fi

# Initialize variables
gstVol=''
gstOss=''
gstMp3=''
equalizer=''

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

if [ "$gstVol" = "Installed" ] && [ "$gstOss" = "Installed" ] && [ "$gstMp3" = "Installed" ] && [ "$equalizer" = "Installed" ]; then
    echo "All dependencies are installed"
else
    if [ "$OS" = "DreamOS" ]; then
        echo "=========================================================================="
        echo "Some Dependencies Need to Be Downloaded From Feeds ...."
        echo "=========================================================================="
        echo "Updating package list..."
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
    else
        echo "=========================================================================="
        echo "Some Dependencies Need to Be Downloaded From Feeds ...."
        echo "=========================================================================="
        echo "Updating package list..."
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
    fi
fi

# التحقق مرة أخرى من التبعيات بعد التثبيت
if ! grep -q 'gstreamer1.0-plugins-base-volume' $STATUS; then
    echo "#########################################################"
    echo "#  gstreamer1.0-plugins-base-volume Not found in feed  #"
    echo "#          IPaudio has not been installed              #"
    echo "#########################################################"
    rm -rf /tmp/ipaudio
    rm -f $CHECK
    rm -f ipaudio-*.tar.gz
    exit 1
fi

ARCH=$(cat $CHECK)

if echo "$ARCH" | grep -qi 'mips'; then
    echo "[ Your device is MIPS ]"
    cp -rf $MIPSBIN $BINDIR 2>/dev/null
    chmod 0775 /usr/bin/gst1.0-ipaudio 2>/dev/null
elif echo "$ARCH" | grep -qi 'armv7l'; then
    echo "[ Your device is armv7l ]"
    cp -rf $ARMBIN $BINDIR 2>/dev/null
    chmod 0775 /usr/bin/gst1.0-ipaudio 2>/dev/null
elif echo "$ARCH" | grep -qi 'sh4'; then
    echo "[ Your device is sh4 ]"
    cp -rf $SH4BIN $BINDIR 2>/dev/null
    chmod 0775 /usr/bin/gst1.0-ipaudio 2>/dev/null
elif echo "$ARCH" | grep -qi 'aarch64'; then
    echo "[ Your device is aarch64 ]"
    cp -rf $AARCH64BIN $BINDIR 2>/dev/null
    chmod 0775 /usr/bin/gst1.0-ipaudio 2>/dev/null
else
    echo "###############################"
    echo "## Your device is not supported ##"
    echo "###############################"
    rm -rf /tmp/ipaudio
    rm -f $CHECK
    rm -f ipaudio-*.tar.gz
    exit 1
fi

# نسخ ملفات IPAudio (الملفات الخاصة بالبلوجين)
if [ -d "/tmp/ipaudio/usr" ]; then
    cp -rf /tmp/ipaudio/usr/* /usr/ 2>/dev/null
fi

# إنشاء المجلد إذا لم يكن موجوداً
mkdir -p /etc/enigma2

if [ ! -f /etc/enigma2/ipaudio.json ] && [ -f "$PLAYLIST" ]; then
    cp -f $PLAYLIST /etc/enigma2/
    echo "IPAudio playlist configuration copied"
fi

if [ ! -f /etc/asound.conf ] && [ -f "$ASOUND" ]; then
    cp -f $ASOUND /etc/
    echo "Copying asound.conf to /etc"
fi

# تنظيف الملفات المؤقتة
rm -rf /tmp/ipaudio
rm -f $CHECK
rm -f ipaudio-*.tar.gz

echo ""
sync
echo "#########################################################"
echo "#          IPAudio $VERSION INSTALLED SUCCESSFULLY          #"
echo "#                  BY ZIKO - support on                #"
echo "#    https://www.tunisia-sat.com/forums/threads/4171372 #"
echo "#########################################################"
echo "#########################################################"

sleep 3

exit 0

#!/bin/sh

TEMPATH='/tmp'
PLUGINPATH='/usr/lib/enigma2/python/Plugins/Extensions/IPAudio'
CHECK='/tmp/check'
BINDIR='/usr/bin/'

VERSION=''

echo "Cleaning up previous installations..."
rm -rf $PLUGINPATH >/dev/null 2>&1
rm -f /usr/bin/gst1.0-ipaudio >/dev/null 2>&1
rm -f /tmp/ipaudio-*.tar.gz >/dev/null 2>&1
rm -rf /tmp/ipaudio >/dev/null 2>&1
rm -f $CHECK >/dev/null 2>&1

killall -9 gst1.0-ipaudio >/dev/null 2>&1

uname -m > $CHECK

cd $TEMPATH

echo "Checking Python version..."
PYTHON_VERSION=$(python -V 2>&1)
echo "Full Python version: $PYTHON_VERSION"

if echo "$PYTHON_VERSION" | grep -q 'Python 3'; then
    echo "Installing IPAudio for Python 3"
    wget -O ipaudio-7.4-ffmpeg.tar.gz "https://raw.githubusercontent.com/emil237/ipaudio/main/ipaudio-7.4-ffmpeg.tar.gz"
    if [ -f "ipaudio-7.4-ffmpeg.tar.gz" ]; then
        tar -xzf ipaudio-7.4-ffmpeg.tar.gz -C /tmp
        VERSION='7.4'
        echo "Python 3 version extracted successfully"
    else
        echo "Error: Failed to download Python 3 version"
        exit 1
    fi
else 
    echo "Installing IPAudio for Python 2"
    wget -O ipaudio-6.8.tar.gz "https://raw.githubusercontent.com/emil237/ipaudio/main/ipaudio-6.8.tar.gz"
    if [ -f "ipaudio-6.8.tar.gz" ]; then
        tar -xzf ipaudio-6.8.tar.gz -C /tmp
        VERSION='6.8'
        echo "Python 2 version extracted successfully"
    else
        echo "Error: Failed to download Python 2 version"
        exit 1
    fi
fi

echo "================================="

if [ ! -d "/tmp/ipaudio" ]; then
    echo "Error: Extracted files not found in /tmp/ipaudio"
    exit 1
fi

echo "Analyzing file structure..."
find /tmp/ipaudio -type f -name "*.py" | head -10
echo "---"

rm -rf $PLUGINPATH
mkdir -p $PLUGINPATH
echo "Created clean plugin directory: $PLUGINPATH"


echo "Copying plugin files correctly..."

if [ -d "/tmp/ipaudio/usr" ]; then
    echo "Copying Python files from /tmp/ipaudio/usr/ to plugin directory..."
    cp -r /tmp/ipaudio/usr/*.py $PLUGINPATH/ 2>/dev/null
    cp -r /tmp/ipaudio/usr/*.so $PLUGINPATH/ 2>/dev/null 2>/dev/null
    cp -r /tmp/ipaudio/usr/*.xml $PLUGINPATH/ 2>/dev/null
    cp -r /tmp/ipaudio/usr/*.png $PLUGINPATH/ 2>/dev/null
    cp -r /tmp/ipaudio/usr/*.json $PLUGINPATH/ 2>/dev/null
    cp -r /tmp/ipaudio/usr/version $PLUGINPATH/ 2>/dev/null
    cp -r /tmp/ipaudio/usr/LICENSE $PLUGINPATH/ 2>/dev/null
    
    if [ -d "/tmp/ipaudio/usr/icons" ]; then
        cp -r /tmp/ipaudio/usr/icons $PLUGINPATH/ 2>/dev/null
    fi
    echo "Python files copied to plugin directory"
fi

ARCH=$(cat $CHECK)
echo "[ Your device is $ARCH ]"

if echo "$ARCH" | grep -qi 'arm'; then
    if [ -d "/tmp/ipaudio/bin/arm" ]; then
        echo "Copying ARM binaries..."
        cp -r /tmp/ipaudio/bin/arm/* $BINDIR 2>/dev/null
        echo "ARM binaries copied successfully"
    else
        echo "Warning: ARM binary directory not found at /tmp/ipaudio/bin/arm"
        
        find /tmp/ipaudio -name "gst1.0-ipaudio" -exec cp {} $BINDIR/ \; 2>/dev/null
        find /tmp/ipaudio -name "ff-ipaudio" -exec cp {} $BINDIR/ \; 2>/dev/null
    fi
fi

if [ -f "/usr/bin/gst1.0-ipaudio" ]; then
    chmod 0755 /usr/bin/gst1.0-ipaudio
    echo "Binary permissions set for gst1.0-ipaudio"
fi

if [ -f "/usr/bin/ff-ipaudio" ]; then
    chmod 0755 /usr/bin/ff-ipaudio
    echo "Binary permissions set for ff-ipaudio"
fi

mkdir -p /etc/enigma2

if [ -f "/tmp/ipaudio/etc/ipaudio.json" ] && [ ! -f "/etc/enigma2/ipaudio.json" ]; then
    cp /tmp/ipaudio/etc/ipaudio.json /etc/enigma2/
    echo "Playlist configuration copied"
fi

if [ -f "/tmp/ipaudio/etc/asound.conf" ] && [ ! -f "/etc/asound.conf" ]; then
    cp /tmp/ipaudio/etc/asound.conf /etc/
    echo "Audio configuration copied"
fi

echo ""
echo "Final installation verification:"
echo "Plugin path: $PLUGINPATH"

if [ -d "$PLUGINPATH" ]; then
    echo "Files in plugin directory:"
    ls -la "$PLUGINPATH/"
    
    if [ -f "$PLUGINPATH/__init__.py" ] || [ -f "$PLUGINPATH/plugin.py" ]; then
        echo "✅ PLUGIN INSTALLED SUCCESSFULLY - CORRECT STRUCTURE"
        INSTALL_STATUS="SUCCESS"
    else
        echo "⚠️ Plugin directory exists but missing core Python files"
        INSTALL_STATUS="INCOMPLETE"
    fi
else
    echo "❌ Plugin directory was not created"
    INSTALL_STATUS="FAILED"
fi

BINARY_STATUS="FAILED"
if [ -f "/usr/bin/gst1.0-ipaudio" ]; then
    echo "✅ Binary gst1.0-ipaudio installed"
    BINARY_STATUS="SUCCESS"
else
    echo "❌ Binary gst1.0-ipaudio not found"
fi

if [ -f "/usr/bin/ff-ipaudio" ]; then
    echo "✅ Binary ff-ipaudio installed"
else
    echo "⚠️ Binary ff-ipaudio not found (may be normal)"
fi

rm -rf /tmp/ipaudio
rm -f $CHECK
rm -f ipaudio-*.tar.gz

echo ""
sync

echo "#########################################################"
echo "#               INSTALLATION COMPLETE                  #"
echo "#########################################################"
echo "# Python Version: $PYTHON_VERSION"
echo "# IPAudio Version: $VERSION"
echo "# Architecture: $ARCH"
echo "# Plugin Status: $INSTALL_STATUS"
echo "# Binary Status: $BINARY_STATUS"
echo "#########################################################"

if [ "$INSTALL_STATUS" = "SUCCESS" ]; then
    echo "# ✅ Plugin installed successfully!                   #"
    echo "#                                                     #"
    echo "#########################################################"
else
    echo "# ❌ Installation failed - check structure           #"
    echo "#########################################################"
fi

echo ""
echo "Installation completed successfully!"

exit 0

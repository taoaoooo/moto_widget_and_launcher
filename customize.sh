﻿ui_print " "

# boot mode
if [ "$BOOTMODE" != true ]; then
  abort "- Please flash via Magisk Manager only!"
fi

# info
MODVER=`grep_prop version $MODPATH/module.prop`
MODVERCODE=`grep_prop versionCode $MODPATH/module.prop`
ui_print " ID=$MODID"
ui_print " Version=$MODVER"
ui_print " VersionCode=$MODVERCODE"
ui_print " MagiskVersion=$MAGISK_VER"
ui_print " MagiskVersionCode=$MAGISK_VER_CODE"
ui_print " "

# sdk
NUM=29
SDK29=29
#ui_print "$MODPATH $MODDIR"


if [  $API -lt $NUM ]; then
  ui_print "! 不支持的SDK $API."
  ui_print "  请升级你的安卓版本"
  ui_print "  使用此模块需要安卓10 SDK $NUM 及以上  "
  abort
elif [ $API -ge $SDK29 ]; then
  ui_print " 你的SDK版本 $API 符合要求"
  ui_print " "
  cp -rf $MODPATH/launcher/*  $MODPATH/system || echo "error code:30 lines"
  rm -rf $MODPATH/system/priv-app/Launcher3QuickStep/Launcher3QuickStep.apk || echo "error code:29 lines"
  rm -rf $MODPATH/system/product/overlay/Launcher3QuickStepRecentsOverlay/Launcher3QuickStepRecentsOverlay.apk || echo "error code:34 lines"
  find $MODPATH/system/etc -type f -name "*com.motorola.launcher3*" -exec rm -rf {} \;
  ui_print " "
  ui_print " 已自动安装此模块 重启生效"
  rm -rf $MODPATH/launcher
  REPLACE_EXAMPLE="
    /system/app/Youtube
    /system/priv-app/SystemUI
    /system/priv-app/Settings
    /system/framework
    "

    # Construct your own list here
  REPLACE="
    /system/priv-app/AsusLauncherDev
    /system/priv-app/Lawnchair
    /system/priv-app/NexusLauncherPrebuilt
    /system/system_ext/priv-app/Launcher3QuickStep
    /system/product/priv-app/ParanoidQuickStep
    /system/product/priv-app/ShadyQuickStep
    /system/product/priv-app/TrebuchetQuickStep
    /system/system_ext/priv-app/DerpLauncherQuickStep
    /system/system_ext/priv-app/NexusLauncherRelease
    /system/system_ext/priv-app/TrebuchetQuickStep
    /system/system_ext/priv-app/Lawnchair
    "
    

    ##########################################################################################
    # Permissions
    ##########################################################################################

    set_permissions() {
        : # Remove this if adding to this function

        # Note that all files/folders in magisk module directory have the $MODPATH prefix - keep this prefix on all of your files/folders
        # Some examples:
  
        # For directories (includes files in them):
        # set_perm_recursive  <dirname>                <owner> <group> <dirpermission> <filepermission> <contexts> (default: u:object_r:system_file:s0)
  
        # set_perm_recursive $MODPATH/system/lib 0 0 0755 0644
        # set_perm_recursive $MODPATH/system/vendor/lib/soundfx 0 0 0755 0644

        # For files (not in directories taken care of above)
        # set_perm  <filename>                         <owner> <group> <permission> <contexts> (default: u:object_r:system_file:s0)
  
        # set_perm $MODPATH/system/lib/libart.so 0 0 0644
        # set_perm /data/local/tmp/file.txt 0 0 644
    }

else
  ui_print " 你的SDK版本是 $API"
  #ui_print " 已自动安装 moto 小部件和moto launcher"
  rm -rf $MODPATH/launcher

  ui_print " 出现未知错误"
  abort

fi

# 覆盖安装时处理
rm -f /data/adb/modules/moto_widget_and_launcher/debug.log
#rm -rf /system/system_ext/priv-app/DerpLauncherQuickStep

# sepolicy.rule
if [ "$BOOTMODE" != true ]; then
  mount -o rw -t auto /dev/block/bootdevice/by-name/persist /persist
  mount -o rw -t auto /dev/block/bootdevice/by-name/metadata /metadata
fi
FILE=$MODPATH/sepolicy.sh
DES=$MODPATH/sepolicy.rule
if [ -f $FILE ] && ! getprop | grep -Eq "sepolicy.sh\]: \[1"; then
  mv -f $FILE $DES
  sed -i 's/magiskpolicy --live "//g' $DES
  sed -i 's/"//g' $DES
fi

# function
conflict() {
for NAMES in $NAME; do
  DIR=/data/adb/modules_update/$NAMES
  if [ -f $DIR/uninstall.sh ]; then
    sh $DIR/uninstall.sh
  fi
  rm -rf $DIR
  DIR=/data/adb/modules/$NAMES
  rm -f $DIR/update
  touch $DIR/remove
  FILE=/data/adb/modules/$NAMES/uninstall.sh
  if [ -f $FILE ]; then
    sh $FILE
    rm -f $FILE
  fi
  rm -rf /metadata/magisk/$NAMES
  rm -rf /mnt/vendor/persist/magisk/$NAMES
  rm -rf /persist/magisk/$NAMES
  rm -rf /data/unencrypted/magisk/$NAMES
  rm -rf /cache/magisk/$NAMES
done
}

# conflict
NAME=MotoWidget
conflict

# recents
if getprop | grep -Eq "moto.recents\]: \[1"; then
  ui_print "- $MODNAME recents provider will be activated"
  NAME=quickstepswitcher
  conflict
  ui_print " "
else
  rm -rf $MODPATH/system/product/overlay/Launcher3QuickStepRecentsOverlay
fi

# cleaning
ui_print "- Cleaning..."
APP="`ls $MODPATH/system/priv-app` `ls $MODPATH/system/app` `ls $MODPATH/system/system_ext/app`"
PKG="com.motorola.launcher3
     com.motorola.timeweatherwidget
     com.motorola.motosignature.app
     com.motorola.android.providers.settings
     "
if [ "$BOOTMODE" == true ]; then
  PKG2=`echo $PKG | sed -n -e 's/com.motorola.timeweatherwidget//p'`
  for PKG2S in $PKG2; do
    RES=`pm uninstall $PKG2S`
  done
fi
for APPS in $APP; do
  rm -f `find /data/dalvik-cache /data/resource-cache -type f -name *$APPS*.apk`
done
rm -f $MODPATH/LICENSE
rm -rf /metadata/magisk/$MODID
rm -rf /mnt/vendor/persist/magisk/$MODID
rm -rf /persist/magisk/$MODID
rm -rf /data/unencrypted/magisk/$MODID
rm -rf /cache/magisk/$MODID
ui_print " "

# power save
PROP=`getprop power.save`
FILE=$MODPATH/system/etc/sysconfig/*
if [ "$PROP" == 1 ]; then
  ui_print "- $MODNAME will not be allowed in power save."
  ui_print "  It may save your battery but decreasing $MODNAME performance."
  for PKGS in $PKG; do
    sed -i "s/<allow-in-power-save package=\"$PKGS\"\/>//g" $FILE
    sed -i "s/<allow-in-power-save package=\"$PKGS\" \/>//g" $FILE
  done
  ui_print " "
fi

# function
cleanup() {
if [ -f $DIR/uninstall.sh ]; then
  sh $DIR/uninstall.sh
fi
DIR=/data/adb/modules_update/$MODID
if [ -f $DIR/uninstall.sh ]; then
  sh $DIR/uninstall.sh
fi
}

# cleanup
DIR=/data/adb/modules/$MODID
FILE=$DIR/module.prop
if getprop | grep -Eq "moto.clean\]: \[1"; then
  ui_print "- Cleaning-up $MODID data..."
  cleanup
  ui_print " "
elif [ -d $DIR ] && ! grep -Eq "$MODNAME" $FILE; then
  ui_print "- Different version detected"
  ui_print "  Cleaning-up $MODID data..."
  cleanup
  ui_print " "
fi

# function
permissive() {
SELINUX=`getenforce`
if [ "$SELINUX" == Enforcing ]; then
  setenforce 0
  SELINUX=`getenforce`
  if [ "$SELINUX" == Enforcing ]; then
    ui_print "  ! Your device can't be turned to Permissive state."
  fi
  setenforce 1
fi
sed -i '1i\
SELINUX=`getenforce`\
if [ "$SELINUX" == Enforcing ]; then\
  setenforce 0\
fi\' $MODPATH/post-fs-data.sh
}

# permissive
if getprop | grep -Eq "permissive.mode\]: \[1"; then
  ui_print "- Using permissive method"
  rm -f $MODPATH/sepolicy.rule
  permissive
  ui_print " "
elif getprop | grep -Eq "permissive.mode\]: \[2"; then
  ui_print "- Using both permissive and SE policy patch"
  permissive
  ui_print " "
fi

# function
hide_oat() {
for APPS in $APP; do
  mkdir -p `find $MODPATH/system -type d -name $APPS`/oat
  touch `find $MODPATH/system -type d -name $APPS`/oat/.replace
done
}

# hide
hide_oat

# permission
ui_print "- Setting permission..."
magiskpolicy --live "dontaudit vendor_overlay_file labeledfs filesystem associate"
magiskpolicy --live "allow     vendor_overlay_file labeledfs filesystem associate"
magiskpolicy --live "dontaudit init vendor_overlay_file dir relabelfrom"
magiskpolicy --live "allow     init vendor_overlay_file dir relabelfrom"
magiskpolicy --live "dontaudit init vendor_overlay_file file relabelfrom"
magiskpolicy --live "allow     init vendor_overlay_file file relabelfrom"
chcon -R u:object_r:vendor_overlay_file:s0 $MODPATH/system/product/overlay
ui_print " "

# feature
NAME=com.motorola.timeweatherwidget
if ! pm list features | grep -Eq $NAME; then
  echo 'rm -rf /data/user/*/com.android.vending/*' >> $MODPATH/cleaner.sh
  ui_print "- Play Store data will be cleared automatically on"
  ui_print "  next reboot for app updates"
  ui_print " "
fi










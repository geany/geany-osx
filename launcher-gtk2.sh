#!/bin/bash -l

if test "x$GTK_DEBUG_LAUNCHER" != x; then
    set -x
fi

if test "x$GTK_DEBUG_GDB" != x; then
    EXEC="gdb --args"
else
    EXEC=exec
fi

ORIG_DIR=`pwd`

# simulate readlink -f which isn't present on OS X
TARGET_FILE=$0
cd `dirname $TARGET_FILE`
TARGET_FILE=`basename $TARGET_FILE`
while [ -L "$TARGET_FILE" ]
do
    TARGET_FILE=`readlink $TARGET_FILE`
    cd `dirname $TARGET_FILE`
    TARGET_FILE=`basename $TARGET_FILE`
done
PHYS_DIR=`pwd -P`

cd "$ORIG_DIR"

tmp=$PHYS_DIR/$TARGET_FILE
name=`basename "$tmp"`
tmp=`dirname "$tmp"`
tmp=`dirname "$tmp"`
bundle=`dirname "$tmp"`
bundle_contents="$bundle"/Contents
bundle_res="$bundle_contents"/Resources
bundle_lib="$bundle_res"/lib
bundle_bin="$bundle_res"/bin
bundle_data="$bundle_res"/share
bundle_etc="$bundle_res"/etc

export XDG_CONFIG_DIRS="$bundle_etc"
export XDG_DATA_DIRS="$bundle_data"
export GTK_DATA_PREFIX="$bundle_res"
export GTK_EXE_PREFIX="$bundle_res"
export GTK_PATH="$bundle_res"

export GTK2_RC_FILES="$bundle_etc/gtk-2.0/gtkrc"
export GTK_IM_MODULE_FILE="$bundle_etc/gtk-2.0/gtk.immodules"
#N.B. When gdk-pixbuf was separated from Gtk+ the location of the
#loaders cache changed as well. Depending on the version of Gtk+ that
#you built with you may still need to use the old location:
#export GDK_PIXBUF_MODULE_FILE="$bundle_etc/gtk-2.0/gdk-pixbuf.loaders"
export GDK_PIXBUF_MODULE_FILE="$bundle_lib/gdk-pixbuf-2.0/2.10.0/loaders.cache"
export PANGO_LIBDIR="$bundle_lib"
export PANGO_SYSCONFDIR="$bundle_etc"

if test -e ~/.config/geany/ignore_locale; then
    export LANG="en_US.UTF-8"
else
    export LANG=`defaults read .GlobalPreferences AppleLocale`
    export LANG="${LANG}.UTF-8"
fi

export LC_MESSAGES=$LANG
export LC_MONETARY=$LANG
export LC_COLLATE=$LANG
export LC_ALL=$LANG

if test -f "$bundle_lib/charset.alias"; then
    export CHARSETALIASDIR="$bundle_lib"
fi

# Extra arguments can be added in environment.sh.
EXTRA_ARGS=
if test -f "$bundle_res/environment.sh"; then
  source "$bundle_res/environment.sh"
fi

# Strip out the argument added by the OS.
if /bin/expr "x$1" : '^x-psn_' > /dev/null; then
    shift 1
fi

export GEANY_PLUGINS_SHARE_PATH="$bundle_res/share/geany-plugins"
export ENCHANT_MODULE_PATH="$bundle_lib/enchant"
export GIO_MODULE_DIR="$bundle_lib/gio/modules"

$EXEC "$bundle_contents/MacOS/$name-bin" "$@" "--vte-lib=$bundle_lib/libvte-2.91.0.dylib" $EXTRA_ARGS

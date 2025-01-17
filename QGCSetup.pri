# -------------------------------------------------
# QGroundControl - Micro Air Vehicle Groundstation
# Please see our website at <http://qgroundcontrol.org>
# Maintainer:
# Lorenz Meier <lm@inf.ethz.ch>
# (c) 2009-2011 QGroundControl Developers
# This file is part of the open groundstation project
# QGroundControl is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# QGroundControl is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with QGroundControl. If not, see <http://www.gnu.org/licenses/>.
# -------------------------------------------------

QMAKE_POST_LINK += echo "Copying files"

#
# Copy the application resources to the associated place alongside the application
#

LinuxBuild {
    DESTDIR_COPY_RESOURCE_LIST = $$DESTDIR
}

MacBuild {
    DESTDIR_COPY_RESOURCE_LIST = $$DESTDIR/$${TARGET}.app/Contents/MacOS
}

# Windows version of QMAKE_COPY_DIR of course doesn't work the same as Mac/Linux. It will only
# copy the contents of the source directory. It doesn't create the top level source directory
# in the target.
WindowsBuild {
    # Make sure to keep both side of this if using the same set of directories
    DESTDIR_COPY_RESOURCE_LIST = $$replace(DESTDIR,"/","\\")
    BASEDIR_COPY_RESOURCE_LIST = $$replace(BASEDIR,"/","\\")
    QMAKE_POST_LINK += $$escape_expand(\\n) $$QMAKE_COPY_DIR \"$$BASEDIR_COPY_RESOURCE_LIST\\flightgear\" \"$$DESTDIR_COPY_RESOURCE_LIST\\flightgear\"
} else {
    !MobileBuild {
        # Make sure to keep both sides of this if using the same set of directories
        QMAKE_POST_LINK += && $$QMAKE_COPY_DIR $$BASEDIR/flightgear $$DESTDIR_COPY_RESOURCE_LIST
    }
}

#
# Perform platform specific setup
#

MacBuild {
    # Copy non-standard frameworks into app package
    QMAKE_POST_LINK += && rsync -a --delete $$BASEDIR/libs/lib/Frameworks $$DESTDIR/$${TARGET}.app/Contents/
    # SDL Framework
    QMAKE_POST_LINK += && install_name_tool -change "@rpath/SDL.framework/Versions/A/SDL" "@executable_path/../Frameworks/SDL.framework/Versions/A/SDL" $$DESTDIR/$${TARGET}.app/Contents/MacOS/$${TARGET}
}

WindowsBuild {
    BASEDIR_WIN = $$replace(BASEDIR, "/", "\\")
    DESTDIR_WIN = $$replace(DESTDIR, "/", "\\")
    QT_BIN_DIR  = $$dirname(QMAKE_QMAKE)

    # Copy dependencies
    DebugBuild: DLL_QT_DEBUGCHAR = "d"
    ReleaseBuild: DLL_QT_DEBUGCHAR = ""
    COPY_FILE_LIST = \
        $$BASEDIR\\libs\\lib\\sdl\\win32\\SDL.dll \
        $$BASEDIR\\libs\\thirdParty\\libxbee\\lib\\libxbee.dll

    for(COPY_FILE, COPY_FILE_LIST) {
        QMAKE_POST_LINK += $$escape_expand(\\n) $$QMAKE_COPY \"$$COPY_FILE\" \"$$DESTDIR_WIN\"
    }

        ReleaseBuild {
        # Copy Visual Studio DLLs
        # Note that this is only done for release because the debugging versions of these DLLs cannot be redistributed.
        win32-msvc2010 {
            QMAKE_POST_LINK += $$escape_expand(\\n) $$QMAKE_COPY \"C:\\Windows\\System32\\msvcp100.dll\"  \"$$DESTDIR_WIN\"
            QMAKE_POST_LINK += $$escape_expand(\\n) $$QMAKE_COPY \"C:\\Windows\\System32\\msvcr100.dll\"  \"$$DESTDIR_WIN\"
        }
        else:win32-msvc2012 {
            QMAKE_POST_LINK += $$escape_expand(\\n) $$QMAKE_COPY \"C:\\Windows\\System32\\msvcp110.dll\"  \"$$DESTDIR_WIN\"
            QMAKE_POST_LINK += $$escape_expand(\\n) $$QMAKE_COPY \"C:\\Windows\\System32\\msvcr110.dll\"  \"$$DESTDIR_WIN\"
        }
        else:win32-msvc2013 {
            QMAKE_POST_LINK += $$escape_expand(\\n) $$QMAKE_COPY \"C:\\Windows\\System32\\msvcp120.dll\"  \"$$DESTDIR_WIN\"
            QMAKE_POST_LINK += $$escape_expand(\\n) $$QMAKE_COPY \"C:\\Windows\\System32\\msvcr120.dll\"  \"$$DESTDIR_WIN\"
        }
        else {
            error("Visual studio version not supported, installation cannot be completed.")
        }
    }

    DEPLOY_TARGET = $$shell_quote($$shell_path($$DESTDIR_WIN\\$${TARGET}.exe))
    QMAKE_POST_LINK += $$escape_expand(\\n) $$QT_BIN_DIR\\windeployqt --no-compiler-runtime --qmldir=$${BASEDIR_WIN}\\src $${DEPLOY_TARGET}

}

LinuxBuild {
    installer {
        QMAKE_POST_LINK += && mkdir -p $$DESTDIR/Qt/libs && mkdir -p $$DESTDIR/Qt/plugins

        # QT_INSTALL_LIBS
        QT_LIB_LIST = \
            libQt5Core.so.5 \
            libQt5DBus.so.5 \
            libQt5Gui.so.5 \
            libQt5Location.so.5 \
            libQt5Network.so.5 \
            libQt5OpenGL.so.5 \
            libQt5Positioning.so.5 \
            libQt5PrintSupport.so.5 \
            libQt5Qml.so.5 \
            libQt5Quick.so.5 \
            libQt5QuickWidgets.so.5 \
            libQt5SerialPort.so.5 \
            libQt5Sql.so.5 \
            libQt5Svg.so.5 \
            libQt5Test.so.5 \
            libQt5Widgets.so.5 \
            libQt5XcbQpa.so.5

        !contains(DEFINES, __rasp_pi2__) {
            QT_LIB_LIST += \
                libicudata.so.54 \
                libicui18n.so.54 \
                libicuuc.so.54
        }

        for(QT_LIB, QT_LIB_LIST) {
            QMAKE_POST_LINK += && $$QMAKE_COPY --dereference $$[QT_INSTALL_LIBS]/$$QT_LIB $$DESTDIR/Qt/libs/
        }

        # QT_INSTALL_PLUGINS
        QT_PLUGIN_LIST = \
            bearer \
            geoservices \
            iconengines \
            imageformats \
            platforminputcontexts \
            platforms \
            platformthemes \
            position \
            sqldrivers

        !contains(DEFINES, __rasp_pi2__) {
            QT_PLUGIN_LIST += xcbglintegrations
        }

        for(QT_PLUGIN, QT_PLUGIN_LIST) {
            QMAKE_POST_LINK += && $$QMAKE_COPY --dereference --recursive $$[QT_INSTALL_PLUGINS]/$$QT_PLUGIN $$DESTDIR/Qt/plugins/
        }

        # QT_INSTALL_QML
        QMAKE_POST_LINK += && $$QMAKE_COPY --dereference --recursive $$[QT_INSTALL_QML] $$DESTDIR/Qt/

        # QGroundControl start script
        QMAKE_POST_LINK += && $$QMAKE_COPY $$BASEDIR/deploy/qgroundcontrol-start.sh $$DESTDIR
    }
}


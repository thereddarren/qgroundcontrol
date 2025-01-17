/*=====================================================================

QGroundControl Open Source Ground Control Station

(c) 2009, 2015 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>

This file is part of the QGROUNDCONTROL project

QGROUNDCONTROL is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

QGROUNDCONTROL is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with QGROUNDCONTROL. If not, see <http://www.gnu.org/licenses/>.

======================================================================*/

import QtQuick          2.5
import QtQuick.Controls 1.2
import QtPositioning    5.2

import QGroundControl               1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.ScreenTools   1.0


//-- Left Menu
Item {
    id:             settingsMenu
    anchors.fill:   parent

    property alias animateShowDialog: __animateShowDialog
    property alias animateHideDialog: __animateHideDialog

    readonly property int  __animationDuration: 100
    readonly property real __closeButtonSize:   ScreenTools.defaultFontPixelHeight * 2

    onVisibleChanged: {
        //-- Unselect any selected button
        panelActionGroup.current = null
        //-- Destroy panel contents if not visible
        if(!visible) {
            __rightPanel.source = ""
        }
    }

    function closeSettings() {
        __rightPanel.source = ""
        mainWindow.hideLeftMenu()
    }

    ParallelAnimation {
        id: __animateShowDialog
        NumberAnimation {
            target:     __transparentSection
            properties: "opacity"
            from:       0.0
            to:         0.8
            duration:   settingsMenu.__animationDuration
        }
        NumberAnimation {
            target:     __transparentSection
            properties: "width"
            from:       1
            to:         mainWindow.width
            duration:   settingsMenu.__animationDuration
        }
    }

    ParallelAnimation {
        id: __animateHideDialog
        NumberAnimation {
            target:     __transparentSection
            properties: "opacity"
            from:       0.8
            to:         0.0
            duration:   settingsMenu.__animationDuration
        }
        NumberAnimation {
            target:     __transparentSection
            properties: "width"
            from:       mainWindow.width
            to:         1
            duration:   settingsMenu.__animationDuration
        }
        onRunningChanged: {
            if (!running) {
                parent.visible = false
            }
        }
    }

    // This covers the screen with a transparent section
    Rectangle {
        id:             __transparentSection
        height:         parent.height - toolBar.height
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        opacity:        0.0
        color:          __qgcPal.window
        visible:        __rightPanel.source == ""
        // Dismiss if clicked outside menu area
        MouseArea {
            anchors.fill: parent
            onClicked: {
                mainWindow.hideLeftMenu()
            }
        }
    }

    //-- Top Separator
    Rectangle {
        id:             __topSeparator
        width:          parent.width
        height:         1
        y:              toolBar.height
        anchors.left:   parent.left
        color:          QGroundControl.isDarkStyle ? "#909090" : "#7f7f7f"
    }

    // This is the menu dialog panel which is anchored to the left edge
    Rectangle {
        id:             __leftMenu
        width:          (tbButtonWidth * 2) + (tbSpacing * 4) + 1
        anchors.left:   parent.left
        anchors.top:    __topSeparator.bottom
        anchors.bottom: parent.bottom
        color:          __qgcPal.windowShadeDark

        ExclusiveGroup { id: panelActionGroup }

        Column {
            width:      parent.width
            spacing:    ScreenTools.defaultFontPixelHeight
            Item {
                width:      1
                height:     ScreenTools.defaultFontPixelHeight * 0.5
            }
            QGCLabel {
                text:           "Preferences"
                anchors.horizontalCenter: parent.horizontalCenter
            }
            QGCButton {
                width:      parent.width * 0.85
                height:     ScreenTools.defaultFontPixelHeight * 2.5
                text:       "General"
                exclusiveGroup: panelActionGroup
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    if(__rightPanel.source != "GeneralSettings.qml") {
                        __rightPanel.source = "GeneralSettings.qml"
                    }
                    checked = true
                }
            }
            QGCButton {
                width:      parent.width * 0.85
                height:     ScreenTools.defaultFontPixelHeight * 2.5
                text:       "Comm Links"
                exclusiveGroup: panelActionGroup
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    if(__rightPanel.source != "LinkSettings.qml") {
                        __rightPanel.source = "LinkSettings.qml"
                    }
                    checked = true
                }
            }
            QGCButton {
                width:      parent.width * 0.85
                height:     ScreenTools.defaultFontPixelHeight * 2.5
                text:       "Offline Maps"
                exclusiveGroup: panelActionGroup
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    if(__rightPanel.source != "OfflineMap.qml") {
                        __rightPanel.source = "OfflineMap.qml"
                    }
                    checked = true
                }
            }
            QGCButton {
                width:      parent.width * 0.85
                height:     ScreenTools.defaultFontPixelHeight * 2.5
                text:       "MavLink"
                exclusiveGroup: panelActionGroup
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    if(__rightPanel.source != "MavlinkSettings.qml") {
                        __rightPanel.source = "MavlinkSettings.qml"
                    }
                    checked = true
                }
            }
            QGCButton {
                width:      parent.width * 0.85
                height:     ScreenTools.defaultFontPixelHeight * 2.5
                text:       "Mock Link"
                visible:    ScreenTools.isDebug
                exclusiveGroup: panelActionGroup
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    if(__rightPanel.source != "MockLink.qml") {
                        __rightPanel.source = "MockLink.qml"
                    }
                    checked = true
                }
            }
            QGCButton {
                width:      parent.width * 0.85
                height:     ScreenTools.defaultFontPixelHeight * 2.5
                text:       "Debug"
                visible:    ScreenTools.isDebug
                exclusiveGroup: panelActionGroup
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    if(__rightPanel.source != "DebugWindow.qml") {
                        __rightPanel.source = "DebugWindow.qml"
                    }
                    checked = true
                }
            }
        }
    }

    //-- Clicking in tool bar area dismiss it all
    MouseArea {
        anchors.top:    parent.top
        anchors.left:   parent.left
        anchors.right:  parent.right
        height:         toolBar.height
        onClicked: {
            mainWindow.hideLeftMenu()
        }
    }

    //-- Vertical Separator
    Rectangle {
        id:             __verticalSeparator
        width:          1
        height:         parent.height - toolBar.height
        anchors.left:   __leftMenu.right
        anchors.bottom: parent.bottom
        color:          QGroundControl.isDarkStyle ? "#909090" : "#7f7f7f"
    }

    //-- Main Setting Display Area
    Rectangle {
        anchors.left:   __verticalSeparator.right
        width:          mainWindow.width - __leftMenu.width - __verticalSeparator.width
        height:         parent.height - toolBar.height - __topSeparator.height
        anchors.bottom: parent.bottom
        visible:        __rightPanel.source != ""
        color:          __qgcPal.window
        //-- Panel Contents
        Loader {
            id:             __rightPanel
            anchors.fill:   parent
        }
        //-- Dismiss it all
        Item {
            id:              closeButton
            width:           __closeButtonSize
            height:          __closeButtonSize
            anchors.right:   parent.right
            anchors.top:     parent.top
            anchors.margins: ScreenTools.defaultFontPixelSize * 0.5
            QGCColoredImage {
                source:       "/res/XDelete.svg"
                mipmap:       true
                fillMode:     Image.PreserveAspectFit
                color:        __qgcPal.text
                width:        parent.width  * 0.75
                height:       parent.height * 0.75
                anchors.centerIn: parent
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    __rightPanel.source = ""
                    mainWindow.hideLeftMenu()
                }
            }

        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager

Item {
id: fullPopup

    // fill many stuff as you can

    implicitWidth: Math.max(mainLayout.implicitWidth, 300)
    implicitHeight: Math.max(mainLayout.implicitWidth, 200)

    Layout.preferredWidth: fullPopup.implicitWidth + Kirigami.Units.smallSpacing
    Layout.preferredHeight: fullPopup.implicitHeight + Kirigami.Units.smallSpacing
    Layout.minimumWidth: fullPopup.implicitWidth + Kirigami.Units.smallSpacing
    Layout.minimumHeight: fullPopup.implicitHeight + Kirigami.Units.smallSpacing
    property var appletroot: "root"

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing

        // headers
        RowLayout {
            Layout.fillWidth: true

            PlasmaComponents.Label {
                text: i18n("Notifications")
                font.bold: true
                font.pixelSize: Kirigami.Units.gridUnit * 1.1
            }

            Item { Layout.fillWidth: true }

            PlasmaComponents.Button {
                text: i18n("Clear All")
                icon.name: "edit-clear-all"
                opacity: (notifListView.count > 0) ? 1 : 0
                visible: opacity > 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.InOutCubic
                    }
                }
                onClicked: {
                    win11Notif.clear(NotificationManager.Notifications.ClearExpired) // func from qmltypes file of course, we clear all here
                }
            }
        }

        Item {
            id: notifDisplay
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            property bool userReading: true

            MouseArea { // use MouseArea so we could have xtra sensivity (just need your mouse)
                anchors.fill: parent
                propagateComposedEvents: true
                hoverEnabled: true

                onEntered: { notifDisplay.userReading = true }

                onExited: { notifDisplay.userReading = false }

                onPressed: (mouse) => { mouse.accepted = false } // no accept mouse
                onReleased: (mouse) => { mouse.accepted = false }
                onClicked: (mouse) => { mouse.accepted = false }
                onDoubleClicked: (mouse) => { mouse.accepted = false }
            }

            ListView {
                id: notifListView
                model: win11Notif
                spacing: Kirigami.Units.smallSpacing
                anchors.fill: parent

                displaced: Transition {
                    NumberAnimation { properties: "y"; duration: 250; easing.type: Easing.OutCubic }
                }

                add: Transition {
                    NumberAnimation { properties: "height"; duration: 200; from: 0; easing.type: Easing.OutQuad }
                    NumberAnimation { properties: "opacity"; duration: 200; from: 0; easing.type: Easing.OutQuad }
                }

                remove: Transition {
                    NumberAnimation { properties: "height"; duration: 200; to: 0; easing.type: Easing.OutQuad }
                    NumberAnimation { properties: "opacity"; duration: 200; to: 0; easing.type: Easing.OutQuad }
                }

                // smart scrolling so you don't go snapped to the top by Two- no, by the goddamn list view (BFDI fan caught in 4k)
                Connections {
                    target: win11Notifications

                    function onRowsInserted(parentIndex, first, last) {
                        if (!notifDisplay.userReading && !notifListView.atYBeginning) { // now i know more properties
                            notifListView.positionViewAtBeginning() // so we have (M)anims (3b1b)
                        }
                    }
                }

                // group notifications by appname
                section.property: "applicationName"
                section.criteria: ViewSection.FullString
                section.delegate: Component {
                    Item {
                        width: ListView.view.width
                        height: Kirigami.Units.gridUnit * 1.5

                        PlasmaComponents.Label {
                            text: section
                            font.bold: true
                            opacity: 0.6
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: Kirigami.Units.smallSpacing
                        }
                    }
                }

                delegate: Rectangle {
                    id: delegateRoot
                    width: ListView.view.width
                    opacity: 0
                    height: Math.min(ListView.view.height / 3, 96)
                    scale: 1

                    color: Qt.rgba(1, 1, 1, 0.05)
                    radius: 4
                    border.color: Qt.rgba(1, 1, 1, 0.1)

                    Component.onCompleted: {
                        opacity = Qt.binding(() => 1)
                        height = Qt.binding(() => Math.min(ListView.view.height / 3, 96))
                    }

                    // animationsssss
                    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                    Item {
                        id: contents
                        anchors.fill: parent

                        Timer {
                            id: delayDelete
                            interval: 210
                            onTriggered: {
                                win11Notifications.close(win11Notifications.index(index, 0))
                            }
                        }

                        // layering is very important
                        MouseArea {
                            id: toastArea // on Windows 10 each item is called "toast"
                            anchors.fill: parent
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            //eventsssss
                            onPressed: {
                                delegateRoot.scale = 0.95
                            }

                            onClicked: {
                                win11Notifications.invokeDefaultAction(win11Notifications.index(index, 0))
                            }

                            onReleased: {
                                delegateRoot.scale = 1.0
                            }

                            onCanceled: {
                                delegateRoot.scale = 1.0
                            }
                        }

                        RowLayout {
                            z: toastArea.z + 1 // go in front of
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.largeSpacing

                            Kirigami.Icon {
                                id: notifIcon
                                source: model.iconName || "dialog-information"
                                Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                PlasmaComponents.Label {
                                    text: model.summary
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                PlasmaComponents.Label {
                                    text: model.body
                                    opacity: 0.8
                                    wrapMode: Text.WordWrap
                                    elide: Text.ElideRight
                                    maximumLineCount: 3
                                    Layout.fillWidth: true
                                }
                            }

                            PlasmaComponents.ToolButton {
                                icon.name: "window-close"
                                onClicked: {
                                    delegateRoot.opacity = 0
                                    delegateRoot.height = 0
                                    delayDelete.start()
                                }
                            }
                        }
                    }
                }
            }

            PlasmaComponents.Label {
                anchors.centerIn: parent
                text: i18n("No new notifications")
                opacity: (notifListView.count === 0) ? 0.5 : 0
                visible: opacity > 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.InOutCubic
                    }
                }
            }
        }
    }
}

import QtQuick 2.15
import org.kde.plasma.core 2.1 as PlasmaCore
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.19 as Kirigami
import org.kde.ksvg as KSvg

PlasmaCore.Dialog {
    id: root

    property string text: "Default"
    property int margin: 10
    property string icon: "dialog-information"
    property string title: i18n("Unknown")
    property string contents: i18n("What is this notification?")
    property var notifIndex: 0
    property bool closing: false

    flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus
    location: PlasmaCore.Types.Floating

    width: 300
    height: 96

    onVisibleChanged: {
        if (visible) {
            x = Screen.width - width - 20;
            y = 50;
            delegateRoot.opacity = 1.0;
            autoTimeoutTimer.start();
        }
    }

    function show() {
        Qt.callLater(function() {
            root.visible = true;;
        });
    }

    function destroyme() {
        if (root.closing) return;
        root.closing = true;

        //root.x = Screen.width;
        delegateRoot.opacity = 0.0;
        exitDelayTimer.start();
    }

    mainItem: Rectangle {
        id: delegateRoot
        width: root.width
        height: root.height

        Component.onCompleted: {
            opacity = Qt.binding(() => 1)
            height = Qt.binding(() => root.height)
        }

        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

        scale: 1
        color: Qt.rgba(1, 1, 1, 0.05)
        radius: 4
        border.color: Qt.rgba(1, 1, 1, 0.1)

        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

        Item {
            id: contentContainer
            anchors.fill: parent

            Timer {
                id: autoTimeoutTimer
                interval: 3000
                running: false
                onTriggered: {
                    destroyme()
                }
            }

            Timer {
                id: exitDelayTimer
                interval: 250
                running: false
                repeat: false
                onTriggered: {
                    root.visible = false;
                }
            }

            MouseArea {
                id: toastArea
                anchors.fill: parent

                onPressed: {
                    delegateRoot.scale = 0.95
                }
                onClicked: {
                    if (typeof win11Notif !== "undefined") {
                        win11Notif.invokeDefaultAction(win11Notif.index(notifIndex, 0))
                    }
                }
                onReleased: { delegateRoot.scale = 1.0 }
                onCanceled: { delegateRoot.scale = 1.0 }
                onEntered: {
                    if (!root.closing) {
                        autoTimeoutTimer.stop(); // you hover you stop clok if time != 0
                    }
                }
                onExited: {
                    // prevent you from stop notif from byeing (only restart the clock if there's still time)
                    if (!root.closing) {
                        autoTimeoutTimer.start();
                    }
                }
            }

            RowLayout {
                z: toastArea.z + 1
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Kirigami.Icon {
                    source: root.icon
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter

                    PlasmaComponents.Label {
                        text: root.title
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    PlasmaComponents.Label {
                        text: root.contents
                        opacity: 0.8
                        wrapMode: Text.WordWrap
                        elide: Text.ElideRight
                        maximumLineCount: 3
                        Layout.fillWidth: true
                    }
                }

                PlasmaComponents.ToolButton {
                    icon.name: "window-close"
                    Layout.alignment: Qt.AlignTop
                    onClicked: {
                        win11Notif.close(win11Notif.index(notifIndex, 0))
                        destroyme()
                    }
                }
            }
        }
    }
}

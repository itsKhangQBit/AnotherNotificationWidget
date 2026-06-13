import QtQuick
import org.kde.plasma.core as PlasmaCore
import QtQuick.Layouts
import QtQuick.Window
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmaCore.Dialog {
    id: root

    property string text: "Default"
    property int margin: 10
    property string icon: "dialog-information"
    property string title: i18n("Unknown")
    property string contents: i18n("What is this notification?")
    property var notifIndex: 0
    property bool closing: false
    property int timeoutinterval: 3000

    flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus
    location: PlasmaCore.Types.TopEdge

    width: 330
    height: 120

    onVisibleChanged: {
        if (visible) {
            root.x = Screen.width - root.width - Kirigami.Units.largeSpacing;
            var offset = Kirigami.Units.smallSpacing;
            var screenAvail = plasmoid.containment.availableScreenRect
            var screenGeom = plasmoid.containment.screenGeometry
            var screen = Qt.rect(screenAvail.x + screenGeom.x, screenAvail.y + screenGeom.y, screenAvail.width, screenAvail.height);
            y = screen.y + panelSvg.margins.bottom + offset;

            delegateRoot.opacity = 1.0;
            autoTimeoutTimer.start();
        }
    }

    hideOnWindowDeactivate: true

    function show() {
        Qt.callLater(function() {
            root.visible = true;
        });
    }

    function destroyme() {
        if (root.closing) return;
        root.closing = true;

        delegateRoot.opacity = 0;
        Qt.callLater(function() {
            exitDelayTimer.start();
        })
    }

    mainItem: Item {
        id: delegateRoot
        width: root.width
        height: root.height

        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

        Timer {
            id: autoTimeoutTimer
            interval: timeoutinterval
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
                root.destroy()
            }
        }

        PlasmaComponents.ProgressBar {
            id: timeoutBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 3
            from: 0
            to: timeoutinterval
            value: timeoutinterval

            NumberAnimation {
                id: timeoutAnimation
                target: timeoutBar
                property: "value"
                from: timeoutinterval
                to: 0
                duration: timeoutinterval
                easing.type: Easing.Linear
                running: autoTimeoutTimer.running
            }
        }

        MouseArea {
            id: toastArea
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            propagateComposedEvents: true

            scale: 1

            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

            onPressed: {
                toastArea.scale = 0.95
            }
            onClicked: {
                if (typeof win11Notif !== "undefined") {
                    win11Notif.invokeDefaultAction(win11Notif.index(notifIndex, 0))
                    destroyme()
                }
            }
            onReleased: { toastArea.scale = 1.0 }
            onCanceled: { toastArea.scale = 1.0 }
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

            RowLayout {
                anchors.margins: 12
                anchors.fill: parent
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
                    Layout.fillHeight: true
                    onClicked: {
                        win11Notif.close(win11Notif.index(notifIndex, 0))
                        destroyme()
                    }
                }
            }
        }
    }
}

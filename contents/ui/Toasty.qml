import QtQuick
import org.kde.plasma.core as PlasmaCore
import QtQuick.Layouts
import QtQuick.Window
import Qt5Compat.GraphicalEffects 1.15 // dude Qt didn't port it to Qt 6??
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
    property int targetY: 60
    property string imgURL: ""
    property int notifWidth: 390
    property real notifHeight: {
        var shortHeight = 120
        var thumbHeight = 320
        var noExpandHeight =  (imgURL !== "" && imgURL !== undefined) ? thumbHeight : shortHeight
        return toolButtons.expandDelegate ? Math.max(contents.implicitHeight + timeoutDisplay.implicitHeight + Kirigami.Units.largeSpacing * 2, noExpandHeight) : noExpandHeight // contents doesn't add timeoutDisplay!??
    }

    signal killme(var toasty)

    flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus // no focus no steal Dream Isla- keyboard*
    location: PlasmaCore.Types.RightEdge // fixed for now

    width: root.notifWidth
    height: root.notifHeight

    onVisibleChanged: {
        if (visible) {
            // code taken from menu 11 enhanced
            root.x = Screen.width - root.width - Kirigami.Units.largeSpacing;
            y = targetY

            // I don't see any animation but let just put it here, maybe a solution soon
            timeoutTimer.start();
        }
    }

    onTargetYChanged: {
        y = targetY
    }

    Behavior on y { id: animY; enabled: false; NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
    Component.onCompleted: Qt.callLater(function() {
        animY.enabled = true
        notifRoot.opacity = 1.0;
    })

    Behavior on height {
        NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
    }

    hideOnWindowDeactivate: true

    function show() {
        notifRoot.opacity = 0.0;
        Qt.callLater(function() {
            root.visible = true;
        });
    }

    function destroyme() {
        if (root.closing) return;
        root.closing = true;

        notifRoot.opacity = 0;
        Qt.callLater(function() {
            exiter.start();
        })
    }

    mainItem: MouseArea {
        clip: true
        id: notifRoot
        width: root.notifWidth
        height: root.notifHeight

        hoverEnabled: true
        preventStealing: true
        propagateComposedEvents: true

        onPressed: {
            toastArea.scale = 0.95
        }
        onClicked: {
            if (typeof win11Notif !== "undefined") { // no nullify
                win11Notif.invokeDefaultAction(win11Notif.index(notifIndex, 0))
                destroyme()
            }
        }
        onReleased: { toastArea.scale = 1.0 }
        onCanceled: { toastArea.scale = 1.0 }
        onEntered: {
            if (!root.closing) {
                timeoutTimer.stop(); // you hover you stop clok if time != 0
            }
        }
        onExited: {
            // prevent you from stop notif from byeing (only restart the clock if there's still time)
            if (!root.closing) {
                timeoutTimer.start();
            }
        }

        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

        Timer {
            id: timeoutTimer
            interval: timeoutinterval
            running: false
            onTriggered: {
                destroyme()
            }
        }

        Timer {
            id: exiter
            interval: 250
            running: false
            repeat: false
            onTriggered: {
                root.visible = false;
                killme(root)
                root.destroy()
            }
        }

        ColumnLayout {
            id: contents
            anchors.margins: Kirigami.Units.largeSpacing
            anchors.fill: parent

            PlasmaComponents.ProgressBar {
                id: timeoutDisplay
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                from: 0
                to: timeoutinterval
                value: timeoutinterval
                visible: timeoutTimer.running

                NumberAnimation { // smooth countdown
                    id: timeoutAnimation
                    target: timeoutDisplay
                    property: "value"
                    from: timeoutinterval
                    to: 0
                    duration: timeoutinterval
                    easing.type: Easing.Linear
                    running: timeoutTimer.running
                }
            }

            ColumnLayout {
                id: toastArea

                scale: 1

                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: spectacleThumb.visible ? 200 : 0
                    radius: 4
                    Image {
                        id: pillarEcho // you get what I'm doing
                        width: parent.width
                        height: parent.height
                        source: (imgURL !== "" && imgURL !== undefined) ? imgURL : "file:///home/itskhang/Pictures/neon.logo.png"
                        visible: (imgURL !== "" && imgURL !== undefined)
                        fillMode: Image.PreserveAspectCrop
                    }

                    FastBlur {
                        source: pillarEcho
                        anchors.fill: pillarEcho
                        radius: 32
                    }

                    Image {
                        width: parent.width
                        height: parent.height
                        id: spectacleThumb // mfer really used Spectacle for this
                        source: (imgURL !== "" && imgURL !== undefined) ? imgURL : "file:///home/itskhang/Pictures/neon.logo.png"
                        visible: (imgURL !== "" && imgURL !== undefined)
                        fillMode: Image.PreserveAspectFit // you can see your thumbnails fully
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    anchors.margins: 12
                    spacing: 12

                    Kirigami.Icon {
                        source: root.icon || "notifications-symbolic"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                        Layout.preferredHeight: width
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        //Layout.fillWidth: true
                        spacing: 2

                        PlasmaComponents.Label {
                            text: root.title
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        PlasmaComponents.Label { // only this could get us to click links
                            text: root.contents
                            onLinkActivated: (link) => {
                                Qt.openUrlExternally(link);
                            }
                            HoverHandler {
                                id: hoverHandler
                                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                            }
                            opacity: 0.8
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
                            maximumLineCount: toolButtons.expandDelegate ? 2763 : 3
                            Layout.fillWidth: true
                        }
                    }

                    ColumnLayout {
                        id: toolButtons
                        Layout.fillHeight: true
                        property bool expandDelegate: false
                        PlasmaComponents.ToolButton {
                            icon.name: "window-close"
                            Layout.fillHeight: true
                            onClicked: {
                                if (typeof win11Notif !== "undefined") { // no nullify
                                    notifRoot.opacity = 0
                                    notifRoot.height = 0
                                    delayDelete.start()
                                }
                            }
                        }
                        PlasmaComponents.ToolButton {
                            icon.name: toolButtons.expandDelegate ? "arrow-up-symbolic" : "arrow-down-symbolic"
                            onClicked: {
                                toolButtons.expandDelegate = !toolButtons.expandDelegate
                            }
                        }
                    }
                }
            }
        }
    }
}

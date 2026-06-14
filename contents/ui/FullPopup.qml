import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import Qt5Compat.GraphicalEffects 1.15
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

    function qtOpexExternal(id, urls) {
        var itemIndex = win11Notif.index(id, 0);

        // is itemIndex a real item?
        if (!itemIndex.valid) {
            console.log("Thông báo đã bị xóa khỏi hàng đợi!");
            return;
        }
        if (urls && urls.length > 0) {
            Qt.openUrlExternally(urls[0]);
        }
    }

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

            PlasmaComponents.ScrollView {
                anchors.fill: parent
                clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ListView {
                    id: notifListView
                    model: win11Notif
                    spacing: Kirigami.Units.gridUnit
                    Layout.fillHeight: true
                    Layout.fillWidth: true

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
                            height: Kirigami.Units.gridUnit * 2

                            PlasmaComponents.Label {
                                text: section
                                font.bold: true
                                opacity: 0.6
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: Kirigami.Units.gridUnit
                            }
                        }
                    }

                    delegate: Rectangle {
                        id: delegateRoot
                        width: ListView.view.width
                        opacity: 0
                        scale: 1
                        height: {
                            var imgURL = (model.urls && model.urls.length > 0) ? model.urls[0].toString() : ""
                            var shortHeight = 120
                            var thumbHeight = 320
                            var rielHeight =  (imgURL !== "" && imgURL !== undefined) ? thumbHeight : shortHeight
                            return toolButtons.expandDelegate ? Math.max(contents.implicitHeight + Kirigami.Units.largeSpacing * 2 , rielHeight) : rielHeight // math.max so it only expands // we have to add the margins in, for some reason ColumnLayout doesn't add the margins
                        }

                        color: Kirigami.Theme.backgroundColor
                        radius: 4
                        border.color: Kirigami.Theme.alternateBackgroundColor

                        Component.onCompleted: {
                            opacity = Qt.binding(() => 1)
                        }

                        // animationsssss
                        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                        Timer {
                            id: delayDelete
                            interval: 210
                            onTriggered: {
                                win11Notifications.close(win11Notifications.index(index, 0))
                            }
                        }

                        MouseArea {
                            clip: true
                            anchors.fill: parent

                            hoverEnabled: true
                            preventStealing: true
                            propagateComposedEvents: true

                            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

                            onPressed: {//visible: delegateRoot.height <= contents.implicitHeigh
                                delegateRoot.scale = 0.95
                            }
                            onClicked: {
                                console.log(model.hasDefaultAction)
                                qtOpexExternal(index, model.urls)
                            }
                            onReleased: { delegateRoot.scale = 1.0 }
                            onCanceled: { delegateRoot.scale = 1.0 }

                            ColumnLayout {
                                id: contents
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.largeSpacing

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: spectacleThumb.visible ? 200 : 0
                                    radius: 4
                                    Image {
                                        id: pillarEcho // you get what I'm doing
                                        width: parent.width
                                        height: parent.height


                                        source: {
                                            var imgURL = (model.urls && model.urls.length > 0) ? model.urls[0].toString() : ""
                                            return (imgURL !== "" && imgURL !== undefined) ? imgURL : "file:///home/itskhang/Pictures/neon.logo.png"
                                        }
                                        visible: {
                                            var imgURL = (model.urls && model.urls.length > 0) ? model.urls[0].toString() : ""
                                            return (imgURL !== "" && imgURL !== undefined)
                                        }
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
                                        source: {
                                            var imgURL = (model.urls && model.urls.length > 0) ? model.urls[0].toString() : ""
                                            return (imgURL !== "" && imgURL !== undefined) ? imgURL : "file:///home/itskhang/Pictures/neon.logo.png"
                                        }
                                        visible: {
                                            var imgURL = (model.urls && model.urls.length > 0) ? model.urls[0].toString() : ""
                                            return (imgURL !== "" && imgURL !== undefined)
                                        }
                                        fillMode: Image.PreserveAspectFit // you can see your thumbnails fully
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 12

                                    Kirigami.Icon {
                                        source: model.iconName || "notifications-symbolic"
                                        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                                        Layout.preferredHeight: width
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    ColumnLayout {
                                        spacing: 2
                                        clip: true

                                        PlasmaComponents.Label {
                                            text: model.summary
                                            font.bold: true
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        PlasmaComponents.Label {
                                            text: model.body
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
                                                    delegateRoot.opacity = 0
                                                    delegateRoot.height = 0
                                                    delayDelete.start()
                                                }
                                            }
                                        }
                                        PlasmaComponents.ToolButton {
                                            icon.name: toolButtons.expandDelegate ? "arrow-up-symbolic" : "arrow-down-symbolic"
                                            //visible:
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

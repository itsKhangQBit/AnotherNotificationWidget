import QtQuick
import org.kde.plasma.core as PlasmaCore
import QtQuick.Layouts
import QtQuick.Window
import Qt5Compat.GraphicalEffects 1.15 // dude Qt didn't port it to Qt 6??
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.plasma5support as Plasma5Support

PlasmaCore.Dialog {
    id: root

    property var notifIndex: 0
    property bool closing: false
    property int timeoutinterval: 3000
    property int targetY: 60
    property int notifWidth: 390
    property var model: win11Notif
    property string imgURL: (model.urls && model.urls.length > 0) ? model.urls[0].toString() : "/home/itskhang/Pictures/pexels-hson-18701754_44802520.jpg"
    property real notifHeight: {
        var shortHeight = 145
        var thumbHeight = 375
        var noExpandHeight =  (imgURL !== "" && imgURL !== undefined) ? thumbHeight : shortHeight
        return Math.max(contents.implicitHeight + timeoutDisplay.implicitHeight + Kirigami.Units.largeSpacing * 2, noExpandHeight)
    }
    property var actions: []

    function qtOpexExternal(id, urls) {
        var itemIndex = win11Notif.index(id, 0);

        // is itemIndex a real item?
        if (!itemIndex.valid) {
            console.log("Oh shoot, notification is deleted");
            return;
        }
        if (urls && urls.length > 0) {
            Qt.openUrlExternally(urls[0]);
        }
    }

    signal killme(var toasty)
    signal reCalculatePos(var toasty)

    onHeightChanged: {
        Qt.callLater(() => {
            reCalculatePos(root)
        })
    }

    flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus // no focus no steal Dream Isla- keyboard*
    location: PlasmaCore.Types.RightEdge // fixed for now

    width: root.notifWidth
    height: root.notifHeight

    onVisibleChanged: {
        if (visible) {
            // code taken from menu 11 enhanced
            root.x = Screen.width - root.width - Kirigami.Units.largeSpacing;
            y = targetY

            if (model.closable) timeoutTimer.start();
        }
    }

    onTargetYChanged: {
        y = targetY
    }

    Behavior on y { id: animY; enabled: false; NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }
    Component.onCompleted: Qt.callLater(function() {
        animY.enabled = true
        notifRoot.opacity = 1.0;
        openWithProcessor.runScanCommand(root.imgURL)
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
        notifRoot.opacity = 0.0;
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
            if (model.hasDefaultAction) win11Notif.invokeDefaultAction(win11Notif.index(model.index, 0), behavior)
            else qtOpexExternal(model.index, model.urls)
            destroyme()
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
                if (model.closable) timeoutTimer.start();
            }
        }

        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

        Plasma5Support.DataSource {
            id: openWithProcessor
            engine: "executable"
            connectedSources: []

            // Hàm kích hoạt chạy cmd quét danh sách app
            function runScanCommand(filePath) {
                // Gom nguyên con script Bash tối ưu của bồ vào một dòng (dùng dấu chấm phẩy)
                var cmd = "FILE_PATH=\"" + filePath + "\"; MIME=\$(xdg-mime query filetype \"\$FILE_PATH\"); APPS_JSON=\"\"; for d in \$(echo \"\${XDG_DATA_HOME:-\$HOME/.local/share}:\${XDG_DATA_DIRS:-/usr/local/share:/usr/share}\" | tr ':' '\\n'); do if [ -f \"\$d/applications/mimeinfo.cache\" ]; then ids=\$(sed -n \"s|^\$MIME=||p\" \"\$d/applications/mimeinfo.cache\" | tr ';' ' '); for id in \$ids; do if [ -f \"\$d/applications/\$id\" ]; then OBJ=\$(awk -F '=' -v desktop_id=\"\$id\" ' /^\\[Desktop Entry\\]/ { inside=1; next } /^\\[/ { inside=0 } inside && /^Name=/ { name=\$2 } inside && /^Icon=/ { icon=\$2 } END { if (name!=\"\") print \"{\\\"name\\\":\\\"\"name\"\\\", \\\"icon\\\":\\\"\"icon\"\\\", \\\"desktop\\\":\\\"\"desktop_id\"\\\"}\" } ' \"\$d/applications/\$id\"); if [ -n \"\$OBJ\" ]; then if [ -z \"\$APPS_JSON\" ]; then APPS_JSON=\"\$OBJ\"; else APPS_JSON=\"\$APPS_JSON, \$OBJ\"; fi; fi; fi; done; fi; done; echo \"[\$APPS_JSON]\"";

                // Gửi lệnh vào hàng chờ của Executable Engine
                openWithProcessor.connectSource(cmd);
            }

            // Bắt sự kiện khi lệnh Bash chạy xong và trả về kết quả
            onNewData: (sourceName, data) => {
                // data.stdout chính là kết quả in ra Terminal từ câu lệnh của bồ
                var output = data.stdout ? data.stdout.trim() : "";
                var scannedApps = [];

                try {
                    if (output) {
                        scannedApps = JSON.parse(output);
                    }
                } catch (e) {
                    console.log("Lỗi xử lý JSON mã nguồn:", e);
                    scannedApps = [];
                }

                // --- 🎯 CỤM MERGE ĐÁP ỨNG ĐÚNG LOGIC CỦA BỒ ---
                var staticActions = root.model.actionNames.map(function(actionName) {
                    return {
                        "name": actionName,
                        "icon": "",
                        "type": "static",
                        "action": actionName
                    };
                });

                var dynamicApps = scannedApps.map(function(app) {
                    return {
                        "name": "Mở bằng " + app.name,
                        "icon": app.icon,
                        "type": "app",
                        "desktop": app.desktop
                    };
                });

                // Trộn mảng xong nạp thẳng vào Model
                root.actions = staticActions.concat(dynamicApps);
                console.log(JSON.stringify(root.actions, null, 4));

                // 🚨 QUAN TRỌNG: Ngắt kết nối để giải phóng engine sau khi chạy xong
                openWithProcessor.disconnectSource(sourceName);
            }
        }

        Timer {
            id: timeoutTimer
            interval: timeoutinterval
            running: model.closable
            onTriggered: {
                destroyme()
            }
            onRunningChanged: {
                if (running) {
                    timeoutAnim.start()
                    resetAnim.stop()
                } else if(!running) {
                    timeoutAnim.stop()
                    resetAnim.start()
                }
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
            anchors.fill: parent

            PlasmaComponents.ProgressBar {
                id: timeoutDisplay
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                from: 0
                to: timeoutinterval
                value: timeoutinterval

                NumberAnimation { // smooth countdown
                    id: timeoutAnim
                    target: timeoutDisplay
                    property: "value"
                    from: timeoutinterval
                    to: 0
                    duration: timeoutinterval
                    easing.type: Easing.Linear
                    running: false
                }

                NumberAnimation { // smooth countUP
                    id: resetAnim
                    target: timeoutDisplay
                    property: "value"
                    to: timeoutinterval
                    duration: {
                        var dist = to - timeoutDisplay.value
                        var fullDist = timeoutinterval
                        var stdDuration = 400

                        if (fullDist <= 0) return stdDuration;
                        if (dist <= 0) return 0;

                        var distRatio = dist / fullDist
                        var x = Math.pow(distRatio, 0.25);
                        x = Math.max(0, Math.min(1, x));

                        return x * stdDuration
                    }
                    easing.type: Easing.OutQuart
                    running: false
                }
            }

            ColumnLayout {
                id: toastArea
                Layout.margins: Kirigami.Units.largeSpacing

                scale: 1

                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: spectacleThumb.visible ? (root.notifWidth * 9 / 16) : 0
                    radius: 4
                    Image {
                        id: pillarEcho // you get what I'm doing
                        width: parent.width
                        height: parent.height
                        source: (imgURL !== undefined) ? imgURL : ""
                        visible: imgURL !== ""
                        fillMode: Image.PreserveAspectCrop
                    }

                    FastBlur {
                        source: pillarEcho
                        anchors.fill: pillarEcho
                        radius: 32
                        visible: pillarEcho.visible
                    }

                    Image {
                        width: parent.width
                        height: parent.height
                        id: spectacleThumb // mfer really used Spectacle for this
                        source: (imgURL !== undefined) ? imgURL : ""
                        visible: imgURL !== ""
                        fillMode: Image.PreserveAspectFit // you can see your thumbnails fully
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    anchors.margins: 12
                    spacing: 12

                    Kirigami.Icon {
                        source: model.iconName || "notifications-symbolic"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.large
                        Layout.preferredHeight: width
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        spacing: 2

                        PlasmaComponents.Label {
                            text: model.summary
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        PlasmaComponents.Label {
                            id: notifContents //literally text
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
                            // this guy doesn't know about object shows because he's in Vietnam and speaks Vietnamese!
                            // OBJECTION!
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
                                if (typeof win11Notif !== "undefined") { // no nonexisty- sorry, technical term: nullify
                                    notifRoot.opacity = 0
                                    destroyme()
                                }
                            }
                        }
                        PlasmaComponents.ToolButton {
                            icon.name: toolButtons.expandDelegate ? "arrow-up-symbolic" : "arrow-down-symbolic"
                            visible: notifContents.truncated ? true : toolButtons.expandDelegate // this is more readable
                            onClicked: {
                                toolButtons.expandDelegate = !toolButtons.expandDelegate
                            }
                            PlasmaComponents.ToolTip {
                                text: i18n("Expand notification")
                            }
                        }
                    }
                }

                PlasmaComponents.ProgressBar {
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: (model.percentage !== undefined) ? model.percentage : 0
                    indeterminate: (model.jobDetails !== undefined) ? (parseInt(model.jobDetails.speed, 10) === 0) : true
                    visible: !model.closable
                    Behavior on value { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: model.actionNames.length > 0
                    Repeater {
                        model: root.model.actionNames
                        delegate: PlasmaComponents.Button {
                            Layout.fillWidth: true
                            text: root.model.actionLabels[index]
                            onClicked: {
                                let action = root.model.actionNames[index];
                                let behavior = root.model.resident ? NotificationManager.Notifications.None : NotificationManager.Notifications.Close;
                                win11Notif.invokeAction(win11Notif.index(root.model.index, 0), action, behavior)
                                destroyme()
                            }
                        }
                    }
                    PlasmaComponents.Button {
                        id: menuButton
                        icon.name: "open-menu"

                        onClicked: {
                            // Mở ra và tự neo vào chính cái Button này
                            contexts.popup(menuButton)
                        }
                    }
                    PlasmaComponents.Menu {
                        id: contexts

                        Repeater {
                            model: root.totalMenuModel // Mảng đã merge [opena, gimp, gwenview...]

                            PlasmaComponents.MenuItem {
                                id: menuItem

                                // Hàm xử lý icon thông minh (Cân cả tên icon, png lẫn đường dẫn path)
                                function getIconSource(iconStr) {
                                    if (!iconStr) return "executable"
                                        if (iconStr.indexOf("/") === 0) return "file://" + iconStr
                                            if (iconStr.indexOf(".png") !== -1 || iconStr.indexOf(".svg") !== -1) return iconStr.split('.')[0]
                                                return iconStr
                                }

                                // Giao diện Luxury: Icon bên trái, Chữ bên phải
                                contentItem: RowLayout {
                                    spacing: 10

                                    Kirigami.Icon {
                                        source: menuItem.getIconSource(modelData.icon)
                                        implicitWidth: 16 // Size icon chuẩn của Context Menu Plasma 6
                                        implicitHeight: 16
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    PlasmaComponents.Label {
                                        text: modelData.name
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }

                                // Xử lý sự kiện click cho từng nút tạm thời
                                onClicked: {
                                    contextMenu.close() // Bấm xong là đóng menu tạm thời ngay

                                    if (modelData.type === "static") {
                                        let action = modelData.action
                                        let behavior = root.model.resident ? NotificationManager.Notifications.None : NotificationManager.Notifications.Close;
                                        win11Notif.invokeAction(win11Notif.index(root.model.index, 0), action, behavior)
                                        destroyme()
                                    } else if (modelData.type === "app") {
                                        // Chạy app động bằng lệnh qua Plasma5Support
                                        openWithProcessor.connectSource("gtk-launch " + modelData.desktop + " " + thumbnailer.url)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

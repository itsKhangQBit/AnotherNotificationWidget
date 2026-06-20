import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager
import org.kde.ksvg as KSvg

PlasmoidItem {
    id: root

    // do we really have to have a different name?
    property alias win11Notif: win11Notifications
    readonly property bool onTaskbar: Plasmoid.location === PlasmaCore.Types.TopEdge || Plasmoid.location === PlasmaCore.Types.BotômEdge || Plasmoid.location === PlasmaCore.Types.LeftEdge || Plasmoid.location === PlasmaCore.Types.RightEdge

    KSvg.FrameSvgItem {
        id : panelSvg

        visible: false

        imagePath: "widgets/panel-background"
    }

    NotificationManager.Notifications {
        id: win11Notifications
        showExpired: true
        showDismissed: true
        showJobs: true
    }

    NotifManager {
        id: notifManager
        panelHeight: panelSvg.margins.bottom
    }

    Repeater {
        model: win11Notifications
        delegate: Item {
            Component.onCompleted: {
                if (onTaskbar && !root.expanded) createToast(model);
                console.log("--- Obj property ---");
                for (var prop in model) {
                    try {
                        console.log("Property: " + prop + " | Value: " + model[prop]);
                    } catch (e) {
                        console.log("Property: " + prop + " | Error: " + e);
                    }
                }
                if (model.jobDetails) {
                    console.log("--- Jobs ---");
                    // Thử kiểm tra các thuộc tính thường có của Job
                    if (model.jobDetails.hasOwnProperty('remainingTime')) {
                        console.log("Remaining Time: " + model.jobDetails.remainingTime);
                    } else {
                        console.log("Không tìm thấy thuộc tính 'remainingTime' trực tiếp.");
                        // Thử in ra tất cả keys của jobDetails để xem cấu trúc
                        for (var prop in model.jobDetails) {
                            console.log("Prop: " + prop + " | Value: " + model.jobDetails[prop]);
                        }
                    }
                }
                if (model.actionLabels !== undefined) {
                    console.log("--- Actions ---");
                    console.log("actionLabels length/value:", model.actionLabels);
                    try {
                        console.log("actionLabels JSON stringify:", JSON.stringify(model.actionLabels));
                    } catch(e) {}
                    try {
                        for (var i = 0; i < 10; i++) { // Thử quét tối đa 10 phần tử
                            if (model.actionLabels[i] !== undefined) {
                                console.log("  => Label[" + i + "]: " + model.actionLabels[i]);
                            } else {
                                break;
                            }
                        }
                    } catch(e) {
                        console.log("Lỗi khi loop actionLabels: " + e);
                    }
                    if (model.actionNames !== undefined) {
                        console.log("actionNames length/value:", model.actionNames);
                        try {
                            console.log("actionNames JSON stringify:", JSON.stringify(model.actionNames));
                        } catch(e) {}
                        try {
                            for (var j = 0; j < 10; j++) {
                                if (model.actionNames[j] !== undefined) {
                                    console.log("  => Name/ID[" + j + "]: " + model.actionNames[j]);
                                } else {
                                    break;
                                }
                            }
                        } catch(e) {
                            console.log("Lỗi khi loop actionNames: " + e);
                        }
                    }
                }

                console.log("=========================================");
                console.log("  TRUY LÙNG DỮ LIỆU GỐC (DEEP INSPECTION) ");
                console.log("=========================================");

                var hintsObj = model.hints;

                if (hintsObj) {
                    // Cách 1: Thử ép sang chuỗi JSON để xem toàn bộ cấu trúc cây dữ liệu
                    try {
                        var jsonHints = JSON.stringify(hintsObj);
                        console.log("👉 TOÀN BỘ RUỘT CỦA HINTS (JSON):");
                        console.log(jsonHints);
                    } catch(e) {
                        console.log("Không thể stringify hints trực tiếp: " + e);
                    }

                    // Cách 2: Duyệt thủ công từng Key-Value nằm trong hints
                    console.log("\n👉 DUYỆT CHI TIẾT TỪNG KEY TRONG HINTS:");
                    for (var key in hintsObj) {
                        try {
                            var val = hintsObj[key];
                            console.log("  🔹 Key: [" + key + "] => Value: " + val + " (Kiểu: " + typeof(val) + ")");

                            // Nếu Value lại là một Object/Array ẩn khác, ta bóc tiếp một lớp nữa
                            if (typeof(val) === "object") {
                                console.log("     ↳ Chi tiết bên trong: " + JSON.stringify(val));
                            }
                        } catch(err) {
                            console.log("  🔺 Lỗi đọc key [" + key + "]: " + err);
                        }
                    }
                } else {
                    console.log("❌ hints bị undefined hoặc null!");
                }

                // Kiểm tra thêm mảng urls kèm theo thông báo (Role UrlsRole)
                if (model.urls) {
                    console.log("\n👉 MẢNG URLS ĐI KÈM THÔNG BÁO:");
                    console.log(JSON.stringify(model.urls));
                }
                console.log("=========================================");

                console.log("=== BẮT ĐẦU TRUY LÙNG HÀM TỪ CÁC ĐỐI TƯỢNG CHA ===");

                // Hàm phụ để dump sạch sành sanh các method có tên rõ ràng
                function scanRealMethods(obj, objName) {
                    if (!obj) {
                        console.log("[" + objName + "] không tồn tại (undefined/null).");
                        return;
                    }
                    console.log("\n🔍 Đang quét hàm của: " + objName);
                    try {
                        var keys = Object.getOwnPropertyNames(obj);
                        var found = false;
                        keys.forEach(function(k) {
                            // Lọc bỏ các hàm đổi thuộc tính (*Changed) và các hàm dạng __0, __1 cho đỡ rác log
                            if (typeof obj[k] === "function" && !k.endsWith("Changed") && !k.startsWith("__")) {
                                console.log("  ⭐ Tìm thấy hàm có thể gọi: " + k + "()");
                                found = true;
                            }
                        });
                        if (!found) console.log("  => Không có hàm thực thi trực tiếp nào (ngoại trừ hàm ẩn hoặc *Changed).");
                    } catch(e) {
                        console.log("  ❌ Lỗi khi quét " + objName + ": " + e);
                    }
                }

                // 1. Kiểm tra đối tượng bọc ngoài cùng của file QML (root)
                if (typeof root !== "undefined") {
                    scanRealMethods(root, "root");
                }

                // 2. Nếu Toast nằm trong ListView, đối tượng 'model' tổng quản lý danh sách sẽ nằm ở đây
                // Thường ListView sẽ có một property tên là 'model' chứa các hàm điều khiển
                // Lưu ý: Đang check 'model' của View chứ không phải biến 'model' (DMAbstractItemModelData) của item nhé!
                if (typeof parent !== "undefined" && parent && parent.model) {
                    scanRealMethods(parent.model, "parent.model (Model tổng)");
                }

                // 3. Quét thử môi trường xung quanh (KDE Plasma Notification thường hay định nghĩa các biến này)
                if (typeof notificationModel !== "undefined") {
                    scanRealMethods(notificationModel, "notificationModel toàn cục");
                }
                if (typeof notificationsModel !== "undefined") {
                    scanRealMethods(notificationsModel, "notificationsModel toàn cục");
                }
            }
        }
    }

    compactRepresentation: MouseArea {
        // filling the ideas here, AI is allowed

        // fill many stuff as you can
        Layout.preferredWidth: plasmoidRow.implicitWidth + Kirigami.Units.smallSpacing
        Layout.preferredHeight: plasmoidRow.implicitHeight + Kirigami.Units.smallSpacing
        Layout.minimumWidth: plasmoidRow.implicitWidth + Kirigami.Units.smallSpacing
        Layout.minimumHeight: plasmoidRow.implicitHeight + Kirigami.Units.smallSpacing

        // get the click action to open the popup
        property bool wasExpanded: false
        onPressed: wasExpanded = root.expanded
        onClicked: root.expanded = !wasExpanded

        ColumnLayout {
            id: plasmoidRow
            anchors.centerIn: parent
            spacing: 2

            PlasmaComponents.Label {
                // Uses the timer-updated global date property from root
                // format again
                text: {
                    var timeFormat = Plasmoid.configuration.twelveHr ? "hh:mm" : "HH:mm"
                    return Qt.formatDateTime(root.currentDate, timeFormat)
                }
                color: Kirigami.Theme.textColor
                font.pixelSize: 13
                font.weight: Font.Normal
                Layout.alignment: Qt.AlignHCenter
            }
            PlasmaComponents.Label {
                // make sure our buddies over the US gets the date by typing the format in
                text: Qt.formatDateTime(root.currentDate, Plasmoid.configuration.dateFormat)
                color: Kirigami.Theme.textColor
                opacity: 0.7
                font.pixelSize: 11
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
    fullRepresentation: FullPopup {
        id: fullPopup
        appletroot: root
    }

    // Updates a global date object every second for both views
    property date currentDate: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentDate = new Date()
    }

    // function for spawning notif
    function createToast(model) {
        var component = Qt.createComponent("Toasty.qml");

        Qt.callLater(function() {
            if (component.status === Component.Ready) {
                // take all shit in
                var toast = component.createObject(null, { "model": model });

                if (toast !== null) {
                    notifManager.regToast(toast); //register so we can calculate y
                    toast.killme.connect(notifManager.unregToast);
                    toast.reCalculatePos.connect(notifManager.updateToast);
                    toast.show(); // show 'em the notification, boi!
                } else {
                    console.log("Can't create object Toasty.qml");
                }
            } else {
                console.log("Component ain't ready: " + component.errorString());
            }
        });
    }
}

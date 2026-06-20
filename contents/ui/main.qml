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

                /*
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
                        console.log("Can't find remainingTime");
                        // Thử in ra tất cả keys của jobDetails để xem cấu trúc
                        for (var prop in model.jobDetails) {
                            console.log("Property: " + prop + " | Value: " + model.jobDetails[prop]);
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
                        console.log("Can't loop actionLabels: " + e);
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
                            console.log("Can't loop actionNames: " + e);
                        }
                    }
                }

                var hintsObj = model.hints;

                if (hintsObj) {
                    try {
                        var jsonHints = JSON.stringify(hintsObj);
                        console.log("Hints (JSON):");
                        console.log(jsonHints);
                    } catch(e) {
                        console.log("Can't stringify hint: " + e);
                    }

                    console.log("\n👉 Keys in hint:");
                    for (var key in hintsObj) {
                        try {
                            var val = hintsObj[key];
                            console.log("  🔹 Key: [" + key + "] => Value: " + val + " (Type: " + typeof(val) + ")");

                            if (typeof(val) === "object") {
                                console.log("     ↳ Info: " + JSON.stringify(val));
                            }
                        } catch(err) {
                            console.log("Can't read key [" + key + "]: " + err);
                        }
                    }
                } else {
                    console.log("Hints might be undefined");
                }*/
            }
        }
    }
    */

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

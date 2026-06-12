import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager

PlasmoidItem {
    id: root

    // do we really have to have a different name?
    property alias win11Notif: win11Notifications

    NotificationManager.Notifications {
        id: win11Notifications

        showExpired: true
        showDismissed: true
        showJobs: true
    }

    Component.onCompleted: {
        for (var method in win11Notifications) {
            console.log("Hàm khả dụng: " + method);
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

    Instantiator {
        model: win11Notifications
        delegate: Toasty {
            title: model.summary
            contents: model.body
            icon: model.iconName  || "dialog-information"
            notifIndex: index
            //win11Notifications: root.win11Notifications

            Component.onCompleted: {
                show();
            }
        }
    }

    // function for spawning notif
    function createToast(title, contents, icon, index, model) {
        var component = Qt.createComponent("Toasty.qml");

        Qt.callLater(function() {
            if (component.status === Component.Ready) {
                // take all shit in
                var newToast = component.createObject(null, { "title": title, "contents": contents, "icon": icon, "notifIndex": index, "win11Notifications": win11Notifications });

                if (newToast !== null) {
                    newToast.show(); // show 'em the notification, boi!
                } else {
                    console.log("Can't create object Toasty.qml");
                }
            } else {
                console.log("Component ain't ready: " + component.errorString());
            }
        });
    }
}

import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

QtObject {
    id: manager
    property var toastList: []
    readonly property int toastHeight: 120
    readonly property int spacing: Kirigami.Units.smallSpacing
    property var panelHeight: 50
    property real screenGeometry: 1920

    function regToast(toast) {
        toastList.push(toast);
        updateToast();
    }

    function unregToast(toast) {
        var index = toastList.indexOf(toast); // get index
        if (index !== -1) {
            toastList.splice(index, 1); // remove index
            updateToast();
        }
    }

    function updateToast() {
        // stack (top2bottom - for top taskbars)
        var spacing = Kirigami.Units.gridUnit
        var screenAvail = plasmoid.containment.availableScreenRect
        var screenGeom = plasmoid.containment.screenGeometry
        var screen = Qt.rect(screenAvail.x + screenGeom.x, screenAvail.y + screenGeom.y, screenAvail.width, screenAvail.height);
        var stackY = screen.y + panelHeight
        for (var i = 0; i < toastList.length; i++) {
            var toast = toastList[i];
            toast.targetY = stackY;
            stackY += toast.height + spacing;
        }
    }
}

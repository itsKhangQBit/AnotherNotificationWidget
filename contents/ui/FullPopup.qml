import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import Qt5Compat.GraphicalEffects 1.15
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.networkmanagement as NetworkManagement

// This source code was made with Rubber Duck Debugging™ (joke, the Duck is an AI and I roasted the duck for dinner..!?)

Item {
id: fullPopup
    //=============================================\\
    // PART 1: THE TOASTS (Notification center)    || bro bubble messages, really?
    //=============================================//
    implicitWidth: Math.max(mainLayout.implicitWidth, 300)
    implicitHeight: Math.max(mainLayout.implicitHeight, 200)

    Layout.preferredWidth: fullPopup.implicitWidth + Kirigami.Units.smallSpacing
    Layout.preferredHeight: fullPopup.implicitHeight + Kirigami.Units.smallSpacing
    Layout.minimumWidth: fullPopup.implicitWidth + Kirigami.Units.smallSpacing
    Layout.minimumHeight: fullPopup.implicitHeight + Kirigami.Units.smallSpacing
    property var appletroot: "root"

    function qtOpexExternal(id, urls) {
        var itemIndex = win11Notif.index(id, 0);

        // is itemIndex a real item?
        if (!itemIndex.valid) {
            console.log("Notification is deleted :(");
            return;
        }
        if (urls && urls.length > 0) {
            Qt.openUrlExternally(urls[0]);
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        clip: true
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
            height: fullPopup.implicitHeight / 5 * 3
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

                    // smart scrolling so you don't get kicked to the top by One- no, by the goddamn list view (BFDI fan caught in 4k)
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

                        property var imgURL: (model.urls && model.urls.length > 0) ? model.urls[0].toString() : ""

                        height: {
                            var shortHeight = 145
                            var thumbHeight = 375
                            var noExpandHeight =  (imgURL !== "" && imgURL !== undefined) ? thumbHeight : shortHeight
                            return Math.max(contents.implicitHeight + Kirigami.Units.largeSpacing * 2, noExpandHeight)
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

                            onPressed: {
                                delegateRoot.scale = 0.95
                            }
                            onClicked: {
                                if (model.hasDefaultAction) win11Notif.invokeDefaultAction(win11Notif.index(model.index, 0), behavior)
                                else qtOpexExternal(model.index, model.urls)
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
                                    spacing: 12

                                    Kirigami.Icon {
                                        source: model.iconName || "notifications-symbolic"
                                        Layout.preferredWidth: Kirigami.Units.iconSizes.large
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
                                            id: notifContents
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
                                            visible: notifContents.truncated ? true : toolButtons.expandDelegate // this is more readable
                                            onClicked: toolButtons.expandDelegate = !toolButtons.expandDelegate
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
                                    id: buttonRow // come on ids so no not defined errors?
                                    Layout.fillWidth: true
                                    visible: model.actionNames.length > 0

                                    property var delegateModels: model // had to pass the models in

                                    Repeater {
                                        model: buttonRow.delegateModels.actionNames
                                        delegate: PlasmaComponents.Button {
                                            Layout.fillWidth: true
                                            text: buttonRow.delegateModels.actionLabels[index]
                                            onClicked: {
                                                let action = buttonRow.delegateModels.actionNames[index];
                                                let behavior = buttonRow.delegateModels.resident ? NotificationManager.Notifications.None : NotificationManager.Notifications.Close;
                                                win11Notif.invokeAction(win11Notif.index(buttonRow.delegateModels.index, 0), action, behavior)
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

        //====================\\
        // No more part 1!    ||
        //====================//

        Kirigami.Separator { // for your visiblity
            Layout.fillWidth: true
            opacity: 0.3
        }

        //===========================================\\
        // PART 2: QUICK CONTROLS (Action center)    ||
        //===========================================//

        property string quickpage: "main"

        ColumnLayout {
            id: quickControls
            visible: mainLayout.quickpage === "main"
            Layout.fillHeight: true
            Layout.fillWidth: true
            property int brightness: 5000 //default
            property int volume: 50
            property bool mute: false
            property var wifilist: []
            property var wifistat: []
            property bool wifi: true

            Component.onCompleted: {
                controller.getbright()
                controller.getvol()
                controller.getwifistat()
                controller.getwifionoff()
            }

            Plasma5Support.DataSource {
                id: controller
                engine: "executable"
                // this is a hell of a function, base is literally nmcli stuff

                function setbright(int) { // 1st time using vars like this to make code more readable
                    connectSource("qdbus org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl org.kde.Solid.PowerManagement.Actions.BrightnessControl.setBrightness " + int)
                }
                function setvol(int) {
                    connectSource("pactl set-sink-volume @DEFAULT_SINK@ " + int + "%")
                }
                function setmute(bool) {
                    connectSource("pactl set-sink-mute @DEFAULT_SINK@ " + bool)
                }
                function setwifionoff(bool) {
                    let status = bool ? "on" : "off"
                    connectSource("nmcli radio wifi " + status)
                }
                function connectwifi(bssid, pass, secureisbool) {
                    let rawconnectcmd = "nmcli device wifi connect " + bssid
                    let executecmd = secureisbool ? rawconnectcmd + ' password "' + pass + '"' : rawconnectcmd
                    connectSource(executecmd)
                }
                function getbright() {
                    connectSource("qdbus org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl org.kde.Solid.PowerManagement.Actions.BrightnessControl.brightness")
                }
                function getvol() {
                    connectSource("pactl get-sink-volume @DEFAULT_SINK@")
                    connectSource("pactl get-sink-mute @DEFAULT_SINK@")
                }
                function getwifistat() {
                    let wificode = 'nmcli -t -f SSID,BSSID,SIGNAL,SECURITY device wifi list | awk -F \':\' \'BEGIN{print "["} $1!=""{gsub(/"/, "\\\"", $1); b=$2":"$3":"$4":"$5":"$6":"$7; print (L++?",":"") "{\\"ssid\\":\\""$1"\\",\\\"bssid\\":\\""b"\\",\\\"signal\\":"$8",\\\"security\\\":\\""$9"\\"}"} END{print "\\n]"}\' | sed \'s/\\\\:/:/g\' | tr -d \'\\n\'';

                    let bashedlister = "bash << 'EOF'\n" + wificode + "\nEOF"; //my god only eof works, bash -c would take all my backslashes

                    let wifistat = "LANG=C LC_ALL=C nmcli -t -f ACTIVE,SSID,BSSID,SIGNAL,SECURITY device wifi list | sed 's/\\\\:/:/g' | awk -F ':' '$1==" + '"yes"{bssid=$3":"$4":"$5":"$6":"$7":"$8; print "{\\\"ssid\\\":\\\""$2"\\\",\\\"bssid\\\":\\\""bssid"\\\",\\\"signal\\\":"$9",\\\"security\\\":\\\""$10"\\\"}"}' + "'"

                    let bashedstatus = "bash << 'EOF'\n" + wifistat + "\nEOF";

                    connectSource(bashedlister);
                    connectSource(bashedstatus);
                }
                function getwifionoff() {
                    connectSource("nmcli radio wifi")
                }
                onNewData: (sourceName, data) => {
                    if (sourceName.endsWith(".brightness")) {
                        quickControls.brightness = parseInt(data["stdout"], 10)
                        if (!volSlider.pressed) brightSlider.value = quickControls.brightness
                    }
                    else if (sourceName.includes("get-sink-volume")) {
                        let match = data["stdout"].match(/(\d+)%/);
                        if (match && match[1]) {
                            quickControls.volume = parseInt(match[1], 10);
                            if (!volSlider.pressed) volSlider.value = quickControls.volume;
                        }
                    }
                    else if (sourceName.includes("get-sink-mute")) {
                        quickControls.mute = data["stdout"].includes("yes")
                    }
                    else if (sourceName.startsWith("bash << 'EOF'\nnmcli -t -f SSID,BSSID,SIGNAL,SECURITY device wifi list")) {
                        quickControls.wifilist = JSON.parse(data["stdout"])
                    }
                    else if (sourceName.includes('"yes"{bssid=$3":"$4":"$5":"$6":"$7":"$8; print "{\\\"ssid\\\":\\\""$2"\\\",\\\"bssid\\\":\\\""bssid"\\\",\\\"signal\\\":"$9",\\\"security\\\":\\\""$10"\\\"}"}')) {
                        quickControls.wifistat = (data["stdout"] === "") ? JSON.parse('{"ssid":"","bssid":"","signal":0,"security":""}') : JSON.parse(data["stdout"])
                    }
                    else if (sourceName === "nmcli radio wifi") quickControls.wifi = data["stdout"].includes("enabled")
                    disconnectSource(sourceName)
                }
            }

            Timer {
                interval: 2000
                running: true
                repeat: true
                onTriggered: {
                    controller.getbright()
                    controller.getvol()
                    controller.getwifionoff()
                }
            }

            Timer {
                interval: mainLayout.quickpage === "wifi" ? 240000 : 2000
                running: quickControls.wifi
                repeat: true
                onTriggered: {
                    if (wifipage.userPasstyping) return
                    controller.getwifistat()
                }
                onRunningChanged: {
                    if (running) controller.getwifistat()
                        else quickControls.wifistat = { "ssid": "", "bssid": "", "signal": 0, "security": "" }
                }
            }

            RowLayout {
                Kirigami.Icon {
                    source: (brightSlider.value >= 50) ? "brightness-high-symbolic" : "brightness-low-symbolic"
                    width: 16
                    height: width
                }
                PlasmaComponents.Slider {
                    id: brightSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 10000 // dbus says 10000 so I'll set 10000
                    stepSize: 100
                    onMoved: controller.setbright(value)
                }
            }
            RowLayout {
                PlasmaComponents.ToolButton {
                    checkable: true
                    checked: quickControls.mute
                    icon.name: {
                        if (quickControls.mute) return "audio-volume-muted-symbolic"
                            if (volSlider.value >= 66) return "audio-volume-high-symbolic"
                                if (volSlider.value >= 33) return "audio-volume-medium-symbolic"
                                    if (volSlider.value >= 0) return "audio-volume-low-symbolic"
                                        return "audio-volume-muted-symbolic"
                    }
                    PlasmaComponents.ToolTip {
                        text: i18n("Mute")
                    }
                    onToggled: controller.setmute(checked)
                }
                PlasmaComponents.Slider {
                    id: volSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 100 // dbus says 10000 so I'll set 10000
                    stepSize: 1
                    onMoved: controller.setvol(value)
                }
            }

            ColumnLayout {
                RowLayout {
                    PlasmaComponents.ToolButton {
                        checkable: true
                        checked: quickControls.wifi
                        icon.name: {
                            var secure = (quickControls.wifistat.security && quickControls.wifistat.security !== "" && !quickControls.wifistat.security.includes("--") && !quickControls.wifistat.security.includes("[]")) ? "-locked" : ""
                            return "network-wireless-" + Math.max(Math.ceil(quickControls.wifistat.signal / 20), 1) * 20 + secure
                        }
                        onToggled: {
                            controller.setwifionoff(checked)
                        }
                    }
                    PlasmaComponents.ToolButton {
                        icon.name: "arrow-right-symbolic"
                        onClicked: {
                            mainLayout.quickpage = "wifi";
                        }
                    }
                }
                PlasmaComponents.Label {
                    text: quickControls.wifistat && quickControls.wifistat.ssid ? quickControls.wifistat.ssid : i18n("Disconnected")
                }
            }
        }

        ColumnLayout {
            id: wifipage
            property bool userPasstyping: false

            visible: mainLayout.quickpage === "wifi"
            Layout.fillWidth: true
            Layout.fillHeight: true

            //headers
            RowLayout {
                PlasmaComponents.ToolButton {
                    icon.name: "arrow-left-symbolic"
                    onClicked: {
                        mainLayout.quickpage = "main";
                    }
                }
                PlasmaComponents.Label {
                    text: i18n("Networks")
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                PlasmaComponents.Switch {
                    checked: quickControls.wifi
                    onToggled: {
                        controller.setwifionoff(checked)
                    }
                }
            }

            //weefee around you
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                PlasmaComponents.ScrollView {
                    anchors.fill: parent
                    clip: true
                    contentWidth: availableWidth
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    ListView {
                        id: wifilister
                        clip: true
                        model: quickControls.wifilist ? quickControls.wifilist : 0
                        spacing: Kirigami.Units.smallSpacing
                        delegate: PlasmaComponents.ItemDelegate {
                            id: wifientry // tryna cook with names

                            property bool secure: (modelData.security && modelData.security !== "" && !modelData.security.includes("--") && !modelData.security.includes("[]"))
                            property string strength: {
                                return "network-wireless-" + Math.max(Math.ceil(modelData.signal / 20), 1) * 20
                            }
                            property bool passwording: false

                            height: passwording ? 84 : 56
                            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuad} }
                            width: wifilister.width
                            clip: true

                            contentItem: ColumnLayout {
                                RowLayout {
                                    Kirigami.Icon {
                                        source: {
                                            return wifientry.secure ? wifientry.strength + "-locked" : wifientry.strength
                                        }
                                        width: Kirigami.Units.iconSizes.small
                                        height: width
                                    }
                                    PlasmaComponents.Label {
                                        id: ssidLabel
                                        text: modelData.ssid ? modelData.ssid : i18n("Hidden network") + "(" + modelData.bssid + ")"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true

                                        PlasmaComponents.ToolTip {
                                            text: ssidLabel.text
                                            visible: ssidArea.containsMouse
                                        }

                                        MouseArea {
                                            id: ssidArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                        }
                                    }
                                    PlasmaComponents.ToolButton {
                                        text: wifientry.passwording ? i18n("Cancel") : i18n("Connect")
                                        icon.name: "network-connect"
                                        onClicked: if (secure) wifientry.passwording = !wifientry.passwording
                                    }
                                }

                                // literally handcoded this section
                                RowLayout {
                                    id: passwordinput
                                    visible: opacity > 0
                                    opacity: wifientry.passwording ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                                    property bool hidethepass: true

                                    PlasmaComponents.TextField {
                                        id: passworder
                                        Layout.fillWidth: true
                                        placeholderText: i18n("Password?")
                                        echoMode: passwordinput.hidethepass ? TextInput.Password : TextInput.Normal
                                        onActiveFocusChanged: wifipage.userPasstyping = activeFocus
                                    }
                                    PlasmaComponents.ToolButton {
                                        checkable: true
                                        checked: !passwordinput.hidethepass
                                        icon.name: passwordinput.hidethepass ? "gnumeric-row-unhide-symbolic" : "gnumeric-row-hide-symbolic" // if this don't look right to you then change it!
                                        onToggled: passwordinput.hidethepass = !passwordinput.hidethepass
                                        PlasmaComponents.ToolTip {
                                            text: passwordinput.hidethepass ? i18n("Unide password") : i18n("Hide password")
                                        }
                                    }
                                    PlasmaComponents.ToolButton {
                                        icon.name: "network-connect"
                                        onClicked: {
                                            controller.connectwifi(modelData.bssid, passworder.text, secure)
                                            wifientry.passwording = !wifientry.passwording
                                        }
                                        PlasmaComponents.ToolTip {
                                            text: i18n("Connect!")
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
}

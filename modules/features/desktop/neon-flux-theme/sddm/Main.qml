import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: config.canvas
    property bool busy: false
    property string message: ""
    property int selectedSession: sessionModel.lastIndex
    function login() {
        if (busy || username.text.trim() === "" || selectedSession < 0) return;
        message = "";
        busy = true;
        sddm.login(username.text.trim(), password.text, selectedSession);
    }
    Image {
        anchors.fill: parent
        source: "background.png"
        fillMode: Image.PreserveAspectCrop
    }
    Rectangle { anchors.fill: parent; color: config.canvas; opacity: 0.35 }
    Rectangle {
        anchors.centerIn: parent
        width: Math.min(440, root.width - 32)
        height: form.implicitHeight + 64
        radius: 22
        color: config.surface
        border.color: config.structure
        border.width: 1
        ColumnLayout {
            id: form
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 32 }
            spacing: 16
            Label {
                text: " /\_/\\  "
                color: config.accent
                font { family: "BlexMono Nerd Font Mono"; pixelSize: 30 }
                Layout.alignment: Qt.AlignHCenter
            }
            Label {
                text: "( o.o )  NEON FLUX"
                color: config.text
                font { family: "BlexMono Nerd Font Mono"; pixelSize: 22; bold: true }
                Layout.alignment: Qt.AlignHCenter
            }
            Label {
                text: "Your terminal cat cleared you for landing."
                color: config.muted
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Label { text: "USER"; color: config.accent; font.pixelSize: 12 }
            TextField {
                id: username
                Accessible.name: "Username"
                Layout.fillWidth: true
                text: userModel.lastUser
                enabled: !root.busy
                color: config.text
                selectionColor: config.selection
                selectedTextColor: config.text
                font { family: "BlexMono Nerd Font Mono"; pixelSize: 16 }
                padding: 14
                background: Rectangle {
                    radius: 8; color: config.raised
                    border.color: username.activeFocus ? config.accent : config.border
                }
                onAccepted: password.forceActiveFocus()
            }
            Label { text: "PASSWORD"; color: config.accent; font.pixelSize: 12 }
            TextField {
                id: password
                objectName: "password"
                Accessible.name: "Password"
                Layout.fillWidth: true
                enabled: !root.busy
                focus: true
                echoMode: TextInput.Password
                color: config.text
                selectionColor: config.selection
                selectedTextColor: config.text
                font { family: "BlexMono Nerd Font Mono"; pixelSize: 16 }
                padding: 14
                background: Rectangle {
                    radius: 8; color: config.raised
                    border.color: password.activeFocus ? config.accent : config.border
                }
                onAccepted: root.login()
            }
            Label { text: "SESSION"; color: config.muted; font.pixelSize: 12 }
            ComboBox {
                id: session
                Layout.fillWidth: true
                model: sessionModel
                textRole: "name"
                currentIndex: root.selectedSession
                enabled: !root.busy
                onActivated: root.selectedSession = index
                padding: 12
                contentItem: Text {
                    text: session.displayText; color: config.text
                    font.pixelSize: 14; verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 8; color: config.raised
                    border.color: session.activeFocus ? config.accent : config.border
                }
                indicator: Text {
                    x: session.width - width - 14; anchors.verticalCenter: parent.verticalCenter
                    text: "▾"; color: config.accent
                }
                delegate: ItemDelegate {
                    width: session.width
                    contentItem: Text { text: model.name; color: config.text; font.pixelSize: 14 }
                    background: Rectangle { color: highlighted ? config.selection : config.raised }
                    highlighted: session.highlightedIndex === index
                }
                popup: Popup {
                    y: session.height + 4; width: session.width
                    implicitHeight: Math.min(contentItem.implicitHeight + 16, 240)
                    padding: 8
                    contentItem: ListView {
                        clip: true; implicitHeight: contentHeight
                        model: session.popup.visible ? session.delegateModel : null
                        currentIndex: session.highlightedIndex
                        ScrollIndicator.vertical: ScrollIndicator { }
                    }
                    background: Rectangle { color: config.raised; radius: 8; border.color: config.structure }
                }
            }
            Label {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.message
                color: config.error
                wrapMode: Text.WordWrap
                font.pixelSize: 13
                Accessible.role: Accessible.AlertMessage
            }
            Button {
                id: launch
                Layout.fillWidth: true
                text: root.busy ? "Preparing for takeoff…" : "Log in  →"
                enabled: !root.busy
                padding: 14
                onClicked: root.login()
                contentItem: Text {
                    text: launch.text; color: config.canvas
                    horizontalAlignment: Text.AlignHCenter
                    font { pixelSize: 16; bold: true }
                }
                background: Rectangle {
                    radius: 8
                    color: launch.down ? config.accentBright : config.accent
                    opacity: launch.enabled ? 1 : 0.6
                    border.color: launch.activeFocus ? config.text : config.accent
                    border.width: launch.activeFocus ? 2 : 1
                }
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20
                Repeater {
                    model: [ { label: "Sleep", available: sddm.canSuspend, action: "suspend" },
                             { label: "Restart", available: sddm.canReboot, action: "reboot" },
                             { label: "Shut down", available: sddm.canPowerOff, action: "powerOff" } ]
                    delegate: Button {
                        id: power
                        required property var modelData
                        visible: modelData.available
                        enabled: !root.busy
                        text: modelData.label
                        padding: 6
                        contentItem: Text { text: power.text; color: power.hovered ? config.accent : config.muted; font.pixelSize: 12 }
                        background: Rectangle { color: config.surface; radius: 4; border.color: power.activeFocus ? config.accent : config.surface }
                        onClicked: {
                            if (modelData.action === "suspend") sddm.suspend();
                            else if (modelData.action === "reboot") sddm.reboot();
                            else sddm.powerOff();
                        }
                    }
                }
            }
        }
    }
    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false;
            root.message = "Login failed. Check your username and password.";
            password.text = "";
            password.forceActiveFocus();
        }
        function onLoginSucceeded() { root.message = ""; }
    }
    Component.onCompleted: {
        if (selectedSession < 0 && sessionModel.count > 0) selectedSession = 0;
        if (username.text === "") username.forceActiveFocus();
        else password.forceActiveFocus();
    }
}

import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Widgets

Popup {
    id: contextMenu

    property var peerData: null
    property bool isTerminalConfigured: false
    property int selectedIndex: -1
    property bool keyboardNavigation: false

    signal actionRequested(string action, var peer)

    property var menuItems: [
        {
            text: "Copy IP",
            icon: "content_copy",
            action: "copy-ip",
            enabled: true
        },
        {
            text: "Copy Hostname",
            icon: "copy_all",
            action: "copy-hostname",
            enabled: true
        },
        {
            type: "separator"
        },
        {
            text: "SSH to Host",
            icon: "terminal",
            action: "ssh",
            enabled: (peerData?.Online || false) && isTerminalConfigured
        },
        {
            text: "Ping Host",
            icon: "radar",
            action: "ping",
            enabled: isTerminalConfigured
        },
        {
            type: "separator"
        },
        {
            text: "Open in Admin",
            icon: "open_in_new",
            action: "admin-console",
            enabled: true
        }
    ]

    property int visibleItemCount: {
        let count = 0;
        for (let i = 0; i < menuItems.length; i++) {
            if (menuItems[i].type !== "separator")
                count++;
        }
        return count;
    }

    function show(x, y, fromKeyboard) {
        let finalX = x;
        let finalY = y;

        if (contextMenu.parent) {
            const parentWidth = contextMenu.parent.width;
            const parentHeight = contextMenu.parent.height;
            const menuWidth = contextMenu.width;
            const menuHeight = contextMenu.height;

            if (finalX + menuWidth > parentWidth)
                finalX = Math.max(0, parentWidth - menuWidth);
            if (finalY + menuHeight > parentHeight)
                finalY = Math.max(0, parentHeight - menuHeight);
        }

        contextMenu.x = finalX;
        contextMenu.y = finalY;
        keyboardNavigation = fromKeyboard || false;
        selectedIndex = fromKeyboard ? 0 : -1;
        open();
    }

    function selectNext() {
        if (visibleItemCount === 0)
            return;
        let current = selectedIndex;
        let next = current;
        do {
            next = (next + 1) % menuItems.length;
        } while (menuItems[next].type === "separator" && next !== current)
        selectedIndex = next;
    }

    function selectPrevious() {
        if (visibleItemCount === 0)
            return;
        let current = selectedIndex;
        let prev = current;
        do {
            prev = (prev - 1 + menuItems.length) % menuItems.length;
        } while (menuItems[prev].type === "separator" && prev !== current)
        selectedIndex = prev;
    }

    function activateSelected() {
        if (selectedIndex < 0 || selectedIndex >= menuItems.length)
            return;
        const item = menuItems[selectedIndex];
        if (item.type === "separator" || !item.enabled)
            return;
        actionRequested(item.action, peerData);
        close();
    }

    width: 200
    height: menuColumn.implicitHeight + Theme.spacingS * 2
    padding: 0
    modal: false
    closePolicy: Popup.CloseOnEscape

    onClosed: {
        closePolicy = Popup.CloseOnEscape;
        keyboardNavigation = false;
        selectedIndex = -1;
    }

    onOpened: {
        outsideClickTimer.start();
        if (keyboardNavigation)
            Qt.callLater(() => keyboardHandler.forceActiveFocus());
    }

    Timer {
        id: outsideClickTimer
        interval: 100
        onTriggered: contextMenu.closePolicy = Popup.CloseOnEscape | Popup.CloseOnPressOutside
    }

    background: Rectangle {
        color: "transparent"
    }

    contentItem: Rectangle {
        color: Theme.withAlpha(Theme.surfaceContainer, Theme.popupTransparency)
        radius: Theme.cornerRadius
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
        border.width: 1

        Item {
            id: keyboardHandler
            anchors.fill: parent
            focus: keyboardNavigation

            Keys.onPressed: event => {
                switch (event.key) {
                case Qt.Key_Down:
                case Qt.Key_J:
                    keyboardNavigation = true;
                    selectNext();
                    event.accepted = true;
                    return;
                case Qt.Key_Up:
                case Qt.Key_K:
                    keyboardNavigation = true;
                    selectPrevious();
                    event.accepted = true;
                    return;
                case Qt.Key_Return:
                case Qt.Key_Enter:
                case Qt.Key_Space:
                    activateSelected();
                    event.accepted = true;
                    return;
                case Qt.Key_Escape:
                case Qt.Key_Left:
                case Qt.Key_H:
                    close();
                    event.accepted = true;
                    return;
                }
            }
        }

        Column {
            id: menuColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingS
            spacing: 1

            Repeater {
                model: menuItems

                Item {
                    width: parent.width
                    height: modelData.type === "separator" ? 5 : 32
                    visible: modelData.type !== "separator" || index > 0

                    Rectangle {
                        visible: modelData.type === "separator"
                        width: parent.width - Theme.spacingS * 2
                        height: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
                    }

                    Rectangle {
                        id: menuItem
                        visible: modelData.type !== "separator"
                        width: parent.width
                        height: 32
                        radius: Theme.cornerRadius
                        color: {
                            if (!modelData.enabled)
                                return "transparent";
                            const isSelected = keyboardNavigation && selectedIndex === index;
                            if (isSelected)
                                return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2);
                            return menuItemArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent";
                        }
                        opacity: modelData.enabled ? 1 : 0.5

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingS

                            DankIcon {
                                name: modelData.icon || ""
                                size: 16
                                color: modelData.enabled ? Theme.surfaceText : Theme.surfaceVariantText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: modelData.text || ""
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Normal
                                color: modelData.enabled ? Theme.surfaceText : Theme.surfaceVariantText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        DankRipple {
                            id: menuItemRipple
                            rippleColor: Theme.surfaceText
                            cornerRadius: menuItem.radius
                        }

                        MouseArea {
                            id: menuItemArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            enabled: modelData.enabled ?? false
                            onEntered: {
                                keyboardNavigation = false;
                                selectedIndex = index;
                            }
                            onPressed: mouse => menuItemRipple.trigger(mouse.x, mouse.y)
                            onClicked: {
                                actionRequested(modelData.action, peerData);
                                close();
                            }
                        }
                    }
                }
            }
        }
    }
}

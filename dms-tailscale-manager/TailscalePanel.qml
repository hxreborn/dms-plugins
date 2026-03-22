import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import "."

Column {
    id: root

    property var daemon: null

    width: parent.width
    spacing: Theme.spacingM

    property bool isTerminalConfigured: (daemon?.terminalCommand ?? "").trim() !== ""

    Process {
        id: clipboardProcess
    }

    property var sortedPeerList: {
        if (!daemon?.peerList) return [];
        var peers = daemon.peerList.slice();

        if (daemon.hideDisconnected) {
            peers = peers.filter(function(peer) {
                return peer.Online === true;
            });
        }

        peers.sort(function(a, b) {
            if (a.Online && !b.Online) return -1;
            if (!a.Online && b.Online) return 1;
            var nameA = (a.HostName || a.DNSName || "").toLowerCase();
            var nameB = (b.HostName || b.DNSName || "").toLowerCase();
            return nameA.localeCompare(nameB);
        });
        return peers;
    }

    function copyToClipboard(text) {
        clipboardProcess.command = ["wl-copy", text];
        clipboardProcess.running = true;
    }

    function getOSIcon(os) {
        if (!os) return "devices";
        switch (os.toLowerCase()) {
            case "linux": return "terminal";
            case "macos": return "desktop_mac";
            case "ios": return "phone_iphone";
            case "android": return "phone_android";
            case "windows": return "laptop_windows";
            default: return "devices";
        }
    }

    function executePeerAction(action, peer) {
        var ips = daemon.filterIPv4(peer.TailscaleIPs);
        if (ips.length === 0) return;
        var ip = ips[0];

        switch (action) {
            case "copy-ip":
                copyToClipboard(ip);
                ToastService.showInfo("IP copied: " + ip);
                break;
            case "copy-hostname":
                var hostname = peer.HostName || peer.DNSName || "Unknown";
                copyToClipboard(hostname);
                ToastService.showInfo("Hostname copied: " + hostname);
                break;
            case "ssh":
                if (!isTerminalConfigured) {
                    ToastService.showError("Terminal not configured - set it in plugin settings");
                    return;
                }
                daemon.launchTerminal([daemon.terminalCommand, "-e", "ssh", ip]);
                break;
            case "ping":
                if (!isTerminalConfigured) {
                    ToastService.showError("Terminal not configured - set it in plugin settings");
                    return;
                }
                daemon.launchTerminal([daemon.terminalCommand, "-e", "ping", "-c", daemon.pingCount.toString(), ip]);
                break;
            case "admin-console":
                var dnsName = (peer.DNSName || "").replace(/\.$/, "");
                Qt.openUrlExternally("https://login.tailscale.com/admin/machines/" + encodeURIComponent(dnsName));
                break;
        }
    }

    StyledRect {
        width: parent.width
        height: ipRow.implicitHeight + Theme.spacingS * 2
        visible: (daemon?.tailscaleRunning ?? false) && (daemon?.tailscaleIp ?? "") !== ""
        color: Theme.surfaceContainerHigh

        Row {
            id: ipRow
            anchors.fill: parent
            anchors.margins: Theme.spacingS
            spacing: Theme.spacingS

            DankIcon {
                name: "badge"
                size: Theme.iconSize - 6
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                StyledText {
                    text: "Your IP"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }

                StyledText {
                    text: daemon?.tailscaleIp || ""
                    font.pixelSize: Theme.fontSizeMedium
                    isMonospace: true
                    color: ipMouseArea.containsMouse ? Theme.primary : Theme.surfaceText
                }
            }
        }

        DankRipple {
            id: ipRipple
            rippleColor: Theme.surfaceText
            cornerRadius: parent.radius
        }

        MouseArea {
            id: ipMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => ipRipple.trigger(mouse.x, mouse.y)
            onClicked: {
                if (daemon?.tailscaleIp) {
                    root.copyToClipboard(daemon.tailscaleIp);
                    ToastService.showInfo("IP copied: " + daemon.tailscaleIp);
                }
            }
        }
    }

    StyledRect {
        width: parent.width
        height: exitNodeLayout.implicitHeight + Theme.spacingS * 2
        visible: daemon?.exitNodeStatus !== null && daemon?.exitNodeStatus !== undefined
        color: Theme.withAlpha(Theme.primary, 0.1)
        border.width: 1
        border.color: Theme.withAlpha(Theme.primary, 0.3)

        Row {
            id: exitNodeLayout
            anchors.fill: parent
            anchors.margins: Theme.spacingS
            spacing: Theme.spacingS

            DankIcon {
                name: "public"
                size: Theme.iconSize - 6
                color: daemon?.exitNodeStatus?.Online ? Theme.primary : Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                StyledText {
                    text: "Exit Node Active"
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: Theme.primary
                }

                StyledText {
                    text: {
                        if (!daemon?.exitNodeStatus) return "";
                        var ipv4 = daemon.filterIPv4(daemon.exitNodeStatus.TailscaleIPs)[0];
                        var status = daemon.exitNodeStatus.Online ? "Online" : "Offline";
                        return ipv4 ? ipv4 + " · " + status : status;
                    }
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    isMonospace: true
                }
            }
        }
    }

    StyledRect {
        width: parent.width
        height: termWarningLayout.implicitHeight + Theme.spacingS * 2
        visible: !root.isTerminalConfigured
        color: Theme.withAlpha(Theme.error, 0.1)
        border.width: 1
        border.color: Theme.withAlpha(Theme.error, 0.3)

        Row {
            id: termWarningLayout
            anchors.fill: parent
            anchors.margins: Theme.spacingS
            spacing: Theme.spacingS

            DankIcon {
                name: "warning"
                size: Theme.iconSize - 6
                color: Theme.error
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                StyledText {
                    text: "Terminal Not Configured"
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: Theme.error
                }

                StyledText {
                    text: "Set terminal in settings for SSH/ping"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }
        }
    }

    StyledRect {
        width: parent.width
        height: peerCol.implicitHeight + Theme.spacingM * 2
        visible: (daemon?.tailscaleRunning ?? false)
        color: Theme.surfaceContainerHigh

        Column {
            id: peerCol
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingS

            StyledText {
                text: "Devices"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            Column {
                width: parent.width
                spacing: 2

                Repeater {
                    model: root.sortedPeerList

                    delegate: Rectangle {
                        id: peerDelegate
                        width: peerCol.width - Theme.spacingM * 2
                        height: 44
                        radius: Theme.cornerRadius
                        color: peerMouseArea.containsMouse ? Theme.surfaceHover : "transparent"

                        property var peerData: modelData
                        property string peerIp: root.daemon.filterIPv4(peerData.TailscaleIPs)[0] || ""
                        property string peerHostname: peerData.HostName || peerData.DNSName || "Unknown"
                        property bool peerOnline: peerData.Online || false

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingS
                            anchors.rightMargin: Theme.spacingS
                            spacing: Theme.spacingS

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: peerDelegate.peerOnline ? Theme.primary : Theme.surfaceVariantText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            DankIcon {
                                name: root.getOSIcon(peerDelegate.peerData.OS)
                                size: Theme.iconSize - 6
                                color: peerDelegate.peerOnline ? Theme.primary : Theme.surfaceVariantText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1

                                StyledText {
                                    text: peerDelegate.peerHostname
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    width: peerDelegate.width - Theme.spacingS * 2 - 8 - (Theme.iconSize - 6) - Theme.spacingS * 3
                                }

                                StyledText {
                                    text: peerDelegate.peerIp
                                    font.pixelSize: 11
                                    color: Theme.surfaceVariantText
                                    isMonospace: true
                                    visible: peerDelegate.peerIp !== ""
                                }
                            }
                        }

                        DankRipple {
                            id: peerRipple
                            rippleColor: Theme.surfaceText
                            cornerRadius: peerDelegate.radius
                        }

                        MouseArea {
                            id: peerMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            onPressed: mouse => peerRipple.trigger(mouse.x, mouse.y)
                            onClicked: function(mouse) {
                                if (mouse.button === Qt.LeftButton) {
                                    if (peerDelegate.peerIp) {
                                        root.executePeerAction(daemon.defaultPeerAction, peerDelegate.peerData);
                                    }
                                } else if (mouse.button === Qt.RightButton) {
                                    var pos = peerMouseArea.mapToItem(root, mouse.x, mouse.y);
                                    peerContextMenu.peerData = peerDelegate.peerData;
                                    peerContextMenu.show(pos.x, pos.y, false);
                                }
                            }
                        }
                    }
                }

                StyledText {
                    width: parent.width
                    text: "No peers found"
                    visible: root.sortedPeerList.length === 0
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: Theme.spacingM
                }
            }
        }
    }

    StyledRect {
        width: parent.width
        height: notConnectedCol.implicitHeight + Theme.spacingM * 2
        visible: !(daemon?.tailscaleRunning ?? false)
        color: Theme.surfaceContainerHigh

        Column {
            id: notConnectedCol
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingS

            StyledText {
                text: "Tailscale is not connected"
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceVariantText
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 40
        visible: daemon?.tailscaleRunning ?? false
        radius: Theme.cornerRadius
        color: adminMouseArea.containsMouse ? Theme.surfaceHover : Theme.withAlpha(Theme.surfaceText, 0.05)

        Row {
            anchors.centerIn: parent
            spacing: Theme.spacingS

            DankIcon {
                name: "open_in_new"
                size: Theme.iconSize - 8
                color: Theme.surfaceText
            }

            StyledText {
                text: "Admin Console"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
            }
        }

        DankRipple {
            id: adminRipple
            rippleColor: Theme.surfaceText
            cornerRadius: parent.radius
        }

        MouseArea {
            id: adminMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => adminRipple.trigger(mouse.x, mouse.y)
            onClicked: Qt.openUrlExternally("https://login.tailscale.com/admin")
        }
    }

    Rectangle {
        width: parent.width
        height: 40
        radius: Theme.cornerRadius
        color: {
            if (toggleMouseArea.containsMouse) {
                return (daemon?.tailscaleRunning ?? false)
                    ? Theme.withAlpha(Theme.error, 0.8)
                    : Theme.withAlpha(Theme.primary, 0.8);
            }
            return (daemon?.tailscaleRunning ?? false)
                ? Theme.error
                : Theme.primary;
        }
        opacity: (daemon?.tailscaleInstalled ?? false) ? 1.0 : 0.5

        Row {
            anchors.centerIn: parent
            spacing: Theme.spacingS

            DankIcon {
                name: (daemon?.tailscaleRunning ?? false) ? "link_off" : "link"
                size: Theme.iconSize - 8
                color: Theme.surface
            }

            StyledText {
                text: (daemon?.tailscaleRunning ?? false) ? "Disconnect" : "Connect"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surface
            }
        }

        DankRipple {
            id: toggleRipple
            rippleColor: Theme.surface
            cornerRadius: parent.radius
        }

        MouseArea {
            id: toggleMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            enabled: daemon?.tailscaleInstalled ?? false
            onPressed: mouse => toggleRipple.trigger(mouse.x, mouse.y)
            onClicked: {
                if (daemon) {
                    daemon.toggleTailscale();
                }
            }
        }
    }

    Item { width: 1; height: Theme.spacingS }

    TailscaleContextMenu {
        id: peerContextMenu
        isTerminalConfigured: root.isTerminalConfigured
        onActionRequested: (action, peer) => root.executePeerAction(action, peer)
    }
}

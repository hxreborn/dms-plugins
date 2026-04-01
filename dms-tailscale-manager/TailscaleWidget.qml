import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "."

PluginComponent {
    id: root

    property bool tailscaleInstalled: false
    property bool tailscaleRunning: false
    property string tailscaleIp: ""
    property string tailscaleHostname: ""
    property int peerCount: 0
    property string lastToggleAction: ""
    property var peerList: []
    property var exitNodeStatus: null

    readonly property int refreshInterval: pluginData?.refreshInterval ?? 5
    readonly property bool showIpAddress: pluginData?.showIpAddress ?? true
    readonly property bool showPeerCount: pluginData?.showPeerCount ?? true
    readonly property bool hideDisconnected: pluginData?.hideDisconnected ?? false
    readonly property string terminalCommand: pluginData?.terminalCommand ?? ""
    readonly property string sshUser: pluginData?.sshUser ?? ""
    readonly property int pingCount: pluginData?.pingCount ?? 5
    readonly property string defaultPeerAction: pluginData?.defaultPeerAction ?? "copy-ip"
    readonly property bool closeOnAction: pluginData?.closeOnAction ?? true
    readonly property bool closeOnCopy: pluginData?.closeOnCopy ?? false

    function filterIPv4(ips) {
        if (!ips || !ips.length) return [];
        return ips.filter(function(ip) { return ip.startsWith("100."); });
    }

    Process {
        id: whichProcess
        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: function(exitCode, exitStatus) {
            root.tailscaleInstalled = (exitCode === 0);
            updateTailscaleStatus();
        }
    }

    Process {
        id: statusProcess
        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: function(exitCode, exitStatus) {
            var stdout = String(statusProcess.stdout.text || "").trim();

            if (exitCode === 0 && stdout && stdout.length > 0) {
                try {
                    var data = JSON.parse(stdout);
                    root.tailscaleRunning = data.BackendState === "Running";

                    if (root.tailscaleRunning && data.Self && data.Self.TailscaleIPs && data.Self.TailscaleIPs.length > 0) {
                        root.tailscaleIp = filterIPv4(data.Self.TailscaleIPs)[0] || data.Self.TailscaleIPs[0];
                        root.tailscaleHostname = data.Self.HostName || "";

                        var peers = [];
                        if (data.Peer) {
                            for (var peerId in data.Peer) {
                                var peer = data.Peer[peerId];
                                var ipv4s = filterIPv4(peer.TailscaleIPs);
                                peers.push({
                                    "HostName": peer.HostName,
                                    "DNSName": peer.DNSName,
                                    "TailscaleIPs": ipv4s,
                                    "Online": peer.Online,
                                    "OS": peer.OS,
                                    "Tags": peer.Tags || []
                                });
                            }
                        }
                        root.peerList = peers;
                        root.peerCount = peers.length;

                        if (data.ExitNodeStatus) {
                            root.exitNodeStatus = {
                                "ID": data.ExitNodeStatus.ID || "",
                                "Online": data.ExitNodeStatus.Online || false,
                                "TailscaleIPs": data.ExitNodeStatus.TailscaleIPs || []
                            };
                        } else {
                            root.exitNodeStatus = null;
                        }
                    } else {
                        root.tailscaleIp = "";
                        root.tailscaleHostname = "";
                        root.peerCount = 0;
                        root.peerList = [];
                        root.exitNodeStatus = null;
                    }
                } catch (e) {
                    console.error("Tailscale: Failed to parse status: " + e);
                    root.tailscaleRunning = false;
                    root.tailscaleHostname = "";
                    root.peerList = [];
                }
            } else {
                root.tailscaleRunning = false;
                root.tailscaleIp = "";
                root.tailscaleHostname = "";
                root.peerCount = 0;
                root.peerList = [];
            }
        }
    }

    Process {
        id: toggleProcess
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                var message = root.lastToggleAction === "connect"
                    ? "Tailscale connected"
                    : "Tailscale disconnected";
                ToastService.showInfo(message);
            }
            statusDelayTimer.start();
        }
    }

    Timer {
        id: statusDelayTimer
        interval: 500
        repeat: false
        onTriggered: updateTailscaleStatus()
    }

    function checkTailscaleInstalled() {
        whichProcess.command = ["which", "tailscale"];
        whichProcess.running = true;
    }

    function updateTailscaleStatus() {
        if (!root.tailscaleInstalled) {
            root.tailscaleRunning = false;
            root.tailscaleIp = "";
            root.tailscaleHostname = "";
            root.peerCount = 0;
            return;
        }

        statusProcess.command = ["tailscale", "status", "--json"];
        statusProcess.running = true;
    }

    Process {
        id: terminalProcess
    }

    function launchTerminal(args) {
        terminalProcess.command = args;
        terminalProcess.running = true;
    }

    function toggleTailscale() {
        if (!root.tailscaleInstalled) return;

        if (root.tailscaleRunning) {
            root.lastToggleAction = "disconnect";
            toggleProcess.command = ["tailscale", "down"];
        } else {
            root.lastToggleAction = "connect";
            toggleProcess.command = ["tailscale", "up"];
        }
        toggleProcess.running = true;
    }

    Timer {
        id: updateTimer
        interval: root.refreshInterval * 1000
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            if (!root.tailscaleInstalled) {
                checkTailscaleInstalled();
            } else {
                updateTailscaleStatus();
            }
        }
    }

    Component.onCompleted: {
        checkTailscaleInstalled();
    }

    pillRightClickAction: () => {
        if (root.tailscaleInstalled) {
            root.toggleTailscale();
        }
    }

    popoutWidth: 400
    popoutHeight: 620

    popoutContent: Component {
        PopoutComponent {
            id: popoutRoot
            headerText: "Tailscale"
            detailsText: root.tailscaleRunning
                ? "Connected" + (root.showPeerCount && root.peerCount > 0 ? " · " + root.peerCount + " devices" : "")
                : "Disconnected"
            showCloseButton: true

            TailscalePanel {
                width: parent.width - Theme.spacingM * 2
                anchors.horizontalCenter: parent.horizontalCenter
                daemon: root
                popoutRoot: popoutRoot
            }
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            TailscaleIcon {
                size: root.iconSize
                color: root.tailscaleRunning ? Theme.primary : Theme.surfaceVariantText
                crossed: !root.tailscaleRunning
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                visible: root.showIpAddress && root.tailscaleRunning && root.tailscaleIp !== ""
                text: root.tailscaleIp
                font.pixelSize: Theme.fontSizeSmall
                isMonospace: true
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            TailscaleIcon {
                size: root.iconSize
                color: root.tailscaleRunning ? Theme.primary : Theme.surfaceVariantText
                crossed: !root.tailscaleRunning
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

}

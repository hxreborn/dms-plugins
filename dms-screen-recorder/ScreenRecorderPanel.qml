import QtQuick
import QtQuick.Layouts
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

    readonly property bool available: daemon?.isAvailable ?? false
    readonly property bool active: daemon?.isActive ?? false
    readonly property bool recording: daemon?.isRecording ?? false
    readonly property bool stopping: daemon?.isStopping ?? false

    readonly property var codecLabels: ({"h264": "H.264", "hevc": "HEVC", "av1": "AV1", "vp8": "VP8", "vp9": "VP9", "hevc_hdr": "HEVC (HDR)", "av1_hdr": "AV1 (HDR)"})
    readonly property var qualityLabels: ({"low": "Low", "medium": "Medium", "high": "High", "very_high": "Very High", "ultra": "Ultra"})
    readonly property var audioLabels: ({"none": "None", "default_output": "Desktop Audio", "default_input": "Microphone", "both": "Both"})
    readonly property var sourceLabels: ({"portal": "Portal", "screen": "Screen"})

    function codecLabel(codec) { return codecLabels[codec] ?? (codec ? codec.toUpperCase() : "Unknown"); }
    function qualityLabel(q) { return qualityLabels[q] ?? q ?? "Unknown"; }
    function audioLabel(source) { return audioLabels[source] ?? source ?? "Unknown"; }
    function sourceLabel(source) { return sourceLabels[source] ?? source ?? "Unknown"; }

    readonly property bool videoMismatch: (daemon?.effectiveVideoCodec ?? "h264") !== (daemon?.videoCodec ?? "h264")
    readonly property bool audioMismatch: (daemon?.effectiveAudioCodec ?? "opus") !== (daemon?.audioCodec ?? "opus")

    readonly property string videoSummary: {
        var parts = [codecLabel(daemon?.effectiveVideoCodec ?? "h264")];
        var res = daemon?.resolution ?? "original";
        if (res !== "original")
            parts.push(res);
        parts.push((daemon?.frameRate?.toString() ?? "60") + " FPS");
        parts.push(qualityLabel(daemon?.quality ?? "very_high"));
        var label = parts.join(" · ");
        if (videoMismatch)
            label += " (set: " + codecLabel(daemon?.videoCodec ?? "h264") + ")";
        return label;
    }

    readonly property string audioSummary: {
        var effective = daemon?.effectiveAudioCodec ?? "opus";
        var configured = daemon?.audioCodec ?? "opus";
        var label = audioLabel(daemon?.audioSource ?? "default_output") + " (" + effective.toUpperCase() + ")";
        if (audioMismatch)
            label += " (set: " + configured.toUpperCase() + ")";
        return label;
    }

    readonly property string sourceSummary: {
        var parts = [];
        var src = sourceLabel(daemon?.videoSource ?? "portal");
        if (daemon?.isFlatpak)
            src += " (Flatpak)";
        parts.push(src);
        if ((daemon?.effectiveColorRange ?? "limited") === "full")
            parts.push("Full range");
        parts.push((daemon?.showCursor ?? true) ? "Cursor shown" : "Cursor hidden");
        return parts.join(" · ");
    }

    readonly property bool isHdrSource: {
        var codec = daemon?.effectiveVideoCodec ?? "h264";
        return codec === "hevc_hdr" || codec === "av1_hdr";
    }

    component SummaryRow: Row {
        property string iconName
        property string summaryText
        property color textColor: Theme.surfaceText
        spacing: Theme.spacingS

        DankIcon {
            name: iconName
            size: Theme.iconSize - 6
            color: Theme.surfaceVariantText
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            text: summaryText
            font.pixelSize: Theme.fontSizeSmall
            color: textColor
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    StyledRect {
        width: parent.width
        height: statusRow.implicitHeight + Theme.spacingS * 2
        visible: !root.available || root.active
        color: Theme.surfaceContainerHigh

        Row {
            id: statusRow
            anchors.fill: parent
            anchors.margins: Theme.spacingS
            spacing: Theme.spacingS

            DankIcon {
                name: {
                    if (!root.available)
                        return "warning";
                    if (daemon?.isCountingDown)
                        return "timer";
                    if (root.recording)
                        return "fiber_manual_record";
                    return "videocam";
                }
                size: Theme.iconSize - 6
                color: {
                    if (!root.available)
                        return Theme.error;
                    if (root.recording)
                        return Theme.error;
                    return Theme.primary;
                }
                anchors.verticalCenter: parent.verticalCenter
                opacity: 1.0

                SequentialAnimation on opacity {
                    running: root.recording
                    loops: Animation.Infinite
                    NumberAnimation {
                        to: 0.4
                        duration: 800
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: 1.0
                        duration: 800
                        easing.type: Easing.InOutSine
                    }
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                StyledText {
                    text: !root.available ? "Not Installed" : (daemon?.statusLabel ?? "Ready")
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }

                StyledText {
                    visible: root.recording
                    text: daemon?.elapsedDisplay ?? "00:00"
                    font.pixelSize: Theme.fontSizeSmall
                    isMonospace: true
                    color: Theme.error
                }

                Item {
                    visible: !root.available
                    width: recheckText.width
                    height: recheckText.height

                    StyledText {
                        id: recheckText
                        text: "gpu-screen-recorder not found. Tap to recheck"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (daemon)
                                daemon.recheckAvailability();
                        }
                    }
                }
            }
        }
    }

    StyledRect {
        width: parent.width
        height: summaryCol.implicitHeight + Theme.spacingS * 2
        visible: root.available
        color: Theme.surfaceContainerHigh

        Column {
            id: summaryCol
            anchors.fill: parent
            anchors.margins: Theme.spacingS
            spacing: Theme.spacingXS

            SummaryRow {
                iconName: "videocam"
                summaryText: root.videoSummary
                textColor: root.videoMismatch ? Theme.error : Theme.surfaceText
            }

            SummaryRow {
                visible: (daemon?.audioSource ?? "default_output") !== "none"
                iconName: "mic"
                summaryText: root.audioSummary
                textColor: root.audioMismatch ? Theme.error : Theme.surfaceText
            }

            SummaryRow {
                iconName: "desktop_windows"
                summaryText: root.sourceSummary
                textColor: root.isHdrSource ? Theme.primary : Theme.surfaceText
            }
        }
    }

    StyledRect {
        width: parent.width
        height: folderRow.implicitHeight + Theme.spacingS * 2
        visible: root.available
        color: folderMouseArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh

        Row {
            id: folderRow
            anchors.fill: parent
            anchors.margins: Theme.spacingS
            spacing: Theme.spacingS

            DankIcon {
                name: "folder_open"
                size: Theme.iconSize - 6
                color: folderMouseArea.containsMouse ? Theme.primary : Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: "Open Recordings Folder"
                font.pixelSize: Theme.fontSizeSmall
                color: folderMouseArea.containsMouse ? Theme.primary : Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: folderMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (daemon)
                    daemon.openOutputFolder();
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 44
        radius: Theme.cornerRadius
        opacity: root.available ? 1.0 : 0.5
        color: {
            if (root.active) {
                return toggleMouseArea.containsMouse ? Theme.withAlpha(Theme.error, 0.8) : Theme.error;
            }
            return toggleMouseArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.8) : Theme.primary;
        }

        Row {
            anchors.centerIn: parent
            spacing: Theme.spacingS

            DankIcon {
                name: root.active ? "stop" : "fiber_manual_record"
                size: Theme.iconSize - 8
                color: Theme.surface
            }

            StyledText {
                text: daemon?.buttonText ?? "Start Recording"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surface
            }
        }

        MouseArea {
            id: toggleMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            enabled: root.available && !root.stopping
            onClicked: {
                if (daemon)
                    daemon.toggleRecording();
            }
        }
    }

    Item {
        width: 1
        height: Theme.spacingS
    }
}

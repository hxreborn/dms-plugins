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

    property bool isAvailable: false
    property bool isFlatpak: false
    property bool isChecking: false

    readonly property string sIdle: "idle"
    readonly property string sCountdown: "countdown"
    readonly property string sStarting: "starting"
    readonly property string sRecording: "recording"
    readonly property string sStopping: "stopping"

    property string recorderState: sIdle
    readonly property bool isCountingDown: recorderState === sCountdown
    readonly property bool isPending: recorderState === sStarting
    readonly property bool isRecording: recorderState === sRecording
    readonly property bool isStopping: recorderState === sStopping
    readonly property bool isActive: recorderState !== sIdle
    property int countdownRemaining: 0

    property string lastRecordingPath: ""
    property var recordingStartTime: null
    property int elapsedSeconds: 0

    function pad2(n) { return n < 10 ? "0" + n : "" + n; }

    readonly property string elapsedDisplay: {
        var h = Math.floor(elapsedSeconds / 3600);
        var m = Math.floor((elapsedSeconds % 3600) / 60);
        var s = elapsedSeconds % 60;
        return h > 0 ? pad2(h) + ":" + pad2(m) + ":" + pad2(s) : pad2(m) + ":" + pad2(s);
    }

    readonly property string statusLabel: {
        if (isCountingDown)
            return countdownRemaining.toString();
        if (isStopping)
            return "Stopping...";
        if (isRecording)
            return "Recording";
        if (isPending)
            return videoSource === "portal" ? "Selecting screen..." : "Starting...";
        return "Ready";
    }
    readonly property string statusText: isRecording ? statusLabel + " " + elapsedDisplay : statusLabel

    readonly property string buttonText: {
        if (isCountingDown)
            return "Cancel";
        if (isStopping)
            return "Stopping...";
        if (isPending)
            return videoSource === "portal" ? "Selecting screen..." : "Starting...";
        if (isRecording)
            return "Stop Recording";
        return "Start Recording";
    }

    readonly property string pillIconName: {
        if (isCountingDown)
            return "timer";
        if (isRecording)
            return "stop_circle";
        if (isPending)
            return "hourglass_top";
        return "videocam";
    }
    readonly property color pillIconColor: {
        if (isCountingDown)
            return Theme.primary;
        if (isRecording)
            return Theme.error;
        if (isPending)
            return Theme.primary;
        return Theme.surfaceVariantText;
    }

    readonly property string outputDir: pluginData?.outputDir ?? "~/Videos"
    readonly property string filenamePattern: pluginData?.filenamePattern ?? "recording_%Y%m%d_%H%M%S"
    readonly property int frameRate: parseInt(pluginData?.frameRate ?? "60", 10)
    readonly property string videoCodec: pluginData?.videoCodec ?? "h264"
    readonly property string quality: pluginData?.quality ?? "very_high"
    readonly property string audioSource: pluginData?.audioSource ?? "default_output"
    readonly property string audioCodec: pluginData?.audioCodec ?? "opus"
    readonly property bool showCursor: pluginData?.showCursor ?? true
    readonly property bool copyToClipboard: pluginData?.copyToClipboard ?? false
    readonly property bool hideInactive: pluginData?.hideInactive ?? false
    readonly property int startDelay: parseInt(pluginData?.startDelay ?? "0", 10)
    readonly property string videoSource: pluginData?.videoSource ?? "portal"
    readonly property string colorRange: pluginData?.colorRange ?? "limited"
    readonly property string resolution: pluginData?.resolution ?? "original"

    readonly property bool isHdrCodec: videoCodec === "hevc_hdr" || videoCodec === "av1_hdr"
    readonly property string effectiveVideoCodec: {
        if (isHdrCodec && videoSource === "portal")
            return "h264";
        return videoCodec;
    }
    readonly property string effectiveAudioCodec: {
        if ((effectiveVideoCodec === "vp8" || effectiveVideoCodec === "vp9") && audioCodec === "aac")
            return "opus";
        return audioCodec;
    }
    readonly property string effectiveColorRange: {
        var codec = effectiveVideoCodec;
        if (codec === "hevc_hdr" || codec === "av1_hdr")
            return "full";
        return colorRange;
    }

    function expandPath(path) {
        if (path.startsWith("~/")) {
            return Quickshell.env("HOME") + "/" + path.substring(2);
        }
        return path;
    }

    function getFileExtension() {
        var codec = effectiveVideoCodec;
        if (codec === "vp8" || codec === "vp9")
            return ".webm";
        if (codec === "hevc_hdr" || codec === "av1_hdr")
            return ".mkv";
        return ".mp4";
    }

    function generateOutputPath() {
        var now = new Date();
        var name = filenamePattern;
        name = name.replace(/%Y/g, Qt.formatDateTime(now, "yyyy"));
        name = name.replace(/%m/g, Qt.formatDateTime(now, "MM"));
        name = name.replace(/%d/g, Qt.formatDateTime(now, "dd"));
        name = name.replace(/%H/g, Qt.formatDateTime(now, "hh"));
        name = name.replace(/%M/g, Qt.formatDateTime(now, "mm"));
        name = name.replace(/%S/g, Qt.formatDateTime(now, "ss"));
        name = name.replace(/[\/\n\r\0]/g, "_").trim();
        if (name === "")
            name = "recording";
        return expandPath(outputDir) + "/" + name + getFileExtension();
    }

    function truncate(text, maxLen) {
        if (!text)
            return "";
        return text.length > maxLen ? text.substring(0, maxLen) + "..." : text;
    }

    function isCancelledByUser(stdoutText, stderrText) {
        var stdout = String(stdoutText || "").toLowerCase();
        var stderr = String(stderrText || "").toLowerCase();
        var combined = stdout + " " + stderr;
        return combined.includes("canceled by") || combined.includes("cancelled by");
    }

    function copyFileToClipboard(filePath) {
        var encoded = filePath.replace(/%/g, "%25").replace(/ /g, "%20").replace(/#/g, "%23").replace(/\?/g, "%3F").replace(/'/g, "%27").replace(/"/g, "%22");
        var fileUri = "file://" + encoded;
        clipboardProcess.command = ["sh", "-c", "printf '%s' \"$1\" | wl-copy --type text/uri-list", "--", fileUri];
        clipboardProcess.running = true;
    }

    function handleRecordingSuccess(path) {
        var displayPath = path.length > 128 ? "..." + path.substring(path.length - 125) : path;
        var savedPath = path;
        ToastService.showInfo("Recording saved", displayPath, "movie", 5000, "Open File", function () {
            openFileProcess.command = ["xdg-open", savedPath];
            openFileProcess.running = true;
        });

        if (root.copyToClipboard && path !== "") {
            copyFileToClipboard(path);
        }
    }

    function buildCommand() {
        var outputPath = generateOutputPath();
        root.lastRecordingPath = outputPath;

        var cmd = [];
        if (root.isFlatpak) {
            cmd = ["flatpak", "run", "--command=gpu-screen-recorder", "--file-forwarding", "com.dec05eba.gpu_screen_recorder"];
        } else {
            cmd = ["gpu-screen-recorder"];
        }

        cmd.push("-w", videoSource, "-f", frameRate.toString(), "-k", effectiveVideoCodec, "-q", quality, "-cr", effectiveColorRange, "-cursor", showCursor ? "yes" : "no", "-o", outputPath);

        if (videoSource === "portal") {
            cmd.push("-restore-portal-session", "yes");
        }

        if (audioSource !== "none") {
            cmd.push("-ac", effectiveAudioCodec);
            if (audioSource === "both") {
                cmd.push("-a", "default_output");
                cmd.push("-a", "default_input");
            } else {
                cmd.push("-a", audioSource);
            }
        }

        if (resolution !== "original") {
            cmd.push("-s", resolution);
        }

        return cmd;
    }

    function warnIfHdrUnsupported() {
        if (isHdrCodec && videoSource === "portal")
            ToastService.showError("HDR codecs are not supported with Portal source, using H.264");
    }

    function confirmRecordingStarted() {
        pendingTimer.running = false;
        root.recorderState = sRecording;
        root.recordingStartTime = new Date();
        root.elapsedSeconds = 0;
        elapsedTimer.running = true;
        startupTimeoutTimer.running = false;
    }

    Process {
        id: checkerProcess
        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: function (exitCode, exitStatus) {
            if (exitCode === 0) {
                root.isAvailable = true;
                root.isFlatpak = false;
                root.isChecking = false;
            } else {
                flatpakCheckerProcess.command = ["sh", "-c", "command -v flatpak >/dev/null 2>&1 && flatpak list --app | grep -q 'com.dec05eba.gpu_screen_recorder'"];
                flatpakCheckerProcess.running = true;
            }
        }
    }

    Process {
        id: flatpakCheckerProcess
        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: function (exitCode, exitStatus) {
            root.isAvailable = (exitCode === 0);
            root.isFlatpak = (exitCode === 0);
            root.isChecking = false;
        }
    }

    Process {
        id: recorderProcess
        stdout: StdioCollector {}
        stderr: StdioCollector {}

        onExited: function (exitCode, exitStatus) {
            var stdoutText = String(recorderProcess.stdout.text || "").trim();
            var stderrText = String(recorderProcess.stderr.text || "").trim();
            var wasCancelled = (root.recorderState === root.sStopping) || isCancelledByUser(stdoutText, stderrText);
            var wasActive = root.recorderState !== root.sIdle;

            pendingTimer.running = false;
            elapsedTimer.running = false;
            killFallbackTimer.running = false;
            startupTimeoutTimer.running = false;

            root.recorderState = root.sIdle;
            root.elapsedSeconds = 0;
            root.recordingStartTime = null;

            if (!wasActive)
                return;

            if (exitCode === 0 && root.lastRecordingPath !== "") {
                handleRecordingSuccess(root.lastRecordingPath);
            } else if (exitCode !== 0 && !wasCancelled) {
                var excerpt = truncate(stderrText, 120);
                if (excerpt) {
                    ToastService.showError("Recording failed: " + excerpt);
                }
            }
        }
    }

    Process {
        id: clipboardProcess
        onExited: function (exitCode) {
            if (exitCode === 0) {
                ToastService.showInfo("Copied to clipboard");
            } else {
                ToastService.showError("Failed to copy to clipboard");
            }
        }
    }

    Process {
        id: openFileProcess
        onExited: function (exitCode) {
            if (exitCode !== 0) {
                ToastService.showError("Failed to open recording");
            }
        }
    }

    Process {
        id: fileCheckProcess
        onExited: function (exitCode) {
            if (exitCode === 0 && root.isPending) {
                confirmRecordingStarted();
            }
        }
    }

    Timer {
        id: elapsedTimer
        interval: 1000
        repeat: true
        onTriggered: {
            if (root.recordingStartTime) {
                root.elapsedSeconds = Math.floor((new Date() - root.recordingStartTime) / 1000);
            }
        }
    }

    // Non-portal: process alive after 2s = started. Portal: polls file existence.
    Timer {
        id: pendingTimer
        interval: 2000
        repeat: root.videoSource === "portal"
        onTriggered: {
            if (root.recorderState !== root.sStarting) {
                pendingTimer.running = false;
                return;
            }

            if (!recorderProcess.running) {
                root.recorderState = root.sIdle;
                pendingTimer.running = false;
                return;
            }

            if (root.videoSource === "portal") {
                fileCheckProcess.command = ["test", "-f", root.lastRecordingPath];
                fileCheckProcess.running = true;
            } else {
                confirmRecordingStarted();
            }
        }
    }

    Timer {
        id: killFallbackTimer
        interval: 3000
        repeat: false
        onTriggered: {
            if (recorderProcess.running)
                Quickshell.execDetached(["pkill", "-9", "-f", "gpu-screen-recorder"]);
        }
    }

    Timer {
        id: startupTimeoutTimer
        interval: 30000
        repeat: false
        onTriggered: {
            if (root.recorderState === root.sStarting) {
                ToastService.showError("Recording startup timed out");
                root.stopRecording();
            }
        }
    }

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        onTriggered: {
            root.countdownRemaining -= 1;
            if (root.countdownRemaining <= 0) {
                countdownTimer.running = false;
                root.recorderState = root.sStarting;
                warnIfHdrUnsupported();
                startRecordingProcess();
            }
        }
    }

    function startRecording() {
        if (!isAvailable || isActive)
            return;

        if (startDelay > 0 && videoSource !== "portal") {
            root.countdownRemaining = startDelay;
            root.recorderState = sCountdown;
            countdownTimer.start();
        } else {
            root.recorderState = sStarting;
            warnIfHdrUnsupported();
            startRecordingProcess();
        }
    }

    function startRecordingProcess() {
        closePopout();
        recorderProcess.command = buildCommand();
        recorderProcess.running = true;
        pendingTimer.start();
        startupTimeoutTimer.start();
    }

    function stopRecording() {
        if (recorderState === sCountdown) {
            countdownTimer.running = false;
            root.recorderState = root.sIdle;
            return;
        }

        pendingTimer.running = false;
        root.recorderState = sStopping;

        if (recorderProcess.running) {
            Quickshell.execDetached(["pkill", "-SIGINT", "-f", "gpu-screen-recorder"]);
            killFallbackTimer.start();
        } else {
            root.recorderState = root.sIdle;
        }
    }

    function toggleRecording() {
        if (isActive) {
            stopRecording();
        } else {
            startRecording();
        }
    }

    function openOutputFolder() {
        openFileProcess.command = ["xdg-open", expandPath(outputDir)];
        openFileProcess.running = true;
    }

    function recheckAvailability() {
        root.isAvailable = false;
        root.isChecking = true;
        checkerProcess.command = ["which", "gpu-screen-recorder"];
        checkerProcess.running = true;
    }

    Component.onCompleted: {
        root.isChecking = true;
        checkerProcess.command = ["which", "gpu-screen-recorder"];
        checkerProcess.running = true;
    }

    popoutWidth: 380
    popoutHeight: 320

    popoutContent: Component {
        PopoutComponent {
            headerText: "Screen Recorder"
            detailsText: root.statusText
            showCloseButton: true

            ScreenRecorderPanel {
                width: parent.width - Theme.spacingM * 2
                anchors.horizontalCenter: parent.horizontalCenter
                daemon: root
            }
        }
    }

    horizontalBarPill: Component {
        Item {
            implicitWidth: hPillRow.implicitWidth
            implicitHeight: hPillRow.implicitHeight
            visible: !root.hideInactive || root.isActive

            Row {
                id: hPillRow
                spacing: Theme.spacingXS

                DankIcon {
                    name: root.pillIconName
                    size: root.iconSize
                    color: root.pillIconColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    visible: root.isRecording || root.isCountingDown
                    text: root.isCountingDown ? root.countdownRemaining.toString() : root.elapsedDisplay
                    font.pixelSize: Theme.fontSizeSmall
                    isMonospace: true
                    color: root.isCountingDown ? Theme.primary : Theme.error
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: root.toggleRecording()
            }
        }
    }

    verticalBarPill: Component {
        Item {
            implicitWidth: vPillCol.implicitWidth
            implicitHeight: vPillCol.implicitHeight
            visible: !root.hideInactive || root.isActive

            Column {
                id: vPillCol
                spacing: Theme.spacingXS

                DankIcon {
                    name: root.pillIconName
                    size: root.iconSize
                    color: root.pillIconColor
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: root.toggleRecording()
            }
        }
    }
}

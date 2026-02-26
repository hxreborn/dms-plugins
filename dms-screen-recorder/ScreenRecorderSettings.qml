import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "screenRecorder"

    StyledText {
        width: parent.width
        text: "Screen Recorder"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Record your screen using gpu-screen-recorder with configurable video, audio, and output settings."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledText {
        width: parent.width
        text: "Output"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Bold
        color: Theme.surfaceText
        topPadding: Theme.spacingM
    }

    StringSetting {
        settingKey: "outputDir"
        label: "Output Directory"
        description: "Directory to save recordings to."
        defaultValue: "~/Videos"
        placeholder: "~/Videos"
    }

    StringSetting {
        settingKey: "filenamePattern"
        label: "Filename Pattern"
        description: "Pattern for recording filenames. Tokens: %Y (year), %m (month), %d (day), %H (hour), %M (minute), %S (second)."
        defaultValue: "recording_%Y%m%d_%H%M%S"
        placeholder: "recording_%Y%m%d_%H%M%S"
    }

    StyledText {
        width: parent.width
        text: "Video"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Bold
        color: Theme.surfaceText
        topPadding: Theme.spacingM
    }

    SelectionSetting {
        settingKey: "videoSource"
        label: "Video Source"
        description: "Capture source. Portal uses xdg-desktop-portal for screen selection."
        defaultValue: "portal"
        options: [
            {
                label: "Portal",
                value: "portal"
            },
            {
                label: "Screen",
                value: "screen"
            }
        ]
    }

    SelectionSetting {
        settingKey: "videoCodec"
        label: "Video Codec"
        description: "Video encoding codec. HDR variants require Screen source and auto-set color range to full."
        defaultValue: "h264"
        options: [
            {
                label: "H.264",
                value: "h264"
            },
            {
                label: "HEVC",
                value: "hevc"
            },
            {
                label: "AV1",
                value: "av1"
            },
            {
                label: "VP8",
                value: "vp8"
            },
            {
                label: "VP9",
                value: "vp9"
            },
            {
                label: "HEVC (HDR)",
                value: "hevc_hdr"
            },
            {
                label: "AV1 (HDR)",
                value: "av1_hdr"
            }
        ]
    }

    SelectionSetting {
        settingKey: "frameRate"
        label: "Frame Rate"
        description: "Recording frame rate."
        defaultValue: "60"
        options: [
            {
                label: "30 FPS",
                value: "30"
            },
            {
                label: "60 FPS",
                value: "60"
            },
            {
                label: "100 FPS",
                value: "100"
            },
            {
                label: "120 FPS",
                value: "120"
            },
            {
                label: "144 FPS",
                value: "144"
            },
            {
                label: "165 FPS",
                value: "165"
            },
            {
                label: "240 FPS",
                value: "240"
            }
        ]
    }

    SelectionSetting {
        settingKey: "quality"
        label: "Quality"
        description: "Recording quality preset."
        defaultValue: "very_high"
        options: [
            {
                label: "Low",
                value: "low"
            },
            {
                label: "Medium",
                value: "medium"
            },
            {
                label: "High",
                value: "high"
            },
            {
                label: "Very High",
                value: "very_high"
            },
            {
                label: "Ultra",
                value: "ultra"
            }
        ]
    }

    SelectionSetting {
        settingKey: "resolution"
        label: "Resolution"
        description: "Output resolution. Original keeps your native resolution."
        defaultValue: "original"
        options: [
            {
                label: "Original",
                value: "original"
            },
            {
                label: "720p",
                value: "1280x720"
            },
            {
                label: "1080p",
                value: "1920x1080"
            },
            {
                label: "1440p",
                value: "2560x1440"
            },
            {
                label: "4K",
                value: "3840x2160"
            }
        ]
    }

    SelectionSetting {
        settingKey: "colorRange"
        label: "Color Range"
        description: "Video color range."
        defaultValue: "limited"
        options: [
            {
                label: "Limited",
                value: "limited"
            },
            {
                label: "Full",
                value: "full"
            }
        ]
    }

    StyledText {
        width: parent.width
        text: "Audio"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Bold
        color: Theme.surfaceText
        topPadding: Theme.spacingM
    }

    SelectionSetting {
        settingKey: "audioSource"
        label: "Audio Source"
        description: "Audio capture source. Both captures desktop audio and microphone."
        defaultValue: "default_output"
        options: [
            {
                label: "None",
                value: "none"
            },
            {
                label: "Desktop Audio",
                value: "default_output"
            },
            {
                label: "Microphone",
                value: "default_input"
            },
            {
                label: "Both",
                value: "both"
            }
        ]
    }

    SelectionSetting {
        settingKey: "audioCodec"
        label: "Audio Codec"
        description: "Audio encoding codec."
        defaultValue: "opus"
        options: [
            {
                label: "Opus",
                value: "opus"
            },
            {
                label: "AAC",
                value: "aac"
            }
        ]
    }

    StyledText {
        width: parent.width
        text: "Behavior"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Bold
        color: Theme.surfaceText
        topPadding: Theme.spacingM
    }

    SelectionSetting {
        settingKey: "startDelay"
        label: "Start Delay"
        description: "Countdown before recording starts."
        defaultValue: "0"
        options: [
            {
                label: "None",
                value: "0"
            },
            {
                label: "3 seconds",
                value: "3"
            },
            {
                label: "5 seconds",
                value: "5"
            },
            {
                label: "10 seconds",
                value: "10"
            }
        ]
    }

    ToggleSetting {
        settingKey: "showCursor"
        label: "Show Cursor"
        description: "Include mouse cursor in the recording."
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "copyToClipboard"
        label: "Copy to Clipboard"
        description: "Copy recording as file URI to clipboard after stopping (pasteable in file managers and chat apps)."
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "hideInactive"
        label: "Hide When Inactive"
        description: "Hide the bar widget when not recording."
        defaultValue: false
    }
}

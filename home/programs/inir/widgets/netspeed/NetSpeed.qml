pragma ComponentBehavior: Bound
// Net Speed — desktop widget: live download / upload throughput.
// Samples /proc/net/dev once per second; loopback is excluded.

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "custom.netspeed"
    defaultConfig: ({
        placementStrategy: "free", widgetScale: 100, widgetOpacity: 100, colorMode: "auto", dim: 0,
        showDownload: true, showUpload: true, useBits: false, showTotals: false,
        x: 260, y: 200
    })

    implicitWidth: content.implicitWidth + Math.round(24 * root.scaleFactor)
    implicitHeight: content.implicitHeight + Math.round(18 * root.scaleFactor)
    resizableAxes: ({ uniform: "widgetScale" })
    resizeMinWidth: 140
    resizeMinHeight: 44

    readonly property bool cfgShowDownload: _readConfigKey("showDownload") ?? true
    readonly property bool cfgShowUpload: _readConfigKey("showUpload") ?? true
    readonly property bool cfgUseBits: _readConfigKey("useBits") ?? false
    readonly property bool cfgShowTotals: _readConfigKey("showTotals") ?? false
    readonly property int fsValue: Math.round(Appearance.font.pixelSize.normal * root.scaleFactor)
    readonly property int fsUnit: Math.max(9, Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor))

    // Throughput in bytes per second, plus session totals.
    property real downloadRate: 0
    property real uploadRate: 0
    property real downloadedBytes: 0
    property real uploadedBytes: 0
    property real _lastReceived: -1
    property real _lastTransmitted: -1
    property double _lastSampleTime: 0

    function rateParts(raw): var {
        let value = Math.max(0, Number(raw) || 0)
        let units = ["B/s", "KB/s", "MB/s", "GB/s"]
        if (root.cfgUseBits) {
            value *= 8
            units = ["bps", "Kbps", "Mbps", "Gbps"]
        }
        let index = 0
        while (value >= 1024 && index < units.length - 1) {
            value /= 1024
            index++
        }
        const decimals = index > 0 && value < 100 ? 1 : 0
        return ({ value: value.toFixed(decimals), unit: units[index] })
    }

    function byteParts(raw): var {
        let value = Math.max(0, Number(raw) || 0)
        const units = ["B", "KB", "MB", "GB", "TB"]
        let index = 0
        while (value >= 1024 && index < units.length - 1) {
            value /= 1024
            index++
        }
        const decimals = index > 0 && value < 100 ? 1 : 0
        return ({ value: value.toFixed(decimals), unit: units[index] })
    }

    function sample(contents): void {
        let received = 0
        let transmitted = 0
        const lines = String(contents).split("\n")
        for (const line of lines) {
            const separator = line.indexOf(":")
            if (separator < 0)
                continue
            const name = line.slice(0, separator).trim()
            if (name.length === 0 || name === "lo")
                continue
            const fields = line.slice(separator + 1).trim().split(/\s+/)
            if (fields.length < 9)
                continue
            const rx = Number(fields[0])
            const tx = Number(fields[8])
            if (!Number.isFinite(rx) || !Number.isFinite(tx))
                continue
            received += rx
            transmitted += tx
        }

        const now = Date.now()
        if (root._lastSampleTime > 0 && now > root._lastSampleTime) {
            const elapsed = now - root._lastSampleTime
            const receivedDelta = received >= root._lastReceived ? received - root._lastReceived : 0
            const transmittedDelta = transmitted >= root._lastTransmitted ? transmitted - root._lastTransmitted : 0
            root.downloadRate = receivedDelta * 1000 / elapsed
            root.uploadRate = transmittedDelta * 1000 / elapsed
            root.downloadedBytes += receivedDelta
            root.uploadedBytes += transmittedDelta
        }
        root._lastReceived = received
        root._lastTransmitted = transmitted
        root._lastSampleTime = now
    }

    FileView {
        id: netStats
        path: "/proc/net/dev"
        printErrors: false
        onLoaded: root.sample(text())
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.visible
        onTriggered: netStats.reload()
    }

    // Card background — inherited appearance controls.
    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadiusOverride >= 0 ? root.cornerRadiusOverride : Appearance.rounding.normal
        color: root.backgroundOpacity > 0 ? ColorUtils.applyAlpha(root.colText, root.backgroundOpacity) : "transparent"
        border.width: root.borderWidth
        border.color: ColorUtils.applyAlpha(root.colText, root.borderOpacity)
    }

    Column {
        id: content
        anchors.centerIn: parent
        spacing: Math.round(4 * root.scaleFactor)

        component SpeedLine: Row {
            id: speedLine
            required property string iconName
            required property color iconColor
            required property var parts

            spacing: Math.round(5 * root.scaleFactor)

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                text: speedLine.iconName
                iconSize: Math.round(15 * root.scaleFactor)
                color: speedLine.iconColor
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: speedLine.parts.value
                color: root.colText
                font {
                    pixelSize: root.fsValue
                    family: Appearance.font.family.numbers
                    weight: Font.Medium
                }
                font.features: ({ "tnum": 1 })
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: speedLine.parts.unit
                color: ColorUtils.applyAlpha(root.colText, 0.6)
                font.pixelSize: root.fsUnit
            }
        }

        SpeedLine {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.cfgShowDownload
            iconName: "arrow_downward"
            iconColor: Appearance.colors.colPrimary
            parts: root.rateParts(root.downloadRate)
        }

        SpeedLine {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.cfgShowUpload
            iconName: "arrow_upward"
            iconColor: Appearance.colors.colTertiary
            parts: root.rateParts(root.uploadRate)
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.cfgShowTotals
            spacing: Math.round(10 * root.scaleFactor)

            Row {
                spacing: Math.round(3 * root.scaleFactor)
                MaterialSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "download"
                    iconSize: Math.round(12 * root.scaleFactor)
                    color: ColorUtils.applyAlpha(root.colText, 0.6)
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.byteParts(root.downloadedBytes).value + " " + root.byteParts(root.downloadedBytes).unit
                    color: ColorUtils.applyAlpha(root.colText, 0.6)
                    font.pixelSize: root.fsUnit
                }
            }

            Row {
                spacing: Math.round(3 * root.scaleFactor)
                MaterialSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "upload"
                    iconSize: Math.round(12 * root.scaleFactor)
                    color: ColorUtils.applyAlpha(root.colText, 0.6)
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.byteParts(root.uploadedBytes).value + " " + root.byteParts(root.uploadedBytes).unit
                    color: ColorUtils.applyAlpha(root.colText, 0.6)
                    font.pixelSize: root.fsUnit
                }
            }
        }
    }

    // Edit-mode quick toggles.
    editPopoverContent: Component {
        GridLayout {
            columns: 2
            columnSpacing: 4
            rowSpacing: 4
            Repeater {
                model: [
                    { label: "Download", icon: "arrow_downward", key: "showDownload", on: root.cfgShowDownload },
                    { label: "Upload", icon: "arrow_upward", key: "showUpload", on: root.cfgShowUpload },
                    { label: "Bits", icon: "speed", key: "useBits", on: root.cfgUseBits },
                    { label: "Totals", icon: "data_usage", key: "showTotals", on: root.cfgShowTotals }
                ]
                SelectionGroupButton {
                    required property var modelData
                    Layout.fillWidth: true
                    leftmost: true
                    rightmost: true
                    buttonIcon: modelData.icon
                    buttonText: modelData.label
                    toggled: modelData.on
                    onClicked: Config.setNestedValue(
                        "background.widgets.custom.netspeed." + modelData.key, !modelData.on)
                }
            }
        }
    }
}

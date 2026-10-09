pragma ComponentBehavior: Bound
// Net Speed — compact iRiS module for the Island's Desktop page.
// Live download / upload throughput, sampled from /proc/net/dev once per
// second; loopback and interfaces without counters are excluded.

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.modules.iris.style
import qs.modules.iris.bar.island

Item {
    id: root

    // Provided by the shell's IrisCustomModule loader.
    property string irisSlot: ""
    property var targetScreen

    // Throughput in bytes per second.
    property real downloadRate: 0
    property real uploadRate: 0
    property real _lastReceived: -1
    property real _lastTransmitted: -1
    property double _lastSampleTime: 0

    implicitWidth: row.implicitWidth + Math.round(16 * IrisStyle.density)
    implicitHeight: Math.round(30 * IrisStyle.density)

    function rateParts(raw): var {
        let value = Math.max(0, Number(raw) || 0)
        const units = ["B/s", "KB/s", "MB/s", "GB/s"]
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
            root.downloadRate = (received >= root._lastReceived ? received - root._lastReceived : 0) * 1000 / elapsed
            root.uploadRate = (transmitted >= root._lastTransmitted ? transmitted - root._lastTransmitted : 0) * 1000 / elapsed
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

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: IrisStyle.fillQuiet
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: IrisStyle.spaceSmall

        RowLayout {
            spacing: Math.round(3 * IrisStyle.density)

            Glyph {
                text: "arrow_downward"
                iconSize: Math.round(13 * IrisStyle.density)
                color: IrisStyle.identity.teal
            }

            Metric {
                value: root.rateParts(root.downloadRate).value
                unit: root.rateParts(root.downloadRate).unit
                pixelSize: IrisStyle.typeLabel
                weight: Font.Bold
                color: IrisStyle.text
            }
        }

        RowLayout {
            spacing: Math.round(3 * IrisStyle.density)

            Glyph {
                text: "arrow_upward"
                iconSize: Math.round(13 * IrisStyle.density)
                color: IrisStyle.identity.sky
            }

            Metric {
                value: root.rateParts(root.uploadRate).value
                unit: root.rateParts(root.uploadRate).unit
                pixelSize: IrisStyle.typeLabel
                weight: Font.Bold
                color: IrisStyle.text
            }
        }
    }
}

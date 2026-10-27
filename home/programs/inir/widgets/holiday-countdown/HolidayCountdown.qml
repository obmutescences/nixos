pragma ComponentBehavior: Bound
// Holiday Countdown — iNiR desktop widget.
//
// 最近三个节日/纪念日的天数倒计时。节日只算当天（中秋 = 八月十五，不管假期
// 区间）；纪念日支持公历与农历，农历三十遇小月按廿九，闰月不计。农历数据来自
// ccal，纪念日数据来自同目录的 anniversaries.json，存盘即生效。面板每天零点
// 刷新一次，重启 shell 也会重新读取。

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.background.widgets
import qs.modules.iris.style
import qs.modules.iris.components

AbstractBackgroundWidget {
    id: root

    configEntryName: "custom.holiday-countdown"
    defaultConfig: ({
        enable: true,
        placementStrategy: "free", widgetScale: 100, widgetOpacity: 100, colorMode: "auto", dim: 0,
        contentWidth: 340, contentHeight: 230,
        showBackground: true, useBlur: false, showBorder: true,
        backgroundOpacity: 0.14, borderWidth: 1, borderOpacity: 0.16, cornerRadius: -1,
        x: 420, y: 180
    })

    implicitWidth: Math.round(root.contentWidthCfg * root.scaleFactor)
    implicitHeight: Math.round(root.contentHeightCfg * root.scaleFactor)
    resizableAxes: ({ width: "contentWidth", height: "contentHeight" })
    resizeMinWidth: 300
    resizeMinHeight: 210
    resizeMaxWidth: 640
    resizeMaxHeight: 320
    needsColText: true
    visibleWhenLocked: true

    readonly property int contentWidthCfg: Math.max(300, Number(root._readConfigKey("contentWidth") ?? 340))
    readonly property int contentHeightCfg: Math.max(210, Number(root._readConfigKey("contentHeight") ?? 230))

    // ── Colours ───────────────────────────────────────────────────────────────
    readonly property color ink: root.widgetSurfaceInk
    readonly property color inkMuted: ColorUtils.applyAlpha(root.widgetSurfaceInk, 0.6)

    // ── State ─────────────────────────────────────────────────────────────────
    property date now: new Date()
    property bool ccalAvailable: true
    property var anniversaries: []
    property var lunarYears: ({})     // { "2026": { "2026-09-25": { m: 8, d: 15, leap: false, term: "" } } }
    property var yearQueue: []
    property string runningYear: ""

    readonly property var chineseDays: [
        "", "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
    ]

    readonly property var weekdayNames: ["日", "一", "二", "三", "四", "五", "六"]
    readonly property var lunarMonthNames: [
        "", "正月", "二月", "三月", "四月", "五月", "六月",
        "七月", "八月", "九月", "十月", "十一月", "十二月"
    ]

    readonly property var festivalDefs: [
        { name: "元旦", calendar: "solar", month: 1, day: 1 },
        { name: "春节", calendar: "lunar", month: 1, day: 1 },
        { name: "清明", calendar: "term", term: "清明" },
        { name: "劳动节", calendar: "solar", month: 5, day: 1 },
        { name: "端午", calendar: "lunar", month: 5, day: 5 },
        { name: "中秋", calendar: "lunar", month: 8, day: 15 },
        { name: "国庆", calendar: "solar", month: 10, day: 1 }
    ]

    // ── Data: custom anniversaries (widget directory, hot reload) ──────────────
    FileView {
        id: anniversariesFile
        path: FileUtils.trimFileProtocol(String(Qt.resolvedUrl("anniversaries.json")))
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const data = JSON.parse(anniversariesFile.text() || "{}")
                root.anniversaries = Array.isArray(data.anniversaries) ? data.anniversaries : []
            } catch (e) {
                // 文件正在保存或格式错误时保留上一份数据
                console.warn("[HolidayCountdown] anniversaries.json:", e)
            }
        }
    }

    // ── Data: lunar calendar via ccal, one whole year per call ────────────────
    Process {
        id: ccalCheck
        command: ["sh", "-c", "command -v ccal"]
        onExited: (exitCode) => {
            root.ccalAvailable = exitCode === 0
            if (root.ccalAvailable)
                root.ensureYears()
        }
    }

    Process {
        id: ccalProc
        property string requestedYear: ""
        command: []
        stdout: StdioCollector { id: ccalOut }
        onExited: (exitCode) => {
            if (exitCode === 0)
                root.parseYear(ccalProc.requestedYear, ccalOut.text)
            root.runningYear = ""
            root._pumpYearQueue()
        }
    }

    Component.onCompleted: ccalCheck.running = true

    function ensureYears() {
        if (!root.ccalAvailable)
            return
        const year = root.now.getFullYear()
        root.requestYear(year)
        root.requestYear(year + 1)
    }

    function requestYear(year) {
        const key = String(year)
        if (root.lunarYears[key] !== undefined || root.runningYear === key)
            return
        for (const queued of root.yearQueue)
            if (queued === year)
                return
        root.yearQueue = root.yearQueue.concat([year])
        root._pumpYearQueue()
    }

    function _pumpYearQueue() {
        if (ccalProc.running || root.yearQueue.length === 0)
            return
        const year = root.yearQueue[0]
        root.yearQueue = root.yearQueue.slice(1)
        root.runningYear = String(year)
        ccalProc.requestedYear = String(year)
        ccalProc.command = ["ccal", "-x", "-g", "-u", String(year)]
        ccalProc.running = true
    }

    function parseYear(year, output) {
        if (!output)
            return
        const key = String(year)
        const days = ({})
        const monthRe = /<ccal:month\s+value="(\d+)"[\s\S]*?<\/ccal:month>/g
        const dayRe = /<ccal:day\s+([^>]*?)\/?>/g
        let monthMatch
        while ((monthMatch = monthRe.exec(output)) !== null) {
            const month = Number(monthMatch[1])
            const block = monthMatch[0]
            dayRe.lastIndex = 0
            let dayMatch
            while ((dayMatch = dayRe.exec(block)) !== null) {
                const attrs = dayMatch[1]
                const day = /(?:^|\s)value="(\d+)"/.exec(attrs)?.[1]
                const lunarMonth = /cmonth="(\d+)"/.exec(attrs)?.[1]
                const lunarDay = /cdate="(\d+)"/.exec(attrs)?.[1]
                if (!day || !lunarMonth || !lunarDay)
                    continue
                const dayName = /cdatename="([^"]*)"/.exec(attrs)?.[1] ?? ""
                const leap = /leap="([^"]*)"/.exec(attrs)?.[1] ?? ""
                const lunarDayNum = Number(lunarDay)
                days[key + "-" + root.pad2(month) + "-" + root.pad2(Number(day))] = {
                    m: Number(lunarMonth),
                    d: lunarDayNum,
                    leap: leap.length > 0,
                    term: dayName === root.chineseDays[lunarDayNum] ? "" : dayName
                }
            }
        }
        const next = Object.assign({}, root.lunarYears)
        next[key] = days
        root.lunarYears = next
    }

    // ── Next occurrence ───────────────────────────────────────────────────────
    function nextDate(def, today) {
        if (def.calendar === "term")
            return root.nextTerm(String(def.term ?? ""), today)
        if (def.calendar === "lunar")
            return root.nextLunar(Number(def.month), Number(def.day), today)
        return root.nextSolar(Number(def.month), Number(def.day), today)
    }

    function nextSolar(month, day, today) {
        if (!(month >= 1 && month <= 12) || !(day >= 1 && day <= 31))
            return null
        const year = today.getFullYear()
        let date = new Date(year, month - 1, day)
        if (date.getMonth() !== month - 1 || date.getDate() !== day)
            return null
        if (date < today)
            date = new Date(year + 1, month - 1, day)
        return date
    }

    function nextLunar(month, day, today) {
        if (!(month >= 1 && month <= 12) || !(day >= 1 && day <= 30))
            return null
        const firstYear = today.getFullYear()
        let best = null
        for (let year = firstYear; year <= firstYear + 1; ++year) {
            const days = root.lunarYears[String(year)]
            if (!days)
                continue
            for (const key in days) {
                const entry = days[key]
                if (entry.leap || entry.m !== month)
                    continue
                let hit = entry.d === day
                // 三十遇小月：只有该农历月确实没有三十时才按廿九算
                if (!hit && day === 30 && entry.d === 29)
                    hit = !root.monthHasThirty(days, key)
                if (!hit)
                    continue
                const date = root.dateFromKey(key)
                if (date < today)
                    continue
                if (!best || date < best)
                    best = date
            }
        }
        return best
    }

    function monthHasThirty(days, key) {
        const nextKey = root.dateKey(root.addDays(root.dateFromKey(key), 1))
        const next = days[nextKey]
        return !!next && next.d === 30 && !next.leap
    }

    function nextTerm(term, today) {
        const firstYear = today.getFullYear()
        let best = null
        for (let year = firstYear; year <= firstYear + 1; ++year) {
            const days = root.lunarYears[String(year)]
            if (!days)
                continue
            for (const key in days) {
                if (days[key].term !== term)
                    continue
                const date = root.dateFromKey(key)
                if (date < today)
                    continue
                if (!best || date < best)
                    best = date
            }
        }
        return best
    }

    function buildUpcoming() {
        const today = root.startOfDay(root.now)
        const items = []
        for (let i = 0; i < root.festivalDefs.length; ++i) {
            const def = root.festivalDefs[i]
            const date = root.nextDate(def, today)
            if (date) {
                const kind = def.calendar === "lunar" ? "阴历"
                    : def.calendar === "term" ? "节气" : "阳历"
                items.push({ name: def.name, days: root.daysUntil(date, today), date: date, kind: kind })
            }
        }
        for (let i = 0; i < root.anniversaries.length; ++i) {
            const item = root.anniversaries[i]
            if (!item || typeof item.name !== "string" || item.name.length === 0)
                continue
            const date = root.nextDate({
                calendar: item.calendar === "lunar" ? "lunar" : "solar",
                month: Number(item.month),
                day: Number(item.day)
            }, today)
            if (date)
                items.push({ name: item.name, days: root.daysUntil(date, today), date: date,
                    kind: item.calendar === "lunar" ? "阴历" : "阳历" })
        }
        items.sort((a, b) => a.days - b.days || a.name.localeCompare(b.name))
        for (let i = 0; i < items.length; ++i) {
            if (items[i].kind !== "阴历")
                continue
            const entry = root.lunarEntry(items[i].date)
            if (entry) {
                items[i].lunarMonth = entry.m
                items[i].lunarDay = entry.d
            }
        }
        return items.slice(0, 3)
    }

    readonly property var upcoming: root.buildUpcoming()

    // ── Date helpers ──────────────────────────────────────────────────────────
    function pad2(value) {
        const text = String(value)
        return text.length < 2 ? "0" + text : text
    }

    function dateKey(date) {
        return date.getFullYear() + "-" + root.pad2(date.getMonth() + 1) + "-" + root.pad2(date.getDate())
    }

    function dateFromKey(key) {
        const parts = key.split("-")
        return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]))
    }

    function addDays(date, delta) {
        return new Date(date.getFullYear(), date.getMonth(), date.getDate() + delta)
    }

    function startOfDay(date) {
        return new Date(date.getFullYear(), date.getMonth(), date.getDate())
    }

    function daysUntil(date, today) {
        return Math.round((date.getTime() - today.getTime()) / 86400000)
    }

    function solarDate(date) {
        return date.getFullYear() + " · " + root.pad2(date.getMonth() + 1) + " · "
            + root.pad2(date.getDate()) + " 周" + root.weekdayNames[date.getDay()]
    }

    function solarDateCompact(date) {
        return date.getFullYear() + "-" + root.pad2(date.getMonth() + 1) + "-"
            + root.pad2(date.getDate()) + " 周" + root.weekdayNames[date.getDay()]
    }

    function lunarEntry(date) {
        const days = root.lunarYears[String(date.getFullYear())]
        return days ? (days[root.dateKey(date)] ?? null) : null
    }

    function dateLabel(item) {
        if (item.kind !== "阴历")
            return item.kind + " " + root.solarDate(item.date)
        const lunar = item.lunarMonth > 0
            ? "阴历 " + root.lunarMonthNames[item.lunarMonth] + root.chineseDays[item.lunarDay]
            : "阴历"
        return lunar + " · " + root.solarDateCompact(item.date)
    }

    function msUntilMidnight() {
        const current = new Date()
        const next = new Date(current.getFullYear(), current.getMonth(), current.getDate() + 1)
        return Math.max(1000, next.getTime() - current.getTime())
    }

    // 一天只算一次；跨年时顺带补拉下一年农历
    Timer {
        id: midnightTimer
        interval: root.msUntilMidnight()
        running: true
        repeat: false
        onTriggered: {
            root.now = new Date()
            root.ensureYears()
            interval = root.msUntilMidnight()
            restart()
        }
    }

    // ── Card surface ──────────────────────────────────────────────────────────
    WidgetSurface {
        irisPresentation: root.widgetIris
        anchors.fill: parent
        regionBrightness: root.regionBrightness
        surfaceRadius: root.cornerRadiusOverride >= 0 ? root.cornerRadiusOverride : root.widgetCardRadius
        surfaceOpacity: root.backgroundOpacity
        surfaceBorderWidth: root.widgetIris ? 0 : root.borderWidth
        surfaceBorderOpacity: root.borderOpacity
        surfaceColor: root.widgetSurfaceInk
        colorMode: root.colorMode
        surfaceAccent: root.widgetAccent
        surfaceFill: root.widgetPlateColor
        surfaceUseBlur: root.effectiveBlur
        screenX: root.x
        screenY: root.y
        screenWidth: root.scaledScreenWidth
        screenHeight: root.scaledScreenHeight
        shown: root.backgroundOpacity > 0 || root.borderWidth > 0 || root.effectiveBlur
    }

    // iRiS rim, same as other custom widgets: no IrisWidgetFace to draw it for us.
    readonly property real irisRadius: root.cornerRadiusOverride >= 0
        ? root.cornerRadiusOverride : root.widgetCardRadius
    readonly property bool irisRimShown: root.widgetIris && root.showBorder && root.borderWidth > 0
        && (GlobalStates.widgetEditMode || root.irisOutline === "always"
            || (root.irisOutline === "auto" && (root.irisMaterial !== "clear" || root.irisRim)))
    readonly property bool irisGlassEdgeShown: root.irisRimShown && root.irisMaterial === "glass"
        && (IrisStyle.glassEdgeLight > 0 || IrisStyle.glassEdgeLine > 0)

    IrisGlassEdge {
        anchors.fill: parent
        visible: root.irisGlassEdgeShown
        radius: root.irisRadius
    }

    Rectangle {
        anchors.fill: parent
        visible: root.irisRimShown && !root.irisGlassEdgeShown
        radius: root.irisRadius
        color: "transparent"
        border.width: IrisStyle.rimWidth
        border.color: root.irisMaterial === "clear" || IrisStyle.rim.a === 0
            ? IrisStyle.clearRim : IrisStyle.rim
    }

    // ── Countdown ─────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.round(14 * root.scaleFactor)
        spacing: Math.round(8 * root.scaleFactor)
        visible: root.upcoming.length > 0

        Repeater {
            model: root.upcoming

            Rectangle {
                id: row
                required property var modelData

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Math.round(62 * root.scaleFactor)
                radius: Math.round(12 * root.scaleFactor)
                color: ColorUtils.applyAlpha(root.ink, 0.045)
                border.width: Math.max(1, Math.round(1 * root.scaleFactor))
                border.color: ColorUtils.applyAlpha(root.ink, 0.07)

                readonly property bool urgent: row.modelData.days <= 3
                readonly property color accent: row.urgent ? root.widgetSignal : root.widgetAccent

                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: Math.round(12 * root.scaleFactor)
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.round(4 * root.scaleFactor)
                    height: Math.round(34 * root.scaleFactor)
                    radius: width / 2
                    color: row.accent
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Math.round(26 * root.scaleFactor)
                    anchors.rightMargin: Math.round(14 * root.scaleFactor)
                    anchors.topMargin: Math.round(8 * root.scaleFactor)
                    anchors.bottomMargin: Math.round(8 * root.scaleFactor)
                    spacing: Math.round(8 * root.scaleFactor)

                    RowLayout {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: Math.round(78 * root.scaleFactor)
                        spacing: Math.round(3 * root.scaleFactor)

                        StyledText {
                            Layout.alignment: Qt.AlignVCenter
                            text: String(row.modelData.days)
                            color: row.accent
                            font.pixelSize: Math.round(28 * root.scaleFactor)
                            font.weight: Font.Medium
                            font.family: Appearance.font.family.numbers
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: Math.round(4 * root.scaleFactor)
                            text: "天"
                            color: root.inkMuted
                            font.pixelSize: Math.round(10 * root.scaleFactor)
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: Math.round(2 * root.scaleFactor)

                        StyledText {
                            Layout.fillWidth: true
                            text: row.modelData.name
                            color: row.urgent ? root.widgetSignal : root.widgetAccent3
                            elide: Text.ElideRight
                            font.pixelSize: Math.round(14 * root.scaleFactor)
                            font.weight: Font.DemiBold
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.dateLabel(row.modelData)
                            color: root.inkMuted
                            elide: Text.ElideRight
                            font.pixelSize: Math.round(11 * root.scaleFactor)
                        }
                    }
                }
            }
        }
    }

    StyledText {
        anchors.centerIn: parent
        visible: root.upcoming.length === 0
        text: root.ccalAvailable ? Translation.tr("Loading…") : Translation.tr("ccal not installed")
        color: root.inkMuted
        font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
    }
}

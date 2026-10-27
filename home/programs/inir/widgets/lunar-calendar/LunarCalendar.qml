pragma ComponentBehavior: Bound
// Lunar Calendar — iNiR desktop widget.
//
// A month view of the Chinese lunisolar calendar: per-day lunar date, solar
// term, statutory holiday (休) and make-up workday (补班) markers, plus custom
// events. Lunar data comes from `ccal`; holiday/调休 data is pulled from the
// holiday-cn dataset. Accent colours come from Appearance (the generated
// Material palette) so the widget follows the wallpaper like built-in widgets.

import QtQuick
import QtQuick.Layouts
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

    configEntryName: "custom.lunar-calendar"
    defaultConfig: ({
        placementStrategy: "free", widgetScale: 100, widgetOpacity: 100, colorMode: "auto", dim: 0,
        contentWidth: 380, contentHeight: 520,
        showBackground: true, useBlur: false, showBorder: true,
        backgroundOpacity: 0.14, borderWidth: 1, borderOpacity: 0.16, cornerRadius: -1,
        showSolarTerm: true, highlightHolidays: true, events: "",
        x: 360, y: 140
    })

    implicitWidth: Math.round(root.contentWidthCfg * root.scaleFactor)
    implicitHeight: Math.round(root.contentHeightCfg * root.scaleFactor)
    resizableAxes: ({ width: "contentWidth", height: "contentHeight" })
    resizeMinWidth: 300
    resizeMinHeight: 380
    resizeMaxWidth: 640
    resizeMaxHeight: 820
    needsColText: true
    visibleWhenLocked: true

    readonly property int contentWidthCfg: Math.max(300, Number(root._readConfigKey("contentWidth") ?? 380))
    readonly property int contentHeightCfg: Math.max(380, Number(root._readConfigKey("contentHeight") ?? 520))
    readonly property bool cfgShowSolarTerm: root._readConfigKey("showSolarTerm") ?? true
    readonly property bool cfgHighlightHolidays: root._readConfigKey("highlightHolidays") ?? true
    readonly property string cfgEvents: String(root._readConfigKey("events") ?? "")

    // ── Accents ───────────────────────────────────────────────────────────────
    // Read through Appearance like every built-in widget: Appearance.colors.*
    // resolves to the generated Material palette (m3primary is palette.json's
    // `primary`) and is rewritten by MaterialThemeLoader on every theme
    // regeneration, so these follow the wallpaper with no file watching.
    readonly property color colPrimary: Appearance.colors.colPrimary
    readonly property color colSecondary: Appearance.colors.colSecondary
    readonly property color colTertiary: Appearance.colors.colTertiary
    readonly property color colError: Appearance.colors.colError
    readonly property color colSuccess: Appearance.colors.colSuccess

    // Surface-aware ink (readable on the widget plate, follows light/dark).
    readonly property color ink: root.widgetSurfaceInk
    readonly property color inkMuted: ColorUtils.applyAlpha(root.widgetSurfaceInk, 0.6)

    // ── Calendar state ────────────────────────────────────────────────────────
    property date now: new Date()
    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth() + 1
    property bool ccalAvailable: true
    property var lunarDataCache: ({})     // { "YYYY-MM": { header, days: { "D": {...} } } }
    property var holidayCache: ({})       // { "YYYY": { "YYYY-MM-DD": { name, isHoliday, isWorkday } } }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    // ── ccal availability ─────────────────────────────────────────────────────
    Process {
        id: ccalCheck
        command: ["sh", "-c", "command -v ccal"]
        onExited: (exitCode) => {
            root.ccalAvailable = exitCode === 0
            if (root.ccalAvailable)
                root._refresh()
        }
    }

    // ── Lunar data (ccal XML, one month per request) ──────────────────────────
    property var monthQueue: []
    property string runningMonth: ""

    Process {
        id: ccalProc
        property string requestedKey: ""
        command: []
        stdout: StdioCollector { id: ccalOut }
        onExited: (exitCode) => {
            if (exitCode === 0)
                root.parseCcal(ccalProc.requestedKey, ccalOut.text)
            root.runningMonth = ""
            root._pumpMonthQueue()
        }
    }

    function requestMonth(year, month) {
        const key = root.monthKey(year, month)
        if (root.lunarDataCache[key] !== undefined)
            return
        if (root.runningMonth === key)
            return
        for (const queued of root.monthQueue)
            if (queued.key === key)
                return
        root.monthQueue = root.monthQueue.concat([{ key: key, year: year, month: month }])
        root._pumpMonthQueue()
    }

    function _pumpMonthQueue() {
        if (ccalProc.running || root.monthQueue.length === 0)
            return
        const req = root.monthQueue[0]
        root.monthQueue = root.monthQueue.slice(1)
        root.runningMonth = req.key
        ccalProc.requestedKey = req.key
        ccalProc.command = ["ccal", "-x", "-g", "-u", String(req.month), String(req.year)]
        ccalProc.running = true
    }

    // ── Holiday data (holiday-cn, one year per request) ───────────────────────
    property var holidayPending: ({})

    function requestHolidays(year) {
        const key = String(year)
        if (root.holidayCache[key] !== undefined || root.holidayPending[key] === true)
            return
        const pending = Object.assign({}, root.holidayPending)
        pending[key] = true
        root.holidayPending = pending

        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return
            const done = Object.assign({}, root.holidayPending)
            done[key] = false
            root.holidayPending = done
            if (xhr.status !== 200)
                return
            try {
                const data = JSON.parse(xhr.responseText)
                const map = ({})
                const days = data.days ?? []
                for (let i = 0; i < days.length; ++i) {
                    const day = days[i]
                    if (typeof day.date !== "string")
                        continue
                    map[day.date] = {
                        isHoliday: day.isOffDay === true,
                        isWorkday: day.isOffDay === false
                    }
                }
                const next = Object.assign({}, root.holidayCache)
                next[key] = map
                root.holidayCache = next
            } catch (e) {
                // Malformed payload — leave the year unfetched so it can retry.
            }
        }
        xhr.open("GET", "https://raw.githubusercontent.com/NateScarlet/holiday-cn/master/" + year + ".json")
        xhr.send()
    }

    function _refresh() {
        if (!root.ccalAvailable)
            return
        root.requestMonth(root.viewYear, root.viewMonth)
        root.requestHolidays(root.viewYear)
    }

    Component.onCompleted: ccalCheck.running = true
    onViewYearChanged: root._refresh()
    onViewMonthChanged: root._refresh()

    // ── Constants & helpers ───────────────────────────────────────────────────
    readonly property var chineseDays: [
        "", "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
    ]
    readonly property var lunarMonthNumbers: ({
        "正月": 1, "二月": 2, "三月": 3, "四月": 4, "五月": 5, "六月": 6,
        "七月": 7, "八月": 8, "九月": 9, "十月": 10, "十一月": 11, "十二月": 12
    })
    readonly property var weekdayLabels: ["日", "一", "二", "三", "四", "五", "六"]

    function pad2(value, width) {
        let text = String(value)
        const target = width ?? 2
        while (text.length < target)
            text = "0" + text
        return text
    }

    function monthKey(year, month) {
        return year + "-" + root.pad2(month)
    }

    function parseCcal(key, output) {
        if (!output)
            return
        const monthData = { header: "", days: ({}) }
        const headerMatch = output.match(/<ccal:month[^>]+cname="([^"]+)"/)
        if (headerMatch)
            monthData.header = headerMatch[1]

        const re = /<ccal:day\s+value="(\d+)"[^>]*?leap="([^"]*)"[^>]*?cdate="(\d+)"[^>]*?cmonthname="([^"]+)"[^>]*?cdatename="([^"]+)"/g
        let match
        while ((match = re.exec(output)) !== null) {
            const gregDay = match[1]
            const isLeap = match[2] !== ""
            const lunarDayNum = Number(match[3])
            const monthName = match[4]
            const displayName = match[5]
            const lunarDayText = root.chineseDays[lunarDayNum] || displayName
            const baseMonth = monthName.replace(/^闰/, "")

            let solarTerm = ""
            if (displayName !== lunarDayText && displayName !== monthName && displayName.indexOf("月") < 0)
                solarTerm = displayName

            monthData.days[gregDay] = {
                lunarDayRaw: lunarDayText,
                lunarDayNum: lunarDayNum,
                lunarMonthNum: root.lunarMonthNumbers[baseMonth] ?? 0,
                solarTerm: solarTerm,
                isLeap: isLeap
            }
        }

        const next = Object.assign({}, root.lunarDataCache)
        next[key] = monthData
        root.lunarDataCache = next
    }

    function lunarDataFor(year, month, day) {
        const cache = root.lunarDataCache[root.monthKey(year, month)]
        if (!cache || !cache.days)
            return null
        return cache.days[String(day)] ?? null
    }

    function holidayFor(year, month, day) {
        const cache = root.holidayCache[String(year)]
        if (!cache)
            return null
        return cache[root.pad2(year, 4) + "-" + root.pad2(month) + "-" + root.pad2(day)] ?? null
    }

    function lunarMonthHeader(year, month) {
        const cache = root.lunarDataCache[root.monthKey(year, month)]
        if (!cache || !cache.header)
            return ""
        const base = cache.header.match(/^(.*?)\d+日始$/)
        return base ? "农历" + base[1] : "农历" + cache.header
    }

    function parseEvents(raw) {
        const out = []
        const lines = String(raw ?? "").split("\n")
        for (let i = 0; i < lines.length; ++i) {
            const line = lines[i].trim()
            if (line.length === 0)
                continue
            const match = line.match(/^(\w)\s+([0-9L]+-\d+)\s+(.+)$/)
            if (!match)
                continue
            const prefix = match[1]
            let datePart = match[2]
            const desc = match[3].trim()
            let leap = false
            if (datePart.charAt(0) === "L") {
                leap = true
                datePart = datePart.slice(1)
            }
            const dm = datePart.match(/^(\d+)-(\d+)$/)
            if (!dm)
                continue
            const mo = Number(dm[1])
            const dy = Number(dm[2])
            if (prefix === "G" && mo >= 1 && mo <= 12 && dy >= 1 && dy <= 31)
                out.push({ type: "G", month: mo, day: dy, desc: desc })
            else if (prefix === "L" && mo >= 1 && mo <= 12 && dy >= 1 && dy <= 30)
                out.push({ type: "L", month: mo, day: dy, desc: desc, leap: leap })
        }
        return out
    }

    function eventDescs(month, day, data) {
        const out = []
        const events = root.parseEvents(root.cfgEvents)
        for (let i = 0; i < events.length; ++i) {
            const event = events[i]
            if (event.type === "G") {
                if (event.month === month && event.day === day)
                    out.push(event.desc)
            } else if (event.type === "L" && data) {
                if (event.month === data.lunarMonthNum && event.day === data.lunarDayNum && event.leap === data.isLeap)
                    out.push(event.desc)
            }
        }
        return out
    }

    function blankCell() {
        return {
            empty: true, day: 0, isToday: false,
            ink: "transparent", lunarInk: "transparent",
            lunarText: "", solarTerm: "", badge: "", badgeInk: "transparent", events: ""
        }
    }

    function dayCell(year, month, day) {
        const now = root.now
        const isToday = now.getFullYear() === year && now.getMonth() + 1 === month && now.getDate() === day
        const data = root.lunarDataFor(year, month, day)
        const holiday = root.holidayFor(year, month, day)
        const events = root.eventDescs(month, day, data)

        // Holiday badge is independent of "today": a make-up workday that falls
        // on today must still read 补班, and a holiday today must still read 休.
        let badge = ""
        let badgeInk = root.colTertiary
        let holidayInk = null
        if (root.cfgHighlightHolidays && holiday) {
            if (holiday.isHoliday) {
                badge = "休"
                badgeInk = root.colSuccess
                holidayInk = root.colError
            } else if (holiday.isWorkday) {
                badge = "补班"
                badgeInk = root.colTertiary
                holidayInk = root.colTertiary
            }
        }

        let ink = root.ink
        let lunarInk = root.inkMuted
        if (isToday) {
            ink = root.colPrimary
            lunarInk = root.colPrimary
        } else if (events.length > 0) {
            ink = root.colError
            lunarInk = root.colError
        } else if (holidayInk) {
            ink = holidayInk
            lunarInk = holidayInk
        }

        return {
            empty: false,
            day: day,
            isToday: isToday,
            ink: ink,
            lunarInk: lunarInk,
            lunarText: data ? data.lunarDayRaw : "",
            solarTerm: (root.cfgShowSolarTerm && data) ? data.solarTerm : "",
            badge: badge,
            badgeInk: badgeInk,
            events: events.join(" ")
        }
    }

    function monthCells(year, month) {
        const startWeekday = new Date(year, month - 1, 1).getDay()
        const daysInMonth = new Date(year, month, 0).getDate()
        const cells = []
        for (let i = 0; i < startWeekday; ++i)
            cells.push(root.blankCell())
        for (let day = 1; day <= daysInMonth; ++day)
            cells.push(root.dayCell(year, month, day))
        while (cells.length % 7 !== 0)
            cells.push(root.blankCell())
        return cells
    }

    readonly property bool viewingCurrentMonth: root.now.getFullYear() === root.viewYear
        && root.now.getMonth() + 1 === root.viewMonth
    readonly property string headerTitle: root.viewingCurrentMonth
        ? root.viewYear + "年" + root.viewMonth + "月" + root.now.getDate() + "日 星期" + root.weekdayLabels[root.now.getDay()]
        : root.viewYear + "年" + root.viewMonth + "月"
    readonly property string headerSubtitle: root.lunarMonthHeader(root.viewYear, root.viewMonth)

    function stepMonth(delta) {
        let month = root.viewMonth + delta
        let year = root.viewYear
        if (month < 1) {
            month = 12
            year -= 1
        } else if (month > 12) {
            month = 1
            year += 1
        }
        root.viewYear = year
        root.viewMonth = month
    }

    function resetToToday() {
        root.viewYear = root.now.getFullYear()
        root.viewMonth = root.now.getMonth() + 1
    }

    // ── Card surface (matches other desktop widgets) ──────────────────────────
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

    // ── iRiS rim / lit glass edge ─────────────────────────────────────────────
    // Built-in iris widgets get this from their IrisWidgetFace (IrisWidgetFace.qml
    // draws IrisGlassEdge + the flat rim). A custom widget has no face, so it is
    // drawn here; without it the card would only carry WidgetSurface's dim ink
    // border instead of the accent-lit ring the other widgets show.
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

    // ── Missing-dependency notice ─────────────────────────────────────────────
    ColumnLayout {
        anchors.centerIn: parent
        visible: !root.ccalAvailable
        spacing: Math.round(8 * root.scaleFactor)
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Translation.tr("ccal not installed")
            color: root.colError
            font.pixelSize: Math.round(Appearance.font.pixelSize.normal * root.scaleFactor)
            font.weight: Font.DemiBold
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Translation.tr("Install ccal to show the lunar calendar")
            color: root.inkMuted
            font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
        }
    }

    // ── Calendar ──────────────────────────────────────────────────────────────
    ColumnLayout {
        visible: root.ccalAvailable
        anchors.fill: parent
        anchors.margins: Math.round(14 * root.scaleFactor)
        spacing: Math.round(8 * root.scaleFactor)

        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(5 * root.scaleFactor)

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Math.round(2 * root.scaleFactor)
                StyledText {
                    text: root.headerTitle
                    color: root.colPrimary
                    font.pixelSize: Math.round(Appearance.font.pixelSize.large * root.scaleFactor)
                    font.weight: Font.Bold
                }
                StyledText {
                    visible: root.headerSubtitle.length > 0
                    text: root.headerSubtitle
                    color: root.colSecondary
                    font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
                }
            }

            Repeater {
                model: [
                    { icon: "chevron_left", tip: "Previous month", action: -1 },
                    { icon: "today", tip: "Today", action: 0 },
                    { icon: "chevron_right", tip: "Next month", action: 1 }
                ]
                RippleButton {
                    required property var modelData
                    Layout.preferredWidth: Math.round(30 * root.scaleFactor)
                    Layout.preferredHeight: Math.round(30 * root.scaleFactor)
                    buttonRadius: Appearance.rounding.full
                    colBackground: modelData.action === 0 && root.viewingCurrentMonth
                        ? ColorUtils.applyAlpha(root.colPrimary, 0.18) : "transparent"
                    colBackgroundHover: ColorUtils.applyAlpha(root.ink, 0.08)
                    colRipple: ColorUtils.applyAlpha(root.colPrimary, 0.12)
                    releaseAction: () => {
                        if (modelData.action === 0)
                            root.resetToToday()
                        else
                            root.stepMonth(modelData.action)
                    }
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: modelData.icon
                        iconSize: Math.round(16 * root.scaleFactor)
                        color: modelData.action === 0 && root.viewingCurrentMonth ? root.colPrimary : root.ink
                    }
                    StyledToolTip { text: Translation.tr(modelData.tip) }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            Repeater {
                model: root.weekdayLabels
                StyledText {
                    required property string modelData
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: root.inkMuted
                    font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
                    font.weight: Font.DemiBold
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            columnSpacing: Math.round(2 * root.scaleFactor)
            rowSpacing: Math.round(2 * root.scaleFactor)

            Repeater {
                model: root.monthCells(root.viewYear, root.viewMonth)

                Item {
                    id: dayCell
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Blank cells must stay visible: QtQuick Layouts drop
                    // invisible children, which would collapse the leading and
                    // trailing blanks and shift the whole week row left.
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Math.round(2 * root.scaleFactor)
                        radius: Math.round(10 * root.scaleFactor)
                        visible: !dayCell.modelData.empty
                        color: dayCell.modelData.isToday ? ColorUtils.applyAlpha(root.colPrimary, 0.16) : "transparent"
                        border.width: dayCell.modelData.isToday ? Math.max(1, Math.round(1 * root.scaleFactor)) : 0
                        border.color: ColorUtils.applyAlpha(root.colPrimary, 0.45)
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        width: parent.width - Math.round(4 * root.scaleFactor)
                        spacing: Math.round(1 * root.scaleFactor)
                        visible: !dayCell.modelData.empty

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: String(dayCell.modelData.day)
                            color: dayCell.modelData.ink
                            font.pixelSize: Math.round((dayCell.modelData.isToday ? 19 : 16) * root.scaleFactor)
                            font.weight: dayCell.modelData.isToday ? Font.Bold : Font.Medium
                            font.family: Appearance.font.family.numbers
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            visible: dayCell.modelData.lunarText.length > 0
                            text: dayCell.modelData.lunarText
                            color: dayCell.modelData.lunarInk
                            font.pixelSize: Math.round(10 * root.scaleFactor)
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            visible: dayCell.modelData.badge.length > 0
                            text: dayCell.modelData.badge
                            color: dayCell.modelData.badgeInk
                            font.pixelSize: Math.round(9 * root.scaleFactor)
                            font.weight: Font.Bold
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            visible: dayCell.modelData.solarTerm.length > 0
                            text: dayCell.modelData.solarTerm
                            color: root.colSecondary
                            font.pixelSize: Math.round(9 * root.scaleFactor)
                            font.weight: Font.Medium
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillWidth: true
                            visible: dayCell.modelData.events.length > 0
                            horizontalAlignment: Text.AlignHCenter
                            text: dayCell.modelData.events
                            color: root.colSecondary
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            font.pixelSize: Math.round(9 * root.scaleFactor)
                        }
                    }
                }
            }
        }
    }

    // ── Edit-mode quick toggles ───────────────────────────────────────────────
    editPopoverContent: Component {
        ColumnLayout {
            spacing: 14
            WidgetQuickSection {
                title: Translation.tr("Show")
                WidgetQuickToggle {
                    Layout.fillWidth: true
                    iconName: "wb_twilight"
                    label: Translation.tr("Solar terms")
                    checked: root.cfgShowSolarTerm
                    onToggled: root._setOutputValue("showSolarTerm", !root.cfgShowSolarTerm)
                }
                WidgetQuickToggle {
                    Layout.fillWidth: true
                    iconName: "event_available"
                    label: Translation.tr("Holidays")
                    checked: root.cfgHighlightHolidays
                    onToggled: root._setOutputValue("highlightHolidays", !root.cfgHighlightHolidays)
                }
            }
        }
    }
}

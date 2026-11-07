import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// "Aurora Rings": a wallpaper drawn entirely with vector primitives, so it is
// sharp and correctly centred on any round screen size.
class WallpaperFaceView extends WatchUi.WatchFace {

    // Ring colours, outermost to innermost (teal -> violet -> magenta).
    private const RING_COLORS = [0x00E5C8, 0x00C2E0, 0x3A8DFF, 0x7B61FF, 0xB34DFF, 0xFF4FA3];
    private const ACCENT = 0xFFB020;

    private var _asleep as Boolean = false;

    function initialize() {
        WatchFace.initialize();
    }

    function onEnterSleep() as Void {
        _asleep = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _asleep = false;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;

        // Pure black background: on AMOLED, unlit pixels cost no power.
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (_asleep) {
            // Low-power mode: dim, outline-only look to limit burn-in.
            drawTicks(dc, cx, cy, w, 0x404040, 0x808080);
            drawTime(dc, cx, cy, 0x909090);
            return;
        }

        drawRings(dc, cx, cy, w);
        drawTicks(dc, cx, cy, w, 0x303030, Graphics.COLOR_WHITE);
        drawTime(dc, cx, cy, Graphics.COLOR_WHITE);
        drawDate(dc, cx, cy, h);
        drawStats(dc, cx, cy, w, h);
    }

    // Decorative concentric arcs. Each ring has a different sweep so the
    // result looks like an abstract aurora rather than a plain target.
    private function drawRings(dc as Dc, cx as Number, cy as Number, w as Number) as Void {
        var maxR = w / 2;
        var starts = [200, 120, 300, 60, 240, 10];
        var sweeps = [150, 200, 110, 230, 140, 260];
        dc.setPenWidth((w * 0.012).toNumber() + 1);
        for (var i = 0; i < RING_COLORS.size(); i++) {
            var r = (maxR * (0.80 - i * 0.075)).toNumber();
            dc.setColor(RING_COLORS[i], Graphics.COLOR_TRANSPARENT);
            var s = starts[i];
            var e = (s + sweeps[i]) % 360;
            dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, e, s);
        }
        dc.setPenWidth(1);
    }

    // 60 minute ticks around the bezel; hour ticks are longer and brighter.
    private function drawTicks(dc as Dc, cx as Number, cy as Number, w as Number,
                               minuteColor as Number, hourColor as Number) as Void {
        var maxR = w / 2;
        for (var i = 0; i < 60; i++) {
            var a = Math.toRadians(i * 6);
            var isHour = (i % 5 == 0);
            var rOuter = maxR - 2;
            var rInner = rOuter - (isHour ? maxR * 0.07 : maxR * 0.03);
            dc.setColor(isHour ? hourColor : minuteColor, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(isHour ? 3 : 1);
            dc.drawLine(cx + rInner * Math.sin(a), cy - rInner * Math.cos(a),
                        cx + rOuter * Math.sin(a), cy - rOuter * Math.cos(a));
        }
        dc.setPenWidth(1);
    }

    private function drawTime(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        var t = System.getClockTime();
        var hour = t.hour;
        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) { hour = 12; }
        }
        var text = hour.format("%d") + ":" + t.min.format("%02d");
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy, Graphics.FONT_NUMBER_HOT, text,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawDate(dc as Dc, cx as Number, cy as Number, h as Number) as Void {
        var now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var text = now.day_of_week.toString().toUpper() + " " + now.day.format("%d");
        dc.setColor(ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.27).toNumber(), Graphics.FONT_TINY, text,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Heart rate (left), steps (right), battery (bottom). Missing data shows "--".
    private function drawStats(dc as Dc, cx as Number, cy as Number, w as Number, h as Number) as Void {
        var y = (h * 0.70).toNumber();

        var hr = Activity.getActivityInfo().currentHeartRate;
        var hrText = (hr != null) ? hr.format("%d") : "--";
        var steps = ActivityMonitor.getInfo().steps;
        var stepsText = (steps != null) ? steps.format("%d") : "--";
        var batt = System.getSystemStats().battery.toNumber();

        dc.setColor(0xFF4FA3, Graphics.COLOR_TRANSPARENT);
        dc.drawText((w * 0.34).toNumber(), y, Graphics.FONT_XTINY, hrText + " bpm",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x00E5C8, Graphics.COLOR_TRANSPARENT);
        dc.drawText((w * 0.66).toNumber(), y, Graphics.FONT_XTINY, stepsText + " st",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(batt <= 15 ? Graphics.COLOR_RED : 0x9AA0A6, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (h * 0.80).toNumber(), Graphics.FONT_XTINY, batt.format("%d") + "%",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

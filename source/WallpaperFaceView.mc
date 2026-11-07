import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// "Outlaw HUD": Red Dead Redemption 2 inspired face.
// Three "core" arcs around the bezel, sunset wallpaper and a cowboy silhouette,
// all drawn with vector primitives so it fits any round screen.
//   Health   (red)   = steps toward daily goal
//   Stamina  (green) = heart rate (fraction of 190 bpm)
//   Dead Eye (gold)  = watch battery
class WallpaperFaceView extends WatchUi.WatchFace {

    private const CREAM  = 0xF2E2C0;
    private const HEALTH = 0xC9372C;
    private const STAMINA = 0x6BBF59;
    private const DEADEYE = 0xE8C15A;
    private const TRACK  = 0x2A2018;

    private const SPAN = 80;  // degrees per core arc

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

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (_asleep) {
            // Low power: dim time only (limits AMOLED burn-in).
            drawTime(dc, cx, (h * 0.42).toNumber(), 0x8A8070);
            return;
        }

        drawScene(dc, cx, w, h);

        // Gather data.
        var info = ActivityMonitor.getInfo();
        var steps = info.steps;
        var goal = info.stepGoal;
        var stepFrac = (steps != null && goal != null && goal > 0) ? steps.toFloat() / goal : 0.0;
        var hr = Activity.getActivityInfo().currentHeartRate;
        var hrFrac = (hr != null) ? hr.toFloat() / 190.0 : 0.0;
        var batt = System.getSystemStats().battery;
        var battFrac = batt / 100.0;

        // Cores: Health on the left, Stamina on the right, Dead Eye on top.
        drawCore(dc, cx, cy, w, 140, stepFrac, HEALTH);
        drawCore(dc, cx, cy, w, 320, hrFrac, STAMINA);
        drawCore(dc, cx, cy, w, 50,  battFrac, DEADEYE);

        // Values sit just inside each arc, at its midpoint.
        var stepsText = (steps != null) ? steps.format("%d") : "--";
        var hrText = (hr != null) ? hr.format("%d") : "--";
        drawAt(dc, cx, cy, w, 180, 0.30, stepsText, HEALTH);
        drawAt(dc, cx, cy, w, 0,   0.30, hrText, STAMINA);
        drawAt(dc, cx, cy, w, 90,  0.34, batt.toNumber().format("%d") + "%", DEADEYE);

        drawDate(dc, cx, (h * 0.30).toNumber());
        drawTime(dc, cx, (h * 0.44).toNumber(), CREAM);
    }

    // Sunset + mesas + original cowboy silhouette.
    private function drawScene(dc as Dc, cx as Number, w as Number, h as Number) as Void {
        var sunY = (h * 0.74).toNumber();
        dc.setColor(0x3A1608, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, sunY, (w * 0.30).toNumber());
        dc.setColor(0x7A2E10, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, sunY, (w * 0.26).toNumber());
        dc.setColor(0xC4501B, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, sunY, (w * 0.21).toNumber());

        // Mesas on the horizon.
        var hy = (h * 0.76).toNumber();
        dc.setColor(0x1C0C06, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [0, h], [0, hy], [(w * 0.10).toNumber(), hy],
            [(w * 0.14).toNumber(), hy - (h * 0.06).toNumber()],
            [(w * 0.26).toNumber(), hy - (h * 0.06).toNumber()],
            [(w * 0.30).toNumber(), hy],
            [(w * 0.70).toNumber(), hy],
            [(w * 0.76).toNumber(), hy - (h * 0.04).toNumber()],
            [(w * 0.88).toNumber(), hy - (h * 0.04).toNumber()],
            [(w * 0.92).toNumber(), hy], [w, hy], [w, h]
        ]);

        // Silhouette (hat, head, shoulders). Units are w/140.
        var u = w / 140.0;
        var by = (h * 0.97).toNumber();
        dc.setColor(0x080403, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            pt(cx, by, u, -28, 0), pt(cx, by, u, -26, -14), pt(cx, by, u, -16, -20),
            pt(cx, by, u, -5, -23), pt(cx, by, u, 5, -23), pt(cx, by, u, 16, -20),
            pt(cx, by, u, 26, -14), pt(cx, by, u, 28, 0)
        ]);
        dc.fillCircle(cx, by - (31 * u).toNumber(), (8 * u).toNumber());
        dc.fillEllipse(cx, by - (37 * u).toNumber(), (18 * u).toNumber(), (3.5 * u).toNumber());
        dc.fillPolygon([
            pt(cx, by, u, -9, -37), pt(cx, by, u, -8, -47), pt(cx, by, u, -4, -49),
            pt(cx, by, u, 4, -49), pt(cx, by, u, 8, -47), pt(cx, by, u, 9, -37)
        ]);
    }

    private function pt(cx as Number, by as Number, u as Float, x as Number, y as Number) as Array<Number> {
        return [cx + (x * u).toNumber(), by + (y * u).toNumber()];
    }

    // One core: dim track plus a filled portion starting at startDeg (counter-clockwise).
    private function drawCore(dc as Dc, cx as Number, cy as Number, w as Number,
                              startDeg as Number, frac as Float, color as Number) as Void {
        if (frac > 1.0) { frac = 1.0; }
        if (frac < 0.0) { frac = 0.0; }
        var r = (w * 0.46).toNumber();
        dc.setPenWidth((w * 0.035).toNumber() + 2);
        dc.setColor(TRACK, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, r, Graphics.ARC_COUNTER_CLOCKWISE, startDeg, startDeg + SPAN);
        if (frac > 0.0) {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(cx, cy, r, Graphics.ARC_COUNTER_CLOCKWISE, startDeg,
                       startDeg + (SPAN * frac).toNumber());
        }
        dc.setPenWidth(1);
    }

    private function drawAt(dc as Dc, cx as Number, cy as Number, w as Number,
                            deg as Number, radiusFrac as Float, text as String, color as Number) as Void {
        var a = Math.toRadians(deg);
        var r = w * radiusFrac;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx + r * Math.cos(a), cy - r * Math.sin(a), Graphics.FONT_XTINY, text,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawTime(dc as Dc, cx as Number, y as Number, color as Number) as Void {
        var t = System.getClockTime();
        var hour = t.hour;
        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) { hour = 12; }
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_NUMBER_HOT, hour.format("%d") + ":" + t.min.format("%02d"),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawDate(dc as Dc, cx as Number, y as Number) as Void {
        var now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        dc.setColor(DEADEYE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_TINY, now.day_of_week.toString().toUpper() + " " + now.day.format("%d"),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;
import Toybox.Application;

// "Outlaw HUD": HUD-style watch face inspired by open-world western games.
// A row of circular cores (icon + draining ring) in an arc above a compass map.
//   Health   (heart) = steps toward daily goal   (icon red; ring gold at 100%)
//   Stamina  (bolt)  = heart rate (of 190 bpm)
//   Dead Eye (eye)   = watch battery
class WallpaperFaceView extends WatchUi.WatchFace {

    private const RING_ON  = 0xF2F2F2;
    private const GOLD     = 0xEBD64B;
    private const ICON_RED = 0xD0302A;
    private const DISC     = 0x0E0B08;
    private const TRACK    = 0x34302A;
    private const PARCH    = 0xC9B48A;
    private const INK      = 0x1A1208;

    private var _asleep as Boolean = false;
    private var _logo as BitmapResource? = null;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
        _logo = WatchUi.loadResource(Rez.Drawables.Logo) as BitmapResource;
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

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        // (Future: draw a background wallpaper bitmap here.)

        if (_asleep) {
            drawTime(dc, cx, (h * 0.45).toNumber(), 0x8A8070);
            return;
        }

        var info = ActivityMonitor.getInfo();
        var steps = info.steps;
        var goal = info.stepGoal;
        var stepFrac = (steps != null && goal != null && goal > 0) ? steps.toFloat() / goal : 0.0;
        var hr = Activity.getActivityInfo().currentHeartRate;
        var hrFrac = (hr != null) ? hr.toFloat() / 190.0 : 0.0;
        var batt = System.getSystemStats().battery;

        drawTime(dc, cx, (h * 0.10).toNumber(), 0xF2F2F2);

        // Logo slot (resources/drawables/logo.png), centred under the time.
        if (_logo != null) {
            dc.drawBitmap(cx - _logo.getWidth() / 2, (h * 0.17).toNumber(), _logo);
        }

        // Cores in an arc: sides lower, centre higher.
        var r = (w * 0.065).toNumber();
        var xL = (w * 0.25).toNumber();
        var xR = (w * 0.75).toNumber();
        var ySide = (h * 0.46).toNumber();
        var yMid = (h * 0.40).toNumber();

        drawCore(dc, xL, ySide, r, stepFrac);
        drawHeart(dc, xL, ySide, r);
        drawCore(dc, cx, yMid, r, hrFrac);
        drawBolt(dc, cx, yMid, r);
        drawCore(dc, xR, ySide, r, batt / 100.0);
        drawEye(dc, xR, ySide, r);

        drawLabel(dc, xL, ySide + r + 12, (steps != null) ? steps.format("%d") : "--");
        drawLabel(dc, cx, yMid + r + 12, (hr != null) ? hr.format("%d") : "--");
        drawLabel(dc, xR, ySide + r + 12, batt.toNumber().format("%d") + "%");

        drawMap(dc, cx, (h * 0.77).toNumber(), (w * 0.235).toNumber(), h);
    }

    // Core: dark disc, ring that drains (gold when full), gap shows what's used.
    private function drawCore(dc as Dc, x as Number, y as Number, r as Number, frac as Float) as Void {
        if (frac > 1.0) { frac = 1.0; }
        if (frac < 0.0) { frac = 0.0; }
        dc.setColor(DISC, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, r);
        dc.setPenWidth(5);
        dc.setColor(TRACK, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(x, y, r);
        if (frac >= 0.995) {
            dc.setColor(GOLD, Graphics.COLOR_TRANSPARENT);
            dc.drawCircle(x, y, r);
        } else if (frac > 0.0) {
            dc.setColor(RING_ON, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(x, y, r, Graphics.ARC_CLOCKWISE, 90, 90 - (360 * frac).toNumber());
        }
        dc.setPenWidth(1);
    }

    // Compass map: parchment disc, dark rim, terrain patches, N/E/S/W, position marker, date.
    private function drawMap(dc as Dc, cx as Number, cy as Number, R as Number, h as Number) as Void {
        dc.setColor(PARCH, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, R);
        dc.setColor(0x8FA38A, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx - R * 0.45, cy + R * 0.25, R * 0.32);
        dc.fillCircle(cx + R * 0.10, cy + R * 0.55, R * 0.22);
        dc.setColor(0xC98A6A, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx - R * 0.15, cy + R * 0.30, R * 0.28);
        dc.setColor(INK, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(5);
        dc.drawCircle(cx, cy, R);
        dc.setPenWidth(1);

        // Compass ticks and letters on the rim.
        for (var i = 0; i < 8; i++) {
            var a = Math.toRadians(i * 45);
            var len = (i % 2 == 0) ? R * 0.10 : R * 0.06;
            dc.setPenWidth(2);
            dc.drawLine(cx + (R - len) * Math.sin(a), cy - (R - len) * Math.cos(a),
                        cx + R * Math.sin(a), cy - R * Math.cos(a));
        }
        dc.setPenWidth(1);
        var letters = ["N", "E", "S", "W"];
        for (var i = 0; i < 4; i++) {
            var a = Math.toRadians(i * 90);
            dc.drawText(cx + R * 0.80 * Math.sin(a), cy - R * 0.80 * Math.cos(a),
                        Graphics.FONT_XTINY, letters[i],
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Position marker (white teardrop).
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy + 4, R * 0.09);
        dc.fillPolygon([[cx - R * 0.08, cy + 1], [cx + R * 0.08, cy + 1], [cx, cy - R * 0.14]]);

        var now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        dc.setColor(INK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + R * 0.50, Graphics.FONT_XTINY,
                    now.day_of_week.toString().toUpper() + " " + now.day.format("%d"),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawHeart(dc as Dc, x as Number, y as Number, r as Number) as Void {
        var s = r * 0.42;
        dc.setColor(ICON_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x - s * 0.5, y - s * 0.3, s * 0.55);
        dc.fillCircle(x + s * 0.5, y - s * 0.3, s * 0.55);
        dc.fillPolygon([[x - s * 1.0, y - s * 0.1], [x + s * 1.0, y - s * 0.1], [x, y + s * 1.0]]);
    }

    private function drawBolt(dc as Dc, x as Number, y as Number, r as Number) as Void {
        var s = r * 0.5;
        dc.setColor(ICON_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [x + s * 0.25, y - s * 1.0], [x - s * 0.55, y + s * 0.1], [x - s * 0.05, y + s * 0.1],
            [x - s * 0.25, y + s * 1.0], [x + s * 0.55, y - s * 0.15], [x + s * 0.05, y - s * 0.15]
        ]);
    }

    private function drawEye(dc as Dc, x as Number, y as Number, r as Number) as Void {
        var s = r * 0.55;
        dc.setColor(ICON_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillEllipse(x, y, s, s * 0.55);
        dc.setColor(DISC, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, s * 0.38);
        dc.setColor(ICON_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, s * 0.2);
    }

    private function drawLabel(dc as Dc, x as Number, y as Number, text as String) as Void {
        dc.setColor(0xF2F2F2, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, Graphics.FONT_XTINY, text,
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
        dc.drawText(cx, y, Graphics.FONT_NUMBER_MEDIUM, hour.format("%d") + ":" + t.min.format("%02d"),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

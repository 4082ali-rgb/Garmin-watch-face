import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// "Outlaw HUD": Red Dead Redemption 2 style core gauges.
// Three circular cores (icon + draining ring), like the in-game HUD:
//   Health   = steps toward daily goal   (red when below 25%)
//   Stamina  = heart rate (of 190 bpm)
//   Dead Eye = watch battery             (gold when full)
class WallpaperFaceView extends WatchUi.WatchFace {

    private const CREAM  = 0xF2E2C0;
    private const HEALTH = 0xC9372C;
    private const GOLD   = 0xE8C15A;
    private const DISC   = 0x14100B;
    private const TRACK  = 0x3A3126;

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

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        // (Future: draw a background wallpaper bitmap here.)

        if (_asleep) {
            drawTime(dc, cx, (h * 0.40).toNumber(), 0x8A8070);
            return;
        }

        var info = ActivityMonitor.getInfo();
        var steps = info.steps;
        var goal = info.stepGoal;
        var stepFrac = (steps != null && goal != null && goal > 0) ? steps.toFloat() / goal : 0.0;
        var hr = Activity.getActivityInfo().currentHeartRate;
        var hrFrac = (hr != null) ? hr.toFloat() / 190.0 : 0.0;
        var batt = System.getSystemStats().battery;

        drawDate(dc, cx, (h * 0.17).toNumber());
        drawTime(dc, cx, (h * 0.36).toNumber(), CREAM);

        var r = (w * 0.095).toNumber();
        var yMid = (h * 0.62).toNumber();
        var yLow = (h * 0.70).toNumber();
        var xL = (w * 0.27).toNumber();
        var xR = (w * 0.73).toNumber();

        // Health (heart), Stamina (bolt), Dead Eye (eye): an arc like the game HUD.
        var hColor = (stepFrac < 0.25) ? HEALTH : CREAM;
        drawCore(dc, xL, yMid, r, stepFrac, hColor);
        drawHeart(dc, xL, yMid, r, hColor);
        drawCore(dc, cx, yLow, r, hrFrac, CREAM);
        drawBolt(dc, cx, yLow, r, CREAM);
        var dColor = (batt >= 99) ? GOLD : CREAM;
        drawCore(dc, xR, yMid, r, batt / 100.0, dColor);
        drawEye(dc, xR, yMid, r, dColor);

        drawLabel(dc, xL, yMid + r + 14, (steps != null) ? steps.format("%d") : "--");
        drawLabel(dc, cx, yLow + r + 14, (hr != null) ? hr.format("%d") : "--");
        drawLabel(dc, xR, yMid + r + 14, batt.toNumber().format("%d") + "%");
    }

    // Circular core: dark disc, dim track, ring that fills clockwise from 12 o'clock.
    private function drawCore(dc as Dc, x as Number, y as Number, r as Number,
                              frac as Float, color as Number) as Void {
        if (frac > 1.0) { frac = 1.0; }
        if (frac < 0.0) { frac = 0.0; }
        dc.setColor(DISC, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, r);
        dc.setPenWidth(4);
        dc.setColor(TRACK, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(x, y, r);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        if (frac >= 0.995) {
            dc.drawCircle(x, y, r);
        } else if (frac > 0.0) {
            dc.drawArc(x, y, r, Graphics.ARC_CLOCKWISE, 90, 90 - (360 * frac).toNumber());
        }
        dc.setPenWidth(1);
    }

    private function drawHeart(dc as Dc, x as Number, y as Number, r as Number, color as Number) as Void {
        var s = r * 0.42;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x - s * 0.5, y - s * 0.3, s * 0.55);
        dc.fillCircle(x + s * 0.5, y - s * 0.3, s * 0.55);
        dc.fillPolygon([[x - s * 1.0, y - s * 0.1], [x + s * 1.0, y - s * 0.1], [x, y + s * 1.0]]);
    }

    private function drawBolt(dc as Dc, x as Number, y as Number, r as Number, color as Number) as Void {
        var s = r * 0.5;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [x + s * 0.25, y - s * 1.0], [x - s * 0.55, y + s * 0.1], [x - s * 0.05, y + s * 0.1],
            [x - s * 0.25, y + s * 1.0], [x + s * 0.55, y - s * 0.15], [x + s * 0.05, y - s * 0.15]
        ]);
    }

    private function drawEye(dc as Dc, x as Number, y as Number, r as Number, color as Number) as Void {
        var s = r * 0.55;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillEllipse(x, y, s, s * 0.55);
        dc.setColor(DISC, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, s * 0.38);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, s * 0.2);
    }

    private function drawLabel(dc as Dc, x as Number, y as Number, text as String) as Void {
        dc.setColor(CREAM, Graphics.COLOR_TRANSPARENT);
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
        dc.drawText(cx, y, Graphics.FONT_NUMBER_HOT, hour.format("%d") + ":" + t.min.format("%02d"),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawDate(dc as Dc, cx as Number, y as Number) as Void {
        var now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        dc.setColor(GOLD, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_TINY, now.day_of_week.toString().toUpper() + " " + now.day.format("%d"),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

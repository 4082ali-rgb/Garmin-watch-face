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

// "Outlaw HUD": western-game HUD watch face.
// Layout (top to bottom): time, date, logo slot, then a row of four round cores
//   HR (heart)  STEPS (bolt, of daily goal)  CAL (eye, of 2500 kcal)  BATT (battery)
// A wallpaper bitmap (full screen) and a logo bitmap are optional slots.
class WallpaperFaceView extends WatchUi.WatchFace {

    private const RING_ON = 0xF2F2F2;
    private const GOLD    = 0xEBD64B;
    private const ICON    = 0xF5E27A;
    private const DISC    = 0x0E0B08;
    private const TRACK   = 0x34302A;
    private const CAL_GOAL = 2500;

    private var _asleep as Boolean = false;
    private var _logo as BitmapResource? = null;
    private var _wallpaper as BitmapResource? = null;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
        _logo = WatchUi.loadResource(Rez.Drawables.Logo) as BitmapResource;
        _wallpaper = WatchUi.loadResource(Rez.Drawables.Wallpaper) as BitmapResource;
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

        if (_asleep) {
            // Low power: dim time only (limits AMOLED burn-in).
            drawTime(dc, cx, (h * 0.45).toNumber(), 0x8A8070);
            return;
        }

        // Wallpaper slot (resources/drawables/wallpaper.png).
        if (_wallpaper != null) {
            dc.drawBitmap((w - _wallpaper.getWidth()) / 2, (h - _wallpaper.getHeight()) / 2, _wallpaper);
        }

        drawTime(dc, cx, (h * 0.10).toNumber(), 0xF2F2F2);
        drawDate(dc, cx, (h * 0.20).toNumber());

        // Logo slot (resources/drawables/logo.png), centred under the date.
        if (_logo != null) {
            dc.drawBitmap(cx - _logo.getWidth() / 2, (h * 0.24).toNumber(), _logo);
        }

        // Data.
        var info = ActivityMonitor.getInfo();
        var steps = info.steps;
        var goal = info.stepGoal;
        var stepFrac = (steps != null && goal != null && goal > 0) ? steps.toFloat() / goal : 0.0;
        var cal = info.calories;
        var calFrac = (cal != null) ? cal.toFloat() / CAL_GOAL : 0.0;
        var hr = Activity.getActivityInfo().currentHeartRate;
        var hrFrac = (hr != null) ? hr.toFloat() / 190.0 : 0.0;
        var batt = System.getSystemStats().battery;

        // Row of four cores.
        var r = (w * 0.05).toNumber();
        var y = (h * 0.79).toNumber();
        var xs = [(w * 0.32).toNumber(), (w * 0.44).toNumber(), (w * 0.56).toNumber(), (w * 0.68).toNumber()];
        var names = ["HR", "STEPS", "CAL", "BATT"];
        var vals = [
            (hr != null) ? hr.format("%d") : "--",
            (steps != null) ? steps.format("%d") : "--",
            (cal != null) ? cal.format("%d") : "--",
            batt.toNumber().format("%d") + "%"
        ];
        var fracs = [hrFrac, stepFrac, calFrac, batt / 100.0];

        for (var i = 0; i < 4; i++) {
            drawCore(dc, xs[i], y, r, fracs[i]);
        }
        drawHeart(dc, xs[0], y, r);
        drawBolt(dc, xs[1], y, r);
        drawEye(dc, xs[2], y, r);
        drawBattery(dc, xs[3], y, r);

        for (var i = 0; i < 4; i++) {
            drawLabel(dc, xs[i], y + r + 12, names[i]);
            drawLabel(dc, xs[i], y + r + 28, vals[i]);
        }
    }

    // Core: dark disc, ring that fills clockwise from 12 o'clock (gold when full).
    private function drawCore(dc as Dc, x as Number, y as Number, r as Number, frac as Float) as Void {
        if (frac > 1.0) { frac = 1.0; }
        if (frac < 0.0) { frac = 0.0; }
        dc.setColor(DISC, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, r);
        dc.setPenWidth(4);
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

    private function drawHeart(dc as Dc, x as Number, y as Number, r as Number) as Void {
        var s = r * 0.42;
        dc.setColor(ICON, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x - s * 0.5, y - s * 0.3, s * 0.55);
        dc.fillCircle(x + s * 0.5, y - s * 0.3, s * 0.55);
        dc.fillPolygon([[x - s * 1.0, y - s * 0.1], [x + s * 1.0, y - s * 0.1], [x, y + s * 1.0]]);
    }

    private function drawBolt(dc as Dc, x as Number, y as Number, r as Number) as Void {
        var s = r * 0.5;
        dc.setColor(ICON, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [x + s * 0.25, y - s * 1.0], [x - s * 0.55, y + s * 0.1], [x - s * 0.05, y + s * 0.1],
            [x - s * 0.25, y + s * 1.0], [x + s * 0.55, y - s * 0.15], [x + s * 0.05, y - s * 0.15]
        ]);
    }

    private function drawEye(dc as Dc, x as Number, y as Number, r as Number) as Void {
        var s = r * 0.55;
        dc.setColor(ICON, Graphics.COLOR_TRANSPARENT);
        dc.fillEllipse(x, y, s, s * 0.55);
        dc.setColor(DISC, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, s * 0.38);
        dc.setColor(ICON, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, s * 0.2);
    }

    private function drawBattery(dc as Dc, x as Number, y as Number, r as Number) as Void {
        var s = r * 0.5;
        dc.setColor(ICON, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRectangle(x - s, y - s * 0.55, s * 2, s * 1.1);
        dc.setPenWidth(1);
        dc.fillRectangle(x + s, y - s * 0.25, s * 0.25, s * 0.5);
        var level = System.getSystemStats().battery / 100.0;
        dc.fillRectangle(x - s + 2, y - s * 0.55 + 2, (s * 2 - 4) * level, s * 1.1 - 4);
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

    private function drawDate(dc as Dc, cx as Number, y as Number) as Void {
        var now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        dc.setColor(0xF2F2F2, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_XTINY,
                    (now.day_of_week.toString() + ", " + now.month.toString() + " " + now.day.format("%d")).toUpper(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

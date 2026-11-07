# Outlaw HUD – RDR2-style Garmin watch face

A Connect IQ watch face with western-game HUD styling: three round "cores"
(icon + draining ring, gold when full) in an arc above a compass map, drawn in
code so it fits any round screen.

| Core | Icon | Shows |
|------|------|-------|
| Health | heart | steps toward your daily goal |
| Stamina | bolt | heart rate (fraction of 190 bpm) |
| Dead Eye | eye | watch battery (gold ring when full) |

![preview](preview.png)

> `preview.png` is a mock-up rendered with Python, not a screenshot from the
> Garmin simulator. Fonts on the real watch will look slightly different.

## Status
**Not yet compiled.** The Connect IQ SDK needs a Garmin login to fetch device
definitions, so this was written but not built or run on a simulator. Expect
to fix small compile errors on the first build.

## Build and install
1. Install the Connect IQ SDK via the [SDK Manager](https://developer.garmin.com/connect-iq/sdk/)
   and download the device for your watch.
2. Install VS Code + the **Monkey C** extension.
3. Run **Monkey C: Generate a Developer Key** once.
4. Open this folder. Run **Monkey C: Edit Products** and tick *only your watch*
   (the manifest lists many round devices; unused ones can be removed).
5. **Monkey C: Build for Device** → produces `bin/*.prg`.
6. Plug the watch in by USB and copy the `.prg` into `GARMIN/APPS/` on the watch.
7. On the watch: hold the face → pick **Outlaw HUD**.

## Customising
Everything is in `source/WallpaperFaceView.mc`: colour constants at the top,
`drawCore` for the ring, `drawHeart` / `drawBolt` / `drawEye` for the icons.
A wallpaper bitmap can be drawn at the marked spot in `onUpdate`.

## Adding a logo
`resources/drawables/logo.png` is a blank placeholder drawn under the time. To use your
own logo image: `python3 tools/prepare_logo.py your_logo.png` (see the script for an
optional crop box), then rebuild. If the result is taller than about 65 px, crop tighter.

## Adding a wallpaper
`resources/drawables/wallpaper.png` is a plain black placeholder drawn behind everything
(not drawn in low-power mode). Use your own image with
`python3 tools/prepare_wallpaper.py your_image.jpg [focus_x focus_y] [dim]`, then rebuild.
Keep your own artwork files out of the repo if you don't own the rights to share them.

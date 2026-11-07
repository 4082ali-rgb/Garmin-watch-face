# Outlaw HUD – RDR2-style Garmin watch face

A Connect IQ watch face inspired by Red Dead Redemption 2: sunset wallpaper,
an original cowboy silhouette (no Rockstar artwork) and the three "core" gauges
around the bezel, all drawn in code so it fits any round screen.

| Core | Colour | Shows |
|------|--------|-------|
| Health | red (left) | steps toward your daily goal |
| Stamina | green (right) | heart rate (fraction of 190 bpm) |
| Dead Eye | gold (top) | watch battery |

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
`drawScene` for the sunset/silhouette, `drawCore` for the gauges. To use your own
wallpaper image instead, add it under `resources/drawables` and draw it in `onUpdate`
before the cores.

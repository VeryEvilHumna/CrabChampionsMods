# My mods for Crab Champions the game

## HaloAim

Halo/Roboquest/Hunt:Showdown style lowered crosshair. The reticle sits `offset_y` px below center, and
shots land on it.

### Demo (720p)

https://github.com/user-attachments/assets/12fb0b69-cee4-410b-9a85-52ff0736bdf8



Demo (4k): [https://youtu.be/5eMQ3wGpy_M](https://youtu.be/5eMQ3wGpy_M)

The game fires along the camera direction (`ECrabShotDirType::CameraDir`), so
rotating the control rotation or the camera can't separate aim from view. This
mod leaves the camera alone and shifts the rendered image instead, using
`PlayerCameraManager.ViewTarget.POV.OffCenterProjectionOffset`. The camera's
aim point is then drawn `offset_y` px lower, right under the moved crosshair.

### Requirements

- Crab Champions
- **Re-UE4SS 2.5.2, xinput build** — <https://github.com/UE4SS-RE/RE-UE4SS/releases>.
  Re-UE4SS 3.0.1 is known to black-screen this game; 2.5.2 works.
- No pak editing and no asset replacement. Mod is one Lua file.

### Install

**1. Find the game's `Win64` folder**

Steam → right-click **Crab Champions** → **Manage** → **Browse local files**, then open:

```
CrabChampions/Binaries/Win64/
```

On Linux/Proton that is `steamapps/common/Crab Champions/CrabChampions/Binaries/Win64/`
(the mods still go next to the game, not inside the `compatdata` prefix).

**2. Install Re-UE4SS there**

Extract the xinput build of Re-UE4SS 2.5.2 into the folder from step 1, so it looks like:

```
Binaries/Win64/
├── CrabChampions-Win64-Shipping.exe
├── xinput1_3.dll          ← from the Re-UE4SS xinput build
├── Mods/
└── ue4ss/
    └── ...
```

On Linux, make sure Proton actually loads the DLL by setting the launch option:

```
WINEDLLOVERRIDES="xinput1_3=n,b" %command%
```

**3. Copy the mod**

Put the `HaloAim` folder next to the other mods:

```
Binaries/Win64/Mods/
└── HaloAim/
```

**4. Enable it**

`enabled.txt` is already inside the folder, so nothing else is required —
Re-UE4SS starts it in its second pass.

If you keep an explicit load order in `Mods/mods.txt`, you can list it instead.
Add the line in the first block, **above** the built-in keybinds:

```
HaloAim : 1

; Built-in keybinds, do not move up!
Keybinds : 0
```

`Keybinds : 0` refers to the sample mod of that name, not to the
`RegisterKeyBind` API function. Leave it last.

### Use

| key | action |
|---|---|
| <kbd>F7</kbd> / <kbd>F8</kbd> | offset -/+ 10 |
| <kbd>F9</kbd> | reset offset |
| <kbd>F10</kbd> | toggle image shift (A/B test) |
| <kbd>F6</kbd> | re-apply + status dump to `UE4SS.log` |

`offset_y` is in UMG units at 1080p and scales with resolution automatically,
so 90 is 90 px at 1080p, ~120 at 1440p

### Uninstall

Delete `Mods/HaloAim/`

## AI usage disclosure

All the code has been vibecoded with DeepSeek v4.1 Flash 1017 and Claude Opus 5.5

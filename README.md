# VOIDZ HUB — Cali Shootout

## Loadstring (always at top)

```lua
loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/fungamer1234/voidz-cali-shootout@main/VOIDZ_CALI.lua"))()
```

Build: `2026-08-23-1.5.0` · Key: `VOIDZHUB` (unlocks everything)

MacSploit: UI parents to **PlayerGui**. Do **not** pass `true` as a second argument to `HttpGet`.

**Xeno-compatible** (also Delta / MacSploit / Solara / Fluxus / UNC). Missing exploit APIs fall back safely.

1. Join **Cali Shootout** — main (`12077443856`) **or Voice Chat** (`16940099758`).
2. Execute the loadstring.
3. Key **`VOIDZHUB`**. RightShift show/hide.

The hub follows you onto the VC place (`queue_on_teleport`). TPs tab can hop main ↔ VC.

GitHub: https://github.com/fungamer1234/voidz-cali-shootout

## Combat God

Combat God keeps your **server position** in a green safe zone (spawn shield) while you still walk around on your screen. It does **not** hook `__namecall`. TPs tab has **Nearest Safe Zone**.

## Tabs

| Tab | What’s in it |
| --- | --- |
| Home | Quick Combat God, silent aim, ESP |
| Combat | Combat God, anti-KO, silent aim, aimbot, hitbox, kill aura, kill-all |
| Guns | No recoil / spread, inf ammo, never jam, rapid fire, one-shot |
| Farm | Instant prompts, box/trash/mop/car/grass autofarm, check printer TPs |
| Move | Speed, fly, noclip, inf jump, Ctrl+Click TP |
| Cars | Whole-chassis accel, max speed, hover fly, springs |
| Visuals | Name/HP/cash/distance ESP, fullbright |
| TPs | Gun shop, jobs, banks, ATMs, turfs, diamond heist (YNC + Teeksaw coords) |
| Players | Select, TP, spectate |
| Misc | Anti-AFK, rejoin, server hop, unload |

Merged from public Cali hubs (Express/_scripts autofarm list, Teeksaw TPs, YNC locations, MikeyHub/Airflow combat). The Luarmor copy of Express Hub is locked; this is a VOIDZ rebuild of those options so they actually run keyless.

## Recent (1.5.0) — MacSploit UI

ScreenGui goes to PlayerGui (MacSploit CoreGui/gethui often never draws). HttpGet is one-argument only.

## Recent (1.4.9) — boot print

Prints `[VOIDZ CALI] booting` as soon as the file runs. Use the multi-URL loadstring at the top if GitHub raw or jsDelivr is stale.

## Recent (1.4.8) — loadstring

GitHub `raw.githubusercontent.com/main` was serving a stale file. Use the jsDelivr loadstring at the top.

## Recent (1.4.7) — TCS off, Express ammo, parked-zone god

Car accel disables TCS (that dashboard light), uses Express velocity on W, and **A/D turns** (boost lets off while you steer). Infinite ammo sets **999/999** on mag + max + HUD like Express. Combat God parks your physics in a green zone every Stepped/Heartbeat so the server shield can actually apply.

## Recent (1.4.6) — cars, ammo, god, health ESP

Accel no longer welds you in a straight line (A/D steers again). Car fly stays upright. Infinite ammo fills the real mag size and **No Reload** blocks R. Combat God desyncs you into a safe zone on the server. Health Esp is on Home and Visuals.

## Recent (1.4.5) — gun mods actually shoot

Rapid fire no longer spams `Tool:Activate()` (that only ejected shells). It retriggers the real mouse-down gun script and the tool’s shoot remotes so bullets can damage.

## Recent (1.4.4) — car mods rebuilt

Acceleration pushes the **whole chassis** (wheels included), adds speed instead of multiplying it, and caps at Max Speed so it doesn’t explode. Car fly CFrame-locks the vehicle, hovers when you let go, and won’t yeet you out of the seat with Space.

## Recent (1.4.3) — safe-zone Combat God

Combat God uses the map’s green safe zones (the spawn-protection shield), not a fake ForceField. TPs → Nearest Safe Zone if you just want to stand in one.

## Recent (1.4.2) — anti-kick

Removed `__namecall` / `TakeDamage` hooks and ForceFields on your character (Cali 267: “namecall instance detector”). ESP now lives in a hidden GUI folder with `Adornee`, not parented to Head/HRP.

## Recent (1.4.1) — Health Esp

Visuals has Health Esp: `HP 87/100` plus a bar over their head that turns red as they drop. All Express ESP includes it.

## Recent (1.4.0) — god / guns / cars

Combat God no longer clones/destroys your Humanoid (that was killing you). It uses an invisible ForceField (blocks `TakeDamage`), health lock, and snap-back if you still drop. Gun mods scan tool stats **and** `getgc` config tables. Fly is CFrame-based. **Cars** tab: Express W-acceleration, max speed, car fly.

## Recent (1.3.2) — ghost gun Combat God

Combat God now hides the gun mesh (LocalTransparencyModifier) while keeping the Tool equipped so you still shoot — the “gun in your hands but the game doesn’t draw it” look.

## Recent (1.3.1) — Combat God actually FE

Cali ignores client `Humanoid.Health`. Combat God now clones the Humanoid (Infinite Yield style) so the server kills a dummy and you keep shooting.

## Recent (1.3.0) — Express ESP + gun mods

Visuals match Express Hub: Name Esp, Box Esp, Distance Esp, Chams Esp (with colors). Gun mods kill camera kick, refill ammo, and rapid-fire while you hold click.

## Recent (1.2.0) — farms actually hit Cali

Farms now use Express Hub’s real paths (`Job System.BoxPickingJob`, `GarbageJob`, `giveMop`, `Cleaning_System.Dirt_Spawn`, `CarRobberys`). Teleports, aimbot (hold RMB), triggerbot, hitbox, fly, and noclip match that working script.

## Recent (1.1.0) — VC + FTAP chrome

Works on the Voice Chat server (place `16940099758`, same universe). UI is the VOIDZ FTAP chrome: V mark, sidebar rails, glass cards, iOS pills, tip bar.

## Recent (1.0.0)

First Cali Shootout VOIDZ hub. Combat God + silent aim + farms + map TPs.

# VOIDZ HUB — Cali Shootout

## Loadstring (always at top)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/fungamer1234/voidz-cali-shootout/main/VOIDZ_CALI.lua", true))()
```

Build: `2026-08-23-1.4.0` · Key: `VOIDZHUB` (unlocks everything)

**Xeno-compatible** (also Delta / MacSploit / Solara / Fluxus / UNC). Missing exploit APIs fall back safely.

1. Join **Cali Shootout** — main (`12077443856`) **or Voice Chat** (`16940099758`).
2. Execute the loadstring.
3. Key **`VOIDZHUB`**. RightShift show/hide.

The hub follows you onto the VC place (`queue_on_teleport`). TPs tab can hop main ↔ VC.

GitHub: https://github.com/fungamer1234/voidz-cali-shootout

## Combat God

This is the “invincible but you can still shoot” option. It does **not** use a ForceField or PlatformStand (those cancel guns). It locks health, blocks Dead/Ragdoll/KO flags, and leaves your tools equipped.

## Tabs

| Tab | What’s in it |
| --- | --- |
| Home | Quick Combat God, silent aim, ESP |
| Combat | Combat God, anti-KO, silent aim, aimbot, hitbox, kill aura, kill-all |
| Guns | No recoil / spread, inf ammo, never jam, rapid fire, one-shot |
| Farm | Instant prompts, box/trash/mop/car/grass autofarm, check printer TPs |
| Move | Speed, fly, noclip, inf jump, Ctrl+Click TP |
| Visuals | Name/HP/cash/distance ESP, fullbright |
| TPs | Gun shop, jobs, banks, ATMs, turfs, diamond heist (YNC + Teeksaw coords) |
| Players | Select, TP, spectate |
| Misc | Anti-AFK, rejoin, server hop, unload |

Merged from public Cali hubs (Express/_scripts autofarm list, Teeksaw TPs, YNC locations, MikeyHub/Airflow combat). The Luarmor copy of Express Hub is locked; this is a VOIDZ rebuild of those options so they actually run keyless.

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

# Copilot Instructions — test-1 (Godot 4.6 Space Combat Prototype)

> Architecture overview: see [`code-map.md`](../../code-map.md) at repo root.
> Godot API questions: use the `godot-docs` skill (offline docs in `godot-docs-md/`). Never guess API signatures from memory.

## Project Overview

Single-player space combat prototype: modular player ship, AI state-machine enemies,
laser/missile weapons, HUD + buff system. Main scene: `scenes/game_scene.tscn`.

## Architecture Rules (follow these strictly)

### Global singletons (autoloads) — roles are fixed, do not mix them

| Autoload | Role |
|---|---|
| `SignalBus` | **Event bus. Signals only — zero logic, zero state.** All cross-module communication goes through it. |
| `GameManager` | Service locator. Holds references (`player_instance`, `hud_manager`, `input_manager`, ...). Register via `register_*()`, read via fields/`get_current_player()`. |
| `Scenes` (`my_scenes.gd`) | **Central PackedScene registry.** Any scene instantiated at runtime must be preloaded here — no scattered `preload()` in feature scripts. |
| `BuffManager` | Buff factory. Applies buffs by file-name convention. |
| `PlayerInfo` | Shared player constants (currently `dead_zone_px`). |

### Communication pattern

- Modules/components **never call each other directly**. Emit/consume `SignalBus` signals
  (`on_player_shoot`, `on_player_lock_target`, `on_player_boost`, ...).
- Signal naming: prefix `on_` (e.g. `on_player_registered`, `on_lockable_target_died`).
- When adding a feature that needs a new event: declare the signal in `SignalBus.gd` first,
  then emit/connect. **Every emitted signal must be declared** (known bug: `input_manager.gd`
  emits `on_player_switch_camera` which is not declared — do not replicate this).
- Lookup shared node references through `GameManager` / `ModulesManager` getters
  (`get_camera_module()`, `get_aim_module()`, ...), not `get_node("../../...")` paths.

### Module system (`scripts/modules/`)

- Ship features are `Module`/`Module3D` nodes installed into `ModulesManager`
  (`install_module()` / `install_module_3d()`), usually from `PlayerShip._ready`.
- Base classes cache `modules_manager` and `root` (the ship) in `_enter_tree` — do not
  re-resolve them in `_ready`.
- Missing dependency pattern: `Log.log_missing_component(self, "x")` then `queue_free()`.
  Never hard-crash on a missing sibling module.
- New module = script in `scripts/modules/` + scene in `scenes/modules/` + preload entry in `Scenes`.

### Components & combat

- `HealthComponent` (Area3D hurtbox) owns HP; ships expose `hit(damage)` / `get_team_id()` /
  `get_health_component()` as their public combat interface. Damage flows:
  `Bullet` → `HealthComponent.take_damage()` → `changed` signal → UI.
- Factions: `TeamID` enum (PLAYER/NEUTRAL/ENEMY) + physics layers 9/10/11 (hurtboxes).
  Projectiles compute `collision_mask` from `team_id` in `Bullet.setup()` — friendly fire
  rules live there, don't hardcode masks elsewhere.
- Projectiles extend `Bullet` (`scripts/bullet/base/bullet_base.gd`): use the chainable
  `setup(pos, dir, team, shooter).set_damage().set_speed()` API. Keep both hit channels
  (per-frame ray step + `area_entered`) and the lifetime `Timer` — they prevent tunneling
  and leaked bullets.
- Buffs: create `scripts/buff/buff_<id>.gd` extending `Buff`; icon goes to
  `textures/icon/icon_buff_<id>.png`. Apply via `BuffManager.apply_buff_by_name()`.

### AI (`scripts/ai/`)

- States are child nodes of a `StateMachine`; switch with `transition_to(index)`.
  State order in the scene tree IS the index — don't reorder children casually.
- New behaviors: extend `State`, implement `enter()`/`exit()`/`physics_update()`.
  Use `MoveSM` helpers (`rotate_towards`, `move_forward`, `set_target_speed`) for maneuvering.

### HUD

- Dynamic HUD groups: `GameManager.hud_manager.register_hud_group(control)` returns a
  `MyHUD` — chain effects: `.set_flow_effect(...).set_rotation_effect().set_boost_offset_effect()...`.
- Screen-projected ("far") HUD elements extend `HUDFarBase` and are registered via
  `register_hud_far(_node)`; they read `HUDFarManager.nose_pos_2d` / `mouse_pos`.

## Code Style

- GDScript, Godot 4.6 syntax. **Tabs** for indentation (Godot default); some legacy files use
  spaces — match the file you are editing.
- Naming: `class_name` PascalCase; files/functions/vars snake_case; private members prefixed
  `_` (`_locked_target`, `_is_destroyed`); signals `on_*`.
- Observable values that UI listens to use `BoolStat` / `IntStat` / `FloatStat` resources
  (signal on set) instead of polling.
- Setup methods that return `self` (chainable) are the preferred configuration style.
- Use `Log.log_error` / `Log.log_missing_component` / `Log.log_info` instead of raw `print`
  for diagnostics.
- Long-lived intent goes in `# TO DO :` / `# FIX ME :` comment blocks at the top of the file
  (existing convention, e.g. `character_body_3d.gd`).

## Godot Gotchas (project-verified)

- **Register into singletons in `_enter_tree`, not `_ready`** — child `_ready` may run before
  the parent's, so `_ready`-time registration can be too late (see `Main.gd`).
- **Never duplicate a `class_name`** in a scene's embedded script when an external script with
  the same name exists — causes "Class X hides a global script class". Reference the external
  script from the `.tscn` instead.
- Node cleanup: combine lifetime timeout with hit-triggered `queue_free()`; guard with
  `is_instance_valid()` before touching freed targets (missiles, locks, buffs all do this).
- Smooth camera/spring-arm motion: assign back to the node property (`spring_arm.position = arm_pos`),
  and cache the base offset for relative boosts — updating a local copy does nothing.

## Build / Run / Validate

- No build step and **no automated test suite**. Validate changes by running the main scene
  (`scenes/game_scene.tscn`) in the Godot 4.6 editor and exercising the feature.
- Debug keys: `O` = self-damage 10, `P` = apply healing buff, `1` = fire missile,
  RMB = lock on, LMB = shoot, Shift = boost, Q = toggle engine.
- Do not edit generated/ignored paths: `.godot/`, `godot-docs-md/` (offline docs corpus),
  `.dsh/`, `*.import` files.

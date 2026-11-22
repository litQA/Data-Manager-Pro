# Migration Report

## Scope

This report covers the first implementation of File Manager Pro for MCreator 2026.1. The plugin combines three areas that were previously provided by separate plugins or were not available for procedures:

- custom loot table conditions read from server data packs;
- file, text, JSON, ZIP and URL procedures with typed file and JSON sockets;
- list and map procedures derived from the Collection plugin design.

## Target Matrix

| Generator | Support |
| --- | --- |
| Forge 1.17.1 | yes |
| Forge 1.18.2 | yes |
| Forge 1.19.2 | yes |
| Forge 1.19.4 | yes |
| Forge 1.20.1 | yes |
| NeoForge 1.20.1 | yes |
| NeoForge 1.20.4 | yes |
| NeoForge 1.20.6 | yes |
| NeoForge 1.21.1 | yes |
| NeoForge 1.21.4 | yes |
| NeoForge 1.21.8 | yes |
| Fabric 1.21.8 | no |

## Design Notes

The plugin is a resource plugin. It contains procedure definitions, toolbox categories, variable definitions, mappings and FreeMarker templates for each supported generator. No MCreator core classes are replaced or patched.

Custom loot functions are generated as private static helpers through the procedure extra-template mechanism. The helpers are emitted once per generated procedure and remain local to that procedure class.

File and JSON procedures use the same typed-socket approach as the Collection plugin. `File`, `JsonObject`, `JsonArray`, `List` and `Map` are declared as plugin variable types, and each procedure input accepts the matching Blockly type.

Data-pack paths are normalized by the helper before lookup. Accepted forms are `data/<namespace>/<path>`, `<namespace>:<path>` and a bare path. A bare path uses the `minecraft` namespace. The `.json` suffix is optional.

The custom loot cache stores the most recently parsed file and the resource-manager instance that produced it. A new resource manager is created by a data-pack reload, so the next call re-reads the file.

Folder mode uses a separate `JsonLootCache` variable. The `Load Loot Folder Into Cache` procedure scans the direct `.json` children of one data-pack folder, reads each root, and stores roots in an `entries` object keyed by `type|target_block`. Paths are sorted before insertion, so when several files share a target the first path wins and later files are reported on standard error. The cache also records the folder and type that produced it.

The loader is explicit. It does nothing when the same folder and type are already loaded, warns and keeps the previous cache when the metadata differs, and rebuilds when `force` is true. A failed or empty scan leaves the previous cache untouched unless `force` is true. The cache is never expired automatically: after `/reload` the user either calls the loader again or keeps the old cache intentionally. One cache describes one folder; separate folders need separate cache variables.

ZIP operations are implemented with `java.util.zip`. Adding a file to an existing archive rewrites the archive through a temporary file so the central directory is not corrupted.

## Compatibility Notes

Minecraft 1.17.1 and 1.18.2 use `EnchantmentHelper.getItemEnchantmentLevel`; later Forge versions and NeoForge before 1.21.1 use `ItemStack.getEnchantmentLevel(Enchantment)`; NeoForge 1.21.1 and newer use enchantment holders. The generated helper is selected per generator, so these calls do not need to coexist in one source file.

Minecraft 1.20.6 and newer no longer expose item NBT as a direct `CompoundTag` field. The generated helper stores loot NBT in `CustomData`. Older generators use `ItemStack.setTag`.

The item registry and effect registry calls also change across the matrix and are selected by generator family.

## Known Limitations

- Custom loot `nbt` is interpreted as legacy JSON NBT. The recursive conversion produces string, number, boolean, list and compound tags. Typed data components, component patches and item-component-only data are not represented.
- The condition index in the custom loot item procedure is one-based. The requirement table uses human-readable sequence numbers while the algorithm states `index - 1`; this release follows the algorithm.
- A custom loot file is validated for `type`, `target_block` and a `conditions` array. Invalid predicates and drops fall back to an empty ItemStack or zero and emit a warning on standard error.
- Custom loot file reads and ZIP, URL, JSON and text operations are blocking. They should not be called every client tick.
- The `download url to file` procedure uses the platform URL connection defaults and does not expose connection or read timeouts.
- Data-pack lookup is server-side only. Integrated-server single-player satisfies the server requirement; a dedicated client without a server returns the fallback value.
- Data-pack cache invalidation follows the resource-manager instance. Reloads that reuse the same manager are not detected.
- The folder loot cache has no automatic expiry. A procedure must call `Load Loot Folder Into Cache` after `/reload`, or pass `force` true, to rebuild it. Leaving the loader out deliberately keeps the previous contents.
- The loader must run from the `Server Started (Integrated And Dedicated)` trigger, not the built-in `Server Load` trigger: the latter uses `FMLDedicatedServerSetupEvent` and never runs in singleplayer.
- One loot cache stores one folder and one procedure type. Use separate `JsonLootCache` variables for separate folders.
- The two condition-count procedures return the final drop count of the first condition whose predicate matches the entity. A matched condition with a zero-count drop does not fall through to later conditions, and the procedures return zero when no condition matches.
- The condition-ID item procedures are predicate-checked. When the requested condition exists but the entity does not satisfy its predicate, the procedures return air and do not scan later conditions.
- The first-match item procedures return air when no condition matches and stop at the first matching predicate even when its final drop count is zero.
- Folder scanning keeps direct `.json` children only; nested subfolders are ignored.
- Folder scanning on Forge 1.17.1 and 1.19.2 uses `ResourceManager.listResources`; 1.18.2 and 1.19.4+ use `PackResources` enumeration. The 1.17.1 and 1.19.2 paths use different return types and are kept as separate generated variants.
- Folder iteration is not recursive. It yields direct children only, matching the requirement.
- Nested loops of the same family share the fixed iterator names and shadow each other. Use nested loops of different families or restructure the procedure.
- The `JsonElement` variable type is an internal helper used by JSON array iteration and is also listed among the variable types.
- `mod folder file` resolves `mods` below the game directory. It does not inspect loader-specific mod directories.
- Custom loot procedures require a block state and an entity. They declare a `blockstate` dependency and therefore appear in block-related procedures; they do not support loot tables without these inputs.
- Fabric generators are not part of this release.
- MCreator 2026.3 and later use a different generator set and are not supported by this build.

## Verification

The resource tree is checked with a JSON validator and a FreeMarker render check. The build produces `file-manager-pro-2026.1.zip` from `src/main/resources`. Real-machine validation in MCreator 2026.1 is required before release use.

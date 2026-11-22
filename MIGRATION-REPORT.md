# Migration Report

## Scope

This report covers the MCreator 2026.3 EAP port of File Manager Pro. The plugin keeps the 2026.1 feature set:

- custom loot table conditions read from server data packs;
- file, text, JSON, ZIP and URL procedures with typed file and JSON sockets;
- list and map procedures derived from the Collection plugin design.

The 2026.1 generator set is replaced by the 2026.3 generator set. The resource-only plugin design is unchanged.

## Target Matrix

| Generator | Support |
| --- | --- |
| Forge 1.20.1 | yes |
| Forge 1.20.4 | yes |
| Forge 1.21.1 | yes |
| Forge 26.3 | yes |
| NeoForge 1.21.1 | yes |
| NeoForge 1.21.4 | yes |
| NeoForge 1.21.8 | yes |
| NeoForge 26.1.2 | yes |
| NeoForge 26.2 | yes |
| NeoForge 26.3 | yes |
| Fabric 1.20.1 | yes |
| Fabric 1.21.1 | yes |
| Fabric 1.21.8 | yes |
| Fabric 1.21.11 | yes |
| Fabric 26.1.2 | yes |
| Fabric 26.2 | yes |
| Fabric 26.3 | yes |

## Design Notes

The plugin is a resource plugin. It contains procedure definitions, toolbox categories, variable definitions, mappings and FreeMarker templates for each supported generator. No MCreator core classes are replaced or patched.

Each generator directory has 86 procedure templates, 6 shared utility templates, 7 variable definitions, 3 mapping files and the plugin's server-start trigger. The procedure definitions and toolbox categories are shared through the resource root.

The 2026.3 port uses one directory per generator. Forge and NeoForge directories share the same procedure bodies and differ in their server trigger and version-specific helper calls. Fabric directories add a generated server holder, a generator overlay and a procedure-init override because Fabric has no global current-server API.

Custom loot functions are generated as private static helpers through the procedure extra-template mechanism. The helpers are emitted once per generated procedure and remain local to that procedure class.

File and JSON procedures use the same typed-socket approach as the Collection plugin. `File`, `JsonObject`, `JsonArray`, `List` and `Map` are declared as plugin variable types, and each procedure input accepts the matching Blockly type.

Data-pack paths are normalized by the helper before lookup. Accepted forms are `data/<namespace>/<path>`, `<namespace>:<path>` and a bare path. A bare path uses the `minecraft` namespace. The `.json` suffix is optional.

The custom loot cache stores the most recently parsed file and the resource-manager instance that produced it. A new resource manager is created by a data-pack reload, so the next call re-reads the file.

Folder mode uses a separate `JsonLootCache` variable. The `Load Loot Folder Into Cache` procedure scans the direct `.json` children of one data-pack folder, reads each root, and stores roots in an `entries` object keyed by `type|target_block`. Paths are sorted before insertion, so when several files share a target the first path wins and later files are reported on standard error. The cache also records the folder and type that produced it.

The loader is explicit. It does nothing when the same folder and type are already loaded, warns and keeps the previous cache when the metadata differs, and rebuilds when `force` is true. A failed or empty scan leaves the previous cache untouched unless `force` is true. The cache is never expired automatically: after `/reload` the user either calls the loader again or keeps the old cache intentionally. One cache describes one folder; separate folders need separate cache variables.

ZIP operations are implemented with `java.util.zip`. Adding a file to an existing archive rewrites the archive through a temporary file so the central directory is not corrupted.

## Compatibility Notes

Forge 1.20.1 and 1.20.4 use their Forge registry and resource APIs. Forge 1.21.1 and Forge 26.3 use the modern registry and component APIs. NeoForge 1.21.1, 1.21.4 and 1.21.8 use the NeoForge server lifecycle API. NeoForge 26.1.2, 26.2 and 26.3 use the same modern registry API with the 26.x resource identifiers.

Minecraft 1.21.11 and the 26.x generators use `Identifier` instead of `ResourceLocation`. The generated templates for those families rewrite both the fully qualified type and the constructor call.

Minecraft 1.21.11 and newer no longer expose `Entity.getServer()`. The affected template families use `entity.level().getServer()`.

Fabric does not expose a global current server. Each Fabric generator adds `FmproServerHolder`, registers `ServerLifecycleEvents.SERVER_STARTED` and `SERVER_STOPPED`, and initializes the holder from the generated procedure loader. The helper and loot templates read the captured server from that holder.

The Fabric helper fully qualifies `PackResources.ResourceOutput`, `IoSupplier` and `PackType`; an aggregate Fabric API jar does not expose those nested types to `javac` reliably when the generated source is compiled outside Loom.

Minecraft 1.20.6 and newer no longer expose item NBT as a direct `CompoundTag` field. The generated helper stores loot NBT in `CustomData`. Older generators use `ItemStack.setTag`.

The item registry, effect registry and enchantment APIs change across the matrix and are selected by generator family. Fabric 1.20.1 uses `EnchantmentHelper.getItemEnchantmentLevel`; Fabric 1.21.1 and newer use the enchantment-component map; the 26.x families obtain enchantment holders from the server registry.

The custom server trigger uses `ServerStartedEvent` on Forge and NeoForge. Fabric registers `ServerLifecycleEvents.SERVER_STARTED` from the trigger constructor.

## Known Limitations

- Custom loot `nbt` is interpreted as legacy JSON NBT. The recursive conversion produces string, number, boolean, list and compound tags. Typed data components, component patches and item-component-only data are not represented.
- The condition index in the custom loot item procedure is one-based. The requirement table uses human-readable sequence numbers while the algorithm states `index - 1`; this release follows the algorithm.
- A custom loot file is validated for `type`, `target_block` and a `conditions` array. Invalid predicates and drops fall back to an empty ItemStack or zero and emit a warning on standard error.
- Custom loot file reads and ZIP, URL, JSON and text operations are blocking. They should not be called every client tick.
- The `download url to file` procedure uses the platform URL connection defaults and does not expose connection or read timeouts.
- Data-pack lookup is server-side only. Integrated-server single-player satisfies the server requirement; a dedicated client without a server returns the fallback value.
- Data-pack cache invalidation follows the resource-manager instance. Reloads that reuse the same manager are not detected.
- The folder loot cache has no automatic expiry. A procedure must call `Load Loot Folder Into Cache` after `/reload`, or pass `force` true, to rebuild it. Leaving the loader out deliberately keeps the previous contents.
- The loader must run from the `Server Started (Integrated And Dedicated)` trigger, not the built-in `Server Load` trigger: the latter is dedicated-server-only.
- One loot cache stores one folder and one procedure type. Use separate `JsonLootCache` variables for separate folders.
- The two condition-count procedures return the final drop count of the first condition whose predicate matches the entity. A matched condition with a zero-count drop does not fall through to later conditions, and the procedures return zero when no condition matches.
- The condition-ID item procedures are predicate-checked. When the requested condition exists but the entity does not satisfy its predicate, the procedures return air and do not scan later conditions.
- The first-match item procedures return air when no condition matches and stop at the first matching predicate even when its final drop count is zero.
- Folder scanning keeps direct `.json` children only; nested subfolders are ignored.
- Folder iteration is not recursive. It yields direct children only, matching the requirement.
- Nested loops of the same family share the fixed iterator names and shadow each other. Use nested loops of different families or restructure the procedure.
- The `JsonElement` variable type is an internal helper used by JSON array iteration and is also listed among the variable types.
- `mod folder file` resolves `mods` below the game directory. It does not inspect loader-specific mod directories.
- Custom loot procedures require a block state and an entity. They declare a `blockstate` dependency and therefore appear in block-related procedures; they do not support loot tables without these inputs.
- Fabric server-dependent data-pack and loot procedures require the generated procedure loader to run. A mod with no external-trigger procedure does not initialize the holder, so those procedures return their fallback values.
- No Minecraft 26.3 merged jar was available for bytecode validation. The 26.3 templates were checked against the 26.3 generator sources and compiled against the 26.2 API jar as the nearest available API surface.

## Verification

The resource tree is checked with `caches/validate_2026.3.py`: 93 procedure JSON files, 17 generator directories, 7 variables, 3 mappings and one trigger per generator.

All 1,564 procedure and utility templates render with FreeMarker 2.3.35.

Fabric helper/loot stubs compile for 1.20.1, 1.21.1, 1.21.8, 1.21.11, 26.1.2, 26.2 and 26.3. The 26.3 pass uses the 26.2 merged API jar and the 26.3 generator templates.

`gradlew.bat pluginZip` produces `build/distributions/file-manager-pro-2026.3.zip`. Real-machine validation in MCreator 2026.3 EAP is required before release use.

# Changelog

## 1.1.0.14-beta

### Fixes
- Loot item expressions now carry the `/*@ItemStack*/` type hint used by MCreator's `MCItem` conversion macros. Assigning a loot result to an `MCItem` variable no longer emits `new ItemStack(ItemStack)` and compiles on NeoForge 1.21.8.

## 1.1.0.13-beta

### Fixes
- Loot item procedures now expose the standard `MCItem` Blockly output type, so their sockets connect to item slots and other item-stack inputs instead of only accepting other loot sockets.

## 1.1.0.12-beta

### Fixes
- Looting modifiers now roll a random bonus from zero through the enchantment level instead of adding the full level. With base count 1 and Looting III, the result is 1-4, matching the vanilla distribution.

## 1.1.0.11-beta

### New Content
- `Server Started (Integrated And Dedicated)` global trigger for running server-side setup on both singleplayer and dedicated servers.

### Changes
- The cache-loading workflow documentation now uses the new trigger instead of the dedicated-server-only `Server Load` trigger.

### Fixes
- Loot folder caches are populated in singleplayer because cache loading no longer depends on `FMLDedicatedServerSetupEvent`.

## 1.1.0.10-beta

### Fixes
- Datapack JSON reads on generators that return a resource handle now catch the checked stream-open failure, removing the `unreported exception IOException` compile error in generated procedures.

## 1.1.0.9-beta

### Changes
- The NeoForge 1.21.4 and 1.21.8 branches resolve potion effects through `Registry#get(ResourceLocation)`. The NeoForge 1.21.1 branch keeps `Registry#getHolder(ResourceKey)`.

### Fixes
- NeoForge 1.21.4 and 1.21.8 no longer emit `getHolder(ResourceKey)` for potion effects, removing the `cannot find symbol` compile error in generated procedures.

## 1.1.0.8-beta

### New Content
- `Custom Loot Item (First Match)` and `Cached Loot Item (First Match)` procedures that take an entity and a block but no condition ID, return the drop of the first condition whose predicate matches, and return air when nothing matches.

### Changes
- `Custom Loot Drop Count` and `Cached Loot Drop Count` use the blue number-block colour.

### Known Limitations
- Condition-ID procedures do not fall through to another condition when the selected condition exists but its predicate does not match the entity; they return air.
- First-match procedures stop at the first matching predicate even when its final drop count is zero.

## 1.1.0.7-beta

### Changes
- `Custom Loot Drop Count` and `Cached Loot Drop Count` now take an entity, evaluate condition predicates in file order, and return the final drop count of the first matching condition.

### Fixes
- Loader and cached loot procedures include the shared helper template, so generated code can resolve `fmproReadDatapackJson` and `fmproRl`.

### Known Limitations
- The count procedures return `0` when no condition matches the entity; they do not fall through to later conditions after a predicate match with a zero-count drop.

## 1.1.0.6-beta

### New Content
- `JsonLootCache` variable type for one loaded loot folder, available in local and global session scopes.
- `Load Loot Folder Into Cache` procedure that scans direct `.json` children of a data-pack folder, indexes roots by `type` and `target_block`, and keeps the first path when several files share a target.
- `Cached Loot Item`, `Cached Loot Condition Count` and `Cached Loot Item By ID` procedures that read the loaded cache instead of a file path.

### Changes
- Custom loot block inputs use the `MCItemBlock` type, so provided block states and block selectors connect directly.
- Custom loot procedures declare a `blockstate` dependency and are offered in block-related procedures, matching the provided-block-state default.
- Exact-file loot procedures pass their block input through the standard block-state conversion.

### Fixes
- Loot block inputs no longer request a `BlockState` socket that no built-in provider offers.

### Known Limitations
- The loot cache does not expire automatically. Call the loader again after `/reload`, or set `force` to true, to rebuild it.
- A cache describes one loot folder. Use separate cache variables for separate folders.
- A failed or empty folder scan keeps the previous cache contents unless `force` is true.
- The 1.17.1 folder scan uses `ResourceManager.listResources`; later generators enumerate data-pack resources through `PackResources`.

## 1.0.0.4-beta

### Fixes
- ZIP insertion derives its temporary file name from a fixed prefix, so archives with very short names are handled.

### Known Limitations
- Custom loot NBT is interpreted as legacy JSON NBT. Minecraft 1.20.6 and newer convert the values into the `CustomData` component; typed data components and component patches are not represented.
- The custom loot condition count and item procedures require a running server. Integrated-server single-player worlds satisfy this requirement.
- Data-pack reads use the current server resource manager. Cache entries are cleared when `/reload` replaces that manager.
- Nested loops of the same family share fixed iterator names and shadow each other.
- Custom loop iterators are visible blocks in the File and JSON categories; they are intended for use inside their matching loop.
- The `JsonElement` variable type is an internal helper exposed by the JSON iteration procedures.
- Fabric generators are not supported by this release.
- MCreator 2026.3 is outside the support matrix of this release.

## 1.0.0.3-beta

### New Content
- Custom loot procedures `Custom Loot Item`, `Custom Loot Condition Count`, and `Custom Loot Item By ID` that read JSON conditions from the server data pack, validate `type` and `target_block`, evaluate enchantment, potion and held-item predicates, and build the resulting ItemStack with count modifiers and NBT data.
- File, JSON object, JSON array, list and map variable types for local, global and session scopes.
- File and folder procedures for the game root, config folder, mods folder, arbitrary paths, names, parent paths, existence checks, folder creation, deletion, renaming, folder iteration and the current folder-loop file.
- UTF-8 text procedures for reading, line reading, streaming line iteration, overwriting, appending and writing lists of lines.
- JSON procedures for reading and writing objects and arrays, data-pack object reads, typed object and array getters, object and array mutation, deep array copy, array iteration, emptiness and value-type predicates.
- ZIP procedures for extracting archives and adding files to an existing or new archive.
- URL download procedure with a blocking download to a target file.
- Collection procedures for lists and maps, including typed getters, iteration, index lookup, mutation, sorting helpers and map key iteration.

### Changes
- The custom loot condition index is one-based, matching the documented `index - 1` lookup algorithm.
- The custom loot reader caches parsed files until the server resource manager is replaced by a data-pack reload.
- Collection block identifiers, variable types and toolbox categories use the `fmpro_` prefix to avoid collisions with the official File Manager and Collection plugins.

### Fixes
- Map insertion inspects the value input it actually uses, so MCItem values are converted correctly.
- Folder iteration exposes a visible current-file block instead of a hidden helper.
- ZIP append rewrites the archive through a temporary file so the central directory remains valid.
- Data-pack paths accept `data/<namespace>/<path>`, `namespace:path` and bare paths, with `minecraft` as the default namespace.
- Client-side custom loot calls return an empty ItemStack or zero without parsing files.
- JSON array and object clear operations remove entries without relying on map-view mutability.

### Known Limitations
- Custom loot NBT is interpreted as legacy JSON NBT. Minecraft 1.20.6 and newer convert the values into the `CustomData` component; typed data components and component patches are not represented.
- The custom loot condition count and item procedures require a running server. Integrated-server single-player worlds satisfy this requirement.
- Data-pack reads use the current server resource manager. Cache entries are cleared when `/reload` replaces that manager.
- Nested loops of the same family share fixed iterator names and shadow each other.
- Custom loop iterators are visible blocks in the File and JSON categories; they are intended for use inside their matching loop.
- The `JsonElement` variable type is an internal helper exposed by the JSON iteration procedures.
- Fabric generators are not supported by this release.
- MCreator 2026.3 is outside the support matrix of this release.

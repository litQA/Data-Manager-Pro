# Changelog

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

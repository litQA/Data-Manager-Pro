# File Manager Pro

File Manager Pro adds file, JSON, ZIP, URL, collection and custom-loot procedures to MCreator 2026.1.

## Requirements

- MCreator 2026.1 with Java plugins support
- Java 21
- Gradle 9.9.1 when building the plugin from source

Supported generators: Forge 1.17.1, 1.18.2, 1.19.2, 1.19.4 and 1.20.1; NeoForge 1.20.1, 1.20.4, 1.20.6, 1.21.1, 1.21.4 and 1.21.8. Fabric is not supported.

## Installation

Build the plugin archive:

```
gradlew.bat pluginZip
```

The archive is written to `build/distributions/file-manager-pro-2026.1.zip`. Place the archive in the MCreator plugins directory and restart MCreator with Java plugins enabled.

The wrapper uses the public Gradle distribution URL by default. If that download fails, run `scripts/use-local-gradle.ps1` once; it resolves the workspace root from its own location, verifies `reference_resources/gradle-9.9.1-bin.zip`, and switches the wrapper to that local archive. Restore the public URL afterwards with `git checkout -- gradle/wrapper/gradle-wrapper.properties`.

## Variable Types

The plugin registers `File`, `JsonObject`, `JsonArray`, `List`, `Map`, `JsonLootCache` and the internal `JsonElement` helper type. All types are available in local and global session variable scopes.

## Procedure Categories

### Files

Game root, config folder and mods folder files; file creation from a path; name, parent and absolute path getters; folder creation, deletion and renaming; existence and folder checks; direct-child folder iteration.

### Text

Read a whole file, read a zero-based line, stream lines in a loop, overwrite, append and write a list of lines. All text is UTF-8.

### JSON

Read and write JSON objects and arrays from files, read an object from a data pack, typed object and array getters, object and array mutation, deep array copy, array iteration, emptiness checks and five value-type predicates.

### ZIP and Network

Extract a ZIP archive with path-traversal protection, add a file to a new or existing archive, and download a URL to a file.

### Lists and Maps

Typed list and map getters, iteration, index lookup, insertion, removal, reversal, merging, splitting and map key iteration.

### Custom Loot

Exact-file procedures read one data-pack JSON file:

- `Custom Loot Item`: block, entity, type, path and one-based condition index.
- `Custom Loot Condition Count`: block, type and path.
- `Custom Loot Item By ID`: block, entity, type, path and condition ID.

Folder-cache procedures avoid repeated data-pack scans:

- `Load Loot Folder Into Cache` scans the direct `.json` children of a folder such as `mymod:loot/crop`, indexes each root by `type` and `target_block`, and stores the result in a `JsonLootCache`.
- `Cached Loot Item`, `Cached Loot Condition Count` and `Cached Loot Item By ID` read that cache with the same condition semantics as the exact-file procedures.

Create one global session `JsonLootCache` variable per folder, for example `jsonLootCache`, and pass it to the loader and the cached procedures. Call the loader once when the server or world loads and again after `/reload`. The cache is not cleared automatically: leave the loader call out to keep the previous contents, or set its `force` input to true to rebuild.

All loot procedures take a block input of MCreator's `MCItemBlock` type. A provided block state from a block-related procedure connects directly; a block selector can be used in other procedures.

Example data-pack file:

```json
{
  "type": "block_break",
  "target_block": "minecraft:stone",
  "conditions": [
    {
      "condition_id": "fortune_bonus",
      "predicate": {
        "logic": "AND",
        "mainhand_item": { "op": "==", "value": "minecraft:diamond_pickaxe" },
        "enchantment_level": { "op": ">=", "enchant": "minecraft:fortune", "value": 1 }
      },
      "drop": {
        "id": "minecraft:diamond",
        "count": 1,
        "modifiers": [
          {
            "mode": "add",
            "function": "looting",
            "enchant": "minecraft:fortune",
            "include_offhand": false
          }
        ]
      }
    }
  ]
}
```

Accepted path forms are `data/<namespace>/<path>.json`, `<namespace>:<path>.json` and a bare path that uses the `minecraft` namespace. The `.json` suffix is optional.

## Behaviour Notes

- File and URL operations are blocking and run on the calling thread.
- Invalid files, missing permissions and JSON errors propagate as Java exceptions.
- Custom loot falls back to an empty ItemStack or zero with a warning on standard error.
- The loot cache keeps its contents when a scan is skipped, fails or finds no matching files. Set the loader's `force` input to true to replace it, including with an empty result.
- Client-side custom loot calls return immediately without reading the data pack or the cache.
- Loot NBT is converted from JSON into legacy tag types. On 1.20.6 and newer the values are stored in the `CustomData` component.

See `MIGRATION-REPORT.md` for known limitations and `CHANGELOG.md` for the change list.

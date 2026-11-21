private static Object fmproLootCacheManager;
private static String fmproLootCachePath;
private static com.google.gson.JsonObject fmproLootCacheJson;

private static void fmproLootWarn(String message) {
	System.err.println("[File Manager Pro] " + message);
}

private static com.google.gson.JsonObject fmproLootLoad(String path) {
	net.minecraft.server.MinecraftServer server = ServerLifecycleHooks.getCurrentServer();
	if (server == null) throw new IllegalStateException("No server available for custom loot read: " + path);
	Object manager = server.getResourceManager();
	if (manager != fmproLootCacheManager || !java.util.Objects.equals(path, fmproLootCachePath)) {
		fmproLootCacheJson = fmproReadDatapackJson(path);
		fmproLootCacheManager = manager;
		fmproLootCachePath = path;
	}
	return fmproLootCacheJson;
}

private static java.util.Map<net.minecraft.resources.ResourceLocation, net.minecraft.server.packs.resources.Resource>
		fmproLootCacheScan(net.minecraft.server.packs.resources.ResourceManager manager, String namespace, String folderPath) {
	java.util.Set<net.minecraft.resources.ResourceLocation> locations = new java.util.HashSet<>();
	class Output implements PackResources.ResourceOutput {
		public void accept(net.minecraft.resources.ResourceLocation location, IoSupplier<java.io.InputStream> supplier) {
			if (!location.getNamespace().equals(namespace)) return;
			String prefix = folderPath + "/";
			if (!location.getPath().startsWith(prefix)) return;
			String rest = location.getPath().substring(prefix.length());
			if (rest.endsWith(".json") && rest.indexOf('/') < 0) locations.add(location);
		}
	}
	manager.listPacks().forEach(pack -> {
		for (String ns : pack.getNamespaces(PackType.SERVER_DATA)) {
			pack.listResources(PackType.SERVER_DATA, ns, folderPath, new Output());
		}
	});
	java.util.Map<net.minecraft.resources.ResourceLocation, net.minecraft.server.packs.resources.Resource> found =
			new java.util.TreeMap<>(java.util.Comparator.comparing(net.minecraft.resources.ResourceLocation::toString));
	for (net.minecraft.resources.ResourceLocation location : locations) {
		manager.getResource(location).ifPresent(resource -> found.put(location, resource));
	}
	return found;
}

private static com.google.gson.JsonObject fmproLootCacheRoot(com.google.gson.JsonObject cache,
		net.minecraft.world.level.block.state.BlockState block, String expectedType) {
	if (cache == null) {
		fmproLootWarn("Loot cache is null");
		return null;
	}
	if (!cache.has("__fmpro_type") || !cache.get("__fmpro_type").isJsonPrimitive()
			|| !cache.get("__fmpro_type").getAsString().equals(expectedType)) {
		fmproLootWarn("Loot cache was not loaded for type: " + expectedType);
		return null;
	}
	if (!cache.has("entries") || !cache.get("entries").isJsonObject()) {
		fmproLootWarn("Loot cache has no entries; run the loader block first");
		return null;
	}
	if (block == null) {
		fmproLootWarn("Loot cache block is null");
		return null;
	}
	String actualBlock = String.valueOf(net.minecraft.core.registries.BuiltInRegistries.BLOCK.getKey(block.getBlock()));
	com.google.gson.JsonObject root = cache.getAsJsonObject("entries").getAsJsonObject(expectedType + "|" + actualBlock);
	if (root == null) {
		fmproLootWarn("No cached loot for block " + actualBlock + " and type " + expectedType);
		return null;
	}
	if (!root.has("target_block") || !root.get("target_block").isJsonPrimitive()
			|| !root.get("target_block").getAsString().equals(actualBlock)) {
		fmproLootWarn("Cached loot target_block does not match: " + actualBlock);
		return null;
	}
	if (!root.has("conditions") || !root.get("conditions").isJsonArray()) {
		fmproLootWarn("Cached loot has no conditions array: " + actualBlock);
		return null;
	}
	return root;
}

private static void fmproLootCacheLoad(com.google.gson.JsonObject cache, String folder, String type, boolean force) {
	if (cache == null) {
		fmproLootWarn("Loot cache is null");
		return;
	}
	String clean = folder == null ? "" : folder.replace('\\', '/').trim();
	while (clean.startsWith("/")) clean = clean.substring(1);
	while (clean.endsWith("/")) clean = clean.substring(0, clean.length() - 1);
	if (clean.isEmpty() || type == null || type.trim().isEmpty()) {
		fmproLootWarn("Loot cache folder and type are required");
		return;
	}
	type = type.trim();
	String namespace = "minecraft";
	String path = clean;
	boolean fromData = clean.startsWith("data/");
	if (fromData) clean = clean.substring(5);
	path = clean;
	int colon = clean.indexOf(':');
	if (colon >= 0) {
		namespace = clean.substring(0, colon);
		path = clean.substring(colon + 1);
	} else if (fromData) {
		int slash = clean.indexOf('/');
		if (slash > 0) {
			namespace = clean.substring(0, slash);
			path = clean.substring(slash + 1);
		}
	}
	while (path.startsWith("/")) path = path.substring(1);
	while (path.endsWith("/")) path = path.substring(0, path.length() - 1);
	if (namespace.isEmpty() || path.isEmpty()) {
		fmproLootWarn("Loot cache folder path is invalid: " + folder);
		return;
	}
	String folderKey = namespace + ":" + path;
	String loadedType = cache.has("__fmpro_type") && cache.get("__fmpro_type").isJsonPrimitive()
			? cache.get("__fmpro_type").getAsString() : null;
	String loadedFolder = cache.has("__fmpro_folder") && cache.get("__fmpro_folder").isJsonPrimitive()
			? cache.get("__fmpro_folder").getAsString() : null;
	if (!force && cache.has("entries") && loadedType != null && loadedFolder != null) {
		if (loadedType.equals(type) && loadedFolder.equals(folderKey)) return;
		fmproLootWarn("Loot cache already contains " + loadedFolder + " (" + loadedType
				+ "); call the loader with force=true to replace it");
		return;
	}
	net.minecraft.server.MinecraftServer server = ServerLifecycleHooks.getCurrentServer();
	if (server == null) {
		fmproLootWarn("No server available for loot cache load: " + folderKey);
		return;
	}
	try {
		java.util.Map<net.minecraft.resources.ResourceLocation, net.minecraft.server.packs.resources.Resource> found =
				fmproLootCacheScan(server.getResourceManager(), namespace, path);
		java.util.List<net.minecraft.resources.ResourceLocation> keys = new java.util.ArrayList<>(found.keySet());
		keys.sort(java.util.Comparator.comparing(net.minecraft.resources.ResourceLocation::toString));
		com.google.gson.JsonObject entries = new com.google.gson.JsonObject();
		for (net.minecraft.resources.ResourceLocation location : keys) {
			try (java.io.InputStream stream = found.get(location).open()) {
				com.google.gson.JsonElement parsed = com.google.gson.JsonParser.parseReader(
						new java.io.InputStreamReader(stream, java.nio.charset.StandardCharsets.UTF_8));
				if (parsed == null || !parsed.isJsonObject()) {
					fmproLootWarn("Skipping malformed loot file: " + location);
					continue;
				}
				com.google.gson.JsonObject root = parsed.getAsJsonObject();
				if (!root.has("type") || !root.get("type").isJsonPrimitive()
						|| !root.get("type").getAsString().equals(type)) continue;
				if (!root.has("target_block") || !root.get("target_block").isJsonPrimitive()) {
					fmproLootWarn("Skipping loot file without target_block: " + location);
					continue;
				}
				String entryKey = type + "|" + root.get("target_block").getAsString();
				if (entries.has(entryKey)) {
					fmproLootWarn("Duplicate cached loot target_block " + root.get("target_block").getAsString()
							+ " in " + location);
					continue;
				}
				entries.add(entryKey, root);
			} catch (Exception e) {
				fmproLootWarn("Failed to read cached loot file " + location + ": " + e.getMessage());
			}
		}
		if (entries.size() == 0) {
			fmproLootWarn("No loot files found in " + folderKey + " for type " + type);
			if (!force) return;
		}
		cache.addProperty("__fmpro_version", 1);
		cache.addProperty("__fmpro_folder", folderKey);
		cache.addProperty("__fmpro_type", type);
		cache.add("entries", entries);
	} catch (Exception e) {
		fmproLootWarn("Failed to load loot cache from " + folderKey + ": " + e.getMessage());
	}
}

private static com.google.gson.JsonObject fmproLootRoot(net.minecraft.world.level.block.state.BlockState block,
		String expectedType, String path) {
	if (block == null) {
		fmproLootWarn("Loot block is null: " + path);
		return null;
	}
	com.google.gson.JsonObject root = fmproLootLoad(path);
	if (root == null || !root.has("type") || !root.get("type").isJsonPrimitive()
			|| !root.get("type").getAsString().equals(expectedType)) {
		fmproLootWarn("Loot file type does not match: " + path);
		return null;
	}
	if (!root.has("target_block") || !root.get("target_block").isJsonPrimitive()) {
		fmproLootWarn("Loot file has no target_block: " + path);
		return null;
	}
	String actualBlock = String.valueOf(net.minecraft.core.registries.BuiltInRegistries.BLOCK.getKey(block.getBlock()));
	if (!root.get("target_block").getAsString().equals(actualBlock)) {
		fmproLootWarn("Loot file target_block does not match: " + path + " (" + actualBlock + ")");
		return null;
	}
	if (!root.has("conditions") || !root.get("conditions").isJsonArray()) {
		fmproLootWarn("Loot file has no conditions array: " + path);
		return null;
	}
	return root;
}

private static boolean fmproLootCompare(double actual, String op, double expected) {
	if (op == null) return false;
	switch (op) {
		case "==" : return actual == expected;
		case "!=" : return actual != expected;
		case ">" : return actual > expected;
		case "<" : return actual < expected;
		case ">=" : return actual >= expected;
		case "<=" : return actual <= expected;
		default : return false;
	}
}

private static boolean fmproLootCompareText(String actual, String op, String expected) {
	if (op == null) return false;
	switch (op) {
		case "==" : return actual.equals(expected);
		case "!=" : return !actual.equals(expected);
		default : return false;
	}
}

private static int fmproLootEnchant(net.minecraft.world.item.ItemStack stack, String id) {
	if (stack == null || stack.isEmpty() || id == null) return 0;
	net.minecraft.server.MinecraftServer server = ServerLifecycleHooks.getCurrentServer();
	if (server == null) return 0;
	net.minecraft.world.item.enchantment.Enchantment enchantment = server.registryAccess().registryOrThrow(net.minecraft.core.registries.Registries.ENCHANTMENT).get(fmproRl(id));
	return enchantment == null ? 0 : stack.getEnchantmentLevel(enchantment);
}

private static String fmproLootHandId(net.minecraft.world.entity.Entity entity, boolean mainHand) {
	if (!(entity instanceof net.minecraft.world.entity.LivingEntity)) return "minecraft:air";
	net.minecraft.world.entity.LivingEntity living = (net.minecraft.world.entity.LivingEntity) entity;
	net.minecraft.world.item.ItemStack stack = mainHand ? living.getMainHandItem() : living.getOffhandItem();
	if (stack.isEmpty()) return "minecraft:air";
	net.minecraft.resources.ResourceLocation key = net.minecraft.core.registries.BuiltInRegistries.ITEM.getKey(stack.getItem());
	return key == null ? "minecraft:air" : key.toString();
}

private static double fmproLootEffect(net.minecraft.world.entity.Entity entity, String id, boolean amplifier) {
	if (!(entity instanceof net.minecraft.world.entity.LivingEntity) || id == null) return amplifier ? -1 : 0;
	net.minecraft.world.entity.LivingEntity living = (net.minecraft.world.entity.LivingEntity) entity;
	net.minecraft.world.effect.MobEffect effect = net.minecraft.core.registries.BuiltInRegistries.MOB_EFFECT.get(fmproRl(id));
	if (effect == null) return amplifier ? -1 : 0;
	if (!living.hasEffect(effect)) return amplifier ? -1 : 0;
	return amplifier ? living.getEffect(effect).getAmplifier() : living.getEffect(effect).getDuration();
}

private static boolean fmproLootPredicate(com.google.gson.JsonObject condition, net.minecraft.world.entity.Entity entity) {
	if (condition == null || !condition.has("predicate") || !condition.get("predicate").isJsonObject()) return false;
	com.google.gson.JsonObject predicate = condition.getAsJsonObject("predicate");
	boolean and = !predicate.has("logic") || "AND".equalsIgnoreCase(predicate.get("logic").getAsString());
	java.util.List<Boolean> checks = new java.util.ArrayList<>();
	net.minecraft.world.entity.LivingEntity living = entity instanceof net.minecraft.world.entity.LivingEntity
			? (net.minecraft.world.entity.LivingEntity) entity : null;
	if (predicate.has("enchantment_level")) {
		com.google.gson.JsonObject check = predicate.getAsJsonObject("enchantment_level");
		String enchant = check.has("enchant") ? check.get("enchant").getAsString() : "";
		int level = living == null ? 0 : fmproLootEnchant(living.getMainHandItem(), enchant);
		checks.add(fmproLootCompare(level, check.has("op") ? check.get("op").getAsString() : "==",
				check.has("value") ? check.get("value").getAsDouble() : 0));
	}
	if (predicate.has("potion_effect_remaining")) {
		com.google.gson.JsonObject check = predicate.getAsJsonObject("potion_effect_remaining");
		String effect = check.has("effect") ? check.get("effect").getAsString() : "";
		double value = fmproLootEffect(entity, effect, false);
		checks.add(fmproLootCompare(value, check.has("op") ? check.get("op").getAsString() : "==",
				check.has("value") ? check.get("value").getAsDouble() : 0));
	}
	if (predicate.has("potion_effect_amplifier")) {
		com.google.gson.JsonObject check = predicate.getAsJsonObject("potion_effect_amplifier");
		String effect = check.has("effect") ? check.get("effect").getAsString() : "";
		double value = fmproLootEffect(entity, effect, true);
		checks.add(fmproLootCompare(value, check.has("op") ? check.get("op").getAsString() : "==",
				check.has("value") ? check.get("value").getAsDouble() : 0));
	}
	if (predicate.has("mainhand_item")) {
		com.google.gson.JsonObject check = predicate.getAsJsonObject("mainhand_item");
		checks.add(fmproLootCompareText(fmproLootHandId(entity, true),
				check.has("op") ? check.get("op").getAsString() : "==",
				check.has("value") ? check.get("value").getAsString() : "minecraft:air"));
	}
	if (predicate.has("offhand_item")) {
		com.google.gson.JsonObject check = predicate.getAsJsonObject("offhand_item");
		checks.add(fmproLootCompareText(fmproLootHandId(entity, false),
				check.has("op") ? check.get("op").getAsString() : "==",
				check.has("value") ? check.get("value").getAsString() : "minecraft:air"));
	}
	if (checks.isEmpty()) return true;
	boolean result = and;
	for (boolean check : checks) result = and ? result && check : result || check;
	return result;
}

private static double fmproLootValue(com.google.gson.JsonElement element, net.minecraft.world.entity.Entity entity) {
	if (element == null || element.isJsonNull()) return 0;
	if (element.isJsonPrimitive() && element.getAsJsonPrimitive().isNumber()) return element.getAsDouble();
	if (element.isJsonObject()) {
		com.google.gson.JsonObject value = element.getAsJsonObject();
		if (value.has("type") && "enchant_level".equals(value.get("type").getAsString())) {
			String enchant = value.has("enchant") ? value.get("enchant").getAsString() : "";
			boolean offhand = value.has("hand") && "offhand".equalsIgnoreCase(value.get("hand").getAsString());
			if (!(entity instanceof net.minecraft.world.entity.LivingEntity)) return 0;
			net.minecraft.world.entity.LivingEntity living = (net.minecraft.world.entity.LivingEntity) entity;
			return fmproLootEnchant(offhand ? living.getOffhandItem() : living.getMainHandItem(), enchant);
		}
	}
	return 0;
}

private static void fmproLootApplyNbt(net.minecraft.world.item.ItemStack stack, com.google.gson.JsonObject nbt) {
	if (nbt == null || nbt.size() == 0) return;
	net.minecraft.nbt.Tag tag = fmproLootTag(nbt);
	if (tag instanceof net.minecraft.nbt.CompoundTag) net.minecraft.world.item.component.CustomData.update(net.minecraft.core.component.DataComponents.CUSTOM_DATA, stack, current -> current.merge((net.minecraft.nbt.CompoundTag) tag));
}

private static net.minecraft.nbt.Tag fmproLootTag(com.google.gson.JsonElement element) {
	if (element == null || element.isJsonNull()) return net.minecraft.nbt.EndTag.INSTANCE;
	if (element.isJsonObject()) {
		net.minecraft.nbt.CompoundTag tag = new net.minecraft.nbt.CompoundTag();
		for (java.util.Map.Entry<String, com.google.gson.JsonElement> entry : element.getAsJsonObject().entrySet()) {
			tag.put(entry.getKey(), fmproLootTag(entry.getValue()));
		}
		return tag;
	}
	if (element.isJsonArray()) {
		net.minecraft.nbt.ListTag tag = new net.minecraft.nbt.ListTag();
		for (com.google.gson.JsonElement child : element.getAsJsonArray()) tag.add(fmproLootTag(child));
		return tag;
	}
	com.google.gson.JsonPrimitive primitive = element.getAsJsonPrimitive();
	if (primitive.isBoolean()) return net.minecraft.nbt.ByteTag.valueOf((byte) (primitive.getAsBoolean() ? 1 : 0));
	if (primitive.isNumber()) {
		String raw = primitive.getAsString();
		if (raw.contains(".") || raw.contains("e") || raw.contains("E"))
			return net.minecraft.nbt.DoubleTag.valueOf(primitive.getAsDouble());
		return net.minecraft.nbt.IntTag.valueOf(primitive.getAsInt());
	}
	return net.minecraft.nbt.StringTag.valueOf(primitive.getAsString());
}

private static net.minecraft.world.item.ItemStack fmproLootDrop(com.google.gson.JsonObject condition,
		net.minecraft.world.entity.Entity entity) {
	if (condition == null || !condition.has("drop") || !condition.get("drop").isJsonObject()) return net.minecraft.world.item.ItemStack.EMPTY;
	com.google.gson.JsonObject drop = condition.getAsJsonObject("drop");
	if (!drop.has("id") || !drop.get("id").isJsonPrimitive()) {
		fmproLootWarn("Loot drop has no id");
		return net.minecraft.world.item.ItemStack.EMPTY;
	}
	int count = 1;
	if (drop.has("count") && drop.get("count").isJsonPrimitive()) {
		try {
			count = drop.get("count").getAsInt();
		} catch (RuntimeException ignored) {
			count = 1;
		}
	}
	if (drop.has("modifiers") && drop.get("modifiers").isJsonArray()) {
		for (com.google.gson.JsonElement modifier : drop.getAsJsonArray("modifiers")) {
			if (!modifier.isJsonObject()) continue;
			com.google.gson.JsonObject value = modifier.getAsJsonObject();
			String mode = value.has("mode") ? value.get("mode").getAsString() : "add";
			String function = value.has("function") ? value.get("function").getAsString() : "uniform";
			double amount;
			if ("looting".equalsIgnoreCase(function)) {
				String enchant = value.has("enchant") ? value.get("enchant").getAsString() : "";
				boolean includeOffhand = value.has("include_offhand") && value.get("include_offhand").getAsBoolean();
				if (entity instanceof net.minecraft.world.entity.LivingEntity) {
					net.minecraft.world.entity.LivingEntity living = (net.minecraft.world.entity.LivingEntity) entity;
					amount = fmproLootEnchant(living.getMainHandItem(), enchant);
					if (includeOffhand) amount += fmproLootEnchant(living.getOffhandItem(), enchant);
				} else {
					amount = 0;
				}
			} else {
				double min = fmproLootValue(value.get("min"), entity);
				double max = fmproLootValue(value.get("max"), entity);
				amount = max < min ? 0 : min + java.util.concurrent.ThreadLocalRandom.current().nextDouble() * (max - min);
			}
			if ("set".equalsIgnoreCase(mode)) count = (int) amount;
			else count += (int) amount;
		}
	}
	count = Math.max(0, count);
	if (count == 0) return net.minecraft.world.item.ItemStack.EMPTY;
	net.minecraft.world.item.Item item = net.minecraft.core.registries.BuiltInRegistries.ITEM.get(fmproRl(drop.get("id").getAsString()));
	if (item == null || item == net.minecraft.world.item.Items.AIR) {
		fmproLootWarn("Unknown loot item: " + drop.get("id").getAsString());
		return net.minecraft.world.item.ItemStack.EMPTY;
	}
	net.minecraft.world.item.ItemStack stack = new net.minecraft.world.item.ItemStack(item);
	stack.setCount(count);
	if (drop.has("nbt") && drop.get("nbt").isJsonObject()) fmproLootApplyNbt(stack, drop.getAsJsonObject("nbt"));
	return stack;
}

private static net.minecraft.world.item.ItemStack fmproLootItemFromRoot(com.google.gson.JsonObject root,
		net.minecraft.world.entity.Entity entity, int index, String label) {
	if (root == null) return net.minecraft.world.item.ItemStack.EMPTY;
	if (!root.has("conditions") || !root.get("conditions").isJsonArray()) {
		fmproLootWarn("Loot file has no conditions array: " + label);
		return net.minecraft.world.item.ItemStack.EMPTY;
	}
	com.google.gson.JsonArray conditions = root.getAsJsonArray("conditions");
	int realIndex = index - 1;
	if (realIndex < 0 || realIndex >= conditions.size()) {
		fmproLootWarn("Loot condition index out of range: " + index + " in " + label);
		return net.minecraft.world.item.ItemStack.EMPTY;
	}
	if (!conditions.get(realIndex).isJsonObject()) {
		fmproLootWarn("Loot condition is not an object: " + index + " in " + label);
		return net.minecraft.world.item.ItemStack.EMPTY;
	}
	com.google.gson.JsonObject condition = conditions.get(realIndex).getAsJsonObject();
	return fmproLootPredicate(condition, entity) ? fmproLootDrop(condition, entity) : net.minecraft.world.item.ItemStack.EMPTY;
}

private static net.minecraft.world.item.ItemStack fmproLootItem(net.minecraft.world.level.block.state.BlockState block,
		net.minecraft.world.entity.Entity entity, String type, String path, int index) {
	if (entity == null || entity.getServer() == null) return net.minecraft.world.item.ItemStack.EMPTY;
	try {
		return fmproLootItemFromRoot(fmproLootRoot(block, type, path), entity, index, path);
	} catch (Exception e) {
		fmproLootWarn("Failed to read custom loot: " + path + " (" + e.getMessage() + ")");
		return net.minecraft.world.item.ItemStack.EMPTY;
	}
}

private static net.minecraft.world.item.ItemStack fmproLootItemFirstFromRoot(com.google.gson.JsonObject root,
		net.minecraft.world.entity.Entity entity, String label) {
	if (root == null) return net.minecraft.world.item.ItemStack.EMPTY;
	if (!root.has("conditions") || !root.get("conditions").isJsonArray()) {
		fmproLootWarn("Loot file has no conditions array: " + label);
		return net.minecraft.world.item.ItemStack.EMPTY;
	}
	for (com.google.gson.JsonElement element : root.getAsJsonArray("conditions")) {
		if (!element.isJsonObject()) continue;
		com.google.gson.JsonObject condition = element.getAsJsonObject();
		if (fmproLootPredicate(condition, entity)) return fmproLootDrop(condition, entity);
	}
	return net.minecraft.world.item.ItemStack.EMPTY;
}

private static net.minecraft.world.item.ItemStack fmproLootItemFirst(net.minecraft.world.level.block.state.BlockState block,
		net.minecraft.world.entity.Entity entity, String type, String path) {
	if (entity == null || entity.getServer() == null) return net.minecraft.world.item.ItemStack.EMPTY;
	try {
		return fmproLootItemFirstFromRoot(fmproLootRoot(block, type, path), entity, path);
	} catch (Exception e) {
		fmproLootWarn("Failed to read custom loot by first match: " + path + " (" + e.getMessage() + ")");
		return net.minecraft.world.item.ItemStack.EMPTY;
	}
}

private static double fmproLootCountFromRoot(com.google.gson.JsonObject root,
		net.minecraft.world.entity.Entity entity, String label) {
	if (root == null) return 0;
	if (!root.has("conditions") || !root.get("conditions").isJsonArray()) {
		fmproLootWarn("Loot file has no conditions array: " + label);
		return 0;
	}
	for (com.google.gson.JsonElement element : root.getAsJsonArray("conditions")) {
		if (!element.isJsonObject()) continue;
		com.google.gson.JsonObject condition = element.getAsJsonObject();
		if (fmproLootPredicate(condition, entity))
			return fmproLootDrop(condition, entity).getCount();
	}
	return 0;
}

private static double fmproLootCount(net.minecraft.world.level.block.state.BlockState block,
		net.minecraft.world.entity.Entity entity, String type, String path) {
	if (entity == null || entity.getServer() == null) return 0;
	try {
		return fmproLootCountFromRoot(fmproLootRoot(block, type, path), entity, path);
	} catch (Exception e) {
		fmproLootWarn("Failed to count custom loot conditions: " + path + " (" + e.getMessage() + ")");
		return 0;
	}
}

private static net.minecraft.world.item.ItemStack fmproLootItemByIdFromRoot(com.google.gson.JsonObject root,
		net.minecraft.world.entity.Entity entity, String conditionId, String label) {
	if (root == null) return net.minecraft.world.item.ItemStack.EMPTY;
	if (!root.has("conditions") || !root.get("conditions").isJsonArray()) {
		fmproLootWarn("Loot file has no conditions array: " + label);
		return net.minecraft.world.item.ItemStack.EMPTY;
	}
	for (com.google.gson.JsonElement element : root.getAsJsonArray("conditions")) {
		if (!element.isJsonObject()) continue;
		com.google.gson.JsonObject condition = element.getAsJsonObject();
		if (condition.has("condition_id") && condition.get("condition_id").isJsonPrimitive()
				&& condition.get("condition_id").getAsString().equals(conditionId)) {
			return fmproLootPredicate(condition, entity) ? fmproLootDrop(condition, entity) : net.minecraft.world.item.ItemStack.EMPTY;
		}
	}
	fmproLootWarn("Loot condition ID not found: " + conditionId + " in " + label);
	return net.minecraft.world.item.ItemStack.EMPTY;
}

private static net.minecraft.world.item.ItemStack fmproLootItemById(net.minecraft.world.level.block.state.BlockState block,
		net.minecraft.world.entity.Entity entity, String type, String path, String conditionId) {
	if (entity == null || entity.getServer() == null) return net.minecraft.world.item.ItemStack.EMPTY;
	try {
		return fmproLootItemByIdFromRoot(fmproLootRoot(block, type, path), entity, conditionId, path);
	} catch (Exception e) {
		fmproLootWarn("Failed to read custom loot by ID: " + path + " (" + e.getMessage() + ")");
		return net.minecraft.world.item.ItemStack.EMPTY;
	}
}

private static net.minecraft.world.item.ItemStack fmproLootItemCached(com.google.gson.JsonObject cache,
		net.minecraft.world.level.block.state.BlockState block, net.minecraft.world.entity.Entity entity,
		String type, int index) {
	if (entity == null || entity.getServer() == null) return net.minecraft.world.item.ItemStack.EMPTY;
	try {
		return fmproLootItemFromRoot(fmproLootCacheRoot(cache, block, type), entity, index, "cache:" + type);
	} catch (Exception e) {
		fmproLootWarn("Failed to read cached custom loot: " + type + " (" + e.getMessage() + ")");
		return net.minecraft.world.item.ItemStack.EMPTY;
	}
}

private static double fmproLootCountCached(com.google.gson.JsonObject cache,
		net.minecraft.world.level.block.state.BlockState block, net.minecraft.world.entity.Entity entity, String type) {
	if (entity == null || entity.getServer() == null) return 0;
	try {
		return fmproLootCountFromRoot(fmproLootCacheRoot(cache, block, type), entity, "cache:" + type);
	} catch (Exception e) {
		fmproLootWarn("Failed to count cached custom loot: " + type + " (" + e.getMessage() + ")");
		return 0;
	}
}

private static net.minecraft.world.item.ItemStack fmproLootItemByIdCached(com.google.gson.JsonObject cache,
		net.minecraft.world.level.block.state.BlockState block, net.minecraft.world.entity.Entity entity,
		String type, String conditionId) {
	if (entity == null || entity.getServer() == null) return net.minecraft.world.item.ItemStack.EMPTY;
	try {
		return fmproLootItemByIdFromRoot(fmproLootCacheRoot(cache, block, type), entity, conditionId, "cache:" + type);
	} catch (Exception e) {
		fmproLootWarn("Failed to read cached custom loot by ID: " + type + " (" + e.getMessage() + ")");
		return net.minecraft.world.item.ItemStack.EMPTY;
	}
}

private static net.minecraft.world.item.ItemStack fmproLootItemFirstCached(com.google.gson.JsonObject cache,
		net.minecraft.world.level.block.state.BlockState block, net.minecraft.world.entity.Entity entity,
		String type) {
	if (entity == null || entity.getServer() == null) return net.minecraft.world.item.ItemStack.EMPTY;
	try {
		return fmproLootItemFirstFromRoot(fmproLootCacheRoot(cache, block, type), entity, "cache:" + type);
	} catch (Exception e) {
		fmproLootWarn("Failed to read cached custom loot by first match: " + type + " (" + e.getMessage() + ")");
		return net.minecraft.world.item.ItemStack.EMPTY;
	}
}

private static java.io.File fmproGameRoot() {
	return net.fabricmc.loader.api.FabricLoader.getInstance().getGameDir().toFile();
}

private static java.io.File fmproFile(String path) {
	if (path == null) return new java.io.File("");
	String normalized = path.replace('\\', java.io.File.separatorChar).replace('/', java.io.File.separatorChar);
	return new java.io.File(normalized);
}

private static String fmproReadText(java.io.File file) {
	try {
		return new String(java.nio.file.Files.readAllBytes(file.toPath()), java.nio.charset.StandardCharsets.UTF_8);
	} catch (java.io.IOException e) {
		throw new java.io.UncheckedIOException(e);
	}
}

private static String fmproReadLine(java.io.File file, int index) {
	try {
		java.util.List<String> lines = java.nio.file.Files.readAllLines(file.toPath(), java.nio.charset.StandardCharsets.UTF_8);
		return index >= 0 && index < lines.size() ? lines.get(index) : "";
	} catch (java.io.IOException e) {
		throw new java.io.UncheckedIOException(e);
	}
}

private static void fmproWriteText(java.io.File file, String text, boolean append) {
	try {
		java.io.File parent = file.getParentFile();
		if (parent != null) parent.mkdirs();
		byte[] bytes = text.getBytes(java.nio.charset.StandardCharsets.UTF_8);
		if (append) {
			java.nio.file.Files.write(file.toPath(), bytes, java.nio.file.StandardOpenOption.CREATE,
					java.nio.file.StandardOpenOption.WRITE, java.nio.file.StandardOpenOption.APPEND);
		} else {
			java.nio.file.Files.write(file.toPath(), bytes, java.nio.file.StandardOpenOption.CREATE,
					java.nio.file.StandardOpenOption.WRITE, java.nio.file.StandardOpenOption.TRUNCATE_EXISTING);
		}
	} catch (java.io.IOException e) {
		throw new java.io.UncheckedIOException(e);
	}
}

private static void fmproWriteLines(java.io.File file, java.util.List<?> lines) {
	try {
		java.io.File parent = file.getParentFile();
		if (parent != null) parent.mkdirs();
		java.util.List<String> out = new java.util.ArrayList<>();
		for (Object line : lines) out.add(String.valueOf(line));
		java.nio.file.Files.write(file.toPath(), out, java.nio.charset.StandardCharsets.UTF_8,
				java.nio.file.StandardOpenOption.CREATE, java.nio.file.StandardOpenOption.WRITE,
				java.nio.file.StandardOpenOption.TRUNCATE_EXISTING);
	} catch (java.io.IOException e) {
		throw new java.io.UncheckedIOException(e);
	}
}

private static java.io.File[] fmproListChildren(java.io.File folder) {
	java.io.File[] children = folder.listFiles();
	return children == null ? new java.io.File[0] : children;
}

private static void fmproCreateFolder(java.io.File folder) {
	if (folder.isDirectory()) return;
	if (folder.exists()) {
		throw new java.io.UncheckedIOException(new java.io.IOException("Path exists and is not a folder: " + folder));
	}
	if (!folder.mkdirs()) {
		throw new java.io.UncheckedIOException(new java.io.IOException("Could not create folder: " + folder));
	}
}

private static void fmproDelete(java.io.File file) {
	try {
		java.nio.file.Files.delete(file.toPath());
	} catch (java.io.IOException e) {
		throw new java.io.UncheckedIOException(e);
	}
}

private static java.io.File fmproRename(java.io.File file, String name) {
	try {
		java.io.File target = new java.io.File(file.getParentFile(), name);
		java.nio.file.Files.move(file.toPath(), target.toPath());
		return target;
	} catch (java.io.IOException e) {
		throw new java.io.UncheckedIOException(e);
	}
}

private static String fmproParentPath(java.io.File file) {
	java.io.File parent = file.getParentFile();
	return parent == null ? "" : parent.getAbsolutePath();
}

private static com.google.gson.JsonObject fmproReadJsonObject(java.io.File file) {
	try {
		String raw = new String(java.nio.file.Files.readAllBytes(file.toPath()), java.nio.charset.StandardCharsets.UTF_8);
		return new com.google.gson.Gson().fromJson(raw, com.google.gson.JsonElement.class).getAsJsonObject();
	} catch (java.io.IOException e) {
		throw new java.io.UncheckedIOException(e);
	}
}

private static com.google.gson.JsonArray fmproReadJsonArray(java.io.File file) {
	try {
		String raw = new String(java.nio.file.Files.readAllBytes(file.toPath()), java.nio.charset.StandardCharsets.UTF_8);
		return new com.google.gson.Gson().fromJson(raw, com.google.gson.JsonElement.class).getAsJsonArray();
	} catch (java.io.IOException e) {
		throw new java.io.UncheckedIOException(e);
	}
}

private static void fmproWriteJson(java.io.File file, com.google.gson.JsonElement json) {
	try {
		java.io.File parent = file.getParentFile();
		if (parent != null) parent.mkdirs();
		java.nio.file.Files.write(file.toPath(),
				new com.google.gson.GsonBuilder().setPrettyPrinting().create().toJson(json)
						.getBytes(java.nio.charset.StandardCharsets.UTF_8),
				java.nio.file.StandardOpenOption.CREATE, java.nio.file.StandardOpenOption.WRITE,
				java.nio.file.StandardOpenOption.TRUNCATE_EXISTING);
	} catch (java.io.IOException e) {
		throw new java.io.UncheckedIOException(e);
	}
}

private static net.minecraft.resources.Identifier fmproRl(String id) {
	String value = id == null ? "minecraft:air" : id.trim();
	if (!value.contains(":")) value = "minecraft:" + value;
	return net.minecraft.resources.Identifier.parse(value);
}

private static com.google.gson.JsonObject fmproReadDatapackJson(String path) {
	String clean = path == null ? "" : path.replace('\\', '/').trim();
	boolean fromData = clean.startsWith("data/");
	if (fromData) clean = clean.substring(5);
	if (!clean.endsWith(".json")) clean += ".json";
	String namespace = "minecraft";
	String resourcePath = clean;
	int colon = clean.indexOf(':');
	if (colon >= 0) {
		namespace = clean.substring(0, colon);
		resourcePath = clean.substring(colon + 1);
	} else if (fromData) {
		int slash = clean.indexOf('/');
		if (slash >= 0) {
			namespace = clean.substring(0, slash);
			resourcePath = clean.substring(slash + 1);
		}
	}
	net.minecraft.server.MinecraftServer server = ${package}.fmpro.FmproServerHolder.get();
	if (server == null) throw new IllegalStateException("No server available for datapack read: " + path);
	net.minecraft.resources.Identifier rl = fmproRl(namespace + ":" + resourcePath);
	java.util.Optional<net.minecraft.server.packs.resources.Resource> resource = server.getResourceManager().getResource(rl);
	if (resource.isEmpty()) throw new IllegalArgumentException("Datapack file not found: " + path);
	java.io.InputStream in;
	try {
		in = resource.get().open();
	} catch (java.io.IOException e) {
		throw new java.io.UncheckedIOException(e);
	}
	try (java.io.InputStream stream = in) {
		com.google.gson.JsonElement element = new com.google.gson.Gson().fromJson(
				new java.io.InputStreamReader(stream, java.nio.charset.StandardCharsets.UTF_8), com.google.gson.JsonElement.class);
		return element.getAsJsonObject();
	} catch (java.io.IOException e) {
		throw new java.io.UncheckedIOException(e);
	}
}

private static <T> T fmproJsonConvert(com.google.gson.JsonElement element, Class<T> type) {
	if (element == null || element.isJsonNull()) return null;
	if (type == String.class) return type.cast(element.isJsonPrimitive() ? element.getAsString() : element.toString());
	if (type == Double.class) return type.cast(element.isJsonPrimitive() && element.getAsJsonPrimitive().isNumber() ? element.getAsDouble() : 0.0);
	if (type == Boolean.class) return type.cast(element.isJsonPrimitive() && element.getAsJsonPrimitive().isBoolean() ? element.getAsBoolean() : false);
	if (type == com.google.gson.JsonObject.class) return type.cast(element.isJsonObject() ? element.getAsJsonObject() : new com.google.gson.JsonObject());
	if (type == com.google.gson.JsonArray.class) return type.cast(element.isJsonArray() ? element.getAsJsonArray() : new com.google.gson.JsonArray());
	return (T) element;
}

private static <T> T fmproJsonObjectGet(com.google.gson.JsonObject object, String key, Class<T> type, T defaultValue) {
	if (object == null || !object.has(key) || object.get(key).isJsonNull()) return defaultValue;
	T value = fmproJsonConvert(object.get(key), type);
	return value == null ? defaultValue : value;
}

private static <T> T fmproJsonArrayGet(com.google.gson.JsonArray array, int index, Class<T> type, T defaultValue) {
	T value = fmproJsonConvert(array.get(index), type);
	return value == null ? defaultValue : value;
}

private static com.google.gson.JsonElement fmproJsonValue(Object value) {
	if (value == null) return com.google.gson.JsonNull.INSTANCE;
	if (value instanceof com.google.gson.JsonElement) return (com.google.gson.JsonElement) value;
	if (value instanceof String) return new com.google.gson.JsonPrimitive((String) value);
	if (value instanceof Number) return new com.google.gson.JsonPrimitive((Number) value);
	if (value instanceof Boolean) return new com.google.gson.JsonPrimitive((Boolean) value);
	return new com.google.gson.JsonPrimitive(String.valueOf(value));
}

private static void fmproJsonObjectSet(com.google.gson.JsonObject object, String key, Object value) {
	object.add(key, fmproJsonValue(value));
}

private static void fmproJsonArrayAdd(com.google.gson.JsonArray array, Object value) {
	array.add(fmproJsonValue(value));
}

private static void fmproJsonArraySet(com.google.gson.JsonArray array, int index, Object value) {
	array.set(index, fmproJsonValue(value));
}

private static void fmproJsonArrayClear(com.google.gson.JsonArray array) {
	while (array.size() > 0) array.remove(0);
}

private static void fmproJsonObjectClear(com.google.gson.JsonObject object) {
	java.util.List<String> keys = new java.util.ArrayList<>();
	for (java.util.Map.Entry<String, com.google.gson.JsonElement> entry : object.entrySet()) keys.add(entry.getKey());
	for (String key : keys) object.remove(key);
}

private static boolean fmproJsonIsString(Object value) {
	if (value instanceof com.google.gson.JsonElement)
		return ((com.google.gson.JsonElement) value).isJsonPrimitive() && ((com.google.gson.JsonElement) value).getAsJsonPrimitive().isString();
	return value instanceof String;
}

private static boolean fmproJsonIsNumber(Object value) {
	if (value instanceof com.google.gson.JsonElement)
		return ((com.google.gson.JsonElement) value).isJsonPrimitive() && ((com.google.gson.JsonElement) value).getAsJsonPrimitive().isNumber();
	return value instanceof Number;
}

private static boolean fmproJsonIsBoolean(Object value) {
	if (value instanceof com.google.gson.JsonElement)
		return ((com.google.gson.JsonElement) value).isJsonPrimitive() && ((com.google.gson.JsonElement) value).getAsJsonPrimitive().isBoolean();
	return value instanceof Boolean;
}

private static boolean fmproJsonIsObject(Object value) {
	if (value instanceof com.google.gson.JsonElement) return ((com.google.gson.JsonElement) value).isJsonObject();
	return value instanceof com.google.gson.JsonObject;
}

private static boolean fmproJsonIsArray(Object value) {
	if (value instanceof com.google.gson.JsonElement) return ((com.google.gson.JsonElement) value).isJsonArray();
	return value instanceof com.google.gson.JsonArray;
}

private static java.io.File fmproDownload(String url, java.io.File file) {
	try {
		java.io.File parent = file.getParentFile();
		if (parent != null) parent.mkdirs();
		try (java.io.InputStream in = java.net.URI.create(url).toURL().openStream()) {
			java.nio.file.Files.copy(in, file.toPath(), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
		}
		return file;
	} catch (java.io.IOException e) {
		throw new java.io.UncheckedIOException(e);
	}
}

private static void fmproExtractZip(java.io.File zip, java.io.File destination) {
	try (java.util.zip.ZipInputStream input = new java.util.zip.ZipInputStream(
			java.nio.file.Files.newInputStream(zip.toPath()))) {
		java.util.zip.ZipEntry entry;
		java.nio.file.Path base = destination.toPath().toAbsolutePath().normalize();
		while ((entry = input.getNextEntry()) != null) {
			java.nio.file.Path target = base.resolve(entry.getName()).normalize();
			if (!target.startsWith(base)) throw new java.io.IOException("Invalid ZIP entry: " + entry.getName());
			if (entry.isDirectory()) {
				java.nio.file.Files.createDirectories(target);
			} else {
				java.nio.file.Files.createDirectories(target.getParent());
				java.nio.file.Files.copy(input, target, java.nio.file.StandardCopyOption.REPLACE_EXISTING);
			}
		}
	} catch (java.io.IOException e) {
		throw new java.io.UncheckedIOException(e);
	}
}

private static void fmproAddFileToZip(java.io.File zip, java.io.File file, String entryName) {
	java.io.File parent = zip.getParentFile();
	if (parent != null) parent.mkdirs();
	String entry = entryName == null || entryName.trim().isEmpty() ? file.getName() : entryName.trim().replace('\\', '/');
	while (entry.startsWith("/")) entry = entry.substring(1);
	try {
		java.io.File temp = java.io.File.createTempFile("fmpro-", ".tmp", parent);
		try {
			try (java.util.zip.ZipOutputStream output = new java.util.zip.ZipOutputStream(
					java.nio.file.Files.newOutputStream(temp.toPath()))) {
				if (zip.isFile()) {
					try (java.util.zip.ZipInputStream input = new java.util.zip.ZipInputStream(
							java.nio.file.Files.newInputStream(zip.toPath()))) {
						byte[] buffer = new byte[8192];
						java.util.zip.ZipEntry existing;
						while ((existing = input.getNextEntry()) != null) {
							if (existing.getName().equals(entry)) continue;
							output.putNextEntry(new java.util.zip.ZipEntry(existing.getName()));
							int read;
							while ((read = input.read(buffer)) != -1) output.write(buffer, 0, read);
							output.closeEntry();
						}
					}
				}
				output.putNextEntry(new java.util.zip.ZipEntry(entry));
				java.nio.file.Files.copy(file.toPath(), output);
				output.closeEntry();
			}
			java.nio.file.Files.move(temp.toPath(), zip.toPath(), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
		} finally {
			java.nio.file.Files.deleteIfExists(temp.toPath());
		}
	} catch (java.io.IOException e) {
		throw new java.io.UncheckedIOException(e);
	}
}

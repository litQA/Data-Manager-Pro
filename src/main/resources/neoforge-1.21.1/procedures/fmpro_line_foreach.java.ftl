try (java.io.BufferedReader fmproReader = java.nio.file.Files.newBufferedReader(${input$file}.toPath(), java.nio.charset.StandardCharsets.UTF_8)) {
	String fmprolineiterator;
	while ((fmprolineiterator = fmproReader.readLine()) != null) {
		${statement$foreach}
	}
} catch (java.io.IOException e) {
	throw new java.io.UncheckedIOException(e);
}

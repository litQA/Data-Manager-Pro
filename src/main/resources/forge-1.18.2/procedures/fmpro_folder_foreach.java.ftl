<@addTemplate file="utils/fmpro/fmpro_helpers.java.ftl"/>
for (java.io.File fmprofileiterator : fmproListChildren(${input$folder})) {
	${statement$foreach}
}

<#assign cls=generator.map(field$type,"fmpro_jsontypes",0)><#assign def=generator.map(field$type,"fmpro_jsontypes",1)>
<@addTemplate file="utils/fmpro/fmpro_helpers.java.ftl"/>
fmproJsonArrayGet(${input$json}, ${opt.toInt(input$index)}, ${cls}.class, ${def})

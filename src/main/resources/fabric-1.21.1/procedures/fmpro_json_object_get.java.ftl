<#assign cls=generator.map(field$type,"fmpro_jsontypes",0)><#assign def=generator.map(field$type,"fmpro_jsontypes",1)>
<@addTemplate file="utils/fmpro/fmpro_helpers.java.ftl"/>
fmproJsonObjectGet(${input$json}, ${input$key}, ${cls}.class, ${def})

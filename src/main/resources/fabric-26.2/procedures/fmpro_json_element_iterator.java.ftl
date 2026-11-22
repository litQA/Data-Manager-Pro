<#assign cls=generator.map(field$type,"fmpro_jsontypes",0)>
<@addTemplate file="utils/fmpro/fmpro_helpers.java.ftl"/>
/*@${cls}*/(fmproJsonConvert(fmprojsonelementiterator, ${cls}.class))

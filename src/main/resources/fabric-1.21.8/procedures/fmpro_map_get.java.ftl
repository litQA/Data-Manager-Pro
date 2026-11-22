<#assign cls=generator.map(field$type,"fmpro_supportedtypes",0)>
<#if addTemplate??>
<@addTemplate file="utils/map/map_get.java.ftl"/>
/*@${cls}*/(getMapValue(${input$map},${input$map_key},${cls}.class,${generator.map(field$type,"fmpro_supportedtypes",1)}))
<#else>
/*@${cls}*/(comp.getMapValue(${input$map},${input$map_key},${cls}.class,${generator.map(field$type,"fmpro_supportedtypes",1)}))
</#if>

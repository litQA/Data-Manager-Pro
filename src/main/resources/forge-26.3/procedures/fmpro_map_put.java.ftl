<#include "mcitems.ftl">
<#if input_id$map_value?starts_with("mcitem_all")>
${input$map}.put(${input$map_key},${mappedMCItemToItemStackCode(input$map_value,1)})
<#else>
<#if addTemplate??>
<@addTemplate file="utils/list/list_convert_value.java.ftl"/>
</#if>
${input$map}.put(${input$map_key},toSupportedType(${input$map_value}));
</#if>
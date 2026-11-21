<#include "mcitems.ftl">
<@addTemplate file="utils/fmpro/fmpro_helpers.java.ftl"/>
<@addTemplate file="utils/fmpro/fmpro_loot.java.ftl"/>
fmproLootCountCached(${input$cache}, ${mappedBlockToBlockStateCode(input$block)}, ${input$entity}, ${input$type})

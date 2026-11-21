<#include "mcitems.ftl">
<@addTemplate file="utils/fmpro/fmpro_helpers.java.ftl"/>
<@addTemplate file="utils/fmpro/fmpro_loot.java.ftl"/>
/*@ItemStack*/fmproLootItem(${mappedBlockToBlockStateCode(input$block)}, ${input$entity}, ${input$type}, ${input$path}, ${opt.toInt(input$index)})

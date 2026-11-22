<#include "mcitems.ftl">
<@addTemplate file="utils/fmpro/fmpro_helpers.java.ftl"/>
<@addTemplate file="utils/fmpro/fmpro_loot.java.ftl"/>
/*@ItemStack*/fmproLootItemById(${mappedBlockToBlockStateCode(input$block)}, ${input$entity}, ${input$type}, ${input$path}, ${input$condition})

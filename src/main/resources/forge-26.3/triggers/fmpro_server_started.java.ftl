<#include "procedures.java.ftl">
@net.minecraftforge.fml.common.Mod.EventBusSubscriber(modid = "${modid}") public class ${name}Procedure {
	@net.minecraftforge.eventbus.api.listener.SubscribeEvent public static void onServerStarted(net.minecraftforge.event.server.ServerStartedEvent event) {
		execute();
	}

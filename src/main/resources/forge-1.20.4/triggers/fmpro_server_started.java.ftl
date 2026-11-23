<#include "procedures.java.ftl">
@net.minecraftforge.fml.common.Mod.EventBusSubscriber public class ${name}Procedure {
	@net.minecraftforge.eventbus.api.SubscribeEvent public static void onServerStarted(net.minecraftforge.event.server.ServerStartedEvent event) {
		execute();
	}

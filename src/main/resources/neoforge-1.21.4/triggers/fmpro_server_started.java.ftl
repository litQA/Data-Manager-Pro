<#include "procedures.java.ftl">
@net.neoforged.fml.common.EventBusSubscriber public class ${name}Procedure {
	@net.neoforged.bus.api.SubscribeEvent public static void onServerStarted(net.neoforged.neoforge.event.server.ServerStartedEvent event) {
		execute();
	}

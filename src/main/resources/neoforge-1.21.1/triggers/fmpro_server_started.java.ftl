<#include "procedures.java.ftl">
@EventBusSubscriber public class ${name}Procedure {
	@SubscribeEvent public static void onServerStarted(net.neoforged.neoforge.event.server.ServerStartedEvent event) {
		execute();
	}

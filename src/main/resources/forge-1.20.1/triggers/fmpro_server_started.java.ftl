<#include "procedures.java.ftl">
@Mod.EventBusSubscriber public class ${name}Procedure {
	@SubscribeEvent public static void onServerStarted(net.minecraftforge.event.server.ServerStartedEvent event) {
		execute();
	}

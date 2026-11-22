<#include "procedures.java.ftl">
@Mod.EventBusSubscriber public class ${name}Procedure {
	@SubscribeEvent public static void onServerStarted(net.minecraftforge.fmlserverevents.FMLServerStartedEvent event) {
		execute();
	}

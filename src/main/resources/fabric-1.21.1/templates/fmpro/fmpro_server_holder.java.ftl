package ${package}.fmpro;

/**
 * Keeps the active integrated or dedicated server for procedure helpers that
 * are not passed a world or entity by their block interface.
 */
public final class FmproServerHolder {
	private static volatile net.minecraft.server.MinecraftServer server;

	private FmproServerHolder() {
	}

	public static void init() {
		net.fabricmc.fabric.api.event.lifecycle.v1.ServerLifecycleEvents.SERVER_STARTED.register(
				started -> FmproServerHolder.server = started);
		net.fabricmc.fabric.api.event.lifecycle.v1.ServerLifecycleEvents.SERVER_STOPPED.register(
				stopped -> FmproServerHolder.server = null);
	}

	public static net.minecraft.server.MinecraftServer get() {
		return FmproServerHolder.server;
	}
}

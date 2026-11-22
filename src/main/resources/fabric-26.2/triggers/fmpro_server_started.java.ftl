<#include "procedures.java.ftl">
public ${name}Procedure() {
	net.fabricmc.fabric.api.event.lifecycle.v1.ServerLifecycleEvents.SERVER_STARTED.register(server -> execute());
}

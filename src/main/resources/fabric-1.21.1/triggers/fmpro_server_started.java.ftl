<#include "procedures.java.ftl">
public class ${name}Procedure {
	public ${name}Procedure() {
		${package}.fmpro.FmproServerHolder.init();
		net.fabricmc.fabric.api.event.lifecycle.v1.ServerLifecycleEvents.SERVER_STARTED.register(server -> execute());
	}

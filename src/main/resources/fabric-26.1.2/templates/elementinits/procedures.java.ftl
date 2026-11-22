package ${package}.init;

@SuppressWarnings("InstantiationOfUtilityClass")
public class ${JavaModName}Procedures {
	public static void load() {
		${package}.fmpro.FmproServerHolder.init();
		<#list procedures as procedure>
			<#if !procedure.procedurexml?contains('no_ext_trigger')>
				new ${procedure.getModElement().getName()}Procedure();
			</#if>
		</#list>
	}
}

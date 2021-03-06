<%@ include file="/WEB-INF/template/include.jsp" %>

<openmrs:require privilege="Manage Programs" otherwise="/login.htm" redirect="/admin/programs/program.form" />

<%@ include file="/WEB-INF/template/header.jsp" %>
<%@ include file="localHeader.jsp" %>

<openmrs:htmlInclude file="/scripts/dojo/dojo.js" />
<openmrs:htmlInclude file="/dwr/util.js" />
<style>
.statesToRetire {
	width: 50px;
	border: 1px solid #009d8e;
}
</style>
<script type="text/javascript">
	var displayedStates = new Array();
	var idToNameMap = new Array();
	var retiredStates = new Array();
	var allSates= new Array();
	var activeStates=new Array();
	var isActiveDisplay=true;
	dojo.require("dojo.widget.openmrs.ConceptSearch");
	dojo.require("dojo.widget.openmrs.OpenmrsPopup");

	dojo.addOnLoad( function() {
		dojo.event.topic.subscribe("cSearch/select", 
			function(msg) {
				idToNameMap[msg.objs[0].conceptId] = msg.objs[0].name;
				addState(msg.objs[0].conceptId, false, false);
			}
		);
	});

	function refreshStateTable() {
		dwr.util.removeAllRows('stateTable');
		if (displayedStates.length != 0) {
			dwr.util.addRows('stateTable', displayedStates, [
					function (st) { return getIdToNameMap(st[0]); },
					function (st) { return '<input type="checkbox" id="initial_' + st[0] + '" ' + (st[1] ? 'checked' : '') + '/>'; },
					function (st) { return '<input type="checkbox" id="terminal_' + st[0] + '" ' + (st[2] ? 'checked' : '') + '/>'; },
					function (st) { return getButton(st[0]); }
				], { escapeHtml:false });
		} else {
			dwr.util.addRows('stateTable', ['<spring:message code="general.none"/>'], [
					function(s) { return s;}
				], { escapeHtml:false });
		}
	}
	
	function retireState(conceptId) {
		for (var i = 0; i < activeStates.length; ++i) {
			if (activeStates[i][0] == conceptId) {
				var x=window.confirm("<spring:message code='State.retire.confirmation'/>")
				if (x) {
					retiredStates.push(activeStates[i]);
					activeStates.splice(i,1);
					if(isActiveDisplay){
						displayedStates=activeStates;
					}else{
						displayedStates=allSates;
						
					}
					
					refreshStateTable();
				}
			}
		}
	}
	
	function unretireState(conceptId) {
		for (var i = 0; i < retiredStates.length; ++i) {
			if (retiredStates[i][0] == conceptId) {
				var x=window.confirm("<spring:message code='State.unretire.confirmation'/>")
				if (x) {
					activeStates.push(retiredStates[i]);
					retiredStates.splice(i,1);
					refreshStateTable();
				}
			}
		}
	}
	
	function getIdToNameMap(conceptId){
		
		if(isStateRetired(conceptId)){
			
			return '<strike>'+idToNameMap[conceptId]+'</strike>';
		 }else{
			 
			 return idToNameMap[conceptId];

		 } 
		
	
}
function getButton(conceptId){
	if(isStateRetired(conceptId)){
		
		return '<input type="button" class="statesToRetire" value="<spring:message code="general.unretire"/>" onclick="unretireState('+conceptId+')"}/>';
	 }else{
		 
	    return '<input type="button" class="statesToRetire" value="<spring:message code="general.retire"/>" onclick="retireState('+conceptId+')"}/>';

	 }
	
}

function isStateRetired(conceptId){
	for(var i = 0; i < retiredStates.length;++i){
		if(conceptId==retiredStates[i][0]){
			return true;
		}
		
	}
}
	function toggleStatesVisibility(){
	if(isActiveDisplay){
	activeStates=displayedStates;
	displayedStates=allSates;
	refreshStateTable();
		isActiveDisplay=false;
	}else{
		displayedStates=activeStates;
		refreshStateTable();
		isActiveDisplay=true;
	}
		
	}
	
	function initialiseStateTable(){
		isActiveDisplay=false;
		activeStates=displayedStates;
		toggleStatesVisibility();
	}
	
	function addState(conceptId, isInitial, isTerminal) {
		for (var i = 0; i < allSates.length; ++i)
			if (allSates[i][0] == conceptId) {
				window.alert("<spring:message code='State.error.name.duplicate'/>");
				return;
			}
		if(isActiveDisplay){
			displayedStates.push([ conceptId, isInitial, isTerminal ]);
			allSates.push([ conceptId, isInitial, isTerminal ]);

		}else{
			activeStates.push([ conceptId, isInitial, isTerminal ]);
			displayedStates.push([ conceptId, isInitial, isTerminal ]);
		}
refreshStateTable();
	}
	
	function handleAddState() {
		var popup = dojo.widget.manager.getWidgetById("conceptSelection")
		var conceptId = popup.hiddenInputNode.value;
		popup.hiddenInputNode.value = '';
		popup.displayNode.innerHTML = '';
		addState(conceptId, false, false);
	}
	
	function handleSave() {
		displayedStates=activeStates;
		var tmp = "";
		for (var i = 0; i < displayedStates.length; ++i) {
			var conceptId = displayedStates[i][0];
			var isInitial = $('initial_' + conceptId).checked;
			var isTerminal = $('terminal_' + conceptId).checked;
			tmp += conceptId + ",";
			tmp += isInitial + ",";
			tmp += isTerminal + "|";
		}
		$('statesToSubmit').value = tmp;
		$('theForm').submit();
	}
</script>

<h3>
	<openmrs_tag:concept conceptId="${workflow.program.concept.conceptId}"/>
	-
	<openmrs_tag:concept conceptId="${workflow.concept.conceptId}"/>
</h3>

<spring:hasBindErrors name="workflow">
	<spring:message code="fix.error"/>
	<br />
</spring:hasBindErrors>

<b class="boxHeader"> <a style="display: block; float: right"
	href="#" onClick="toggleStatesVisibility();"> <spring:message
			code="general.toggle.retired" /> </a> <spring:message
		code="State.list.title" /> </b>

<form method="post" id="theForm">
	<table>
		<thead>
			<tr>
				<th><spring:message code="State.state"/></th>
				<th><spring:message code="State.initial"/>?</th>
				<th><spring:message code="State.terminal"/>?</th>
			</tr>
		</thead>
		<tbody id="stateTable">
			<tr><td colspan="3"><spring:message code="general.none" /></td></tr>
		</tbody>
		<tbody>
			<tr>
				<td colspan="3" align="center">
					<div dojoType="ConceptSearch" widgetId="cSearch" conceptId="" showVerboseListing="false" conceptClasses="State"></div>
					<div dojoType="OpenmrsPopup" widgetId="conceptSelection" hiddenInputName="conceptId" searchWidget="cSearch" searchTitle='<spring:message code="Concept.find" />' changeButtonValue='<spring:message code="general.add"/>'></div>
				</td>
			</tr>
		</tbody>
	</table>
	<input type="hidden" id="statesToSubmit" name="newStates" />
	<input type="button" onClick="handleSave()" value="<spring:message code="general.save" />" />
</form>

<script type="text/javascript">
<c:forEach var="state" items="${workflow.states}">
idToNameMap[${state.concept.conceptId}] = '<openmrs:concept conceptId="${state.concept.conceptId}" nameVar="n" var="v" numericVar="nv">${n.name}</openmrs:concept>';
allSates.push([ ${state.concept.conceptId}, ${state.initial}, ${state.terminal} ]);
	<c:if test="${!state.retired}">
	displayedStates.push([ ${state.concept.conceptId}, ${state.initial}, ${state.terminal} ]);
</c:if>
<c:if test="${state.retired}">
var conceptId=${state.concept.conceptId};
retiredStates.push([ ${state.concept.conceptId}, ${state.initial}, ${state.terminal} ]);
</c:if>
</c:forEach>
initialiseStateTable();
refreshStateTable();
</script>

<%@ include file="/WEB-INF/template/footer.jsp" %>

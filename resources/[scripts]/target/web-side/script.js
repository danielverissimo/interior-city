let targetVisible = false;
let targetCursorMode = false;

function hideTarget() {
	$(".target-label").html("");
	$(".target").css("display","none");
	targetVisible = false;
	targetCursorMode = false;
}

function notifyLostFocus() {
	if (!targetVisible || targetCursorMode) return;

	// Esconde imediatamente no Chromium e avisa o client para zerar também
	// targetActive/NUI focus. Isso cobre ALT+TAB mesmo quando o FiveM perde
	// o key-up do ALT.
	hideTarget();
	$.post("http://target/targetLostFocus",JSON.stringify({}));
}

window.addEventListener("message",function(event){
	let item = event["data"];

	if (item["response"] == "openTarget"){
		$(".target-label").html("");
		$(".target").css("display","flex");
		targetVisible = true;
		targetCursorMode = false;

	} else if (item["response"] == "cursorTarget"){
		targetCursorMode = true;

	} else if (item["response"] == "closeTarget"){
		hideTarget();

	} else if (item["response"] == "validTarget"){
		$(".target-label").html("");

		$.each(item["data"],function(index,item){
			$(".target-label").append("<div id='target-" + index + "'<li>" + item["label"] + "</li></div>");

			$("#target-" + index).data("TargetData",item["event"]);
			$("#target-" + index).data("TunnelData",item["tunnel"]);
			$("#target-" + index).data("ServiceData",item["service"]);
		});

	} else if (item["response"] == "leftTarget"){
		hideTarget();
		$.post("http://target/closeTarget");
	}
});

document.onkeyup = data => {
	if (data["key"] === "Escape"){
		hideTarget();
		$.post("http://target/closeTarget");
	}
};

// Se o Chromium/NUI perder foco porque o jogador saiu da janela do FiveM,
// encerra o target apenas no modo de segurar ALT. No modo de cursor, ele
// permanece disponível para clicar nas opções.
window.addEventListener("blur",notifyLostFocus);

document.addEventListener("visibilitychange",function(){
	if (document.hidden){
		notifyLostFocus();
	}
});

$(document).on("mousedown",(event) => {
	let element = event["target"];

	if (element["id"].split("-")[0] === "target"){
		let targetData = $("#" + element["id"]).data("TargetData");
		let tunnelData = $("#" + element["id"]).data("TunnelData");
		let serviceData = $("#" + element["id"]).data("ServiceData");

		$.post("http://target/selectTarget",JSON.stringify({ event: targetData, tunnel: tunnelData, service: serviceData }));

		hideTarget();
	}
});

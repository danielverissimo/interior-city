$(function (){
    const actionContainer = $("#actionmenu");
    const resourceName = typeof GetParentResourceName === "function" ? GetParentResourceName() : "m_snippets";

    function post(endpoint, data){
        return $.post(`https://${resourceName}/${endpoint}`, JSON.stringify(data || {}));
    }

    window.addEventListener("message", function(event){
        const data = event.data || {};

        if(data.showmenu){
            $("#botoes").empty();
            $("#andar").html(`<p id="numeroandar">${String(data.andar || "")}</p>`);

            const floors = Array.isArray(data.elevador)
                ? data.elevador
                : Object.keys(data.elevador || {}).map(name => ({ name }));

            floors.forEach(floor => {
                const name = String(floor.name || "");
                if(!name) return;

                const current = name === String(data.andar || "");
                const button = $("<button>", {
                    class: `floor-button${current ? " current" : ""}`,
                    text: name,
                    disabled: current
                });

                if(!current){
                    button.on("click", () => setFloorNumber(String(data.tipo || ""), name));
                }

                $("#botoes").append(button);
            });

            actionContainer.show();
        }

        if(data.hidemenu) actionContainer.hide();
    });

    document.onkeyup = function(data){
        if(data.which === 27 && actionContainer.is(":visible")){
            actionContainer.hide();
            post("closeNui", {});
        }
    };

    window.setFloorNumber = function(nameElevador, floorNumber){
        const audio = new Audio("sounds/click.ogg");
        audio.play().catch(()=>{});

        $("#andar").html(`<p id="numeroandar">${String(floorNumber)}</p>`);
        post("elevadorInit", {
            elevador: nameElevador,
            andar: floorNumber
        });
    };
});

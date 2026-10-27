var app = new Vue({
    el: '#app',
    data: {
        show: false,
        table: []
    }
})


function take_un(fardas) {
    $.post("http://m_cloakroom/ButtonClick", JSON.stringify(fardas))
}

function remove_un() {
    $.post("http://m_cloakroom/rmv_un", JSON.stringify())
    close()
}


function close() {
    app.show = false
    $.post("http://m_cloakroom/close", JSON.stringify())
}

document.addEventListener("DOMContentLoaded", function(){

    window.addEventListener("message", function(event) {

    app.show = event.data.showNUI
    
    if(app.show) {
        app.table = event.data.table
    }

    document.onkeyup = function(data) {
      if (data.which == 27) {
        close()
      }
    }


    })
  })




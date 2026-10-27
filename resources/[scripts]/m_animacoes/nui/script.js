var app = new Vue({
    el: '#app',
    data: {
        show: false,
        table: []
    }
  })

function confirm_an(anim) {
  app.show = false

  $.post('http://m_animacoes/confirm',JSON.stringify(anim))
}

  function close() {
    app.show = false
    $.post("https://m_animacoes/close")
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

var app = new Vue({
    el: '#app',
    data: {
        show: false,
        policia: null,
        in_ptr: false,
        ranking: []
    },
    
})

function confirm(tipo,policia) {

    if(app.in_ptr){
        const Toast = Swal.mixin({
            toast: true,
            position: 'top-end',
            background: 'linear-gradient(180deg, rgba(120,20,20,0.92), rgba(60,10,10,0.95))',
            color: '#ffd6d6',
            showConfirmButton: false,
            timer: 10000,
            timerProgressBar: true,
            target: document.getElementById('app'),
            customClass: {
                popup: 'swal-popup-alert',
                title: 'swal-text-alert'
            },
            didOpen: (toast) => {
                toast.addEventListener('mouseenter', Swal.stopTimer)
                toast.addEventListener('mouseleave', Swal.resumeTimer)
            }
        })

        Toast.fire({
            icon: 'warning',
            title: 'Você já está em patrulha!'
        })
        return
    }

    Swal.fire({
        title: `Deseja iniciar a patrulha ${tipo}?`,
        text: `Sua patrulha é essencial para manter a ordem.`,
        icon: "question",
        showCancelButton: true,
        background: '#0b1d2a',
        color: '#ffffff',
        confirmButtonColor: "#0b4906ff",
        cancelButtonColor: "#d33",
        target: document.getElementById('app'),
        heightAuto: false,
        position: 'center',
        confirmButtonText: "Sim, começar patrulha",
        cancelButtonText: "Cancelar",
        customClass: {
        popup: 'swal-popup',
        title: 'swal-text',
        htmlContainer: 'swal-text',
        confirmButton: 'swal-text',
        cancelButton: 'swal-text'
        }

        }).then((result) => {
        if (result.isConfirmed) {
           const Toast = Swal.mixin({
                toast: true,
                position: 'top-end',
                background: '#0b1d2a',
                color: '#ffffff',
                showConfirmButton: false,
                timer: 10000,
                timerProgressBar: true,
                target: document.getElementById('app'),
                customClass: {
                    popup: 'swal-popup',
                    title: 'swal-text'
                },
                didOpen: (toast) => {
                    toast.addEventListener('mouseenter', Swal.stopTimer)
                    toast.addEventListener('mouseleave', Swal.resumeTimer)
                }
            })
            Toast.fire({
            icon: 'success',
            title: 'Patrulha ' + tipo + ' iniciada com sucesso!'
            })

            $.post("http://m_patrulha/confirm",JSON.stringify({tipo,policia}))
            app.in_ptr = true
            // app.show = false

        }
    });

}

function encerrar() {

    Swal.fire({
        title: `Deseja encerrar a patrulha?`,
        text: `Obrigado por seu trabalho em nossa cidade.`,
        icon: "question",
        showCancelButton: true,
        background: '#0b1d2a',
        color: '#ffffff',
        confirmButtonColor: "#0b4906ff",
        cancelButtonColor: "#d33",
        target: document.getElementById('app'),
        heightAuto: false,
        position: 'center',
        confirmButtonText: "Sim, encerrar patrulha",
        cancelButtonText: "Cancelar",
        customClass: {
        popup: 'swal-popup',
        title: 'swal-text',
        htmlContainer: 'swal-text',
        confirmButton: 'swal-text',
        cancelButton: 'swal-text'
        }

        }).then((result) => {
        if (result.isConfirmed) {
           const Toast = Swal.mixin({
                toast: true,
                position: 'top-end',
                background: '#0b1d2a',
                color: '#ffffff',
                showConfirmButton: false,
                timer: 10000,
                timerProgressBar: true,
                target: document.getElementById('app'),
                customClass: {
                    popup: 'swal-popup',
                    title: 'swal-text'
                },
                didOpen: (toast) => {
                    toast.addEventListener('mouseenter', Swal.stopTimer)
                    toast.addEventListener('mouseleave', Swal.resumeTimer)
                }
            })
            Toast.fire({
            icon: 'success',
            title: 'Patrulha finalizada com sucesso!'
            })

           encerrar_ptr()

        }
    });

}

function close() {
    $.post("http://m_patrulha/close")
    app.show = false
}

function encerrar_ptr() {
    $.post("http://m_patrulha/encerrar_ptr")
    app.in_ptr = false
    app.show = false
}
  
document.addEventListener("DOMContentLoaded", function(){

window.addEventListener("message", function(event) {

    if(event.data.show){

        app.show = event.data.show
        app.policia = event.data.policia
        app.ranking = event.data.ranking

    }


    document.onkeyup = function(data) {
        if (data.which == 27) {
            close()
        }
    }



    })
})



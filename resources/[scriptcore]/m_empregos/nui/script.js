
var app = new Vue({
    el: '#app',
    data: {
        painel: "",
        emp_infos: [],
        emp_data: [],
        at_emprego: "Nenhum",
        menuOpen: false,
        menuEmprego: null,
        menuPos: { top: 0, left: 0 },
        trucker: []
    },
   computed: {
    empInfosOrdenado() {
      const arr = Array.isArray(this.emp_infos)
        ? this.emp_infos
        : (this.emp_infos && typeof this.emp_infos === 'object'
            ? Object.values(this.emp_infos)
            : [])

      return [...arr].sort((a, b) => {
        const A = (a && a.index) ? String(a.index) : ''
        const B = (b && b.index) ? String(b.index) : ''
        return A.localeCompare(B, 'pt-BR', { sensitivity: 'base' })
      })
    }
  },
    methods: {
        toggleMenu(emprego, evt) {
    
    if (this.menuOpen && this.menuEmprego === emprego) {
      this.menuOpen = false;
      this.menuEmprego = null;
      return;
    }

    this.menuOpen = true;
    this.menuEmprego = emprego;

    const rect = evt.target.getBoundingClientRect();
    const appRect = evt.target.closest('.container').querySelector('.box_dados');

    this.menuPos.top  = (rect.top - appRect.top) + rect.height / 2 - 52; 
    this.menuPos.left = (rect.left - appRect.left) + rect.width + 10;
  },

  closeMenu() {
    this.menuOpen = false;
    this.menuEmprego = null;
  },

  actionUniform(tipo, emprego) {
    this.closeMenu();
    
    // aqui você chama o NUI/POST do seu script
    // exemplo:
    $.post(`http://m_empregos/${tipo}_uniforme`, JSON.stringify({ emprego }));

    // ou faça o que você já usa no seu painel
  },

  pedirDemissao(emprego) {
    this.closeMenu();

    // opcional: confirmação
    Swal.fire({
      title: "Pedir demissão?",
      text: `Você vai sair do emprego: ${emprego}`,
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "Sim, pedir demissão",
      cancelButtonText: "Cancelar",
      target: document.getElementById('app'),
      heightAuto: false,
      background: '#0b1d2a',
      color: '#fff',
      customClass: {
        title: 'swal-text',
        htmlContainer: 'swal-text',
        confirmButton: 'swal-text',
        cancelButton: 'swal-text'
        }
    }).then((r) => {
      if (r.isConfirmed) {
        $.post("http://m_empregos/pedir_demissao", JSON.stringify({ emprego }));
        close_central()
      }
    });
  }
    }
  })

  

  function confirm(at_emprego,index,loc) {
    if(at_emprego == index){
        $.post("http://m_empregos/set_at_emprego",JSON.stringify({at_emprego,index}))
        return
    }
    Swal.fire({
        title: `Deseja mesmo assinar carteira como ${index}?`,
        text: `Você irá sair do emprego: ${at_emprego}.`,
        icon: "question",
        showCancelButton: true,
        background: '#0b1d2a',
        color: '#ffffff',
        confirmButtonColor: "#0b4906ff",
        cancelButtonColor: "#d33",
        target: document.getElementById('app'),
        heightAuto: false,
        position: 'center',
        confirmButtonText: "Sim, começar trabalho",
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
            Swal.fire({
            background: '#0b1d2a',
            color: '#ffffff',
            title: "Confirmado!",
            text: `Agora você tem carteira assinada no emprego de ${index}.`,
            icon: "success",
            target: document.getElementById('app'),
            heightAuto: false,
            position: 'center',
                customClass: {
                popup: 'swal-popup',
                htmlContainer: 'swal-text',
                title: 'swal-text'
                }
            });

            app.at_emprego = index
            
            $.post("http://m_empregos/set_at_emprego",JSON.stringify({at_emprego,index,loc}))

            console.log('codigo sucess aqui')

        }
    });
  }

function select_trucker(route) {

  if (route == 'show') {
    textcontent = 'Entrega de carga para eventos pela cidade.'
  } else if (route == 'gas') {
    textcontent = 'Entrega de combustivel para postos pela cidade.'
  } else if (route == 'carros') {
    textcontent = 'Entrega de veiculos pela cidade.'
  } else if (route == 'madeiras') {
    textcontent = 'Entrega de madeiras pelo norte.'
  }

    Swal.fire({
        title: `Deseja mesmo iniciar a rota de ${route}?`,
        text: textcontent,
        icon: "question",
        showCancelButton: true,
        background: '#0b1d2a',
        color: '#ffffff',
        confirmButtonColor: "#0b4906ff",
        cancelButtonColor: "#d33",
        target: document.getElementById('app'),
        heightAuto: false,
        position: 'center',
        confirmButtonText: "Sim, iniciar rota",
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
            title: 'Rota de ' + route + ' selecionada com sucesso!'
            })
            
            $.post("http://m_empregos/select_route",JSON.stringify(route))
            close_central()
            console.log('codigo sucess aqui')

        }
    });
  }



  function close_central() {

    
    if(app.painel == "trucker"){
      $.post("http://m_empregos/close_trucker")
    } 
    if(app.painel == "central" || app.painel == "status"){
      $.post("http://m_empregos/close_central")
    } 
      
    app.painel = ""
    app.menuOpen = false

  }



  function preloadImages() {
        const images = [
            'images/caminhoneiro.jpg',
            'images/motorista.jpg',
            'images/taxista.jpg',
            'images/entregador.jpg',
            'images/pescador.jpg',
            'images/lixeiro.jpg',
            'images/minerador.jpg',
            'images/eletricista.jpg'
        ];

        images.forEach(src => {
            const img = new Image();
            img.src = src;
        });
    }

  
  document.addEventListener("DOMContentLoaded", function(){
    
    window.addEventListener("message", function(event) {

    if(event.data.showCENTRAL == "central" || event.data.showCENTRAL == "status" || event.data.showCENTRAL == "trucker") {
        preloadImages();

        app.painel = event.data.showCENTRAL;
        app.emp_data = event.data.emp_data;
        app.emp_infos = event.data.emp_infos;
        app.at_emprego = event.data.at_emprego;

        if(event.data.showCENTRAL == "trucker"){
           app.trucker = event.data.trucker;
        }

    }


    document.onkeyup = function(data) {
      if (data.which == 27) {
        close_central()
      }
    }

    

    })
  })


document.addEventListener('wheel', function (e) {
  const box = e.target.closest('.container_box');
  if (!box) return;

  if (box.scrollWidth <= box.clientWidth) return;

  e.preventDefault();

  const speed = 3.0; // 🔥 quanto maior, mais rápido
  box.scrollLeft += e.deltaY * speed;
}, { passive: false });

document.addEventListener('click', () => {
  if (app && app.menuOpen) {
    app.closeMenu();
  }
});
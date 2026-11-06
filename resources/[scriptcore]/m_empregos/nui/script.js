
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
      if (window.FishingMinigame && window.FishingMinigame.isActive()) return;
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

// -----------------------------------------------------------------------------
// MINIGAME DE PESCA
// Implementação própria para NUI: barra com inércia + peixe com padrões de movimento
// + progresso de captura. O servidor continua sendo a autoridade sobre peixe e prêmio.
// -----------------------------------------------------------------------------
window.FishingMinigame = (() => {
  const game = document.getElementById('fishing-game');
  const track = document.getElementById('fishing-track');
  const catchBar = document.getElementById('fishing-catch-bar');
  const fish = document.getElementById('fishing-fish');
  const progressEl = document.getElementById('fishing-progress');
  const difficultyEl = document.getElementById('fishing-difficulty');

  let active = false;
  let resolving = false;
  let holding = false;
  let challenge = null;
  let animationFrame = 0;
  let startedAt = 0;
  let lastFrame = 0;
  let rng = Math.random;

  let catchY = 0.62;
  let catchVelocity = 0;
  let fishY = 0.60;
  let fishVelocity = 0;
  let fishTarget = 0.60;
  let targetTimer = 0.6;
  let progress = 0.28;
  let phaseSpeedMul = 1.0;
  let phaseAccelMul = 1.0;
  let lastCatchingState = null;

  function clamp(v, min, max) {
    return Math.max(min, Math.min(max, v));
  }

  function approach(current, target, amount) {
    if (current < target) return Math.min(current + amount, target);
    return Math.max(current - amount, target);
  }

  function seededRandom(seed) {
    let a = (Number(seed) || 1) >>> 0;
    return function() {
      a |= 0;
      a = (a + 0x6D2B79F5) | 0;
      let t = Math.imul(a ^ (a >>> 15), 1 | a);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }

  function randomRange(min, max) {
    return min + ((max - min) * rng());
  }

  function chooseFishTarget() {
    const behavior = String(challenge.behavior || 'mixed');
    phaseSpeedMul = 1.0;
    phaseAccelMul = 1.0;

    if (behavior === 'sinker') {
      fishTarget = rng() < 0.72 ? randomRange(0.58, 0.92) : randomRange(0.10, 0.88);
    } else if (behavior === 'floater') {
      fishTarget = rng() < 0.72 ? randomRange(0.08, 0.42) : randomRange(0.10, 0.88);
    } else if (behavior === 'dart') {
      const calmChance = Number(challenge.calmChance) || 0.30;
      const isCalmPhase = rng() < calmChance;

      if (isCalmPhase) {
        const calmDistance = Number(challenge.calmDistance) || 0.18;
        const localTarget = fishY + randomRange(-calmDistance, calmDistance);
        fishTarget = clamp(localTarget, 0.10, 0.90);
        phaseSpeedMul = Number(challenge.calmSpeedMul) || 0.58;
        phaseAccelMul = Number(challenge.calmAccelMul) || 0.62;
        targetTimer = randomRange(
          Number(challenge.calmDurationMin) || 0.95,
          Number(challenge.calmDurationMax) || 1.70
        );
        return;
      }

      const direction = rng() < 0.5 ? -1 : 1;
      const distance = randomRange(0.28, 0.58);
      fishTarget = clamp(fishY + (direction * distance), 0.07, 0.93);
      if (Math.abs(fishTarget - fishY) < 0.18) {
        fishTarget = fishY < 0.5 ? randomRange(0.66, 0.93) : randomRange(0.07, 0.34);
      }
    } else if (behavior === 'smooth') {
      const localTarget = fishY + randomRange(-0.28, 0.28);
      fishTarget = clamp(localTarget, 0.10, 0.90);
    } else {
      fishTarget = randomRange(0.08, 0.92);
    }

    targetTimer = randomRange(
      Number(challenge.changeMin) || 0.45,
      Number(challenge.changeMax) || 1.05
    );
  }

  function updateVisuals(catching) {
    const barSize = clamp(Number(challenge.barSize) || 0.24, 0.12, 0.42);
    catchBar.style.height = `${barSize * 100}%`;
    catchBar.style.top = `${catchY * 100}%`;
    fish.style.top = `${fishY * 100}%`;
    progressEl.style.height = `${clamp(progress, 0, 1) * 100}%`;

    if (lastCatchingState !== catching) {
      catchBar.classList.toggle('is-catching', catching);
      fish.classList.toggle('is-catching', catching);
      lastCatchingState = catching;
    }
  }

  function finish(success, reason) {
    if (!active || resolving) return;
    resolving = true;
    holding = false;

    const elapsedMs = Math.max(0, Math.floor(performance.now() - startedAt));
    const payload = {
      token: challenge && challenge.token,
      success: success === true,
      reason: reason || (success ? 'caught' : 'escaped'),
      elapsedMs
    };

    cancelAnimationFrame(animationFrame);
    animationFrame = 0;

    // Fecha esta rodada imediatamente. A próxima só poderá ser criada depois
    // que o callback Lua concluir a validação server-side.
    closeVisual();

    const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'm_empregos';
    fetch(`https://${resource}/fishingResult`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(payload)
    }).catch(() => {});
  }

  function cancelFish() {
    if (!active || resolving) return;
    resolving = true;
    holding = false;
    const elapsedMs = Math.max(0, Math.floor(performance.now() - startedAt));
    cancelAnimationFrame(animationFrame);
    animationFrame = 0;

    const token = challenge && challenge.token;
    closeVisual();

    const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'm_empregos';
    fetch(`https://${resource}/fishingCancel`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({ token, elapsedMs })
    }).catch(() => {});
  }

  function quitService() {
    if (!active || resolving) return;
    resolving = true;
    holding = false;
    cancelAnimationFrame(animationFrame);
    animationFrame = 0;

    const token = challenge && challenge.token;
    closeVisual();

    const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'm_empregos';
    fetch(`https://${resource}/fishingQuitService`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({ token })
    }).catch(() => {});
  }

  function frame(now) {
    if (!active || resolving) return;

    let dt = (now - lastFrame) / 1000;
    lastFrame = now;
    dt = clamp(dt || 0.016, 0.001, 0.04);

    const barSize = clamp(Number(challenge.barSize) || 0.24, 0.12, 0.42);
    const halfBar = barSize / 2;
    const liftForce = Number(challenge.liftForce) || 1.88;
    const gravity = Number(challenge.gravity) || 1.82;
    const maxBarSpeed = Number(challenge.maxBarSpeed) || 0.82;
    const bounce = clamp(Number(challenge.barBounce) || 0.34, 0, 0.8);

    catchVelocity += (holding ? -liftForce : gravity) * dt;
    catchVelocity *= Math.pow(0.955, dt * 60);
    catchVelocity = clamp(catchVelocity, -maxBarSpeed, maxBarSpeed);
    catchY += catchVelocity * dt;

    if (catchY < halfBar) {
      catchY = halfBar;
      if (catchVelocity < 0) catchVelocity = Math.abs(catchVelocity) * bounce;
    } else if (catchY > 1 - halfBar) {
      catchY = 1 - halfBar;
      if (catchVelocity > 0) catchVelocity = -Math.abs(catchVelocity) * bounce;
    }

    targetTimer -= dt;
    if (targetTimer <= 0) chooseFishTarget();

    const fishSpeed = (Number(challenge.fishSpeed) || 0.55) * phaseSpeedMul;
    const fishAccel = (Number(challenge.fishAccel) || 2.5) * phaseAccelMul;
    const desiredVelocity = clamp((fishTarget - fishY) * fishAccel, -fishSpeed, fishSpeed);
    fishVelocity = approach(fishVelocity, desiredVelocity, fishAccel * 0.82 * dt);
    fishVelocity *= Math.pow(0.992, dt * 60);
    fishY += fishVelocity * dt;

    if (fishY < 0.055) {
      fishY = 0.055;
      fishVelocity = Math.abs(fishVelocity) * 0.55;
      chooseFishTarget();
    } else if (fishY > 0.945) {
      fishY = 0.945;
      fishVelocity = -Math.abs(fishVelocity) * 0.55;
      chooseFishTarget();
    }

    const fishRadius = 0.032;
    const catching = (fishY + fishRadius) >= (catchY - halfBar) && (fishY - fishRadius) <= (catchY + halfBar);
    const gain = Number(challenge.progressGain) || 0.31;
    const loss = Number(challenge.progressLoss) || 0.22;

    if (catching) {
      progress += gain * dt;
    } else {
      progress -= loss * dt;
    }
    progress = clamp(progress, 0, 1);

    updateVisuals(catching);

    if (progress >= 1) {
      finish(true, 'caught');
      return;
    }

    if (progress <= 0) {
      finish(false, 'escaped');
      return;
    }

    const timeoutMs = Math.max(8000, Number(challenge.timeoutMs) || 45000);
    if ((now - startedAt) >= timeoutMs) {
      finish(false, 'timeout');
      return;
    }

    animationFrame = requestAnimationFrame(frame);
  }

  function open(data) {
    if (!game || !track || !catchBar || !fish || !progressEl) return;

    challenge = data || {};
    rng = seededRandom(challenge.seed);
    active = true;
    resolving = false;
    holding = false;

    catchY = 0.62;
    catchVelocity = 0;
    const barSize = clamp(Number(challenge.barSize) || 0.24, 0.12, 0.42);
    fishY = clamp(catchY + randomRange(-barSize * 0.24, barSize * 0.24), 0.08, 0.92);
    fishVelocity = 0;
    fishTarget = fishY;
    targetTimer = 0.55;
    phaseSpeedMul = 1.0;
    phaseAccelMul = 1.0;
    progress = clamp(Number(challenge.startProgress) || 0.28, 0.12, 0.65);
    lastCatchingState = null;

    const difficulty = Math.max(1, Math.min(5, Number(challenge.difficulty) || 1));
    if (difficultyEl) difficultyEl.textContent = `NÍVEL ${difficulty}`;

    game.classList.add('active');
    game.setAttribute('aria-hidden', 'false');
    updateVisuals(true);

    startedAt = performance.now();
    lastFrame = startedAt;
    cancelAnimationFrame(animationFrame);
    animationFrame = requestAnimationFrame(frame);
  }

  function closeVisual() {
    active = false;
    resolving = false;
    holding = false;
    challenge = null;
    lastCatchingState = null;
    cancelAnimationFrame(animationFrame);
    animationFrame = 0;
    if (game) {
      game.classList.remove('active');
      game.setAttribute('aria-hidden', 'true');
    }
  }

  function keyDown(event) {
    if (!active) return;

    const code = event.code || '';
    const key = String(event.key || '').toLowerCase();

    if (code === 'Space' || code === 'KeyE' || key === 'e') {
      holding = true;
      event.preventDefault();
      event.stopPropagation();
      return;
    }

    if (code === 'Escape' || key === 'escape') {
      event.preventDefault();
      event.stopPropagation();
      cancelFish();
      return;
    }

    if (code === 'F6' || key === 'f6') {
      event.preventDefault();
      event.stopPropagation();
      quitService();
    }
  }

  function keyUp(event) {
    if (!active) return;
    const code = event.code || '';
    const key = String(event.key || '').toLowerCase();
    if (code === 'Space' || code === 'KeyE' || key === 'e') {
      holding = false;
      event.preventDefault();
      event.stopPropagation();
    }
  }

  window.addEventListener('keydown', keyDown, true);
  window.addEventListener('keyup', keyUp, true);

  window.addEventListener('mousedown', (event) => {
    if (!active || event.button !== 0) return;
    holding = true;
    event.preventDefault();
    event.stopPropagation();
  }, true);

  window.addEventListener('mouseup', (event) => {
    if (!active || event.button !== 0) return;
    holding = false;
    event.preventDefault();
    event.stopPropagation();
  }, true);

  window.addEventListener('blur', () => {
    if (active) holding = false;
  });

  window.addEventListener('message', (event) => {
    if (event.data && event.data.showFishing === true) {
      open(event.data.challenge || {});
    }
    if (event.data && event.data.hideFishing === true) {
      closeVisual();
    }
  });

  return {
    isActive: () => active,
    close: closeVisual
  };
})();

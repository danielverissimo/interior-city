// ===== SISTEMA DE MINI PLAYER =====

// Função para obter nome do resource de forma segura
function getMiniPlayerResourceName() {
  if (typeof window.GetParentResourceName === "function") {
    return window.GetParentResourceName()
  }
  return "foxzinlafy"
}

// Variáveis do mini player
let miniPlayerVisible = false
let miniCurrentTrackData = null
let miniIsDJMode = false
let miniIsPlaying = false
let miniCurrentProgress = 0
let currentVideoId // NOVO: Declaração da variável currentVideoId
let isPlaying // NOVO: Declaração da variável isPlaying
let isDJMode // NOVO: Declaração da variável isDJMode
let MiniPlayer // NOVO: Declaração da variável MiniPlayer

// Elementos DOM do mini player
const miniPlayer = document.getElementById("mini-player")
const miniTitle = document.getElementById("mini-title")
const miniArtist = document.getElementById("mini-artist")
const miniArtwork = document.getElementById("mini-artwork-img")
const miniPlayPause = document.getElementById("mini-play-pause")
const miniPrev = document.getElementById("mini-prev")
const miniNext = document.getElementById("mini-next")
const miniProgressFill = document.getElementById("mini-progress-fill")

// Sistema de Mini Player
const MiniPlayerUI = {
  // Verificar se mini player deve ser mostrado
  shouldShow: () => {
    return miniCurrentTrackData && miniIsPlaying && typeof currentVideoId !== "undefined" && currentVideoId
  },

  // Mostrar mini player com animação
  show: (trackData, djMode = false, playing = false) => {
    if (!trackData || !playing) {
      console.log("🔽 Mini player não mostrado - sem dados ou não tocando")
      return
    }

    console.log("🎵 Mostrando mini player:", trackData)

    miniCurrentTrackData = trackData
    miniIsDJMode = djMode
    miniIsPlaying = playing

    // Atualizar informações
    MiniPlayerUI.updateInfo(trackData)
    MiniPlayerUI.updatePlayState(playing)
    MiniPlayerUI.updateDJMode(djMode)

    // Mostrar com animação
    miniPlayer.classList.add("entering")
    miniPlayer.classList.add("visible")

    // Adicionar classe ao body
    document.body.classList.add("has-mini-player")

    // Remover classe de animação após completar
    setTimeout(() => {
      miniPlayer.classList.remove("entering")
    }, 400)

    miniPlayerVisible = true
  },

  // Esconder mini player com animação
  hide: () => {
    if (!miniPlayerVisible) return

    console.log("🔽 Escondendo mini player")

    miniPlayer.classList.add("leaving")

    setTimeout(() => {
      miniPlayer.classList.remove("visible", "leaving")
      document.body.classList.remove("has-mini-player")
      miniPlayerVisible = false
      miniIsPlaying = false // NOVO: Resetar estado de reprodução
    }, 300)
  },

  // Atualizar informações da música
  updateInfo: (trackData) => {
    if (!trackData) return

    miniTitle.textContent = trackData.title || "Música Desconhecida"
    miniArtist.textContent = trackData.artist || "Artista Desconhecido"

    if (trackData.thumbnail) {
      miniArtwork.src = trackData.thumbnail

      // Precarregar imagem para evitar flickering
      const img = new Image()
      img.onload = () => {
        miniArtwork.src = trackData.thumbnail
      }
      img.src = trackData.thumbnail
    }

    // Verificar se título é muito longo para marquee
    if (trackData.title && trackData.title.length > 25) {
      miniTitle.classList.add("marquee")
    } else {
      miniTitle.classList.remove("marquee")
    }

    miniCurrentTrackData = trackData
  },

  // Atualizar estado de play/pause
  updatePlayState: (playing) => {
    miniIsPlaying = playing

    const playIcon = miniPlayPause.querySelector(".play-icon")
    const pauseIcon = miniPlayPause.querySelector(".pause-icon")

    if (playing) {
      playIcon.style.display = "none"
      pauseIcon.style.display = "block"
      miniPlayer.classList.add("playing")
    } else {
      playIcon.style.display = "block"
      pauseIcon.style.display = "none"
      miniPlayer.classList.remove("playing")

      // NOVO: Esconder mini player quando pausar
      setTimeout(() => {
        if (!miniIsPlaying) {
          MiniPlayerUI.hide()
        }
      }, 1000)
    }
  },

  // Atualizar modo DJ
  updateDJMode: (isDJMode) => {
    miniIsDJMode = isDJMode

    if (isDJMode) {
      miniPlayer.classList.add("dj-mode")
    } else {
      miniPlayer.classList.remove("dj-mode")
    }
  },

  // Atualizar progresso
  updateProgress: (progress) => {
    miniCurrentProgress = Math.max(0, Math.min(100, progress))
    miniProgressFill.style.width = `${miniCurrentProgress}%`
  },

  // Alternar visibilidade
  toggle: () => {
    if (miniPlayerVisible) {
      MiniPlayerUI.hide()
    } else if (MiniPlayerUI.shouldShow()) {
      MiniPlayerUI.show(miniCurrentTrackData, miniIsDJMode, miniIsPlaying)
    }
  },
}

// Event listeners para controles do mini player
if (miniPlayPause) {
  miniPlayPause.addEventListener("click", (e) => {
    e.stopPropagation()

    console.log("🎵 Mini player: Play/Pause clicado")

    fetch(`https://${getMiniPlayerResourceName()}/miniPlayerAction`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ action: "playPause" }),
    }).catch(console.error)

    // Feedback visual imediato
    const newState = !miniIsPlaying
    MiniPlayerUI.updatePlayState(newState)

    // Se pausou, esconder após delay
    if (!newState) {
      setTimeout(() => {
        if (!miniIsPlaying) {
          MiniPlayerUI.hide()
        }
      }, 1000)
    }
  })
}

if (miniPrev) {
  miniPrev.addEventListener("click", (e) => {
    e.stopPropagation()

    console.log("🎵 Mini player: Previous clicado")

    fetch(`https://${getMiniPlayerResourceName()}/miniPlayerAction`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ action: "previous" }),
    }).catch(console.error)

    // Efeito visual
    miniPrev.style.transform = "scale(0.9)"
    setTimeout(() => {
      miniPrev.style.transform = "scale(1)"
    }, 150)
  })
}

if (miniNext) {
  miniNext.addEventListener("click", (e) => {
    e.stopPropagation()

    console.log("🎵 Mini player: Next clicado")

    fetch(`https://${getMiniPlayerResourceName()}/miniPlayerAction`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ action: "next" }),
    }).catch(console.error)

    // Efeito visual
    miniNext.style.transform = "scale(0.9)"
    setTimeout(() => {
      miniNext.style.transform = "scale(1)"
    }, 150)
  })
}

// Clique no mini player para abrir NUI principal
if (miniPlayer) {
  miniPlayer.addEventListener("click", (e) => {
    // Evitar que cliques nos botões de controle abram a UI
    if (e.target.closest(".mini-controls")) return

    console.log("🎵 Mini player: Abrindo UI principal")

    fetch(`https://${getMiniPlayerResourceName()}/openMainUI`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({}),
    }).catch(console.error)

    // Efeito visual de clique
    miniPlayer.style.transform = "translateY(-2px) scale(0.98)"
    setTimeout(() => {
      miniPlayer.style.transform = ""
    }, 200)
  })
}

// Listener para mensagens do FiveM relacionadas ao mini player
function handleMiniPlayerMessages(event) {
  if (!event.data || !event.data.type) return

  switch (event.data.type) {
    case "showMiniPlayer":
      console.log("📨 Recebido showMiniPlayer:", event.data)
      // NOVO: Só mostrar se estiver tocando
      if (event.data.isPlaying) {
        MiniPlayerUI.show(event.data.trackData, event.data.djMode, event.data.isPlaying)
      }
      break

    case "hideMiniPlayer":
      console.log("📨 Recebido hideMiniPlayer")
      MiniPlayerUI.hide()
      break

    case "updateMiniPlayer":
      console.log("📨 Recebido updateMiniPlayer:", event.data)
      if (miniPlayerVisible) {
        MiniPlayerUI.updateInfo(event.data.trackData)
        MiniPlayerUI.updateDJMode(event.data.djMode)
      }
      break

    case "updateMiniPlayState":
      console.log("📨 Recebido updateMiniPlayState:", event.data.isPlaying)
      MiniPlayerUI.updatePlayState(event.data.isPlaying)

      // NOVO: Esconder se pausou
      if (!event.data.isPlaying) {
        setTimeout(() => {
          if (!miniIsPlaying) {
            MiniPlayerUI.hide()
          }
        }, 1000)
      }
      break

    case "updateMiniProgress":
      MiniPlayerUI.updateProgress(event.data.progress)
      break

    case "setMiniDJMode":
      console.log("📨 Recebido setMiniDJMode:", event.data.enabled)
      MiniPlayerUI.updateDJMode(event.data.enabled)
      break

    case "ui":
      // Quando UI principal abre/fecha
      if (event.data.status) {
        // UI principal abriu - esconder mini player
        if (miniPlayerVisible) {
          MiniPlayerUI.hide()
        }
      } else {
        // UI principal fechou - mostrar mini player se há música TOCANDO
        setTimeout(() => {
          if (
            typeof isPlaying !== "undefined" &&
            isPlaying &&
            typeof currentVideoId !== "undefined" &&
            currentVideoId
          ) {
            // Verificar se existe função MiniPlayer do script principal
            if (typeof MiniPlayer !== "undefined" && MiniPlayer.getCurrentTrackData) {
              const trackData = MiniPlayer.getCurrentTrackData()
              if (trackData) {
                const djMode = typeof isDJMode !== "undefined" ? isDJMode : false
                MiniPlayerUI.show(trackData, djMode, true)
              }
            }
          }
        }, 500)
      }
      break

    // NOVO: Casos específicos para pause/stop
    case "pausePlayback":
    case "forceStop":
      console.log("📨 Recebido comando de pause/stop")
      MiniPlayerUI.updatePlayState(false)
      setTimeout(() => {
        MiniPlayerUI.hide()
      }, 500)
      break

    case "resumePlayback":
      console.log("📨 Recebido comando de resume")
      MiniPlayerUI.updatePlayState(true)
      if (!miniPlayerVisible && miniCurrentTrackData) {
        MiniPlayerUI.show(miniCurrentTrackData, miniIsDJMode, true)
      }
      break
  }
}

// Adicionar listener para mensagens
window.addEventListener("message", handleMiniPlayerMessages)

// Integração com o sistema principal
document.addEventListener("DOMContentLoaded", () => {
  console.log("🎵 Mini Player JavaScript carregado!")

  // Verificar se elementos existem
  if (!miniPlayer) {
    console.warn("⚠️ Elemento mini-player não encontrado")
    return
  }

  // Configurar estado inicial
  miniPlayerVisible = false
  MiniPlayerUI.updatePlayState(false)
  MiniPlayerUI.updateDJMode(false)

  // Detectar quando UI principal é fechada para mostrar mini player
  const mainApp = document.getElementById("app")
  if (mainApp) {
    // Observer para detectar mudanças na classe 'visible'
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.type === "attributes" && mutation.attributeName === "class") {
          const isMainUIVisible = mainApp.classList.contains("visible")

          if (!isMainUIVisible && !miniPlayerVisible) {
            // UI principal foi fechada e mini player não está visível
            setTimeout(() => {
              // NOVO: Verificar se está tocando antes de mostrar
              if (
                typeof isPlaying !== "undefined" &&
                isPlaying &&
                typeof currentVideoId !== "undefined" &&
                currentVideoId
              ) {
                if (typeof MiniPlayer !== "undefined" && MiniPlayer.getCurrentTrackData) {
                  const trackData = MiniPlayer.getCurrentTrackData()
                  if (trackData) {
                    const djMode = typeof isDJMode !== "undefined" ? isDJMode : false
                    MiniPlayerUI.show(trackData, djMode, true)
                  }
                }
              }
            }, 300)
          } else if (isMainUIVisible && miniPlayerVisible) {
            // UI principal foi aberta - esconder mini player
            MiniPlayerUI.hide()
          }
        }
      })
    })

    observer.observe(mainApp, {
      attributes: true,
      attributeFilter: ["class"],
    })
  }

  // NOVO: Função melhorada para sincronizar com o player principal
  setInterval(() => {
    if (typeof isPlaying !== "undefined" && typeof currentVideoId !== "undefined") {
      // Verificar se deve mostrar/esconder baseado no estado de reprodução
      if (
        isPlaying &&
        currentVideoId &&
        !miniPlayerVisible &&
        !document.getElementById("app").classList.contains("visible")
      ) {
        // Música tocando, mini player não visível, UI principal fechada
        if (typeof MiniPlayer !== "undefined" && MiniPlayer.getCurrentTrackData) {
          const trackData = MiniPlayer.getCurrentTrackData()
          if (trackData) {
            const djMode = typeof isDJMode !== "undefined" ? isDJMode : false
            MiniPlayerUI.show(trackData, djMode, true)
          }
        }
      } else if (!isPlaying && miniPlayerVisible) {
        // Música pausada e mini player visível - esconder
        MiniPlayerUI.hide()
      }

      // Sincronizar estado de reprodução
      if (miniPlayerVisible && miniIsPlaying !== isPlaying) {
        MiniPlayerUI.updatePlayState(isPlaying)
      }

      // Sincronizar modo DJ
      if (typeof isDJMode !== "undefined" && miniIsDJMode !== isDJMode) {
        MiniPlayerUI.updateDJMode(isDJMode)
      }

      // Atualizar progresso se necessário
      if (
        isPlaying &&
        miniPlayerVisible &&
        typeof window.player !== "undefined" &&
        window.player &&
        window.player.getCurrentTime &&
        window.player.getDuration
      ) {
        try {
          const currentTime = window.player.getCurrentTime()
          const duration = window.player.getDuration()

          if (currentTime && duration) {
            const progress = (currentTime / duration) * 100
            MiniPlayerUI.updateProgress(progress)
          }
        } catch (error) {
          // Ignorar erros silenciosamente
        }
      }
    }
  }, 1000) // NOVO: Verificar a cada 1 segundo para resposta mais rápida

  // NOVO: Sistema de controles do mini player
  console.log("🎵 Mini player controls inicializados")

  // Event listeners para os controles do mini player
  setupMiniPlayerControls()
})

function setupMiniPlayerControls() {
  // Botão de play/pause do mini player
  const miniPlayPauseBtn = document.getElementById("mini-play-pause")
  if (miniPlayPauseBtn) {
    miniPlayPauseBtn.addEventListener("click", (e) => {
      e.stopPropagation()
      console.log("🎵 Mini player play/pause clicado")

      // Enviar callback para o Lua
      if (typeof window.invokeNative === "function") {
        window.invokeNative("miniPlayerPlayPause", {})
      } else {
        // Fallback para desenvolvimento
        if (typeof MiniPlayer !== "undefined") {
          MiniPlayer.togglePlayPause()
        }
      }
    })
  }

  // Botão anterior do mini player
  const miniPreviousBtn = document.getElementById("mini-prev")
  if (miniPreviousBtn) {
    miniPreviousBtn.addEventListener("click", (e) => {
      e.stopPropagation()
      console.log("🎵 Mini player anterior clicado")

      // Enviar callback para o Lua
      if (typeof window.invokeNative === "function") {
        window.invokeNative("miniPlayerPrevious", {})
      } else {
        // Fallback para desenvolvimento
        if (typeof MiniPlayer !== "undefined") {
          MiniPlayer.previousTrack()
        }
      }
    })
  }

  // Botão próximo do mini player
  const miniNextBtn = document.getElementById("mini-next")
  if (miniNextBtn) {
    miniNextBtn.addEventListener("click", (e) => {
      e.stopPropagation()
      console.log("🎵 Mini player próximo clicado")

      // Enviar callback para o Lua
      if (typeof window.invokeNative === "function") {
        window.invokeNative("miniPlayerNext", {})
      } else {
        // Fallback para desenvolvimento
        if (typeof MiniPlayer !== "undefined") {
          MiniPlayer.nextTrack()
        }
      }
    })
  }

  // Clique no mini player para abrir interface principal
  const miniPlayerElement = document.getElementById("mini-player")
  if (miniPlayerElement) {
    miniPlayerElement.addEventListener("click", (e) => {
      // Só abrir se não clicou em um botão de controle
      if (!e.target.closest("button")) {
        console.log("🎵 Mini player clicado - abrindo interface principal")

        // Enviar comando para abrir interface
        if (typeof window.invokeNative === "function") {
          window.invokeNative("openMusicInterface", {})
        }
      }
    })
  }

  console.log("✅ Controles do mini player configurados")
}

// Função para atualizar o estado visual dos botões
function updateMiniPlayerButtons(isPlaying) {
  const playPauseBtn = document.getElementById("mini-play-pause")
  if (!playPauseBtn) return

  const playIcon = playPauseBtn.querySelector(".play-icon")
  const pauseIcon = playPauseBtn.querySelector(".pause-icon")

  if (isPlaying) {
    if (playIcon) playIcon.style.display = "none"
    if (pauseIcon) pauseIcon.style.display = "block"
  } else {
    if (playIcon) playIcon.style.display = "block"
    if (pauseIcon) pauseIcon.style.display = "none"
  }
}

// Expor função para uso externo
window.updateMiniPlayerButtons = updateMiniPlayerButtons

console.log("🎵 Sistema de Mini Player inicializado!")

// Exportar para uso global
window.MiniPlayerUI = MiniPlayerUI

// Detectar redimensionamento da janela para reposicionar mini player
window.addEventListener("resize", () => {
  if (miniPlayerVisible) {
    // Aguardar um pouco para o layout se estabilizar
    setTimeout(() => {
      // Verificar se mini player ainda está visível na tela
      const rect = miniPlayer.getBoundingClientRect()
      const windowWidth = window.innerWidth
      const windowHeight = window.innerHeight

      // Se mini player saiu da tela, reposicionar
      if (rect.right > windowWidth || rect.bottom > windowHeight || rect.left < 0 || rect.top < 0) {
        miniPlayer.style.top = "20px"
        miniPlayer.style.right = "20px"
        miniPlayer.style.left = "auto"
        miniPlayer.style.bottom = "auto"
      }
    }, 100)
  }
})

// Salvar posição do mini player no localStorage (funcionalidade futura)
function saveMiniPlayerPosition() {
  if (miniPlayerVisible) {
    const rect = miniPlayer.getBoundingClientRect()
    const position = {
      top: rect.top,
      right: window.innerWidth - rect.right,
    }

    try {
      localStorage.setItem("miniPlayerPosition", JSON.stringify(position))
    } catch (error) {
      console.warn("Não foi possível salvar posição do mini player:", error)
    }
  }
}

// Restaurar posição do mini player (funcionalidade futura)
function restoreMiniPlayerPosition() {
  try {
    const savedPosition = localStorage.getItem("miniPlayerPosition")
    if (savedPosition) {
      const position = JSON.parse(savedPosition)
      miniPlayer.style.top = `${position.top}px`
      miniPlayer.style.right = `${position.right}px`
    }
  } catch (error) {
    console.warn("Não foi possível restaurar posição do mini player:", error)
  }
}
;(() => {
  try {
    const enabled = localStorage.getItem('foxzin_debug') === 'true'
    const noop = function () {}
    if (!enabled) {
      console.log = noop
      console.info = noop
      console.warn = noop
    }
  } catch (_) {}
})()

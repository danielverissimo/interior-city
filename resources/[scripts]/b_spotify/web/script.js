let isPlaying = false
let player
let ambientPlayer = null
let currentVideoId = null
let isDragging = false
let currentX
let currentY
let initialX
let initialY
let xOffset = 0
let yOffset = 0
let currentTrackIndex = 0
let playlist = []
let savedVolume = 100
let trackHistory = []

// Adicionar variáveis para gerenciar múltiplos players
const externalPlayers = {} // Objeto para armazenar players externos por ID
const gainNodes = {} // Nós de ganho para controle de volume
const panNodes = {} // Nós de panorama para posicionamento estéreo

// NOVO: Variáveis para sistema de DJ e mute
const djPlayers = {} // Players de DJ
const djGainNodes = {} // Nós de ganho para DJ
const djPanNodes = {} // Nós de panorama para DJ
let userId = null // ID do usuário para operações com o banco de dados
let isDJMode = false // Modo DJ ativo
let currentDJStation = null // Mesa de DJ atual
let isGlobalMuted = false // Status de mute global
let audioContext // Declarar audioContext
let currentPlaylistId = null // ID da playlist atualmente aberta

// Implementar função showPlaylistSelector que estava faltando
function showPlaylistSelector(videoId) {
  console.log("Abrindo seletor de playlist para vídeo:", videoId)
  
  const modal = document.getElementById("playlist-modal")
  if (!modal) {
    console.error("Modal de playlist não encontrado")
    return
  }
  
  // Mostrar o modal
  modal.style.display = "flex"
  
  // Carregar playlists do usuário
  loadPlaylistsForModal()
  // Se já tivermos playlists em cache, popular imediatamente
  try {
    if (Array.isArray(dataCache?.favoritos) && dataCache.favoritos.length > 0) {
      populatePlaylistModal(dataCache.favoritos)
    }
  } catch (e) {
    console.warn("Não foi possível popular modal a partir do cache:", e)
  }
  
  // Armazenar o videoId para uso posterior
  modal.dataset.videoId = videoId
}

// NOVO: Configurar ações do now-playing (favoritar e adicionar à playlist)
function setupNowPlayingActions() {
  try {
    const nowPlaying = document.querySelector('.now-playing')
    const favoriteBtn = document.querySelector('.now-playing-actions .favorite')
    const addBtn = document.querySelector('.now-playing-actions .add-to-playlist')

    if (!favoriteBtn && !addBtn) return

    // Remover possíveis listeners duplicados
    favoriteBtn?.replaceWith(favoriteBtn.cloneNode(true))
    addBtn?.replaceWith(addBtn.cloneNode(true))

    const refreshedFavoriteBtn = document.querySelector('.now-playing-actions .favorite')
    const refreshedAddBtn = document.querySelector('.now-playing-actions .add-to-playlist')

    refreshedFavoriteBtn?.addEventListener('click', (e) => {
      e.stopPropagation()

      if (!currentVideoId || !player || !player.getVideoData) {
        showNotification('Nenhuma música tocando no momento', 'warning')
        return
      }

      const isActive = refreshedFavoriteBtn.classList.contains('active')
      const data = player.getVideoData() || {}
      const title = nowPlaying?.dataset.title || data.title || 'Música'
      const duration = nowPlaying?.dataset.duration || formatTime(player.getDuration())
      const videoId = nowPlaying?.dataset.videoId || currentVideoId

      refreshedFavoriteBtn.classList.toggle('active')

      const action = isActive ? 'removida dos' : 'adicionada aos'
      showNotification(`Música ${action} favoritos`, isActive ? 'info' : 'success')

      fetch(`https://${safeGetParentResourceName()}/toggleFavorite`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          videoId,
          id: videoId,
          title,
          thumbnail: getOptimizedThumbnail(videoId, 'medium'),
          duration,
        }),
      }).catch((error) => {
        console.error('Erro ao favoritar (now-playing):', error)
        // Reverter estado
        refreshedFavoriteBtn.classList.toggle('active')
        showNotification('Erro ao favoritar música', 'error')
      })
    })

    refreshedAddBtn?.addEventListener('click', (e) => {
      e.stopPropagation()

      const videoId = nowPlaying?.dataset.videoId || currentVideoId
      if (!videoId) {
        showNotification('Nenhuma música selecionada para adicionar', 'warning')
        return
      }

      if (typeof showPlaylistSelector === 'function') {
        showPlaylistSelector(videoId)
      } else {
        console.error('Função showPlaylistSelector não encontrada')
        showNotification('Não foi possível abrir o seletor de playlist', 'error')
      }
    })
  } catch (err) {
    console.error('Erro ao configurar ações do now-playing:', err)
  }
}

// Função para carregar playlists no modal
function loadPlaylistsForModal() {
  console.log("Carregando playlists para o modal...")
  
  fetch(`https://${safeGetParentResourceName()}/getPlaylists`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({}),
  })
  .then(() => {
    // As playlists serão recebidas via evento 'playlists' e processadas automaticamente
    console.log("Solicitação de playlists enviada")
  })
  .catch((error) => console.error("Erro ao carregar playlists:", error))
}

// Função para popular o modal com as playlists
function populatePlaylistModal(playlists) {
  const playlistsList = document.querySelector("#playlist-modal .playlists-list")
  if (!playlistsList) return
  
  if (!Array.isArray(playlists) || playlists.length === 0) {
    playlistsList.innerHTML = `
      <div class="empty-playlists">
        <p>Você ainda não criou nenhuma playlist.</p>
        <p>Use o formulário abaixo para criar sua primeira playlist.</p>
      </div>
    `
    return
  }
  
  playlistsList.innerHTML = playlists.map(playlist => `
    <div class="playlist-item" data-playlist-id="${playlist.id}" style="display:flex;align-items:center;gap:10px;padding:10px;border-radius:8px;background-color:rgba(255,255,255,0.05);border:1px solid rgba(255,255,255,0.1);">
      <div class="playlist-icon" style="width:40px;height:40px;border-radius:4px;background:${playlist.thumbnail ? `url('${playlist.thumbnail}') center/cover` : 'rgba(255,255,255,0.1)'};display:flex;align-items:center;justify-content:center;color:#1db954;flex-shrink:0;">
        ${playlist.thumbnail ? '' : '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 18V5l12 13V5M1 5v14l4-4h4"/></svg>'}
      </div>
      <span class="playlist-name" style="flex:1;color:#fff;">${playlist.name}</span>
      <button class="add-to-this-playlist" data-playlist-id="${playlist.id}" style="padding:8px 12px;background-color:#1db954;border:none;border-radius:6px;color:#000;font-weight:600;cursor:pointer;">Adicionar</button>
    </div>
  `).join("")
  
  // Adicionar eventos aos botões de adicionar
  playlistsList.querySelectorAll(".add-to-this-playlist").forEach(btn => {
    btn.addEventListener("click", (e) => {
      e.stopPropagation()
      const playlistId = btn.dataset.playlistId
      const modal = document.getElementById("playlist-modal")
      const videoId = modal.dataset.videoId
      
      if (playlistId && videoId) {
        addVideoToPlaylist(playlistId, videoId)
      }
    })
  })
}

// Função para adicionar vídeo à playlist
function addVideoToPlaylist(playlistId, videoId) {
  console.log(`Adicionando vídeo ${videoId} à playlist ${playlistId}`)
  
  fetch(`https://${safeGetParentResourceName()}/addToPlaylist`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ playlistId, videoId }),
  })
  .then(() => {
    console.log("Vídeo adicionado à playlist com sucesso")
    // Fechar o modal
    const modal = document.getElementById("playlist-modal")
    if (modal) {
      modal.style.display = "none"
    }
    
    // Mostrar feedback visual (opcional)
    showNotification("Música adicionada à playlist!")
  })
  .catch((error) => {
    console.error("Erro ao adicionar vídeo à playlist:", error)
    showNotification("Erro ao adicionar música à playlist", "error")
  })
}

// Função para mostrar notificações
function showNotification(message, type = "success") {
  // Criar elemento de notificação
  const notification = document.createElement("div")
  notification.className = `notification ${type}`
  notification.textContent = message
  notification.style.cssText = `
    position: fixed;
    top: 20px;
    right: 20px;
    background: ${type === "error" ? "#ff4444" : "#00ff88"};
    color: white;
    padding: 12px 20px;
    border-radius: 8px;
    z-index: 10000;
    font-weight: 500;
    box-shadow: 0 4px 12px rgba(0,0,0,0.3);
    transform: translateX(100%);
    transition: transform 0.3s ease;
  `
  
  document.body.appendChild(notification)
  
  // Animar entrada
  setTimeout(() => {
    notification.style.transform = "translateX(0)"
  }, 100)
  
  // Remover após 3 segundos
  setTimeout(() => {
    notification.style.transform = "translateX(100%)"
    setTimeout(() => {
      if (notification.parentNode) {
        notification.parentNode.removeChild(notification)
      }
    }, 300)
  }, 3000)
}

// Função showPlaylistSelector é global por declaração de função; não precisa de atribuição

// NOVO: Variáveis para mini player
let miniPlayerVisible = false
let miniCurrentTrackData = null
let miniIsPlaying = false

// CORRIGIDO: Variáveis de controle de abas e carregamento
let currentTab = "musicas" // Controlar aba atual
const isDataLoaded = {
  musicas: false,
  favoritos: false,
  curtidas: false,
}

// Cache de dados para evitar recarregamentos desnecessários
const dataCache = {
  musicas: [],
  favoritos: [],
  curtidas: [],
}

// OTIMIZAÇÃO: Cache de thumbnails para carregamento mais rápido
const thumbnailCache = new Map()
const imagePreloader = new Map()

// OTIMIZAÇÃO: Pool de imagens para reutilização
const imagePool = []
const MAX_POOL_SIZE = 50

// CORREÇÃO: Verificar se estamos no ambiente FiveM
const isFiveMEnvironment = () => {
  return (
    typeof window !== "undefined" &&
    typeof window.GetParentResourceName === "function" &&
    typeof window.RegisterNUICallback === "function"
  )
}

// CORREÇÃO: Função segura para RegisterNUICallback
function safeRegisterNUICallback(eventName, callback) {
  if (isFiveMEnvironment()) {
    try {
      window.RegisterNUICallback(eventName, callback)
      console.log(`✅ Callback registrado: ${eventName}`)
    } catch (error) {
      console.error(`❌ Erro ao registrar callback ${eventName}:`, error)
    }
  } else {
    console.warn(`⚠️ Ambiente FiveM não detectado, callback ${eventName} não registrado`)
    // Fallback para desenvolvimento web
    window[`nui_${eventName}`] = callback
  }
}

// CORREÇÃO: Função segura para GetParentResourceName
function safeGetParentResourceName() {
  if (isFiveMEnvironment()) {
    try {
      return window.GetParentResourceName()
    } catch (error) {
      console.error("❌ Erro ao obter nome do resource:", error)
      return "b_spotify"
    }
  }
  return "b_spotify" // Fallback
}

// NOVO: Sistema de Mini Player integrado
const MiniPlayer = {
  // CORRIGIDO: Verificar se mini player deve ser mostrado - só se estiver TOCANDO
  shouldShow: () => {
    console.log("🔍 Verificando se deve mostrar mini player:")
    console.log("  - currentVideoId:", currentVideoId)
    console.log("  - isPlaying:", isPlaying)
    console.log("  - player state:", player && player.getPlayerState ? player.getPlayerState() : "N/A")

    // Declare YT here
    const YT = window.YT

    const shouldShow =
      currentVideoId &&
      isPlaying &&
      (!player ||
        !player.getPlayerState ||
        (player.getPlayerState() !== YT.PlayerState.PAUSED && player.getPlayerState() !== YT.PlayerState.ENDED))

    console.log("  - Resultado:", shouldShow)
    return shouldShow
  },

  // Obter dados da faixa atual
  getCurrentTrackData: () => {
    if (!player || !currentVideoId) return null

    try {
      const data = player.getVideoData()
      const currentTrack = playlist.find((track) => track.id === currentVideoId || track.videoId === currentVideoId)

      return {
        videoId: currentVideoId,
        title: data?.title || currentTrack?.title || "Música Desconhecida",
        artist: currentTrack?.author || "Artista Desconhecido",
        thumbnail: getOptimizedThumbnail(currentVideoId, "medium"),
        duration: player.getDuration ? formatTime(player.getDuration()) : "0:00",
      }
    } catch (error) {
      console.error("Erro ao obter dados da faixa:", error)
      return null
    }
  },

  // Mostrar mini player
  show: () => {
    // CORRIGIDO: Verificar se deve mostrar antes de tentar mostrar
    if (!MiniPlayer.shouldShow()) {
      console.log("🚫 Mini player não deve ser mostrado - música não está tocando")
      return
    }

    const trackData = MiniPlayer.getCurrentTrackData()
    if (!trackData) {
      console.log("🚫 Mini player não mostrado - sem dados da faixa")
      return
    }

    console.log("✅ Mostrando mini player:", trackData.title)

    // Tentar via NUI callback primeiro
    if (isFiveMEnvironment()) {
      try {
        fetch(`https://${safeGetParentResourceName()}/showMiniPlayer`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            trackData: trackData,
            djMode: isDJMode && currentDJStation,
            isPlaying: isPlaying,
          }),
        }).catch(console.error)
      } catch (error) {
        console.error("Erro ao mostrar mini player via fetch:", error)
      }
    }

    // Fallback: Mostrar diretamente via NUI
    try {
      const miniPlayerElement = document.getElementById("mini-player")
      if (miniPlayerElement) {
        // Atualizar informações
        const miniTitle = document.getElementById("mini-title")
        const miniArtist = document.getElementById("mini-artist")
        const miniArtwork = document.getElementById("mini-artwork-img")

        if (miniTitle) miniTitle.textContent = trackData.title
        if (miniArtist) miniArtist.textContent = trackData.artist
        if (miniArtwork) miniArtwork.src = trackData.thumbnail

        // Aplicar classes
        miniPlayerElement.classList.toggle("dj-mode", isDJMode && currentDJStation)
        miniPlayerElement.classList.toggle("playing", isPlaying)
        miniPlayerElement.classList.add("visible")

        miniPlayerVisible = true
        miniCurrentTrackData = trackData
        miniIsPlaying = isPlaying

        console.log("✅ Mini player mostrado localmente:", trackData)
      }
    } catch (error) {
      console.error("Erro ao mostrar mini player localmente:", error)
    }
  },

  // Esconder mini player
  hide: () => {
    console.log("🔽 Escondendo mini player")

    // Via callback
    if (isFiveMEnvironment()) {
      try {
        fetch(`https://${safeGetParentResourceName()}/hideMiniPlayer`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({}),
        }).catch(console.error)
      } catch (error) {
        console.error("Erro ao esconder mini player via fetch:", error)
      }
    }

    // Fallback: Esconder diretamente
    try {
      const miniPlayerElement = document.getElementById("mini-player")
      if (miniPlayerElement) {
        miniPlayerElement.classList.remove("visible")
        miniPlayerVisible = false
        console.log("🔽 Mini player escondido localmente")
      }
    } catch (error) {
      console.error("Erro ao esconder mini player localmente:", error)
    }
  },

  // Atualizar estado de reprodução
  updatePlayState: () => {
    if (isFiveMEnvironment()) {
      try {
        fetch(`https://${safeGetParentResourceName()}/updateMiniPlayState`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            isPlaying: isPlaying,
          }),
        }).catch(console.error)
      } catch (error) {
        console.error("Erro ao atualizar estado via fetch:", error)
      }
    }

    // Fallback local
    try {
      const miniPlayerElement = document.getElementById("mini-player")
      const playPauseBtn = document.getElementById("mini-play-pause")

      if (miniPlayerElement) {
        miniPlayerElement.classList.toggle("playing", isPlaying)
      }

      if (playPauseBtn) {
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

      miniIsPlaying = isPlaying
    } catch (error) {
      console.error("Erro ao atualizar estado localmente:", error)
    }
  },

  // Atualizar informações da música
  updateTrack: () => {
    const trackData = MiniPlayer.getCurrentTrackData()
    if (!trackData) return

    if (isFiveMEnvironment()) {
      try {
        fetch(`https://${safeGetParentResourceName()}/updateMiniPlayer`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            trackData: trackData,
            djMode: isDJMode && currentDJStation,
          }),
        }).catch(console.error)
      } catch (error) {
        console.error("Erro ao atualizar track via fetch:", error)
      }
    }

    // Atualizar localmente também
    try {
      const miniTitle = document.getElementById("mini-title")
      const miniArtist = document.getElementById("mini-artist")
      const miniArtwork = document.getElementById("mini-artwork-img")
      const miniPlayerElement = document.getElementById("mini-player")

      if (miniTitle) miniTitle.textContent = trackData.title
      if (miniArtist) miniArtist.textContent = trackData.artist
      if (miniArtwork) miniArtwork.src = trackData.thumbnail
      if (miniPlayerElement) {
        miniPlayerElement.classList.toggle("dj-mode", isDJMode && currentDJStation)
      }

      miniCurrentTrackData = trackData
    } catch (error) {
      console.error("Erro ao atualizar track localmente:", error)
    }
  },

  // NOVO: Função para pausar/tocar via mini player
  togglePlayPause: () => {
    console.log("🎵 Mini player toggle play/pause")

    if (!player || !currentVideoId) {
      console.log("🚫 Player ou videoId não disponível")
      return
    }

    if (isPlaying) {
      // PAUSAR
      player.pauseVideo()
      isPlaying = false

      // Atualizar botão principal
      const playPauseBtn = document.getElementById("play-pause")
      if (playPauseBtn) {
        playPauseBtn.innerHTML = `
          <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
              <path d="M8 5V19L19 12L8 5Z"/>
          </svg>
        `
      }

      // Esconder mini player quando pausar
      MiniPlayer.hide()

      // Enviar comando de pause para o servidor
      if (isDJMode && currentDJStation) {
        MusicSystem.pauseDJTrack({
          stationIndex: currentDJStation.stationIndex,
        })
      } else {
        MusicSystem.pauseTrack()
      }
  } else {
      // TOCAR
      player.playVideo()
      isPlaying = true

      // NOVO: Informar ao client para reanexar o prop ao retomar
      try {
        fetch(`https://${safeGetParentResourceName()}/resumePlayback`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({}),
        }).catch((error) => console.error("Erro ao retomar reprodução (resumePlayback):", error))
      } catch (error) {
        console.error("Erro ao enviar resumePlayback:", error)
      }

      // Atualizar botão principal
      const playPauseBtn = document.getElementById("play-pause")
      if (playPauseBtn) {
        playPauseBtn.innerHTML = `
          <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
              <path d="M6 4h4v16H6V4zm8 0h4v16h-4V4z"/>
          </svg>
        `
      }

      // Atualizar mini player
      MiniPlayer.updatePlayState()
    }
  },

  // NOVO: Função para próxima música via mini player
  nextTrack: () => {
    console.log("🎵 Mini player próxima música")
    playNextTrack()
  },

  // NOVO: Função para música anterior via mini player
  previousTrack: () => {
    console.log("🎵 Mini player música anterior")
    playPreviousTrack()
  },
}

// OTIMIZAÇÃO: Função para obter thumbnail otimizada
function getOptimizedThumbnail(videoId, quality = "mqdefault") {
  // Usar diferentes qualidades baseado na necessidade
  const qualities = {
    low: "default", // 120x90
    medium: "mqdefault", // 320x180
    high: "hqdefault", // 480x360
    max: "maxresdefault", // 1280x720
  }

  const selectedQuality = qualities[quality] || "mqdefault"
  return `https://i.ytimg.com/vi/${videoId}/${selectedQuality}.jpg`
}

// OTIMIZAÇÃO: Precarregar imagens de forma assíncrona
function preloadImage(src, videoId) {
  return new Promise((resolve, reject) => {
    // Verificar cache primeiro
    if (thumbnailCache.has(src)) {
      resolve(thumbnailCache.get(src))
      return
    }

    // Verificar se já está sendo carregada
    if (imagePreloader.has(src)) {
      imagePreloader.get(src).then(resolve).catch(reject)
      return
    }

    // Criar nova promise de carregamento
    const loadPromise = new Promise((imgResolve, imgReject) => {
      const img = new Image()
      img.crossOrigin = "anonymous"

      // Timeout para evitar travamentos
      const timeout = setTimeout(() => {
        imgReject(new Error("Timeout ao carregar imagem"))
      }, 3000)

      img.onload = () => {
        clearTimeout(timeout)
        thumbnailCache.set(src, src)
        imagePreloader.delete(src)
        imgResolve(src)
      }

      img.onerror = () => {
        clearTimeout(timeout)
        imagePreloader.delete(src)
        // Fallback para qualidade menor
        const fallbackSrc = getOptimizedThumbnail(videoId, "low")
        if (fallbackSrc !== src) {
          preloadImage(fallbackSrc, videoId).then(imgResolve).catch(imgReject)
        } else {
          imgReject(new Error("Falha ao carregar imagem"))
        }
      }

      img.src = src
    })

    imagePreloader.set(src, loadPromise)
    loadPromise.then(resolve).catch(reject)
  })
}

// OTIMIZAÇÃO: Lazy loading para imagens
function setupLazyLoading() {
  // Verificar se IntersectionObserver está disponível
  if (!window.IntersectionObserver) {
    console.warn("⚠️ IntersectionObserver não suportado, usando carregamento direto")
    return {
      observe: (img) => {
        // Fallback: carregar imagem diretamente
        const src = img.dataset.src
        const videoId = img.dataset.videoId
        if (src && videoId) {
          preloadImage(src, videoId)
            .then((loadedSrc) => {
              img.src = loadedSrc
              img.classList.add("loaded")
            })
            .catch(() => {
              img.src = getOptimizedThumbnail(videoId, "low")
              img.classList.add("loaded")
            })
        }
      },
      unobserve: () => {}, // Noop
    }
  }

  const imageObserver = new IntersectionObserver(
    (entries, observer) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          const img = entry.target
          const videoId = img.dataset.videoId
          const src = img.dataset.src

          if (src && videoId) {
            preloadImage(src, videoId)
              .then((loadedSrc) => {
                img.src = loadedSrc
                img.classList.add("loaded")
              })
              .catch(() => {
                img.src = getOptimizedThumbnail(videoId, "low")
                img.classList.add("loaded")
              })
          }

          observer.unobserve(img)
        }
      })
    },
    {
      rootMargin: "50px", // Carregar 50px antes de aparecer
    },
  )

  return imageObserver
}

// Carrega histórico do localStorage
try {
  const savedHistory = localStorage.getItem("trackHistory")
  if (savedHistory) {
    trackHistory = JSON.parse(savedHistory)
    playlist = trackHistory
  }
} catch (error) {
  console.error("Erro ao carregar histórico:", error)
  trackHistory = []
}

// CORREÇÃO: Inicializar Web Audio API com verificações
function initAudioContext() {
  try {
    // Verificar se AudioContext está disponível
    if (!window.AudioContext && !window.webkitAudioContext) {
      console.warn("⚠️ AudioContext não suportado neste navegador")
      return
    }

    audioContext = new (window.AudioContext || window.webkitAudioContext)()
    console.log("✅ Contexto de áudio inicializado")

    // Verificar se o contexto foi suspenso (política do navegador)
    if (audioContext.state === "suspended") {
      console.log("🔊 Contexto de áudio suspenso, será ativado na primeira interação")
    }
  } catch (e) {
    console.error("❌ Falha na inicialização do contexto de áudio:", e)
  }
}

// CORREÇÃO: Função para ativar contexto de áudio na primeira interação
function resumeAudioContext() {
  if (audioContext && audioContext.state === "suspended") {
    audioContext
      .resume()
      .then(() => {
        console.log("✅ Contexto de áudio ativado")
      })
      .catch((error) => {
        console.error("❌ Erro ao ativar contexto de áudio:", error)
      })
  }
}

// CORRIGIDO: Função para criar um player de DJ com volume correto
function createDJPlayer(stationId, videoId) {
  const YT = window.YT
  if (djPlayers[stationId]) {
    console.log(`Atualizando player de DJ ${stationId} para o vídeo ${videoId}`)

    if (
      djPlayers[stationId].player &&
      djPlayers[stationId].player.getPlayerState &&
      djPlayers[stationId].player.getPlayerState() === YT.PlayerState.PLAYING
    ) {
      djPlayers[stationId].player.pauseVideo()
    }

    djPlayers[stationId].player.loadVideoById(videoId)
    djPlayers[stationId].videoId = videoId
    return
  }

  console.log(`Criando novo player de DJ para estação ${stationId}, vídeo ${videoId}`)

  const playerContainer = document.createElement("div")
  playerContainer.id = `youtube-dj-player-${stationId}`
  playerContainer.style.display = "none"
  document.body.appendChild(playerContainer)

  const newPlayer = new YT.Player(`youtube-dj-player-${stationId}`, {
    height: "0",
    width: "0",
    videoId: videoId,
    playerVars: {
      playsinline: 1,
      controls: 0,
      mute: 0,
    },
    events: {
      onReady: (event) => onDJPlayerReady(event, stationId),
      onStateChange: (event) => onDJPlayerStateChange(event, stationId),
    },
  })

  if (audioContext) {
    try {
      djGainNodes[stationId] = audioContext.createGain()
      djGainNodes[stationId].gain.value = 1.0 // CORRIGIDO: Volume inicial 100%

      djPanNodes[stationId] = audioContext.createStereoPanner()
      djPanNodes[stationId].pan.value = 0

      djGainNodes[stationId].connect(djPanNodes[stationId])
      djPanNodes[stationId].connect(audioContext.destination)
    } catch (error) {
      console.error("❌ Erro ao criar nós de áudio para DJ:", error)
    }
  }

  djPlayers[stationId] = {
    player: newPlayer,
    videoId: videoId,
    volume: 100, // CORRIGIDO: Volume inicial 100%
    pan: 0,
    container: playerContainer,
  }
}

// CORRIGIDO: Evento quando um player de DJ está pronto
function onDJPlayerReady(event, stationId) {
  console.log(`Player de DJ ${stationId} pronto`)

  if (!djPlayers[stationId]) return

  try {
    // CORRIGIDO: Definir volume inicial como 100 (não 0)
    event.target.setVolume(100)
    event.target.playVideo()

    console.log(`🎧 Player DJ ${stationId} iniciado com volume 100%`)
  } catch (error) {
    console.error(`❌ Erro ao configurar player DJ ${stationId}:`, error)
  }
}

// NOVO: Evento quando o estado de um player de DJ muda
function onDJPlayerStateChange(event, stationId) {
  console.log(`Estado do player de DJ ${stationId} mudou para ${event.data}`)

  if (!djPlayers[stationId]) return

  try {
    const YT = window.YT
    if (event.data === YT.PlayerState.ENDED) {
      event.target.playVideo()
    }
  } catch (error) {
    console.error(`❌ Erro no player DJ ${stationId}:`, error)
  }
}

// CORRIGIDO: Função para atualizar volume e pan de um player de DJ
function updateDJPlayer(stationId, volume, pan) {
  if (!djPlayers[stationId]) return

  console.log(`🎧 Atualizando DJ ${stationId} - Volume: ${volume}%, Pan: ${pan}`)

  djPlayers[stationId].volume = volume
  djPlayers[stationId].pan = pan

  try {
    if (djPlayers[stationId].player && djPlayers[stationId].player.setVolume) {
      const finalVolume = isGlobalMuted ? 0 : volume
      djPlayers[stationId].player.setVolume(finalVolume)
      console.log(`🎧 Volume aplicado no player DJ: ${finalVolume}%`)
    }

    if (audioContext) {
      if (djGainNodes[stationId]) {
        djGainNodes[stationId].gain.value = isGlobalMuted ? 0 : volume / 100
      }

      if (djPanNodes[stationId]) {
        djPanNodes[stationId].pan.value = pan
      }
    }
  } catch (error) {
    console.error(`❌ Erro ao atualizar player DJ ${stationId}:`, error)
  }

  updateAmbientSourcesList()
}

// NOVO: Função para remover um player de DJ
function removeDJPlayer(stationId) {
  if (!djPlayers[stationId]) return

  console.log(`Removendo player de DJ ${stationId}`)

  try {
    if (djPlayers[stationId].player) {
      djPlayers[stationId].player.stopVideo()
      djPlayers[stationId].player.destroy()
    }

    if (audioContext) {
      if (djGainNodes[stationId]) {
        djGainNodes[stationId].disconnect()
        delete djGainNodes[stationId]
      }

      if (djPanNodes[stationId]) {
        djPanNodes[stationId].disconnect()
        delete djPanNodes[stationId]
      }
    }

    if (djPlayers[stationId].container) {
      djPlayers[stationId].container.remove()
    }

    delete djPlayers[stationId]
  } catch (error) {
    console.error(`❌ Erro ao remover player DJ ${stationId}:`, error)
  }

  updateAmbientSourcesList()
}

// Função para criar um novo player externo
function createExternalPlayer(sourceId, videoId) {
  const YT = window.YT
  if (externalPlayers[sourceId]) {
    console.log(`Atualizando player externo ${sourceId} para o vídeo ${videoId}`)

    if (
      externalPlayers[sourceId].player &&
      externalPlayers[sourceId].player.getPlayerState &&
      externalPlayers[sourceId].player.getPlayerState() === YT.PlayerState.PLAYING
    ) {
      externalPlayers[sourceId].player.pauseVideo()
    }

    externalPlayers[sourceId].player.loadVideoById(videoId)
    // Garantir que o vídeo comece a tocar ao atualizar um player existente
    try {
      // Alguns estados retornam CUED/UNSTARTED após loadVideoById; forçar play ajuda o sync
      externalPlayers[sourceId].player.playVideo()
    } catch (err) {
      console.warn(`Não foi possível iniciar reprodução automática do player externo ${sourceId}:`, err)
    }
    externalPlayers[sourceId].videoId = videoId
    return
  }

  console.log(`Criando novo player externo para fonte ${sourceId}, vídeo ${videoId}`)

  const playerContainer = document.createElement("div")
  playerContainer.id = `youtube-player-${sourceId}`
  playerContainer.style.display = "none"
  document.body.appendChild(playerContainer)

  const newPlayer = new YT.Player(`youtube-player-${sourceId}`, {
    height: "0",
    width: "0",
    videoId: videoId,
    playerVars: {
      playsinline: 1,
      controls: 0,
      mute: 0,
    },
    events: {
      onReady: (event) => onExternalPlayerReady(event, sourceId),
      onStateChange: (event) => onExternalPlayerStateChange(event, sourceId),
    },
  })

  if (audioContext) {
    try {
      gainNodes[sourceId] = audioContext.createGain()
      gainNodes[sourceId].gain.value = 0.5

      panNodes[sourceId] = audioContext.createStereoPanner()
      panNodes[sourceId].pan.value = 0

      gainNodes[sourceId].connect(panNodes[sourceId])
      panNodes[sourceId].connect(audioContext.destination)
    } catch (error) {
      console.error("❌ Erro ao criar nós de áudio externos:", error)
    }
  }

  externalPlayers[sourceId] = {
    player: newPlayer,
    videoId: videoId,
    volume: 50,
    pan: 0,
    container: playerContainer,
  }
}

// Evento quando um player externo está pronto
function onExternalPlayerReady(event, sourceId) {
  console.log(`Player externo ${sourceId} pronto`)

  if (!externalPlayers[sourceId]) return

  try {
    event.target.setVolume(0)
    event.target.playVideo()
  } catch (error) {
    console.error(`❌ Erro no player externo ${sourceId}:`, error)
  }
}

// Evento quando o estado de um player externo muda
function onExternalPlayerStateChange(event, sourceId) {
  console.log(`Estado do player externo ${sourceId} mudou para ${event.data}`)

  if (!externalPlayers[sourceId]) return

  try {
    const YT = window.YT
    // Forçar reprodução quando o player entra em estados preparados
    if (
      event.data === YT.PlayerState.CUED ||
      event.data === YT.PlayerState.UNSTARTED
    ) {
      event.target.playVideo()
      return
    }

    if (event.data === YT.PlayerState.ENDED) {
      event.target.playVideo()
    }
  } catch (error) {
    console.error(`❌ Erro no player externo ${sourceId}:`, error)
  }
}

// Função para atualizar volume e pan de um player externo
function updateExternalPlayer(sourceId, volume, pan) {
  if (!externalPlayers[sourceId]) return

  externalPlayers[sourceId].volume = volume
  externalPlayers[sourceId].pan = pan

  try {
    if (externalPlayers[sourceId].player && externalPlayers[sourceId].player.setVolume) {
      externalPlayers[sourceId].player.setVolume(isGlobalMuted ? 0 : volume)
    }

    if (audioContext) {
      if (gainNodes[sourceId]) {
        gainNodes[sourceId].gain.value = isGlobalMuted ? 0 : volume / 100
      }

      if (panNodes[sourceId]) {
        panNodes[sourceId].pan.value = pan
      }
    }
  } catch (error) {
    console.error(`❌ Erro ao atualizar player externo ${sourceId}:`, error)
  }

  updateAmbientSourcesList()
}

// Função para remover um player externo
function removeExternalPlayer(sourceId) {
  if (!externalPlayers[sourceId]) return

  console.log(`Removendo player externo ${sourceId}`)

  try {
    if (externalPlayers[sourceId].player) {
      externalPlayers[sourceId].player.stopVideo()
      externalPlayers[sourceId].player.destroy()
    }

    if (audioContext) {
      if (gainNodes[sourceId]) {
        gainNodes[sourceId].disconnect()
        delete gainNodes[sourceId]
      }

      if (panNodes[sourceId]) {
        panNodes[sourceId].disconnect()
        delete panNodes[sourceId]
      }
    }

    if (externalPlayers[sourceId].container) {
      externalPlayers[sourceId].container.remove()
    }

    delete externalPlayers[sourceId]
  } catch (error) {
    console.error(`❌ Erro ao remover player externo ${sourceId}:`, error)
  }

  updateAmbientSourcesList()
}

// Função para atualizar a lista de fontes ambientes
function updateAmbientSourcesList() {
  const sourcesList = document.querySelector(".ambient-sources-list")
  if (!sourcesList) return

  sourcesList.innerHTML = ""

  const hasExternalSources = Object.keys(externalPlayers).length > 0
  const hasDJSources = Object.keys(djPlayers).length > 0
  const hasSources = hasExternalSources || hasDJSources

  const ambientSources = document.querySelector(".ambient-sources")
  const ambientIndicator = document.querySelector(".ambient-indicator")

  if (ambientSources) ambientSources.classList.toggle("active", hasSources)
  if (ambientIndicator) ambientIndicator.style.display = hasSources ? "flex" : "none"

  for (const sourceId in externalPlayers) {
    const sourceData = externalPlayers[sourceId]
    const sourceElement = document.createElement("div")
    sourceElement.className = "ambient-source"
    sourceElement.innerHTML = `
            <div class="ambient-title" title="${sourceData.title || "Música Desconhecida"}">
                🎵 ${sourceData.title || "Música Desconhecida"}
            </div>
            <div class="ambient-volume">
                Volume: ${Math.round(sourceData.volume)}%
            </div>
        `
    sourcesList.appendChild(sourceElement)
  }

  for (const stationId in djPlayers) {
    const djData = djPlayers[stationId]
    const sourceElement = document.createElement("div")
    sourceElement.className = "ambient-source dj-source"
    sourceElement.innerHTML = `
            <div class="ambient-title" title="${djData.title || "DJ Desconhecido"}">
                🎧 DJ: ${djData.title || "Música Desconhecida"}
            </div>
            <div class="ambient-volume">
                Volume: ${Math.round(djData.volume)}%
            </div>
        `
    sourcesList.appendChild(sourceElement)
  }
}

function saveToHistory(track) {
  if (!track || !track.videoId) return

  trackHistory = trackHistory.filter((t) => t.videoId !== track.videoId)

  const historyTrack = {
    videoId: track.videoId,
    id: track.videoId,
    title: track.title,
    thumbnail: getOptimizedThumbnail(track.videoId, "medium"),
    duration: track.duration,
  }

  trackHistory.unshift(historyTrack)
  trackHistory = trackHistory.slice(0, 100)

  try {
    localStorage.setItem("trackHistory", JSON.stringify(trackHistory))
    playlist = trackHistory
  } catch (error) {
    console.error("Erro ao salvar histórico:", error)
  }
}

function loadYouTubeAPI() {
  if (window.YT) return

  const tag = document.createElement("script")
  tag.src = "https://www.youtube.com/iframe_api"
  const firstScriptTag = document.getElementsByTagName("script")[0]
  firstScriptTag.parentNode.insertBefore(tag, firstScriptTag)
}

function onYouTubeIframeAPIReady() {
  try {
    player = new YT.Player("youtube-player", {
      height: "0",
      width: "0",
      playerVars: {
        playsinline: 1,
        controls: 0,
        enablejsapi: 1,
      },
      events: {
        onStateChange: onPlayerStateChange,
        onReady: onPlayerReady,
      },
    })

    if (!player.setStereoPan) {
      player.setStereoPan = (pan) => {
        const audioElement = document.querySelector("#youtube-player audio")
        if (audioElement) {
          try {
            const audioContext = new (window.AudioContext || window.webkitAudioContext)()
            const source = audioContext.createMediaElementSource(audioElement)
            const panNode = audioContext.createStereoPanner()

            source.connect(panNode)
            panNode.connect(audioContext.destination)
            panNode.pan.value = pan
          } catch (error) {
            console.error("Erro no stereo pan:", error)
          }
        }
      }
    }

    // Inicializar player ambiente para o fundo do Expanded Player
    const ambientEl = document.getElementById("ep-ambient")
    if (ambientEl && typeof YT !== "undefined" && YT.Player) {
      try {
        ambientPlayer = new YT.Player("ep-ambient", {
          height: "100%",
          width: "100%",
          playerVars: {
            playsinline: 1,
            controls: 0,
            disablekb: 1,
            fs: 0,
            rel: 0,
            modestbranding: 1,
          },
          events: {
            onReady: (e) => {
              try {
                e.target.mute()
                if (currentVideoId) {
                  e.target.loadVideoById(currentVideoId)
                  e.target.playVideo()
                }
              } catch (_) {}
            },
          },
        })
      } catch (error) {
        console.error("❌ Erro ao inicializar ambient player:", error)
      }
    }
  } catch (error) {
    console.error("❌ Erro ao inicializar YouTube player:", error)
  }
}

function onPlayerReady(event) {
  if (!player) return

  try {
    const volume = Math.max(0, Math.min(savedVolume || 50, 100))
    player.setVolume(isGlobalMuted ? 0 : volume)

    // Atualiza todos os sliders de volume (mini e expandido)
    document.querySelectorAll(".volume-slider, .ep-volume-slider").forEach((s) => {
      s.value = volume
      if (typeof updateSliderBackground === "function") updateSliderBackground(s)
    })
    const epVolValue = document.querySelector(".ep-volume-value")
    if (epVolValue) epVolValue.textContent = `${Math.round(volume)}%`
    if (typeof updateVolumeIcon === "function") updateVolumeIcon(volume)
  } catch (error) {
    console.error("❌ Erro no onPlayerReady:", error)
  }
}

function updateVolumeIcon(volume) {
  const volumeBtn = document.querySelector(".volume-btn")
  if (!volumeBtn) return

  const svgMuted = `
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor">
        <path d="M11 5L6 9H2V15H6L11 19V5Z" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>
    `

  const svgLowVolume = `
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor">
        <path d="M11 5L6 9H2V15H6L11 19V5Z" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        <path d="M14 9L19 14M19 9L14 14" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>
    `

  const svgHighVolume = `
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor">
        <path d="M11 5L6 9H2V15H6L11 19V5Z" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        <path d="M14 9L19 14M19 9L14 14" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        <path d="M18 6.7C19.3 8.1 20 10 20 12C20 14 19.3 15.9 18 17.3" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>
    `

  if (volume === 0 || isGlobalMuted) {
    volumeBtn.innerHTML = svgMuted
  } else if (volume < 50) {
    volumeBtn.innerHTML = svgLowVolume
  } else {
    volumeBtn.innerHTML = svgHighVolume
  }
}

function playVideo(videoId) {
  if (!player || !videoId) return

  try {
    currentVideoId = videoId
    player.loadVideoById(videoId)
    isPlaying = true

    // Sincronizar vídeo ambiente no fundo
    try {
      if (ambientPlayer && typeof ambientPlayer.loadVideoById === "function") {
        ambientPlayer.mute()
        ambientPlayer.loadVideoById(videoId)
        ambientPlayer.playVideo()
      }
    } catch (_) {}

    const playPauseBtn = document.getElementById("play-pause")
    if (playPauseBtn) {
      playPauseBtn.innerHTML = `
                <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M6 4h4v16H6V4zm8 0h4v16h-4V4z"/>
                </svg>
            `
    }

    // NOVO: Atualizar mini player se estiver ativo
    if (miniPlayerVisible) {
      MiniPlayer.updatePlayState()
      MiniPlayer.updateTrack()
    }

    // NOVO: Abrir player expandido automaticamente ao iniciar reprodução
    if (typeof ExpandedPlayer !== "undefined") {
      ExpandedPlayer.show()
    }
  } catch (error) {
    console.error("Erro ao reproduzir vídeo:", error)
  }
}

// CORRIGIDO: Função playNextTrack que detecta modo DJ
function playNextTrack() {
  if (!playlist || !Array.isArray(playlist) || playlist.length === 0) return

  try {
    currentTrackIndex = (currentTrackIndex + 1) % playlist.length
    const nextTrack = playlist[currentTrackIndex]

    if (nextTrack && nextTrack.id) {
      playVideo(nextTrack.id)
      updateNowPlaying()

      const trackData = {
        videoId: nextTrack.id,
        title: nextTrack.title,
        thumbnail: nextTrack.thumbnail,
        duration: nextTrack.duration,
      }

      if (isDJMode && currentDJStation) {
        // MODO DJ
        trackData.stationIndex = currentDJStation.stationIndex
        trackData.stationData = currentDJStation.stationData

        MusicSystem.playDJTrack(trackData).catch((error) => console.error("Erro ao tocar próxima faixa DJ:", error))
      } else {
        // MODO NORMAL
        fetch(`https://${safeGetParentResourceName()}/playTrack`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(trackData),
        }).catch((error) => console.error("Erro ao tocar próxima faixa:", error))
      }
    }
  } catch (error) {
    console.error("Erro ao reproduzir próxima faixa:", error)
  }
}

function playPreviousTrack() {
  if (!playlist || !Array.isArray(playlist) || playlist.length === 0) return

  try {
    currentTrackIndex = (currentTrackIndex - 1 + playlist.length) % playlist.length
    const prevTrack = playlist[currentTrackIndex]

    if (prevTrack && prevTrack.id) {
      playVideo(prevTrack.id)
      updateNowPlaying()

      const trackData = {
        videoId: prevTrack.id,
        title: prevTrack.title,
        thumbnail: prevTrack.thumbnail,
        duration: prevTrack.duration,
      }

      if (isDJMode && currentDJStation) {
        // MODO DJ
        trackData.stationIndex = currentDJStation.stationIndex
        trackData.stationData = currentDJStation.stationData

        MusicSystem.playDJTrack(trackData).catch((error) => console.error("Erro ao tocar faixa anterior DJ:", error))
      } else {
        // MODO NORMAL
        fetch(`https://${safeGetParentResourceName()}/playTrack`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(trackData),
        }).catch((error) => console.error("Erro ao tocar faixa anterior:", error))
      }
    }
  } catch (error) {
    console.error("Erro ao reproduzir faixa anterior:", error)
  }
}

function onPlayerStateChange(event) {
  if (!event) return

  try {
    const YT = window.YT
    if (event.data === YT.PlayerState.ENDED) {
      playNextTrack()
    } else if (event.data === YT.PlayerState.PLAYING) {
      isPlaying = true
      updateNowPlaying()
      // NOVO: Atualizar mini player
      if (miniPlayerVisible) {
        MiniPlayer.updatePlayState()
      }
      // NOVO: Atualizar estado do player expandido
      if (typeof ExpandedPlayer !== "undefined") {
        ExpandedPlayer.updatePlayState(true)
        ExpandedPlayer.updateFromPlayer()
      }
    } else if (event.data === YT.PlayerState.PAUSED) {
      isPlaying = false
      // NOVO: Atualizar mini player e esconder quando pausar
      if (miniPlayerVisible) {
        MiniPlayer.updatePlayState()
        // NOVO: Esconder mini player quando pausar
        setTimeout(() => {
          if (!isPlaying) {
            MiniPlayer.hide()
          }
        }, 1000)
      }
      // NOVO: Atualizar estado do player expandido
      if (typeof ExpandedPlayer !== "undefined") {
        ExpandedPlayer.updatePlayState(false)
      }
    }
  } catch (error) {
    console.error("❌ Erro no onPlayerStateChange:", error)
  }
}

// CORRIGIDO: updateNowPlaying com debug para DJ
function updateNowPlaying() {
  if (!player || !player.getVideoData || !currentVideoId) return

  try {
    const data = player.getVideoData()
    if (!data || !data.title) return

    const duration = player.getDuration()
    const thumbnail = getOptimizedThumbnail(currentVideoId, "medium")

    const nowPlayingTitle = document.querySelector(".now-playing-title")
    const nowPlayingDuration = document.querySelector(".now-playing-duration")
    const nowPlayingImg = document.querySelector(".now-playing-thumbnail")
    const nowPlayingContainer = document.querySelector(".now-playing")

    if (nowPlayingTitle) {
      const prefix = isDJMode ? "🎧 DJ: " : ""
      nowPlayingTitle.textContent = prefix + data.title
      console.log("📻 Now Playing atualizado:", prefix + data.title)
    }
    if (nowPlayingDuration) nowPlayingDuration.textContent = formatTime(duration)
    if (nowPlayingImg) {
      // OTIMIZAÇÃO: Precarregar thumbnail do now playing
      preloadImage(thumbnail, currentVideoId)
        .then((src) => (nowPlayingImg.src = src))
        .catch(() => (nowPlayingImg.src = getOptimizedThumbnail(currentVideoId, "low")))
    }

    // NOVO: Preencher atributos de dados para ações de now-playing
    if (nowPlayingContainer) {
      nowPlayingContainer.dataset.videoId = currentVideoId
      nowPlayingContainer.dataset.title = data.title || ""
      nowPlayingContainer.dataset.duration = formatTime(duration)
    }

    // NOVO: Atualizar também o overlay de player expandido
    try {
      const epTitle = document.getElementById("ep-title")
      const epArtist = document.getElementById("ep-artist")
      const epArtwork = document.getElementById("ep-artwork")
      const epTotal = document.getElementById("ep-total")
      if (epTitle) epTitle.textContent = data.title
      if (epArtist) epArtist.textContent = data.author || ""
      if (epArtwork) {
        preloadImage(thumbnail, currentVideoId)
          .then((src) => (epArtwork.src = src))
          .catch(() => (epArtwork.src = getOptimizedThumbnail(currentVideoId, "low")))
      }
      if (epTotal) epTotal.textContent = formatTime(duration)
    } catch (e) {}
  } catch (error) {
    console.error("Erro ao atualizar reprodução atual:", error)
  }
}

// ===== Expanded Player (overlay) =====
const ExpandedPlayer = (() => {
  let el,
    btnClose,
    btnPlay,
    btnPrev,
    btnNext,
    btnFav,
    btnAdd,
    slider,
    timeCurrent,
    timeTotal,
    eventsBound = false,
    progressTimer = null

  function getElements() {
    el = document.getElementById("expanded-player")
    btnClose = document.getElementById("ep-close")
    btnPlay = document.getElementById("ep-play")
    btnPrev = document.getElementById("ep-prev")
    btnNext = document.getElementById("ep-next")
    btnFav = document.getElementById("ep-favorite")
    btnAdd = document.getElementById("ep-add")
    slider = document.getElementById("ep-slider")
    timeCurrent = document.getElementById("ep-current")
    timeTotal = document.getElementById("ep-total")
  }

  function setSliderPercent(p) {
    const percent = Math.min(100, Math.max(0, p || 0))
    if (slider) {
      slider.value = percent
      slider.style.background = `linear-gradient(90deg, #47ff8d ${percent}%, rgba(255,255,255,0.2) ${percent}%)`
    }
  }

  function attachEvents() {
    if (!el) return
    if (btnClose) btnClose.addEventListener("click", () => hide())
    if (btnPrev) btnPrev.addEventListener("click", () => {
      if (typeof MiniPlayer !== "undefined") MiniPlayer.previousTrack()
    })
    if (btnNext) btnNext.addEventListener("click", () => {
      if (typeof MiniPlayer !== "undefined") MiniPlayer.nextTrack()
    })
    if (btnPlay) btnPlay.addEventListener("click", () => {
      if (typeof MiniPlayer !== "undefined") MiniPlayer.togglePlayPause()
    })
    // Like
    if (btnFav) btnFav.addEventListener("click", (e) => {
      e.stopPropagation()
      if (!currentVideoId || !player || !player.getVideoData) {
        showNotification("Nenhuma música tocando no momento", "warning")
        return
      }
      const isActive = btnFav.classList.contains("active")
      const data = player.getVideoData() || {}
      const title = data.title || "Música"
      const duration = formatTime(player.getDuration())
      const videoId = currentVideoId

      btnFav.classList.toggle("active")
      const action = isActive ? "removida dos" : "adicionada aos"
      showNotification(`Música ${action} favoritos`, isActive ? "info" : "success")

      fetch(`https://${safeGetParentResourceName()}/toggleFavorite`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          videoId,
          id: videoId,
          title,
          thumbnail: getOptimizedThumbnail(videoId, "medium"),
          duration,
        }),
      }).catch((error) => {
        console.error("Erro ao favoritar (expanded):", error)
        btnFav.classList.toggle("active")
        showNotification("Erro ao favoritar música", "error")
      })
    })
    // Adicionar à playlist
    if (btnAdd) btnAdd.addEventListener("click", (e) => {
      e.stopPropagation()
      const videoId = currentVideoId
      if (!videoId) {
        showNotification("Nenhuma música selecionada para adicionar", "warning")
        return
      }
      if (typeof showPlaylistSelector === "function") {
        showPlaylistSelector(videoId)
      } else {
        console.error("Função showPlaylistSelector não encontrada")
        showNotification("Não foi possível abrir o seletor de playlist", "error")
      }
    })
    if (slider) {
      slider.addEventListener("input", () => setSliderPercent(parseFloat(slider.value)))
      slider.addEventListener("change", () => {
        try {
          if (player && player.getDuration && player.seekTo) {
            const dur = player.getDuration() || 0
            const seekSec = (parseFloat(slider.value) / 100) * dur
            player.seekTo(seekSec, true)
          }
        } catch (_) {}
      })
    }
  }

  function startProgressLoop() {
    stopProgressLoop()
    progressTimer = setInterval(() => {
      if (el && el.classList.contains("open")) {
        updateFromPlayer()
      }
    }, 500)
  }
  function stopProgressLoop() {
    if (progressTimer) {
      clearInterval(progressTimer)
      progressTimer = null
    }
  }

  function show() {
    getElements()
    if (!el) return
    if (!eventsBound) {
      attachEvents()
      eventsBound = true
    }
    el.classList.add("open")
    updateFromPlayer()
    startProgressLoop()
  }
  function hide() {
    getElements()
    if (!el) return
    el.classList.remove("open")
    stopProgressLoop()
  }
  function updateFromPlayer() {
    try {
      if (!player || !player.getVideoData || !currentVideoId) return
      const d = player.getVideoData()
      const dur = player.getDuration() || 0
      const cur = player.getCurrentTime ? player.getCurrentTime() : 0
      const percent = dur ? (cur / dur) * 100 : 0
      setSliderPercent(percent)
      if (timeCurrent) timeCurrent.textContent = formatTime(cur)
      if (timeTotal) timeTotal.textContent = formatTime(dur)
      // Ícones play/pause
      const playIcon = btnPlay?.querySelector(".ep-play-icon")
      const pauseIcon = btnPlay?.querySelector(".ep-pause-icon")
      if (playIcon && pauseIcon) {
        playIcon.style.display = isPlaying ? "none" : "block"
        pauseIcon.style.display = isPlaying ? "block" : "none"
      }
    } catch (_) {}
  }
  function updatePlayState(playing) {
    try {
      const playIcon = btnPlay?.querySelector(".ep-play-icon")
      const pauseIcon = btnPlay?.querySelector(".ep-pause-icon")
      if (playIcon && pauseIcon) {
        const state = typeof playing === "boolean" ? playing : isPlaying
        playIcon.style.display = state ? "none" : "block"
        pauseIcon.style.display = state ? "block" : "none"
      }
    } catch (_) {}
  }

  // Expor API
  return { show, hide, updateFromPlayer, updatePlayState }
})()

// Abrir overlay ao clicar no bloco now-playing
function escapeSearchHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;")
}

document.addEventListener("DOMContentLoaded", () => {
  const np = document.querySelector(".now-playing")
  if (np) {
    np.addEventListener("click", () => {
      if (typeof ExpandedPlayer !== "undefined") ExpandedPlayer.show()
    })
  }
})

// CORRIGIDO: Função para atualizar UI do modo DJ
function updateDJModeUI() {
  const app = document.getElementById("app")
  const djIndicator = document.querySelector(".dj-mode-indicator")

  if (isDJMode && currentDJStation) {
    app.classList.add("dj-mode")

    if (!djIndicator) {
      const indicator = document.createElement("div")
      indicator.className = "dj-mode-indicator"
      indicator.innerHTML = `
                <div class="dj-icon">🎧</div>
                    <div class="dj-title">Modo DJ Ativo</div>
                    <div class="dj-station">${currentDJStation.stationData.name}</div>
                </div>
            `
      app.appendChild(indicator)
    } else {
      djIndicator.querySelector(".dj-station").textContent = currentDJStation.stationData.name
    }

    console.log("🎧 UI atualizada para modo DJ:", currentDJStation.stationData.name)
  } else {
    app.classList.remove("dj-mode")
    if (djIndicator) {
      djIndicator.remove()
    }
    console.log("🎵 UI restaurada para modo normal")
  }
}

// Função para configurar os botões de abas - CORRIGIDA
function configurarBotoesAbas() {
  const botoes = document.querySelectorAll(".tab")

  botoes.forEach((botao) => {
    botao.removeEventListener("click", botaoClickHandler)
    botao.addEventListener("click", botaoClickHandler)
  })
}

// Handler para o clique nos botões de abas - CORRIGIDO
function botaoClickHandler(e) {
  document.querySelectorAll(".tab").forEach((b) => b.classList.remove("active"))
  this.classList.add("active")

  const nomeAba = this.getAttribute("data-tab") || this.textContent.toLowerCase()
  currentTab = nomeAba

  console.log("Abrindo aba:", nomeAba)
  carregarConteudo(nomeAba)
}

// Função para carregar o conteúdo da aba selecionada - CORRIGIDA
function carregarConteudo(nomeAba) {
  const areaConteudo = document.querySelector(".grid")

  // Se já temos dados em cache, usar eles
  if (dataCache[nomeAba] && dataCache[nomeAba].length > 0) {
    console.log("Carregando da cache:", nomeAba)
    if (nomeAba === "musicas") {
      exibirMusicas(dataCache[nomeAba], "history")
    } else if (nomeAba === "favoritos") {
      exibirPlaylists(dataCache[nomeAba])
    } else if (nomeAba === "curtidas") {
      exibirMusicas(dataCache[nomeAba], "favorites")
    }
    return
  }

  // Mostrar loading (manter classe do grid)
  const currentClass = areaConteudo.className || "grid"
  areaConteudo.innerHTML = `<div class="loading">Carregando ${nomeAba}...</div>`

  // Solicitar dados do servidor
  if (nomeAba === "musicas") {
    console.log("Solicitando histórico...")
    fetch(`https://${safeGetParentResourceName()}/getHistory`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({}),
    }).catch((error) => {
      console.error("Erro ao carregar histórico:", error)
      carregarHistoricoMusicas() // Fallback para localStorage
    })
  } else if (nomeAba === "favoritos") {
    console.log("Solicitando playlists...")
    loadPlaylists()
  } else if (nomeAba === "curtidas") {
    console.log("Solicitando favoritos...")
    loadFavorites()
  }
}

// Função para carregar histórico de músicas - CORRIGIDA
function carregarHistoricoMusicas() {
  try {
    const historico = JSON.parse(localStorage.getItem("trackHistory") || "[]")
    dataCache.musicas = historico
    if (currentTab === "musicas") {
      exibirMusicas(historico, "history")
    }
  } catch (erro) {
    console.error("Erro ao carregar histórico:", erro)
    mostrarErro("Não foi possível carregar o histórico de músicas.")
  }
}

// Função para mostrar mensagens de erro
function mostrarErro(mensagem) {
  const areaConteudo = document.querySelector(".grid")
  areaConteudo.innerHTML = `
        <div class="error-state">
            <p>${mensagem}</p>
            <button onclick="carregarConteudo(currentTab)">Tentar novamente</button>
        </div>
    `
}

// OTIMIZAÇÃO: Função para exibir músicas com lazy loading e thumbnails otimizadas
function exibirMusicas(musicas, tipo) {
  const areaConteudo = document.querySelector(".grid")
  
  // Aplicar classe específica para tracks
  const listMode = (currentTab === "musicas") || (tipo === "musicas") || (tipo === "history" && currentTab === "musicas")
  areaConteudo.className = listMode ? "grid tracks-list" : "grid tracks-grid"

  if (!Array.isArray(musicas) || musicas.length === 0) {
    areaConteudo.innerHTML = `
            <div class="empty-state">
                ${
                  tipo === "history"
                    ? "Você ainda não assistiu nenhum vídeo. Pesquise alguma música para começar."
                    : tipo === "favorites"
                      ? "Você ainda não marcou nenhum favorito. Clique no coração para adicionar."
                      : "Nenhuma música encontrada nesta categoria."
                }
            </div>
        `
    return
  }

  // Determina tipo da lista atual
  const isFavoritos = tipo === "favorites"
  const isPlaylist = tipo === "playlist"
  const isListView = (currentTab === "musicas") || (tipo === "musicas") || (tipo === "history" && currentTab === "musicas")

  // OTIMIZAÇÃO: Criar HTML com lazy loading e thumbnails otimizadas
  const html = musicas
    .map((musica) => {
      const videoId = musica.videoId || musica.id
      const optimizedThumbnail = getOptimizedThumbnail(videoId, "medium")
      const fallbackThumbnail = getOptimizedThumbnail(videoId, "low")

      if (isListView) {
        return `
          <div class="track-row" data-video-id="${videoId}">
            <div class="thumb">
              <img 
                class="lazy-image" 
                data-src="${optimizedThumbnail}" 
                data-video-id="${videoId}"
                src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='112' height='63'%3E%3Crect width='100%25' height='100%25' fill='%23333'/%3E%3C/text%3E%3C/svg%3E"
                alt="${musica.title}" 
                onerror="this.src='${fallbackThumbnail}'"
                loading="lazy"
              >
            </div>
            <div class="info">
              <h3 class="track-title">${musica.title}</h3>
              <p class="track-duration">${musica.duration || "--:--"}</p>
            </div>
            <div class="actions">
              <button class="favorite ${isFavoritos ? "active" : ""}">${isFavoritos ? "❤️" : "🤍"}</button>
              <button class="add-to-playlist">+</button>
            </div>
          </div>
        `
      }

      return `
        <div class="track-card" data-video-id="${videoId}">
          <img 
            class="lazy-image" 
            data-src="${optimizedThumbnail}" 
            data-video-id="${videoId}"
            src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='320' height='180'%3E%3Crect width='100%25' height='100%25' fill='%23333'/%3E%3Ctext x='50%25' y='50%25' text-anchor='middle' dy='.3em' fill='%23666'%3ECarregando...%3C/text%3E%3C/svg%3E"
            alt="${musica.title}" 
            onerror="this.src='${fallbackThumbnail}'"
            loading="lazy"
          >
          <div class="info">
            <h3>${musica.title}</h3>
            <p>${musica.duration || "--:--"}</p>
          </div>
          <div class="buttons">
            <button class="favorite ${isFavoritos ? "active" : ""}">${isFavoritos ? "❤️" : "🤍"}</button>
            <button class="add-to-playlist">+</button>
            ${isPlaylist ? '<button class="remove-from-playlist" title="Remover da playlist">🗑</button>' : ''}
          </div>
        </div>
      `
    })
    .join("")

  areaConteudo.innerHTML = html

  // OTIMIZAÇÃO: Configurar lazy loading para as novas imagens
  const imageObserver = setupLazyLoading()
  document.querySelectorAll(".lazy-image").forEach((img) => {
    imageObserver.observe(img)
  })

  // Adiciona eventos de clique aos novos itens
  addTrackCardListeners()
}

// Nova função para exibir playlists - CORRIGIDA
function exibirPlaylists(playlists) {
  const areaConteudo = document.querySelector(".grid")
  
  // Aplicar classe específica para playlists
  areaConteudo.className = "grid playlists-grid"

  if (!Array.isArray(playlists) || playlists.length === 0) {
    areaConteudo.innerHTML = `
            <div class="empty-state">
                <p>Você ainda não criou nenhuma playlist.</p>
                <button class="create-playlist-btn">Criar uma playlist</button>
            </div>
        `

    // Adicionar evento ao botão
    const createBtn = areaConteudo.querySelector(".create-playlist-btn")
    if (createBtn) {
      createBtn.addEventListener("click", () => {
        const modal = document.createElement("div")
        modal.className = "playlist-modal"
        modal.innerHTML = `
                    <div class="playlist-selector">
                        <h3>Criar Nova Playlist</h3>
                        <div class="new-playlist">
                            <input type="text" placeholder="Nome da nova playlist">
                            <button>Criar</button>
                        </div>
                    </div>
                `
        document.body.appendChild(modal)

        const createButton = modal.querySelector(".new-playlist button")
        const nameInput = modal.querySelector(".new-playlist input")

        createButton.addEventListener("click", () => {
          const name = nameInput.value.trim()
          if (name) {
            fetch(`https://${safeGetParentResourceName()}/createPlaylist`, {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({ name }),
            }).catch((error) => console.error("Erro ao criar playlist:", error))

            modal.remove()
          }
        })

        modal.addEventListener("click", (e) => {
          if (e.target === modal) {
            modal.remove()
          }
        })
      })
    }

    return
  }

  // Criar o HTML para cada playlist
  const html = playlists
    .map(
      (playlist) => `
        <div class="playlist-card" data-playlist-id="${playlist.id}">
            <div class="playlist-cover" style="${playlist.thumbnail ? `background-image: url('${playlist.thumbnail}')` : ''}">
                ${playlist.thumbnail ? '' : `
                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M9 18V5l12 13V5M1 5v14l4-4h4"/>
                </svg>`}
            </div>
            <div class="playlist-info">
                <div class="playlist-meta">
                    <h3>${playlist.name}</h3>
                    <p>Playlist</p>
                </div>
                <button class="delete-playlist" data-playlist-id="${playlist.id}" title="Excluir playlist">🗑</button>
            </div>
        </div>
    `,
    )
    .join("")

  areaConteudo.innerHTML = html

  // Adicionar eventos de clique às playlists
  document.querySelectorAll(".playlist-card").forEach((card) => {
    card.addEventListener("click", function (e) {
      if (e.target && e.target.classList.contains("delete-playlist")) return
      const playlistId = this.dataset.playlistId
      currentPlaylistId = playlistId
      fetch(`https://${safeGetParentResourceName()}/getPlaylistVideos`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ playlistId }),
      }).catch((error) => console.error("Erro ao carregar vídeos da playlist:", error))
    })
  })

  document.querySelectorAll(".delete-playlist").forEach((btn) => {
    btn.addEventListener("click", function (e) {
      e.stopPropagation()
      const playlistId = this.dataset.playlistId
      if (!playlistId) return
      deletePlaylist(playlistId)
    })
  })
}

// CORRIGIDO: Função para adicionar event listeners aos cards de música - Sistema DJ funcionando
function addTrackCardListeners() {
  document.querySelectorAll(".track-card, .track-row").forEach((card) => {
    const videoId = card.dataset.videoId
    const title = card.querySelector("h3")?.textContent
    const thumbnail = card.querySelector("img")?.src
    const durationEl = card.querySelector("p")
    const duration = durationEl ? durationEl.textContent.split("•").pop().trim() : ""

    if (!videoId || !title || !thumbnail) return

    card.removeEventListener("click", handleCardClick)
    card.querySelector(".favorite")?.removeEventListener("click", handleFavoriteClick)
    card.querySelector(".add-to-playlist")?.removeEventListener("click", handleAddToPlaylist)
    card.querySelector(".remove-from-playlist")?.removeEventListener("click", handleRemoveFromPlaylist)

    card.addEventListener("click", handleCardClick)
    card.querySelector(".favorite")?.addEventListener("click", handleFavoriteClick)
    card.querySelector(".add-to-playlist")?.addEventListener("click", handleAddToPlaylist)
    card.querySelector(".remove-from-playlist")?.addEventListener("click", handleRemoveFromPlaylist)

    function handleCardClick(e) {
      if (
        e.target.classList.contains("favorite") ||
        e.target.classList.contains("add-to-playlist") ||
        e.target.classList.contains("remove-from-playlist")
      ) return

      // Ativar contexto de áudio na primeira interação
      resumeAudioContext()

      try {
        console.log("=== CARD CLICK ===")
        console.log("Modo DJ ativo:", isDJMode)
        console.log("Estação DJ atual:", currentDJStation)

        const trackData = {
          videoId,
          title,
          thumbnail: getOptimizedThumbnail(videoId, "medium"),
          duration,
        }

        // CORRIGIDO: Detectar modo DJ e usar endpoint correto
        if (isDJMode && currentDJStation) {
          console.log("🎧 MODO DJ DETECTADO - Enviando para playDJTrack")

          // Adicionar dados da estação DJ
          trackData.stationIndex = currentDJStation.stationIndex
          trackData.stationData = currentDJStation.stationData

          console.log("🎧 Dados sendo enviados:", trackData)

          // CORRIGIDO: Usar fetch diretamente
          fetch(`https://${safeGetParentResourceName()}/playDJTrack`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(trackData),
          })
            .then((response) => {
              console.log("🎧 Resposta do servidor DJ:", response.status)
              if (response.ok) {
                // Atualizar interface
                isPlaying = true
                currentVideoId = videoId
                playVideo(videoId) // Tocar no player principal também
                updateNowPlaying()

                // NOVO: Mostrar mini player se não estiver visível
                if (!miniPlayerVisible) {
                  MiniPlayer.show()
                }
              }
              return response.text()
            })
            .then((data) => {
              console.log("🎧 Dados da resposta:", data)
            })
            .catch((error) => {
              console.error("❌ Erro ao tocar música de DJ:", error)
            })
        } else {
          console.log("🎵 MODO NORMAL - Usando playTrack")

          // Modo normal (prop/carro)
          currentVideoId = videoId
          currentTrackIndex = playlist.findIndex((track) => track.id === videoId)
          playVideo(videoId)

          fetch(`https://${safeGetParentResourceName()}/playTrack`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(trackData),
          }).catch((error) => console.error("Erro ao tocar música:", error))

          // NOVO: Mostrar mini player se não estiver visível
          if (!miniPlayerVisible) {
            MiniPlayer.show()
          }
        }

        // Salvar no histórico sempre
        saveToHistory(trackData)
      } catch (error) {
        console.error("Erro em handleCardClick:", error)
      }
    }

    function handleFavoriteClick(e) {
      e.stopPropagation()
      const btn = e.target
      const card = btn.closest('.track-card, .track-row')
      const isActive = btn.classList.contains("active")

      // Obter dados da música do card
      const cardVideoId = card.dataset.videoId || videoId
      const cardTitle = card.querySelector('.track-title')?.textContent || title
      const cardDuration = card.querySelector('.track-duration')?.textContent || duration

      btn.textContent = isActive ? "🤍" : "❤️"
      btn.classList.toggle("active")

      // Mostrar notificação
      const action = isActive ? 'removida dos' : 'adicionada aos'
      showNotification(`Música ${action} favoritos`, isActive ? 'info' : 'success')

      fetch(`https://${safeGetParentResourceName()}/toggleFavorite`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          videoId: cardVideoId,
          id: cardVideoId,
          title: cardTitle,
          thumbnail: getOptimizedThumbnail(cardVideoId, "medium"),
          duration: cardDuration,
        }),
      }).catch((error) => {
        console.error("Erro ao favoritar:", error)
        // Reverter o estado do botão em caso de erro
        btn.textContent = isActive ? "❤️" : "🤍"
        btn.classList.toggle("active")
        showNotification('Erro ao favoritar música', 'error')
      })
    }

    function handleAddToPlaylist(e) {
      e.stopPropagation()
      
      // Encontrar o elemento track-card pai
      const trackCard = e.target.closest('.track-card, .track-row')
      if (!trackCard) {
        console.error('Track card não encontrado')
        return
      }
      
      // Extrair o videoId do data-video-id
      const videoId = trackCard.dataset.videoId
      if (!videoId) {
        console.error('VideoId não encontrado no track card')
        return
      }
      
      if (typeof showPlaylistSelector === "function") {
        showPlaylistSelector(videoId)
      } else {
        console.error('Função showPlaylistSelector não encontrada')
      }
    }

    function handleRemoveFromPlaylist(e) {
      e.stopPropagation()
      if (!currentPlaylistId) {
        showNotification("Playlist não identificada.", "error")
        return
      }
      const confirmRemove = confirm("Remover esta música da playlist?")
      if (!confirmRemove) return
      removeFromPlaylist(currentPlaylistId, videoId)
    }
  })
}

// Remover música da playlist atual
function removeFromPlaylist(playlistId, videoId) {
  fetch(`https://${safeGetParentResourceName()}/removeFromPlaylist`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ playlistId, videoId }),
  })
    .then((response) => {
      if (response.ok) {
        showNotification("Música removida da playlist.")
        loadPlaylistVideos(playlistId)
      } else {
        showNotification("Erro ao remover música da playlist.", "error")
      }
    })
    .catch((error) => {
      console.error("Erro ao remover da playlist:", error)
      showNotification("Erro ao remover música da playlist.", "error")
    })
}

// Excluir playlist
function deletePlaylist(playlistId) {
  fetch(`https://${safeGetParentResourceName()}/deletePlaylist`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ playlistId }),
  })
    .then((response) => {
      if (response.ok) {
        showNotification("Playlist excluída.")
        loadPlaylists()
      } else {
        showNotification("Erro ao excluir playlist.", "error")
      }
    })
    .catch((error) => {
      console.error("Erro ao excluir playlist:", error)
      showNotification("Erro ao excluir playlist.", "error")
    })
}

// CORRIGIDO: Sistema de comunicação melhorado
const MusicSystem = {
  // Tocar música de DJ
  playDJTrack: (data) => {
    console.log("🎧 MusicSystem.playDJTrack chamado:", data)

    return fetch(`https://${safeGetParentResourceName()}/playDJTrack`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    })
      .then((response) => {
        console.log("🎧 Resposta playDJTrack:", response.status)
        if (response.ok) {
          isPlaying = true
          // Salvar no histórico
          fetch(`https://${safeGetParentResourceName()}/saveToHistory`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ videoId: data.videoId }),
          }).catch(console.error)

          // Salvar vídeo
          fetch(`https://${safeGetParentResourceName()}/saveVideo`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              id: data.videoId,
              title: data.title,
              thumbnail: data.thumbnail,
              duration: data.duration,
            }),
          }).catch(console.error)
        }
        return response
      })
      .catch((error) => {
        console.error("❌ Erro em playDJTrack:", error)
        throw error
      })
  },

  // Pausar música de DJ
  pauseDJTrack: (data) => {
    console.log("🎧 MusicSystem.pauseDJTrack chamado:", data)

    return fetch(`https://${safeGetParentResourceName()}/pauseDJTrack`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    })
      .then((response) => {
        console.log("🎧 Resposta pauseDJTrack:", response.status)
        if (response.ok) {
          isPlaying = false
          // NOVO: Esconder mini player quando pausar DJ
          MiniPlayer.hide()
        }
        return response
      })
      .catch((error) => {
        console.error("❌ Erro em pauseDJTrack:", error)
        throw error
      })
  },

  // Pausar música normal
  pauseTrack: () => {
    console.log("🎵 MusicSystem.pauseTrack chamado")

    // Remover prop JBL
    fetch(`https://${safeGetParentResourceName()}/deleteProp`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({}),
    }).catch(console.error)

    return fetch(`https://${safeGetParentResourceName()}/pauseTrack`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({}),
    })
      .then((response) => {
        console.log("🎵 Resposta pauseTrack:", response.status)
        if (response.ok) {
          isPlaying = false
          // NOVO: Esconder mini player quando pausar
          MiniPlayer.hide()
        }
        return response
      })
      .catch((error) => {
        console.error("❌ Erro em pauseTrack:", error)
        throw error
      })
  },
}

// Funções para gerenciar favoritos e playlists
function loadFavorites() {
  console.log("Solicitando favoritos do servidor...")
  fetch(`https://${safeGetParentResourceName()}/getFavorites`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({}),
  }).catch((error) => console.error("Erro ao carregar favoritos:", error))
}

function createNewPlaylist(name) {
  if (!name || name.trim() === "") return

  fetch(`https://${safeGetParentResourceName()}/createPlaylist`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ name: name.trim() }),
  }).catch((error) => console.error("Erro ao criar playlist:", error))
}

function loadPlaylists() {
  console.log("Solicitando playlists do servidor...")
  fetch(`https://${safeGetParentResourceName()}/getPlaylists`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({}),
  }).catch((error) => console.error("Erro ao carregar playlists:", error))
}

function loadPlaylistVideos(playlistId) {
  console.log("Solicitando vídeos da playlist: " + playlistId)
  fetch(`https://${safeGetParentResourceName()}/getPlaylistVideos`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ playlistId }),
  }).catch((error) => console.error("Erro ao carregar vídeos da playlist:", error))
}

/////////////////////////////////////////////////////////////////youtube pesquisa////////////////////////
const CACHE_NAME = "youtube_search_cache_v4"
const CACHE_EXPIRATION_HOURS = 6 // cache expira em 6h
const MAX_CACHE_ITEMS = 200

const sessionCache = new Map()
const searchQueue = new Map()

// A pesquisa é feita pelo SERVER do FiveM.
// Isso evita bloqueios de CORS/CEF e não depende de uma única instância pública no navegador.
async function searchYouTubeServer(query) {
  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), 15000)

  try {
    const response = await fetch(`https://${safeGetParentResourceName()}/searchYouTube`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ query }),
      signal: controller.signal,
    })

    if (!response.ok) {
      throw new Error(`Falha no callback de pesquisa (HTTP ${response.status})`)
    }

    const payload = await response.json()
    if (!payload || payload.success !== true || !Array.isArray(payload.results)) {
      throw new Error(payload?.error || "A pesquisa não retornou resultados válidos")
    }

    return payload.results
  } finally {
    clearTimeout(timeout)
  }
}

async function searchYouTubeWithCache(query) {
  if (!query?.trim()) return []

  const normalizedQuery = query.toLowerCase().trim()

  // 1. Cache da sessão
  if (sessionCache.has(normalizedQuery)) {
    console.log("[Busca] Retornando cache da sessão:", query)
    return sessionCache.get(normalizedQuery)
  }

  // 2. Evita buscas duplicadas simultâneas
  if (searchQueue.has(normalizedQuery)) {
    return await searchQueue.get(normalizedQuery)
  }

  // 3. Cache persistente da NUI
  const cachedResults = await getFromCache(normalizedQuery)
  if (cachedResults) {
    sessionCache.set(normalizedQuery, cachedResults)
    return cachedResults
  }

  // 4. Busca real executada pelo servidor FiveM
  const searchPromise = searchYouTubeServer(query)
  searchQueue.set(normalizedQuery, searchPromise)

  try {
    const results = await searchPromise

    if (Array.isArray(results) && results.length > 0) {
      sessionCache.set(normalizedQuery, results)
      await saveToCache(normalizedQuery, results)
      return results
    }

    return []
  } catch (error) {
    console.error("[Busca] Falha na pesquisa do servidor:", error)
    throw error
  } finally {
    searchQueue.delete(normalizedQuery)
  }
}

async function getFromCache(query) {
  try {
    const cache = JSON.parse(localStorage.getItem(CACHE_NAME) || "{}")
    const cachedData = cache[query]

    if (!cachedData) return null

    const cacheAge = (Date.now() - cachedData.timestamp) / (1000 * 60 * 60)
    if (cacheAge > CACHE_EXPIRATION_HOURS) {
      delete cache[query]
      localStorage.setItem(CACHE_NAME, JSON.stringify(cache))
      return null
    }

    return cachedData.results
  } catch (error) {
    console.warn("Erro ao acessar cache:", error)
    return null
  }
}

async function saveToCache(query, results) {
  try {
    const cache = JSON.parse(localStorage.getItem(CACHE_NAME) || "{}")

    const keys = Object.keys(cache)
    if (keys.length >= MAX_CACHE_ITEMS) {
      const oldest = keys
        .map((key) => ({ key, timestamp: cache[key].timestamp }))
        .sort((a, b) => a.timestamp - b.timestamp)
        .slice(0, Math.floor(MAX_CACHE_ITEMS * 0.3))

      oldest.forEach((item) => delete cache[item.key])
    }

    cache[query] = {
      results,
      timestamp: Date.now(),
    }

    localStorage.setItem(CACHE_NAME, JSON.stringify(cache))
  } catch (error) {
    console.warn("Erro ao salvar no cache:", error)
  }
}

// OTIMIZAÇÃO: Função para obter a melhor thumbnail com fallbacks
function getBestThumbnail(video) {
  if (video.videoThumbnails && video.videoThumbnails.length > 0) {
    // Priorizar medium quality, depois high, depois qualquer uma
    const priorities = ["medium", "high", "default"]

    for (const quality of priorities) {
      const thumb = video.videoThumbnails.find((t) => t.quality === quality)
      if (thumb && thumb.url) return thumb.url
    }

    // Se não encontrou por qualidade, pegar a primeira disponível
    const firstThumb = video.videoThumbnails[0]
    if (firstThumb && firstThumb.url) return firstThumb.url
  }

  // Fallback para URL padrão do YouTube
  return getOptimizedThumbnail(video.videoId, "medium")
}

// Função para formatar duração
function formatDuration(seconds) {
  if (!seconds) return "00:00"
  const date = new Date(0)
  date.setSeconds(seconds)
  return date.toISOString().substring(11, 19).replace(/^00:/, "")
}

// Interface pública
window.youtubeSearch = {
  search: searchYouTubeWithCache,
  clearCache: async () => {
    sessionCache.clear()
    searchQueue.clear()
    localStorage.removeItem(CACHE_NAME)
  },
}

function formatTime(seconds) {
  if (!seconds) return "0:00"
  seconds = Math.floor(seconds)
  const minutes = Math.floor(seconds / 60)
  seconds = seconds % 60
  return `${minutes}:${seconds.toString().padStart(2, "0")}`
}

function updateSliderBackground(slider) {
  const value = ((slider.value - slider.min) / (slider.max - slider.min)) * 100
  slider.style.background = `linear-gradient(to right, #1DB954 0%, #1DB954 ${value}%, #282828 ${value}%, #282828 100%)`
}

// NOVO: Função de debug para testar modo DJ
window.debugDJ = () => {
  console.log("=== DEBUG DJ ===")
  console.log("isDJMode:", isDJMode)
  console.log("currentDJStation:", currentDJStation)
  console.log("isPlaying:", isPlaying)
  console.log("currentVideoId:", currentVideoId)
  console.log("player:", player)
  console.log("===============")
}

// NOVO: Debug para mini player
window.debugMiniPlayer = () => {
  console.log("=== MINI PLAYER DEBUG ===")
  console.log("Visible:", miniPlayerVisible)
  console.log("DJ Mode:", isDJMode)
  console.log("Playing:", miniIsPlaying)
  console.log("Track Data:", miniCurrentTrackData)
  console.log("Should Show:", MiniPlayer.shouldShow())
  console.log("========================")
}

// NOVO: Debug para sistema de busca
window.debugSearch = async (query) => {
  console.log("=== SEARCH DEBUG ===")
  console.log("Query:", query)
  console.log("Cache em memória:", sessionCache.has(query?.toLowerCase()))
  console.log("Cache localStorage:", await getFromCache(query?.toLowerCase()))

  try {
    const results = await searchYouTubeWithCache(query)
    console.log("Resultados:", results.length)
    console.log("Primeiro resultado:", results[0])
  } catch (error) {
    console.error("Erro na busca:", error)
  }
  console.log("==================")
}

document.addEventListener("DOMContentLoaded", () => {
  loadYouTubeAPI()
  const app = document.getElementById("app")

  // Inicializar Web Audio API
  initAudioContext()

  // Carregar informações do usuário
  userId = localStorage.getItem("userId")
  if (!userId) {
    userId = "1"
    localStorage.setItem("userId", userId)
  }

  const searchInput = document.querySelector(".search-bar input")
  const gridContainer = document.querySelector(".grid")

  // CORRIGIDO: Debounce melhorado para pesquisa com melhor tratamento de erros
  let searchTimeout
  let lastSearchQuery = ""

  searchInput.addEventListener("input", (e) => {
    clearTimeout(searchTimeout)
    const query = e.target.value.trim()

    // Evitar pesquisas duplicadas
    if (query === lastSearchQuery) return

    searchTimeout = setTimeout(async () => {
      if (query.length > 2) {
        lastSearchQuery = query

        // Mostrar loading imediatamente
        gridContainer.innerHTML = `
          <div class="loading-search">
            <div class="spinner"></div>
            <p>Buscando "${query}"...</p>
          </div>
        `

        try {
          const results = await window.youtubeSearch.search(query)

          if (!Array.isArray(results)) {
            console.error("Resultados inválidos:", results)
            return
          }

          playlist = results

          // OTIMIZAÇÃO: Renderizar com lazy loading
          // Forçar layout em lista para resultados de busca na aba Músicas
          gridContainer.className = "grid tracks-list"
          gridContainer.innerHTML = results
            .map((item) => {
              const optimizedThumbnail = getOptimizedThumbnail(item.id, "medium")
              const fallbackThumbnail = getOptimizedThumbnail(item.id, "low")

              return `
                <div class="track-row" data-video-id="${item.id}">
                  <div class="thumb">
                    <img 
                      class="lazy-image search-result-img" 
                      data-src="${optimizedThumbnail}" 
                      data-video-id="${item.id}"
                      src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='112' height='63'%3E%3Crect width='100%25' height='100%25' fill='%23333'/%3E%3C/svg%3E"
                      alt="${escapeSearchHtml(item.title)}"
                      onerror="this.src='${fallbackThumbnail}'"
                      loading="lazy"
                    >
                  </div>
                  <div class="info">
                    <h3 class="track-title">${escapeSearchHtml(item.title)}</h3>
                    <p class="track-duration">${escapeSearchHtml(item.author)} • ${escapeSearchHtml(item.duration)}</p>
                  </div>
                  <div class="actions">
                    <button class="favorite">🤍</button>
                    <button class="add-to-playlist">+</button>
                  </div>
                </div>
              `
            })
            .join("")

          // OTIMIZAÇÃO: Configurar lazy loading para as novas imagens de pesquisa
          const imageObserver = setupLazyLoading()
          document.querySelectorAll(".search-result-img").forEach((img) => {
            imageObserver.observe(img)
          })

          addTrackCardListeners()

          // OTIMIZAÇÃO: Precarregar as primeiras 5 thumbnails imediatamente
          results.slice(0, 5).forEach((item) => {
            preloadImage(getOptimizedThumbnail(item.id, "medium"), item.id).catch(() => {}) // Ignorar erros silenciosamente
          })
        } catch (error) {
          console.error("Erro na pesquisa:", error)
          gridContainer.innerHTML = `
            <div class="error-message">
                <p>Não foi possível carregar os resultados. Verifique sua conexão ou tente novamente mais tarde.</p>
                <button onclick="searchInput.dispatchEvent(new Event('input'))">Tentar novamente</button>
            </div>
          `
        }
      } else if (query.length === 0) {
        // Limpar resultados quando campo estiver vazio
        lastSearchQuery = ""
        clearTimeout(searchTimeout)
        searchInput.value = ""
        gridContainer.innerHTML = ""
        try {
          carregarConteudo(currentTab || "musicas")
        } catch (err) {
          console.warn("Falha ao recarregar conteúdo após limpar busca:", err)
        }
      }
    }, 650) // Evita disparar requisições a cada tecla
  })

  // Botão de limpar (ícone "x") — limpa input e reseta resultados
  const clearButton = document.querySelector(".search-clear")
  if (clearButton) {
    clearButton.addEventListener("click", () => {
      try {
        clearTimeout(searchTimeout)
        searchInput.value = ""
        lastSearchQuery = ""
        gridContainer.innerHTML = ""
        carregarConteudo(currentTab || "musicas")
        searchInput.focus()
      } catch (err) {
        console.error("Erro ao limpar busca:", err)
      }
    })
  }

  const bluetoothBtn = document.querySelector(".bluetooth-btn")
  const iconSpan = bluetoothBtn.querySelector(".icon-svg")

  const svgSound = `
    <svg xmlns="http://www.w3.org/2000/svg" class="sound-icon" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"></polygon>
      <path d="M19.07 4.93a10 10 0 0 1 0 14.14"></path>
      <path d="M15.54 8.46a5 5 0 0 1 0 7.07"></path>
    </svg>
    `

  const svgBluetooth = `
    <svg xmlns="http://www.w3.org/2000/svg" class="bluetooth-icon" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <polyline points="6.5 6.5 17.5 17.5 12 23 12 1 17.5 6.5 6.5 17.5"></polyline>
    </svg>
    `

  bluetoothBtn.addEventListener("click", () => {
    fetch(`https://${safeGetParentResourceName()}/toggleBluetooth`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({}),
    })
      .then((res) => res.json())
      .then((data) => {
        if (data.success) {
          bluetoothBtn.classList.toggle("active", data.mode === "car")
          iconSpan.innerHTML = data.mode === "car" ? svgBluetooth : svgSound
        }
      })
  })

  // Volume: suporte a mini e expandido
  const volumeBtn = document.querySelector(".volume-btn")
  const allVolumeSliders = Array.from(document.querySelectorAll(".volume-slider, .ep-volume-slider"))

  const syncVolumeUI = (vol) => {
    allVolumeSliders.forEach((s) => {
      s.value = vol
      if (typeof updateSliderBackground === "function") updateSliderBackground(s)
    })
    const epVal = document.querySelector(".ep-volume-value")
    if (epVal) epVal.textContent = `${Math.round(vol)}%`
    updateVolumeIcon(vol)
  }

  // Inicializar sliders com volume salvo
  syncVolumeUI(savedVolume)

  allVolumeSliders.forEach((slider) => {
    slider.addEventListener("input", (e) => {
      const volume = Number.parseInt(e.target.value, 10)
      savedVolume = volume
      if (player && player.setVolume) {
        player.setVolume(isGlobalMuted ? 0 : volume)
      }
      syncVolumeUI(volume)
    })
  })

  if (volumeBtn) {
    volumeBtn.addEventListener("click", () => {
      const primarySlider = document.querySelector(".volume-slider") || document.querySelector(".ep-volume-slider")
      if (!primarySlider) return
      const currentVolume = Number.parseInt(primarySlider.value, 10)
      if (currentVolume > 0) {
        primarySlider.dataset.lastVolume = currentVolume
        syncVolumeUI(0)
      } else {
        const last = Number.parseInt(primarySlider.dataset.lastVolume || savedVolume, 10)
        syncVolumeUI(last)
      }
      const newVolume = Number.parseInt(document.querySelector(".volume-slider")?.value || document.querySelector(".ep-volume-slider")?.value || savedVolume, 10)
      if (player && player.setVolume) {
        player.setVolume(isGlobalMuted ? 0 : newVolume)
      }
      savedVolume = newVolume
    })
  }

  document.getElementById("previous")?.addEventListener("click", playPreviousTrack)
  document.getElementById("next")?.addEventListener("click", playNextTrack)

  function dragStart(e) {
    if (e.target.tagName === "INPUT" || e.target.tagName === "BUTTON") return

    initialX = e.clientX - xOffset
    initialY = e.clientY - yOffset

    if (e.target.closest("#app")) {
      isDragging = true
    }
  }

  function drag(e) {
    if (isDragging) {
      e.preventDefault()
      currentX = e.clientX - initialX
      currentY = e.clientY - initialY
      xOffset = currentX
      yOffset = currentY
      setTranslate(currentX, currentY, app)
    }
  }

  function dragEnd() {
    initialX = currentX
    initialY = currentY
    isDragging = false
  }

  function setTranslate(xPos, yPos, el) {
    el.style.transform = `translate(${xPos}px, ${yPos}px)`
  }

  app.addEventListener("mousedown", dragStart)
  document.addEventListener("mousemove", drag)
  document.addEventListener("mouseup", dragEnd)

  // CORRIGIDO: Botão de play/pause que detecta modo DJ e esconde mini player
  const playPauseBtn = document.getElementById("play-pause")
  if (playPauseBtn) {
    playPauseBtn.addEventListener("click", () => {
      if (!player || !currentVideoId) return

      if (isPlaying) {
        // PAUSAR
        player.pauseVideo()
        playPauseBtn.innerHTML = `
            <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                <path d="M8 5V19L19 12L8 5Z"/>
            </svg>
        `
        isPlaying = false

        // NOVO: Esconder mini player imediatamente quando pausar
        MiniPlayer.hide()

        // Enviar comando de pause para o servidor
        if (isDJMode && currentDJStation) {
          MusicSystem.pauseDJTrack({
            stationIndex: currentDJStation.stationIndex,
          })
        } else {
          MusicSystem.pauseTrack()
        }
      } else {
        // TOCAR
        player.playVideo()
        // Garantir que o AudioContext retome quando tocar
        try { resumeAudioContext() } catch (e) {}

        // Enviar NUI para reanexar o prop na mão ao retomar
        try {
          fetch(`https://${safeGetParentResourceName()}/resumePlayback`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({}),
          }).catch(() => {})
        } catch (_) {}
        playPauseBtn.innerHTML = `
            <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                <path d="M6 4h4v16H6V4zm8 0h4v16h-4V4z"/>
            </svg>
        `
        isPlaying = true

        // NOVO: Mostrar mini player quando tocar
        if (MiniPlayer.shouldShow()) {
          MiniPlayer.show()
        }
      }
    })
  }

  const progress = document.querySelector(".progress")
  if (progress) {
    progress.addEventListener("click", function (e) {
      if (!player || !currentVideoId) return

      const progressBar = this.getBoundingClientRect()
      const percent = (e.clientX - progressBar.left) / progressBar.width
      const duration = player.getDuration()
      player.seekTo(duration * percent, true)

      const progressFilled = document.querySelector(".progress-filled")
      if (progressFilled) {
        progressFilled.style.width = `${percent * 100}%`
      }
    })
  }

  // Atualização da barra de progresso
  setInterval(() => {
    if (!player || !player.getCurrentTime || !isPlaying) return

    try {
      const currentTime = player.getCurrentTime()
      const duration = player.getDuration()
      if (!currentTime || !duration) return

      const percent = (currentTime / duration) * 100

      const progressFilled = document.querySelector(".progress-filled")
      const currentTimeEl = document.querySelector(".time.current")
      const totalTimeEl = document.querySelector(".time.total")

      if (progressFilled) progressFilled.style.width = `${percent}%`
      if (currentTimeEl) currentTimeEl.textContent = formatTime(currentTime)
      if (totalTimeEl) totalTimeEl.textContent = formatTime(duration)

      // NOVO: Atualizar progresso do mini player
      if (miniPlayerVisible && MiniPlayer.shouldShow()) {
        const miniProgressFill = document.getElementById("mini-progress-fill")
        if (miniProgressFill) {
          miniProgressFill.style.width = `${percent}%`
        }
      }
    } catch (error) {
      console.error("Erro ao atualizar progresso:", error)
    }
  }, 1000)

  // CORRIGIDO: Manipulador de mensagens - Só mostra mini player se estiver tocando
  window.addEventListener("message", (event) => {
    if (!event.data || !event.data.type) return

    switch (event.data.type) {
      case "ui":
        if (event.data.status) {
          app.classList.add("visible")
          currentTab = "musicas"
          document.querySelectorAll(".tab").forEach((tab) => {
            tab.classList.remove("active")
            if (tab.getAttribute("data-tab") === "musicas" || tab.textContent.toLowerCase() === "músicas") {
              tab.classList.add("active")
            }
          })
          carregarConteudo("musicas")
          // Esconder mini player quando UI principal abre
          MiniPlayer.hide()
        } else {
          app.classList.remove("visible")
          // Resetar modo DJ ao fechar
          isDJMode = false
          currentDJStation = null
          updateDJModeUI()

          // CORRIGIDO: Só mostrar mini player se música estiver TOCANDO
          setTimeout(() => {
            console.log("🔍 UI fechada - verificando se deve mostrar mini player:")
            console.log("  - isPlaying:", isPlaying)
            console.log("  - currentVideoId:", currentVideoId)
            console.log("  - shouldShow:", MiniPlayer.shouldShow())

            if (MiniPlayer.shouldShow()) {
              console.log("✅ Mostrando mini player após fechar UI")
              MiniPlayer.show()
            } else {
              console.log("🚫 Mini player não mostrado - música não está tocando")
            }
          }, 500)
        }
        break

      case "setUIImages": {
        try {
          const bannerUrl = event.data.bannerUrl
          const avatarUrl = event.data.avatarUrl

          // Atualizar banner do header
          if (bannerUrl) {
            const header = document.querySelector('.drag-header')
            if (header) {
              header.style.backgroundImage = `linear-gradient(rgba(0,0,0,0.55), rgba(0,0,0,0.55)), url('${bannerUrl}')`
              header.style.backgroundSize = 'cover'
              header.style.backgroundPosition = 'center'
              header.style.backgroundRepeat = 'no-repeat'
            }
          }

          // Atualizar avatar do perfil
          if (avatarUrl) {
            const profilePicEl = document.querySelector('.profile-pic')
            if (profilePicEl) {
              if (profilePicEl.tagName === 'IMG') {
                profilePicEl.src = avatarUrl
                profilePicEl.onerror = function () {
                  this.src = 'https://i.ibb.co/XghQBGw/unknown.png'
                }
              } else {
                profilePicEl.style.backgroundImage = `url('${avatarUrl}')`
              }
            }
          }
        } catch (e) {
          console.error('Erro ao aplicar setUIImages:', e)
        }
        break
      }
        break

      case "setDJMode":
        console.log("📨 Recebido setDJMode:", event.data)

        isDJMode = event.data.enabled
        currentDJStation = event.data.enabled
          ? {
              stationIndex: event.data.stationIndex,
              stationData: event.data.stationData,
            }
          : null

        console.log("🎧 Modo DJ definido:", isDJMode, currentDJStation)
        updateDJModeUI()
        // Atualizar mini player se estiver visível
        if (miniPlayerVisible) {
          MiniPlayer.updateTrack()
        }
        break

      case "setGlobalMute":
        isGlobalMuted = event.data.muted

        if (player && player.setVolume) {
          const currentVol = Math.min(100, Math.max(0, Number.parseInt(document.querySelector(".volume-slider")?.value || document.querySelector(".ep-volume-slider")?.value || savedVolume || 50, 10)))
          player.setVolume(isGlobalMuted ? 0 : currentVol)
        }

        for (const sourceId in externalPlayers) {
          if (externalPlayers[sourceId].player && externalPlayers[sourceId].player.setVolume) {
            externalPlayers[sourceId].player.setVolume(isGlobalMuted ? 0 : externalPlayers[sourceId].volume)
          }
        }

        for (const stationId in djPlayers) {
          if (djPlayers[stationId].player && djPlayers[stationId].player.setVolume) {
            djPlayers[stationId].player.setVolume(isGlobalMuted ? 0 : djPlayers[stationId].volume)
          }
        }

        updateVolumeIcon(Number.parseInt(document.querySelector(".volume-slider")?.value || 50))
        break

      // Mini player messages
      case "showMiniPlayer":
        console.log("📨 Recebido showMiniPlayer:", event.data)
        // CORRIGIDO: Só mostrar se estiver tocando
        if (event.data.isPlaying) {
          try {
            const miniPlayerElement = document.getElementById("mini-player")
            if (miniPlayerElement) {
              const miniTitle = document.getElementById("mini-title")
              const miniArtist = document.getElementById("mini-artist")
              const miniArtwork = document.getElementById("mini-artwork-img")

              if (event.data.trackData) {
                if (miniTitle) miniTitle.textContent = event.data.trackData.title
                if (miniArtist) miniArtist.textContent = event.data.trackData.artist || "Artista Desconhecido"
                if (miniArtwork) miniArtwork.src = event.data.trackData.thumbnail
              }

              miniPlayerElement.classList.toggle("dj-mode", event.data.djMode)
              miniPlayerElement.classList.toggle("playing", event.data.isPlaying)
              miniPlayerElement.classList.add("visible")

              miniPlayerVisible = true
              miniCurrentTrackData = event.data.trackData
              miniIsPlaying = event.data.isPlaying

              console.log("✅ Mini player mostrado via message")
            }
          } catch (error) {
            console.error("Erro ao processar showMiniPlayer:", error)
          }
        } else {
          console.log("🚫 Mini player não mostrado - música não está tocando")
        }
        break

      case "hideMiniPlayer":
        console.log("📨 Recebido hideMiniPlayer")
        try {
          const miniPlayerElement = document.getElementById("mini-player")
          if (miniPlayerElement) {
            miniPlayerElement.classList.remove("visible")
            miniPlayerVisible = false
            console.log("🔽 Mini player escondido via message")
          }
        } catch (error) {
          console.error("Erro ao processar hideMiniPlayer:", error)
        }
        break

      case "updateMiniPlayer":
        console.log("📨 Recebido updateMiniPlayer:", event.data)
        try {
          if (miniPlayerVisible && event.data.trackData) {
            const miniTitle = document.getElementById("mini-title")
            const miniArtist = document.getElementById("mini-artist")
            const miniArtwork = document.getElementById("mini-artwork-img")
            const miniPlayerElement = document.getElementById("mini-player")

            if (miniTitle) miniTitle.textContent = event.data.trackData.title
            if (miniArtist) miniArtist.textContent = event.data.trackData.artist || "Artista Desconhecido"
            if (miniArtwork) miniArtwork.src = event.data.trackData.thumbnail
            if (miniPlayerElement) {
              miniPlayerElement.classList.toggle("dj-mode", event.data.djMode)
            }

            miniCurrentTrackData = event.data.trackData
          }
        } catch (error) {
          console.error("Erro ao processar updateMiniPlayer:", error)
        }
        break

      case "updateMiniPlayState":
        console.log("📨 Recebido updateMiniPlayState:", event.data.isPlaying)
        try {
          const miniPlayerElement = document.getElementById("mini-player")
          const playPauseBtn = document.getElementById("mini-play-pause")

          if (miniPlayerElement) {
            miniPlayerElement.classList.toggle("playing", event.data.isPlaying)
          }

          if (playPauseBtn) {
            const playIcon = playPauseBtn.querySelector(".play-icon")
            const pauseIcon = playPauseBtn.querySelector(".pause-icon")

            if (event.data.isPlaying) {
              if (playIcon) playIcon.style.display = "none"
              if (pauseIcon) pauseIcon.style.display = "block"
            } else {
              if (playIcon) playIcon.style.display = "block"
              if (pauseIcon) pauseIcon.style.display = "none"
            }
          }

          miniIsPlaying = event.data.isPlaying

          // CORRIGIDO: Esconder se pausou
          if (!event.data.isPlaying) {
            setTimeout(() => {
              MiniPlayer.hide()
            }, 1000)
          }
        } catch (error) {
          console.error("Erro ao processar updateMiniPlayState:", error)
        }
        break

      case "updateMiniProgress":
        try {
          const miniProgressFill = document.getElementById("mini-progress-fill")
          if (miniProgressFill) {
            const progress = Math.max(0, Math.min(100, event.data.progress))
            miniProgressFill.style.width = `${progress}%`
          }
        } catch (error) {
          console.error("Erro ao processar updateMiniProgress:", error)
        }
        break

      case "setMiniDJMode":
        console.log("📨 Recebido setMiniDJMode:", event.data.enabled)
        try {
          const miniPlayerElement = document.getElementById("mini-player")
          if (miniPlayerElement) {
            miniPlayerElement.classList.toggle("dj-mode", event.data.enabled)
          }
        } catch (error) {
          console.error("Erro ao processar setMiniDJMode:", error)
        }
        break

      case "playlists":
        if (Array.isArray(event.data.data)) {
          dataCache.favoritos = event.data.data
          if (currentTab === "favoritos") {
            exibirPlaylists(event.data.data)
          }
          // Se o modal estiver aberto, popular lista e checar auto-add
          const modalEl = document.getElementById('playlist-modal')
          if (modalEl && modalEl.style.display !== 'none') {
            try {
              populatePlaylistModal(event.data.data)
              const createdName = modalEl.dataset.newPlaylistName
              const videoId = modalEl.dataset.videoId
              if (createdName && videoId) {
                const matches = (event.data.data || []).filter(p => p && p.name === createdName)
                const target = matches.length > 0 ? matches[matches.length - 1] : null
                if (target && target.id) {
                  // Limpar flag para evitar múltiplas inserções
                  delete modalEl.dataset.newPlaylistName
                  addVideoToPlaylist(target.id, videoId)
                }
              }
            } catch (err) {
              console.error('Erro ao atualizar modal de playlists:', err)
            }
          }
        }
        break

      case "playlistVideos":
        if (Array.isArray(event.data.data)) {
          playlist = event.data.data
          exibirMusicas(event.data.data, "playlist")
        }
        break

      case "favorites":
        if (Array.isArray(event.data.data)) {
          dataCache.curtidas = event.data.data
          if (currentTab === "curtidas") {
            exibirMusicas(event.data.data, "favorites")
          }
        }
        break

      case "history":
        if (Array.isArray(event.data.data)) {
          trackHistory = event.data.data
          dataCache.musicas = event.data.data
          try {
            localStorage.setItem("trackHistory", JSON.stringify(event.data.data))
          } catch (error) {
            console.error("Erro ao salvar histórico no localStorage:", error)
          }
          if (currentTab === "musicas") {
            exibirMusicas(event.data.data, "history")
          }
        }
        break

      case "setVolume":
        const volume = Math.min(100, Math.max(0, event.data.volume))
        if (player && player.setVolume) {
          player.setVolume(isGlobalMuted ? 0 : volume)
          savedVolume = volume
          document.querySelectorAll(".volume-slider, .ep-volume-slider").forEach((s) => {
            s.value = volume
            updateSliderBackground(s)
          })
          const epVal = document.querySelector(".ep-volume-value")
          if (epVal) epVal.textContent = `${Math.round(volume)}%`
          updateVolumeIcon(volume)
        }
        break

      case "setStereoPan":
        const pan = Math.min(1, Math.max(-1, event.data.pan))
        if (player && player.setStereoPan) {
          player.setStereoPan(pan)
        }
        break

      // Processar addExternalTrack, updateExternalTrack, removeExternalTrack
      case "addExternalTrack":
        if (typeof YT !== "undefined" && YT.Player) {
          createExternalPlayer(event.data.sourceId, event.data.videoId)
        } else {
          setTimeout(() => {
            if (typeof YT !== "undefined" && YT.Player) {
              createExternalPlayer(event.data.sourceId, event.data.videoId)
            }
          }, 1000)
        }
        break

      case "updateExternalTrack":
        updateExternalPlayer(event.data.sourceId, event.data.volume, event.data.pan)
        break

      case "removeExternalTrack":
        removeExternalPlayer(event.data.sourceId)
        break

      case "addDJTrack":
        if (typeof YT !== "undefined" && YT.Player) {
          createDJPlayer(event.data.sourceId, event.data.videoId)
        } else {
          setTimeout(() => {
            if (typeof YT !== "undefined" && YT.Player) {
              createDJPlayer(event.data.sourceId, event.data.videoId)
            }
          }, 1000)
        }
        break

      case "updateDJTrack":
        console.log("🎧 Atualizando volume DJ via message:", event.data.volume)
        updateDJPlayer(event.data.sourceId, event.data.volume, event.data.pan)
        break

      case "removeDJTrack":
        removeDJPlayer(event.data.sourceId)
        break

      case "pausePlayback":
        if (player && player.pauseVideo) {
          player.pauseVideo()
          isPlaying = false
          // Pausar vídeo ambiente de fundo
          try {
            if (ambientPlayer && ambientPlayer.pauseVideo) ambientPlayer.pauseVideo()
          } catch (_) {}
          const playPauseBtn = document.getElementById("play-pause")
          if (playPauseBtn) {
            playPauseBtn.innerHTML = `
                <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M8 5V19L19 12L8 5Z"/>
                </svg>
            `
          }
          // NOVO: Esconder mini player imediatamente
          MiniPlayer.hide()
        }
        break

      case "resumePlayback":
        if (player && player.playVideo) {
          player.playVideo()
          isPlaying = true
          // Retomar vídeo ambiente de fundo
          try {
            if (ambientPlayer && ambientPlayer.playVideo) ambientPlayer.playVideo()
          } catch (_) {}

          // NOVO: Informar ao client para reanexar o prop ao retomar
          try {
            fetch(`https://${safeGetParentResourceName()}/resumePlayback`, {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({}),
            }).catch((error) => console.error("Erro ao retomar reprodução (resumePlayback message):", error))
          } catch (error) {
            console.error("Erro ao enviar resumePlayback (message):", error)
          }
          const playPauseBtn = document.getElementById("play-pause")
          if (playPauseBtn) {
            playPauseBtn.innerHTML = `
                <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M6 4h4v16H6V4zm8 0h4v16h-4V4z"/>
                </svg>
            `
          }
          // NOVO: Mostrar mini player quando retomar
          if (MiniPlayer.shouldShow()) {
            MiniPlayer.show()
          }
        }
        break

      case "forceStop":
        if (player && player.stopVideo) {
          player.stopVideo()
          isPlaying = false
          // Parar vídeo ambiente de fundo
          try {
            if (ambientPlayer && ambientPlayer.stopVideo) ambientPlayer.stopVideo()
          } catch (_) {}
          const playPauseBtn = document.getElementById("play-pause")
          if (playPauseBtn) {
            playPauseBtn.innerHTML = `
                <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M8 5V19L19 12L8 5Z"/>
                </svg>
            `
          }
          // NOVO: Esconder mini player imediatamente
          MiniPlayer.hide()
        }
        break

      case "action":
        if (event.data.action === "mostrarNome" && event.data.nome) {
          const playerNameEl = document.getElementById("player-name")
          if (playerNameEl) {
            playerNameEl.innerText = event.data.nome
          }
        }
        break

      case "updatePlayerProfile":
        {
          console.log("Recebido updatePlayerProfile:", event.data)
          const payload = event.data.profile || event.data.profileData
          console.log("Payload processado:", payload)
          
          if (payload) {
            const playerNameEl = document.getElementById("player-name")
            const profilePicEl = document.querySelector(".profile-pic")
            
            console.log("Elemento player-name encontrado:", playerNameEl)
            console.log("Nome do payload:", payload.name)

            if (playerNameEl && payload.name) {
              playerNameEl.innerText = payload.name
              console.log("Nome atualizado para:", payload.name)
            }

            if (profilePicEl && payload.avatar) {
              console.log("Atualizando avatar para:", payload.avatar)
              if (profilePicEl.tagName === "IMG") {
                profilePicEl.src = payload.avatar
                profilePicEl.onerror = function () {
                  this.src = "https://i.ibb.co/XghQBGw/unknown.png"
                  console.log("Erro ao carregar avatar, usando padrão")
                }
              } else {
                profilePicEl.style.backgroundImage = `url('${payload.avatar}')`
              }
            }
          } else {
            console.log("Payload vazio ou inválido")
          }
        }
        break
    }
  })

  // Função para solicitar dados iniciais do servidor
  function requestInitialData() {
    ;["getPlaylists", "getFavorites", "getHistory"].forEach((endpoint) => {
      fetch(`https://${safeGetParentResourceName()}/${endpoint}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({}),
      }).catch((error) => console.error(`Erro ao buscar ${endpoint}:`, error))
    })
  }

  // Manipulador de tecla ESC para sair
  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
      fetch(`https://${safeGetParentResourceName()}/exit`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({}),
      }).catch((error) => console.error("Erro ao lidar com saída:", error))
    }
  })

  // Verificar mudanças de dispositivos de áudio
  if (navigator.mediaDevices && navigator.mediaDevices.addEventListener) {
    navigator.mediaDevices.addEventListener("devicechange", () => {
      console.log("Dispositivos de áudio alterados")
      fetch(`https://${safeGetParentResourceName()}/audioDeviceChanged`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({}),
      }).catch((error) => console.error("Erro ao lidar com mudança de dispositivo de áudio:", error))
    })
  }

  // Inicializar os botões de abas
  configurarBotoesAbas()

  // Eventos do modal de playlist
  const playlistModal = document.getElementById('playlist-modal')
  const closeModalBtn = document.querySelector('.close-modal')
  const createPlaylistBtn = document.getElementById('create-playlist-btn')
  const newPlaylistInput = document.getElementById('new-playlist-name')

  // Fechar modal
  if (closeModalBtn) {
    closeModalBtn.addEventListener('click', () => {
      if (playlistModal) {
        playlistModal.style.display = 'none'
      }
    })
  }

  // Fechar modal clicando fora dele
  if (playlistModal) {
    playlistModal.addEventListener('click', (e) => {
      if (e.target === playlistModal) {
        playlistModal.style.display = 'none'
      }
    })
  }

  // Criar nova playlist
  if (createPlaylistBtn && newPlaylistInput) {
    createPlaylistBtn.addEventListener('click', async () => {
      const playlistName = newPlaylistInput.value.trim()
      if (playlistName) {
        try {
          // Sinalizar para auto-adicionar após criação, se houver vídeo no modal
          if (playlistModal) {
            playlistModal.dataset.newPlaylistName = playlistName
          }
          const response = await fetch(`https://${safeGetParentResourceName()}/createPlaylist`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name: playlistName })
          })
          
          if (response.ok) {
            showNotification(`Playlist "${playlistName}" criada com sucesso!`, 'success')
            newPlaylistInput.value = ''
            loadPlaylistsForModal() // Recarregar playlists no modal
            
            // Se estiver na aba playlists, recarregar também
            if (currentTab === 'favoritos') {
              loadPlaylists()
            }
          } else {
            showNotification('Erro ao criar playlist', 'error')
          }
        } catch (error) {
          console.error('Erro ao criar playlist:', error)
          showNotification('Erro ao criar playlist', 'error')
        }
      } else {
        showNotification('Digite um nome para a playlist', 'warning')
      }
    })

    // Criar playlist ao pressionar Enter
    newPlaylistInput.addEventListener('keypress', (e) => {
      if (e.key === 'Enter') {
        createPlaylistBtn.click()
      }
    })
  }

  // Carregar dados iniciais
  requestInitialData()

  // Configurar ações do now-playing (favoritar e adicionar à playlist)
  if (typeof setupNowPlayingActions === 'function') {
    setupNowPlayingActions()
  }

  // Log de inicialização
  console.log("🎵 Spotify inicializado!")
  console.log("🔍 Sistema de busca YouTube v3 carregado")
  console.log("📱 Mini player integrado")
  console.log("🎧 Sistema DJ ativo")
})

// Detecta alteração no slider manualmente
document.addEventListener("DOMContentLoaded", () => {
  const sliders = document.querySelectorAll(".volume-slider, .ep-volume-slider")
  sliders.forEach((slider) => {
    slider.addEventListener("input", function (e) {
      const userVolume = Number.parseInt(e.target.value, 10)
      const maxVolume = 100

      fetch(`https://${safeGetParentResourceName()}/setUserMaxVolume`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          maxVolume: userVolume === maxVolume,
        }),
      })

      updateSliderBackground(this)
    })

    updateSliderBackground(slider)
  })
})
;(() => {
  try {
    const enabled = localStorage.getItem('foxzin_debug') === 'true'
    const noop = function () {}
    if (!enabled) {
      console.log = noop
      console.info = noop
      console.warn = noop
    }
    window.setFoxzinDebug = (v) => {
      try {
        localStorage.setItem('foxzin_debug', v ? 'true' : 'false')
      } catch (_) {}
    }
  } catch (_) {}
})()

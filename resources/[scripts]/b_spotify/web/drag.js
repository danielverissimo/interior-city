// Sistema de arrastar corrigido - sem pulo inicial
document.addEventListener("DOMContentLoaded", () => {
  const app = document.getElementById("app")
  const dragHeader = document.querySelector(".drag-header")

  let isDragging = false
  let currentX = 0
  let currentY = 0
  let initialX = 0
  let initialY = 0
  let xOffset = 0
  let yOffset = 0

  // Função para obter a posição atual do elemento
  function getCurrentTransform(el) {
    const style = window.getComputedStyle(el)
    const matrix = style.transform

    if (matrix === "none" || matrix === undefined) {
      return { x: 0, y: 0 }
    }

    // Extrair valores da matriz de transformação (suporta matrix e matrix3d)
    let x = 0
    let y = 0

    if (matrix.startsWith("matrix3d(")) {
      const match = matrix.match(/matrix3d\(([^)]+)\)/)
      if (match && match[1]) {
        const values = match[1].split(", ")
        // Para matrix3d, os offsets de translação estão nas posições 12 (x) e 13 (y)
        x = Number.parseFloat(values[12]) || 0
        y = Number.parseFloat(values[13]) || 0
      }
    } else {
      const match = matrix.match(/matrix\(([^)]+)\)/)
      if (match && match[1]) {
        const values = match[1].split(", ")
        x = Number.parseFloat(values[4]) || 0
        y = Number.parseFloat(values[5]) || 0
      } else {
        // Se não houver correspondência, retornar padrão
        return { x: 0, y: 0 }
      }
    }

    return { x, y }
  }

  // Função para iniciar o arraste
  function dragStart(e) {
    // Verificar se o clique foi em elementos que não devem arrastar
    if (
      e.target.closest(".window-controls") ||
      e.target.tagName === "BUTTON" ||
      e.target.tagName === "INPUT" ||
      e.target.closest("button") ||
      e.target.closest("input")
    ) {
      return
    }

    // Só permitir arrastar se clicar no header
    if (!e.target.closest(".drag-header")) {
      return
    }

    // Obter posição atual do elemento
    const currentTransform = getCurrentTransform(app)
    xOffset = currentTransform.x
    yOffset = currentTransform.y

    if (e.type === "touchstart") {
      initialX = e.touches[0].clientX - xOffset
      initialY = e.touches[0].clientY - yOffset
    } else {
      initialX = e.clientX - xOffset
      initialY = e.clientY - yOffset
    }

    isDragging = true

    // Feedback visual
    if (dragHeader) {
      dragHeader.style.cursor = "grabbing"
      app.style.userSelect = "none"
    }

    // Prevenir seleção de texto
    e.preventDefault()
  }

  // Função para arrastar
  function drag(e) {
    if (!isDragging) return

    e.preventDefault()

    if (e.type === "touchmove") {
      currentX = e.touches[0].clientX - initialX
      currentY = e.touches[0].clientY - initialY
    } else {
      currentX = e.clientX - initialX
      currentY = e.clientY - initialY
    }

    xOffset = currentX
    yOffset = currentY

    setTranslate(currentX, currentY, app)
  }

  // Função para finalizar o arraste
  function dragEnd(e) {
    if (!isDragging) return

    initialX = currentX
    initialY = currentY
    isDragging = false

    // Restaurar cursor e seleção
    if (dragHeader) {
      dragHeader.style.cursor = "move"
      app.style.userSelect = ""
    }
  }

  // Função para aplicar a transformação
  function setTranslate(xPos, yPos, el) {
    el.style.transform = `translate(calc(-50% + ${xPos}px), calc(-50% + ${yPos}px))`
  }

  // Event listeners para mouse
  if (dragHeader) {
    dragHeader.addEventListener("mousedown", dragStart, false)
  }

  document.addEventListener("mousemove", drag, false)
  document.addEventListener("mouseup", dragEnd, false)

  // Event listeners para touch (mobile)
  if (dragHeader) {
    dragHeader.addEventListener("touchstart", dragStart, { passive: false })
  }

  document.addEventListener("touchmove", drag, { passive: false })
  document.addEventListener("touchend", dragEnd, false)

  // Configurar botões de controle da janela
  const minimizeBtn = document.querySelector(".minimize-btn")
  const closeBtn = document.querySelector(".close-btn")

  if (minimizeBtn) {
    minimizeBtn.addEventListener("click", (e) => {
      e.stopPropagation()
      app.classList.remove("visible")

      // Enviar mensagem para o FiveM
      fetch(`https://${getResourceName()}/minimize`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({}),
      }).catch((err) => console.error("Erro ao minimizar:", err))
    })
  }

  if (closeBtn) {
    closeBtn.addEventListener("click", (e) => {
      e.stopPropagation()
      app.classList.remove("visible")

      // Enviar mensagem para o FiveM
      fetch(`https://${getResourceName()}/exit`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({}),
      }).catch((err) => console.error("Erro ao fechar:", err))
    })
  }

  // Função auxiliar para obter o nome do resource
  function getResourceName() {
    if (typeof window.GetParentResourceName === "function") {
      return window.GetParentResourceName()
    }
    return "foxzinlafy" // fallback
  }

  // Inicializar cursor do header
  if (dragHeader) {
    dragHeader.style.cursor = "move"
  }

  console.log("✅ Sistema de arrastar inicializado sem pulo inicial")
})

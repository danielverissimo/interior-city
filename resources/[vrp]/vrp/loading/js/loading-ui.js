(() => {
  const audio = document.getElementById('music');
  const toggle = document.querySelector('.button--volume');
  const panel = document.getElementById('volume-panel');
  const slider = document.getElementById('music-volume');
  const value = document.getElementById('volume-value');
  const mute = document.querySelector('.volume-mute');
  let lastVolume = 0.5;

  function syncVolume() {
    const silent = audio.muted || audio.volume === 0;
    const percent = silent ? 0 : Math.round(audio.volume * 100);
    slider.value = percent;
    slider.style.setProperty('--volume-fill', percent + '%');
    value.textContent = percent + '%';
    toggle.classList.toggle('is-active', silent);
    toggle.querySelector('i').className = silent ? 'ph-speaker-x' : 'ph-speaker-high';
    mute.textContent = silent ? 'Ativar som' : 'Mutar música';
    mute.setAttribute('aria-pressed', String(silent));
  }

  function closePanel() {
    panel.hidden = true;
    toggle.setAttribute('aria-expanded', 'false');
  }

  toggle.addEventListener('click', () => {
    panel.hidden = !panel.hidden;
    toggle.setAttribute('aria-expanded', String(!panel.hidden));
  });
  slider.addEventListener('input', () => {
    audio.volume = Number(slider.value) / 100;
    audio.muted = false;
    if (audio.volume > 0) lastVolume = audio.volume;
    syncVolume();
  });
  mute.addEventListener('click', () => {
    if (audio.muted || audio.volume === 0) {
      if (audio.volume === 0) audio.volume = lastVolume;
      audio.muted = false;
    } else {
      lastVolume = audio.volume;
      audio.muted = true;
    }
    syncVolume();
  });
  audio.addEventListener('volumechange', syncVolume);
  document.addEventListener('click', (event) => {
    if (!event.target.closest('.volume-control')) closePanel();
  });
  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && !panel.hidden) {
      closePanel();
      toggle.focus();
    }
  });
  // Keep the player's space shortcut from firing while using volume controls.
  panel.addEventListener('keyup', (event) => event.stopPropagation());
  syncVolume();

  const progress = document.getElementById('city-progress');
  const fill = document.getElementById('city-progress-fill');
  const percent = document.getElementById('loading-percent');
  window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || data.eventName !== 'loadProgress' ||
        typeof data.loadFraction !== 'number' || !Number.isFinite(data.loadFraction)) return;
    const amount = Math.round(Math.max(0, Math.min(1, data.loadFraction)) * 100);
    fill.style.width = amount + '%';
    percent.textContent = amount + '%';
    progress.setAttribute('aria-valuenow', String(amount));
  });
})();

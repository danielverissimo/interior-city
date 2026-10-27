(() => {
  const state = {
    enabled: false,
    hudOpen: true,
    hunger: 100,
    thirst: 100,
    vehicle: false,
    stats: 1,
    velocimeter: 2
  };

  const clamp = (value) => Math.max(0, Math.min(100, Number(value) || 0));
  const normalizeLayout = (layout) => {
    if (!layout || typeof layout !== 'object') return;
    const stats = Number(layout.stats);
    const velocimeter = Number(layout.velocimeter);
    if (stats === 1 || stats === 2) state.stats = stats;
    if (velocimeter === 1 || velocimeter === 2) state.velocimeter = velocimeter;
  };

  try {
    const storedLayout = window.localStorage ? window.localStorage.getItem('hud-state') : null;
    if (storedLayout) normalizeLayout(JSON.parse(storedLayout));
  } catch (_) {}

  const ringPath = 'M40.25 21C40.25 26.1054 38.2219 31.0017 34.6118 34.6118C31.0017 38.2219 26.1054 40.25 21 40.25C15.8946 40.25 10.9983 38.2219 7.3882 34.6118C3.77812 31.0017 1.75 26.1054 1.75 21C1.75 15.8946 3.77812 11.0017 7.38819 7.3882C10.9983 3.77812 15.8946 1.75 21 1.75C26.1054 1.75 31.0017 3.77812 34.6118 7.38819C38.2219 10.9983 40.25 15.8946 40.25 21Z';

  const ring = (type) => `
    <svg class="needs-ring" width="42" height="42" viewBox="0 0 42 42" fill="none" aria-hidden="true">
      <defs>
        <mask id="needs-strokes-${type}" maskUnits="userSpaceOnUse" x="0" y="0" width="42" height="42">
          <path d="${ringPath}" stroke="white" stroke-width="4" stroke-dasharray="10 2" />
        </mask>
      </defs>
      <path class="needs-ring-track" d="${ringPath}" stroke="#FFFFFF33" stroke-width="4" stroke-dasharray="100.01" pathLength="100.01" mask="url(#needs-strokes-${type})" />
      <path class="needs-ring-progress" d="${ringPath}" stroke="var(--needs-color)" stroke-width="4" stroke-dasharray="100.01" pathLength="100.01" stroke-dashoffset="0" mask="url(#needs-strokes-${type})" />
    </svg>
  `;

  const root = document.createElement('div');
  root.id = 'needs-hud';
  root.className = 'needs-hud';
  root.setAttribute('aria-hidden', 'true');
  root.innerHTML = `
    <div class="needs-row needs-food" data-need="hunger">
      ${ring('hunger')}
      <div class="needs-icon"><img src="./icons/food.svg" alt=""></div>
      <div class="needs-bar" aria-label="Fome">
        ${Array.from({ length: 13 }, (_, i) => `<span data-segment="${i}"></span>`).join('')}
      </div>
    </div>
    <div class="needs-row needs-water" data-need="thirst">
      ${ring('thirst')}
      <div class="needs-icon"><img src="./icons/water.svg" alt=""></div>
      <div class="needs-bar" aria-label="Sede">
        ${Array.from({ length: 13 }, (_, i) => `<span data-segment="${i}"></span>`).join('')}
      </div>
    </div>
  `;
  document.body.appendChild(root);

  const rows = {
    hunger: root.querySelector('[data-need="hunger"]'),
    thirst: root.querySelector('[data-need="thirst"]')
  };

  function updateRow(type, value) {
    const row = rows[type];
    if (!row) return;

    const normalized = clamp(value);
    const segments = row.querySelectorAll('[data-segment]');
    const filled = Math.round((normalized / 100) * segments.length);
    const ringProgress = row.querySelector('.needs-ring-progress');

    row.setAttribute('data-value', String(Math.round(normalized)));
    segments.forEach((segment, index) => segment.classList.toggle('is-filled', index < filled));
    row.classList.toggle('is-critical', normalized <= 20);

    if (ringProgress) {
      ringProgress.style.strokeDashoffset = String(100.01 - (normalized / 100) * 100.01);
    }
  }

  function render() {
    root.classList.toggle('is-visible', state.enabled && state.hudOpen);
    root.classList.toggle('vehicle-open', state.vehicle);
    root.classList.toggle('hud-stats-1', state.stats === 1);
    root.classList.toggle('hud-stats-2', state.stats === 2);
    root.classList.toggle('hud-velo-1', state.velocimeter === 1);
    root.classList.toggle('hud-velo-2', state.velocimeter === 2);
    root.setAttribute('aria-hidden', state.enabled && state.hudOpen ? 'false' : 'true');

    updateRow('hunger', state.hunger);
    updateRow('thirst', state.thirst);
  }

  window.addEventListener('hud:layout', (event) => {
    normalizeLayout(event.detail);
    render();
  });

  window.addEventListener('message', (event) => {
    const message = event.data || {};

    if (message.action === 'needs:update') {
      const data = message.data || {};
      state.enabled = data.enabled === true;
      state.hunger = clamp(data.hunger);
      state.thirst = clamp(data.thirst);
      render();
      return;
    }

    if (message.action === 'needs:layout') {
      normalizeLayout(message.data || {});
      render();
      return;
    }

    if (message.action === 'open') {
      state.hudOpen = true;
      render();
      return;
    }

    if (message.action === 'close') {
      state.hudOpen = false;
      render();
      return;
    }

    if (message.action === 'update' && message.data && message.data.vehicle) {
      const vehicle = message.data.vehicle;
      state.vehicle = vehicle.show === true || vehicle.data === true;
      render();
    }
  });

  render();
})();

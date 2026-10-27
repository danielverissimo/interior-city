(() => {
  let radioChannel = 0;
  let powered = true;

  const container = document.getElementById('container');
  const channelInput = document.getElementById('RadioChannel');
  const powerButton = document.getElementById('power');
  const form = document.getElementById('Radio-Form');
  const volume = document.getElementById('volume');

  const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'radio';

  async function post(endpoint, payload = {}) {
    try {
      const response = await fetch(`https://${resource}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(payload)
      });
      return await response.json();
    } catch (_) {
      return { ok: false };
    }
  }

  function normalizeChannel(value) {
    const number = Number(value);
    if (!Number.isFinite(number) || number <= 0) return 0;
    return Math.floor(number);
  }

  function showRadio() {
    container.style.display = 'block';
    if (powered) {
      channelInput.placeholder = '1 - 9999';
      channelInput.value = radioChannel > 0 ? String(radioChannel) : '';
    } else {
      channelInput.value = '';
      channelInput.placeholder = 'Off';
    }
    channelInput.focus();
  }

  function hideRadio() {
    container.style.display = 'none';
  }

  async function saveChannel(closeAfter = false) {
    const desired = powered ? normalizeChannel(channelInput.value) : 0;
    const response = await post(closeAfter ? 'close' : 'poweredOn', { channel: desired });
    if (response?.ok !== false) radioChannel = desired;
    if (closeAfter && response?.ok !== false) hideRadio();
  }

  window.addEventListener('message', (event) => {
    const item = event.data || {};
    if (item.reset === true) {
      post('cleanClose', {});
      hideRadio();
      return;
    }
    if (item.set === true) {
      radioChannel = normalizeChannel(item.setChannel);
      if (powered) channelInput.value = radioChannel > 0 ? String(radioChannel) : '';
    }
    if (item.open === true) showRadio();
    if (item.open === false) hideRadio();
  });

  form?.addEventListener('submit', async (event) => {
    event.preventDefault();
    await saveChannel(true);
  });

  powerButton?.addEventListener('click', async () => {
    powered = !powered;
    await post('click', {});
    if (powered) {
      channelInput.placeholder = '1 - 9999';
      channelInput.value = radioChannel > 0 ? String(radioChannel) : '';
      await post('poweredOn', { channel: radioChannel });
    } else {
      channelInput.value = '';
      channelInput.placeholder = 'Off';
      await post('poweredOff', {});
    }
  });

  channelInput?.addEventListener('keydown', async (event) => {
    if (event.key !== 'Enter') return;
    event.preventDefault();
    await post('click', {});
    await saveChannel(false);
  });

  volume?.addEventListener('input', () => {
    post('volumeRadio', { volume: Number(volume.value || 0.5) });
  });

  document.addEventListener('keyup', async (event) => {
    if (event.key !== 'Escape') return;
    await saveChannel(true);
  });
})();

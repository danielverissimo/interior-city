const spawn = (name) => {
  fetch('http://m_survival/spawn', {
    method: 'POST',
    body: JSON.stringify({ name })
  })
}

function formatTime(seconds) {
  const safeSeconds = Math.max(0, Number(seconds) || 0);
  const minutes = Math.floor(safeSeconds / 60);
  const restSeconds = safeSeconds % 60;
  return `${minutes.toString().padStart(2, '0')}:${restSeconds.toString().padStart(2, '0')}`;
}

let deathUiOpen = false;
let medicRequestBusy = false;
let medicRequestSent = false;

function setMedicState(state, message = '') {
  const button = document.querySelector('#medic-call-button');
  const feedback = document.querySelector('#medic-call-feedback');
  if (!button || !feedback) return;

  button.classList.remove('is-loading', 'is-success', 'is-error');
  feedback.classList.remove('is-success', 'is-error');

  if (state === 'loading') {
    button.disabled = true;
    button.classList.add('is-loading');
    button.querySelector('strong').textContent = 'ENVIANDO CHAMADO...';
    feedback.textContent = 'Localizando médicos disponíveis...';
  } else if (state === 'success') {
    button.disabled = true;
    button.classList.add('is-success');
    button.querySelector('strong').textContent = 'MÉDICO SOLICITADO';
    feedback.classList.add('is-success');
    feedback.textContent = message || 'Seu chamado foi enviado. Aguarde um médico aceitar.';
  } else if (state === 'error') {
    button.disabled = false;
    button.classList.add('is-error');
    button.querySelector('strong').textContent = 'CHAMAR MÉDICO';
    feedback.classList.add('is-error');
    feedback.textContent = message || 'Não foi possível enviar o chamado.';
  } else {
    button.disabled = false;
    button.querySelector('strong').textContent = 'CHAMAR MÉDICO';
    feedback.textContent = '';
  }
}

async function callMedic() {
  if (medicRequestBusy || medicRequestSent) return;
  medicRequestBusy = true;
  setMedicState('loading');

  try {
    const response = await fetch('http://m_survival/callMedic', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({})
    });

    const payload = await response.json().catch(() => ({ ok: false, message: 'Resposta inválida do servidor.' }));
    if (payload && payload.ok) {
      medicRequestSent = true;
      setMedicState('success', payload.message || 'Paciente desmaiado solicitou médico.');
    } else {
      setMedicState('error', payload?.message || 'Não foi possível enviar o chamado médico.');
    }
  } catch (_) {
    setMedicState('error', 'Não foi possível comunicar com o sistema médico.');
  } finally {
    medicRequestBusy = false;
  }
}

let called = false;
function callStaff() {
  if (called) return;
  setTimeout(() => called = false, 5000);
  fetch('http://m_survival/callStaff', { method: 'POST' });
  called = true;
}

const notify = ({ id, distance }) => {
  document.querySelector('#id').innerHTML = id;
  document.querySelector('#distance').innerHTML = `${distance.toLocaleString('pt-BR')}m`;
  document.querySelector('.notify').style.display = 'flex';
}

window.addEventListener('message', ({ data }) => {
  if (data.action === 'open') {
    const timer = Math.max(0, Number(data.deathtimer) || 0);

    if (!deathUiOpen) {
      deathUiOpen = true;
      medicRequestBusy = false;
      medicRequestSent = data.medicCalled === true;
      setMedicState(medicRequestSent ? 'success' : 'idle');
      document.querySelector('.timer-progress').style.animation = 'none';
      void document.querySelector('.timer-progress').offsetWidth;
      document.querySelector('.timer-progress').style.animation = `progress ${timer}s linear forwards`;
    } else if (data.medicCalled === true && !medicRequestSent) {
      medicRequestSent = true;
      setMedicState('success');
    }

    if (timer > 0) {
      document.querySelector('.medic-call').style.display = 'flex';
      document.querySelector('.locales').style.display = 'none';
      document.querySelector('.timer-value').innerHTML = ` ${formatTime(timer)}`;
    } else {
      document.querySelector('.medic-call').style.display = 'none';
      document.querySelector('.locales').style.display = 'flex';
    }

    document.body.style.display = 'block';
  } else if (data.action === 'close') {
    deathUiOpen = false;
    medicRequestBusy = false;
    medicRequestSent = false;
    setMedicState('idle');
    document.body.style.display = 'none';
  }

  if (data.action === 'notify') notify(data);
  if (data.action === 'notify:close') document.querySelector('.notify').style.display = 'none';
});

if (!window.invokeNative) {
  window.postMessage({ action: 'open', deathtimer: 180, medicCalled: false });
}

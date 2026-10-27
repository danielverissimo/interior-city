const panel = document.getElementById('wall-panel');
const closeButton = document.getElementById('close');
const inputs = [...document.querySelectorAll('[data-setting]')];

const resource = typeof GetParentResourceName === 'function'
    ? GetParentResourceName()
    : 'Wall';

function post(endpoint, payload = {}) {
    return fetch(`https://${resource}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(payload)
    }).catch(() => {});
}

function syncSettings(settings = {}) {
    inputs.forEach((input) => {
        const key = input.dataset.setting;
        if (Object.prototype.hasOwnProperty.call(settings, key)) {
            input.checked = settings[key] === true;
        }
    });
}

function setVisible(visible) {
    panel.classList.toggle('hidden', !visible);
}

inputs.forEach((input) => {
    input.addEventListener('change', () => {
        post('updateSetting', {
            key: input.dataset.setting,
            value: input.checked
        });
    });
});

closeButton.addEventListener('click', () => post('close'));

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        post('close');
    }
});

window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.action === 'setVisible') {
        if (data.settings) syncSettings(data.settings);
        setVisible(data.visible === true);
    }

    if (data.action === 'syncSettings' && data.settings) {
        syncSettings(data.settings);
    }
});

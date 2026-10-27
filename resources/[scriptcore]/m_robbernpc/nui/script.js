const prompt = document.getElementById('trunk-prompt');
const keyLabel = document.getElementById('key-label');
const actionLabel = document.getElementById('action-label');
const trackingWarning = document.getElementById('tracking-warning');
const trackingTitle = document.getElementById('tracking-title');
const trackingTime = document.getElementById('tracking-time');
const drugOffer = document.getElementById('drug-offer');
const drugOfferText = document.getElementById('drug-offer-text');
const drugConfirmKey = document.getElementById('drug-confirm-key');
const drugCancelKey = document.getElementById('drug-cancel-key');

let trackerInterval = null;
let trackerEndsAt = 0;

function formatTime(totalSeconds) {
    const seconds = Math.max(0, Math.ceil(totalSeconds));
    const minutes = Math.floor(seconds / 60);
    const remain = seconds % 60;
    return `${String(minutes).padStart(2, '0')}:${String(remain).padStart(2, '0')}`;
}

function stopTrackerWarning() {
    if (trackerInterval) {
        clearInterval(trackerInterval);
        trackerInterval = null;
    }

    trackerEndsAt = 0;
    trackingWarning.classList.remove('visible');
}

function startTrackerWarning(seconds, text) {
    stopTrackerWarning();

    const duration = Math.max(1, Number(seconds) || 90);
    trackerEndsAt = Date.now() + (duration * 1000);
    trackingTitle.textContent = String(text || 'VOCÊ ESTÁ SENDO RASTREADO,FUJA!').toUpperCase();
    trackingTime.textContent = formatTime(duration);
    trackingWarning.classList.add('visible');

    trackerInterval = setInterval(() => {
        const remaining = (trackerEndsAt - Date.now()) / 1000;
        trackingTime.textContent = formatTime(remaining);

        if (remaining <= 0) {
            stopTrackerWarning();
        }
    }, 100);
}

window.addEventListener('message', ({ data }) => {
    if (!data || !data.action) return;

    if (data.action === 'show') {
        if (typeof data.x === 'number') prompt.style.left = `${data.x}%`;
        if (typeof data.y === 'number') prompt.style.top = `${data.y}%`;
        if (data.key) keyLabel.textContent = String(data.key).toUpperCase();
        if (data.text) actionLabel.textContent = String(data.text).toUpperCase();
        prompt.classList.add('visible');
        return;
    }

    if (data.action === 'hide') {
        prompt.classList.remove('visible');
        return;
    }

    if (data.action === 'offerShow') {
        drugOfferText.textContent = String(data.text || 'Deseja realizar a venda?');
        drugConfirmKey.textContent = String(data.confirmKey || 'N').toUpperCase();
        drugCancelKey.textContent = String(data.cancelKey || 'BACKSPACE').toUpperCase();
        drugOffer.classList.add('visible');
        drugOffer.setAttribute('aria-hidden', 'false');
        return;
    }

    if (data.action === 'offerHide') {
        drugOffer.classList.remove('visible');
        drugOffer.setAttribute('aria-hidden', 'true');
        return;
    }

    if (data.action === 'trackerStart') {
        startTrackerWarning(data.seconds, data.text);
        return;
    }

    if (data.action === 'trackerStop') {
        stopTrackerWarning();
    }
});

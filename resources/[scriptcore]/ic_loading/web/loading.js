const video = document.querySelector('#intro');
const sound = document.querySelector('#sound');
let progress = 0;
video.volume = .4;
video.addEventListener('playing', () => document.body.classList.add('video-ready'));
video.addEventListener('error', () => {
    document.body.classList.remove('video-ready');
    console.error('[ic_loading] Falha de mídia:', video.error?.code ?? 'unknown');
});
sound.addEventListener('click', () => {
    video.muted = !video.muted;
    sound.textContent = video.muted ? 'Ativar som' : 'Silenciar';
    sound.setAttribute('aria-pressed', String(!video.muted));
    video.play().catch(() => {});
});
window.addEventListener('message', ({ data }) => {
    if (data?.eventName !== 'loadProgress' || typeof data.loadFraction !== 'number' || !Number.isFinite(data.loadFraction)) return;
    progress = Math.max(progress, Math.min(100, Math.max(0, Math.round(data.loadFraction * 100))));
    document.querySelector('#bar').style.width = `${progress}%`;
    document.querySelector('#percentage').textContent = `${progress}%`;
    document.querySelector('#progress').setAttribute('aria-valuenow', String(progress));
});
// FiveM owns the loading-screen lifetime. Never keep a loading NUI open over spawn.

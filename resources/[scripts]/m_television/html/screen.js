let player = null;
let playerType = null;
let wantedVolume = 50;
let currentRequest = 0;

const media = document.getElementById('media');
const signal = document.getElementById('signal');
const overlay = document.querySelector('#overlay span');
const notification = document.getElementById('notification');

// GetParentResourceName() is available in the regular NUI page, but it is not
// guaranteed to exist inside a DUI browser. Resolve the resource name from the
// cfx-nui hostname as a safe fallback so the TV screen can still call Lua NUI
// callbacks when it is loaded through CreateDui().
function getResourceName() {
    try {
        if (typeof GetParentResourceName === 'function') {
            const name = GetParentResourceName();
            if (name) return name;
        }
    } catch (_) {}

    try {
        const host = String(window.location.hostname || '');
        if (host.startsWith('cfx-nui-')) {
            const name = host.substring('cfx-nui-'.length);
            if (name) return name;
        }
    } catch (_) {}

    return 'm_television';
}

const RESOURCE_NAME = getResourceName();

function nuiPost(name, data = {}) {
    try {
        return fetch(`https://${RESOURCE_NAME}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data)
        }).catch(() => null);
    } catch (_) {
        return Promise.resolve(null);
    }
}

function clearPlayer() {
    const oldPlayer = player;
    const oldType = playerType;

    player = null;
    playerType = null;

    try {
        if (oldType === 'youtube' && oldPlayer && typeof oldPlayer.destroy === 'function') {
            oldPlayer.destroy();
        } else if (oldType === 'twitch' && oldPlayer && typeof oldPlayer.destroy === 'function') {
            oldPlayer.destroy();
        } else if (oldType === 'video' && oldPlayer) {
            oldPlayer.pause?.();
            oldPlayer.removeAttribute?.('src');
            oldPlayer.load?.();
        }
    } catch (_) {}

    media.replaceChildren();
}

function setSignal(show) {
    signal.style.display = show ? 'flex' : 'none';
}

function channelDisplay(channel) {
    if (channel) {
        overlay.textContent = `CH ${String(channel).padStart(2, '0')}`;
        overlay.style.display = 'block';
    } else {
        overlay.textContent = '';
        overlay.style.display = 'none';
    }
}

function parseSource(raw) {
    if (!raw) return null;

    const url = String(raw).trim();
    let match = url.match(/(?:youtu\.be\/|youtube\.com\/(?:watch\?.*?[?&]?v=|embed\/|shorts\/|live\/))([\w-]{11})/i);
    if (!match) {
        match = url.match(/[?&]v=([\w-]{11})/i);
    }
    if (match) return { type: 'youtube', id: match[1], url };

    match = url.match(/twitch\.tv\/([^/?#]+)/i);
    if (match && match[1] && !['videos', 'directory'].includes(match[1].toLowerCase())) {
        return { type: 'twitch', id: match[1], url };
    }

    const clean = url.split('?')[0].toLowerCase();
    if (/\.(png|jpg|jpeg|gif|webp|bmp)$/.test(clean)) return { type: 'image', url };
    if (/\.(mp4|webm|ogg|mov|m4v)$/.test(clean)) return { type: 'video', url };

    return { type: 'unknown', url };
}

function waitFor(test, timeout = 10000) {
    return new Promise(resolve => {
        const start = Date.now();
        const timer = setInterval(() => {
            let ready = false;
            try { ready = !!test(); } catch (_) {}

            if (ready) {
                clearInterval(timer);
                resolve(true);
            } else if (Date.now() - start > timeout) {
                clearInterval(timer);
                resolve(false);
            }
        }, 50);
    });
}

async function playYoutube(source, time, requestId) {
    clearPlayer();
    setSignal(false);
    channelDisplay(null);

    const holder = document.createElement('div');
    holder.id = `youtube-player-${requestId}`;
    media.appendChild(holder);

    const ok = await waitFor(() => window.YT && typeof window.YT.Player === 'function');
    if (!ok || requestId !== currentRequest) {
        if (requestId === currentRequest) setSignal(true);
        return;
    }

    playerType = 'youtube';

    try {
        player = new YT.Player(holder.id, {
            height: '100%',
            width: '100%',
            videoId: source.id,
            playerVars: {
                autoplay: 1,
                controls: 1,
                playsinline: 1,
                rel: 0,
                start: Math.max(0, Math.floor(Number(time) || 0))
            },
            events: {
                onReady: event => {
                    if (requestId !== currentRequest) return;
                    try {
                        // Starting muted first avoids CEF autoplay blocking. We unmute
                        // immediately after playback has actually been requested.
                        event.target.mute();
                        event.target.setVolume(wantedVolume);
                        if (Number(time) > 0) event.target.seekTo(Math.max(0, Number(time)), true);
                        event.target.playVideo();
                        setTimeout(() => {
                            if (requestId !== currentRequest) return;
                            try {
                                event.target.unMute();
                                event.target.setVolume(wantedVolume);
                            } catch (_) {}
                        }, 250);
                    } catch (_) {}
                },
                onStateChange: event => {
                    if (requestId !== currentRequest) return;
                    try {
                        if (event.data === YT.PlayerState.PLAYING) {
                            event.target.unMute();
                            event.target.setVolume(wantedVolume);
                            setSignal(false);
                        }
                    } catch (_) {}
                },
                onError: () => {
                    if (requestId === currentRequest) setSignal(true);
                }
            }
        });
    } catch (_) {
        if (requestId === currentRequest) setSignal(true);
    }
}

async function playTwitch(source, requestId) {
    clearPlayer();
    setSignal(false);
    channelDisplay(null);

    const holder = document.createElement('div');
    holder.id = `twitch-player-${requestId}`;
    media.appendChild(holder);

    const ok = await waitFor(() => window.Twitch && typeof window.Twitch.Player === 'function');
    if (!ok || requestId !== currentRequest) {
        if (requestId === currentRequest) setSignal(true);
        return;
    }

    playerType = 'twitch';

    try {
        const parentHost = String(window.location.hostname || 'localhost');
        player = new Twitch.Player(holder.id, {
            width: '100%',
            height: '100%',
            channel: source.id,
            autoplay: true,
            muted: false,
            parent: [parentHost, 'localhost']
        });

        const readyEvent = (window.Twitch.Player && Twitch.Player.READY) || (window.Twitch.Embed && Twitch.Embed.VIDEO_READY);
        if (readyEvent && player.addEventListener) {
            player.addEventListener(readyEvent, () => {
                if (requestId !== currentRequest) return;
                try {
                    player.setMuted(false);
                    player.setVolume(wantedVolume / 100);
                    setSignal(false);
                } catch (_) {}
            });
        }
    } catch (_) {
        if (requestId === currentRequest) setSignal(true);
    }
}

function playImage(source) {
    clearPlayer();
    playerType = 'image';

    const img = document.createElement('img');
    img.src = source.url;
    img.alt = '';
    img.className = 'fit-cover';
    img.addEventListener('load', () => setSignal(false));
    img.addEventListener('error', () => setSignal(true));
    media.appendChild(img);

    setSignal(false);
    channelDisplay(null);
}

function playDirectVideo(source, time) {
    clearPlayer();
    playerType = 'video';

    const video = document.createElement('video');
    video.src = source.url;
    video.autoplay = true;
    video.controls = true;
    video.playsInline = true;
    video.preload = 'auto';
    video.volume = wantedVolume / 100;

    video.addEventListener('loadedmetadata', () => {
        try {
            if (Number(time) > 0) video.currentTime = Math.max(0, Number(time));
            const promise = video.play();
            if (promise && promise.catch) promise.catch(() => {});
        } catch (_) {}
    });
    video.addEventListener('playing', () => setSignal(false));
    video.addEventListener('error', () => setSignal(true));

    media.appendChild(video);
    player = video;
    setSignal(false);
    channelDisplay(null);
}

async function setVideo(data) {
    const source = parseSource(data?.url);
    const requestId = ++currentRequest;

    if (!source) {
        clearPlayer();
        setSignal(true);
        return;
    }

    if (source.type === 'youtube') {
        await playYoutube(source, data?.time || 0, requestId);
    } else if (source.type === 'twitch') {
        await playTwitch(source, requestId);
    } else if (source.type === 'image') {
        playImage(source);
    } else if (source.type === 'video') {
        playDirectVideo(source, data?.time || 0);
    } else {
        clearPlayer();
        setSignal(true);
    }

    if (data?.channel && requestId === currentRequest) channelDisplay(data.channel);
}

function setVolume(value) {
    wantedVolume = Math.max(0, Math.min(100, Number(value) || 0));

    try {
        if (playerType === 'youtube' && player?.setVolume) {
            player.setVolume(wantedVolume);
            if (wantedVolume > 0) player.unMute?.();
        } else if (playerType === 'twitch' && player?.setVolume) {
            player.setVolume(wantedVolume / 100);
            player.setMuted?.(wantedVolume <= 0);
        } else if (playerType === 'video' && player) {
            player.volume = wantedVolume / 100;
            player.muted = wantedVolume <= 0;
        }
    } catch (_) {}
}

function showNotification(channel, data) {
    notification.textContent = `Canal #${channel} ${data ? `(${data.name || 'Canal'}) está ao vivo!` : 'ficou offline.'}`;
    notification.style.display = 'block';
    setTimeout(() => notification.style.display = 'none', 3500);
}

window.addEventListener('message', event => {
    const data = event.data || {};
    if (data.action === 'setVideo') setVideo(data.data || {});
    else if (data.action === 'setVolume') setVolume(data.data);
    else if (data.action === 'channelNotification') showNotification(data.channel, data.data);
});

window.addEventListener('DOMContentLoaded', () => {
    setSignal(true);
    channelDisplay(null);

    // The callback is only a readiness handshake. Failure must never break the
    // player itself, which is why nuiPost is completely exception-safe.
    nuiPost('screenReady');
});

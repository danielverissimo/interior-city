// The game-view texture handshake is provided by FiveM's CEF WebGL integration.
// No desktop capture, recording, dependency, or remote script is used.
export function createGameCapture({ width = 960, height = 540, fps = 12 } = {}) {
    const canvas = document.createElement('canvas');
    canvas.width = Math.min(1280, Math.max(480, width)); canvas.height = Math.min(720, Math.max(270, height));
    canvas.className = 'capture-canvas'; canvas.setAttribute('aria-hidden', 'true'); document.body.append(canvas);
    const gl = canvas.getContext('webgl', { alpha: false, antialias: false, preserveDrawingBuffer: true, depth: false, stencil: false });
    if (!gl) { canvas.remove(); throw new Error('A NUI não oferece WebGL para captura.'); }
    const program = gl.createProgram(); const shaders = [];
    try {
        for (const [type, source] of [
            [gl.VERTEX_SHADER, 'attribute vec2 p; varying vec2 uv; void main(){ uv=(p+1.0)/2.0; gl_Position=vec4(p,0.0,1.0); }'],
            [gl.FRAGMENT_SHADER, 'precision mediump float; varying vec2 uv; uniform sampler2D game; void main(){ gl_FragColor=texture2D(game,uv); }']
        ]) {
            const shader = gl.createShader(type); shaders.push(shader); gl.shaderSource(shader, source); gl.compileShader(shader);
            if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) throw new Error('Falha ao preparar captura.');
            gl.attachShader(program, shader);
        }
        gl.linkProgram(program); if (!gl.getProgramParameter(program, gl.LINK_STATUS)) throw new Error('Falha ao iniciar captura.');
        gl.useProgram(program);
        const vertices = gl.createBuffer(); gl.bindBuffer(gl.ARRAY_BUFFER, vertices);
        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1,-1,1,-1,-1,1,1,1]), gl.STATIC_DRAW);
        const attribute = gl.getAttribLocation(program, 'p'); gl.enableVertexAttribArray(attribute); gl.vertexAttribPointer(attribute, 2, gl.FLOAT, false, 0, 0);
        const texture = gl.createTexture(); gl.bindTexture(gl.TEXTURE_2D, texture);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 1, 1, 0, gl.RGBA, gl.UNSIGNED_BYTE, new Uint8Array([0,0,0,255]));
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR); gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        for (const value of [gl.CLAMP_TO_EDGE, 33648, gl.REPEAT]) gl.texParameterf(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, value);
        gl.uniform1i(gl.getUniformLocation(program, 'game'), 0); gl.viewport(0, 0, canvas.width, canvas.height);
        if (!canvas.captureStream) throw new Error('A NUI não oferece captura de vídeo.');
        const stream = canvas.captureStream(Math.min(20, Math.max(6, fps)));
        let stopped = false, timer = 0, previous = 0;
        const draw = now => {
            if (stopped) return;
            timer = requestAnimationFrame(draw);
            if (now - previous < 1000 / fps) return;
            previous = now; gl.bindTexture(gl.TEXTURE_2D, texture); gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4); gl.flush();
        };
        timer = requestAnimationFrame(draw);
        return { canvas, stream, stop() {
            if (stopped) return; stopped = true; cancelAnimationFrame(timer);
            stream.getTracks().forEach(track => track.stop()); gl.deleteTexture(texture); gl.deleteBuffer(vertices);
            shaders.forEach(shader => gl.deleteShader(shader)); gl.deleteProgram(program); gl.getExtension('WEBGL_lose_context')?.loseContext(); canvas.remove();
        } };
    } catch (error) { gl.getExtension('WEBGL_lose_context')?.loseContext(); canvas.remove(); throw error; }
}

export function createMonitor({ call, post, toast, captureFactory = createGameCapture }) {
    let receiver = null, publisher = null, generation = 0;
    const status = text => { const node = document.querySelector('#monitor-status'); if (node) node.textContent = text; };
    const send = (token, kind, payload = {}) => post('monitorSignal', { token, kind, payload });
    function cleanup(session) {
        if (!session) return;
        clearTimeout(session.timeout); clearInterval(session.heartbeat); clearInterval(session.relayTimer);
        session.peer?.close(); session.capture?.stop();
    }
    function peerFor(session, publishing = false) {
        const peer = new RTCPeerConnection({ iceServers: session.options.iceServers || [] }); session.peer = peer;
        peer.onicecandidate = event => { if (event.candidate) send(session.token, 'candidate', event.candidate.toJSON()).catch(() => {}); };
        peer.onconnectionstatechange = () => {
            if (peer.connectionState === 'connected') { clearTimeout(session.timeout); if (!publishing) status('AO VIVO · WebRTC'); }
            if (peer.connectionState === 'failed' && !publishing) fallback(session);
        };
        peer.ontrack = event => {
            const video = document.querySelector('#monitor-video'); if (!video) return;
            video.srcObject = event.streams[0] || new MediaStream([event.track]); video.play().catch(() => {});
        };
        return peer;
    }
    async function applyCandidates(session) {
        if (!session.peer?.remoteDescription) return;
        for (const candidate of session.candidates.splice(0)) await session.peer.addIceCandidate(candidate);
    }
    async function fallback(session) {
        if (receiver !== session || session.relay) return;
        session.relay = true; clearTimeout(session.timeout); status('Conectando pelo servidor...');
        try { await call('monitor.relay', { token: session.token }); }
        catch (error) { status('Transmissão indisponível'); toast(error.message, true); }
    }
    async function publish(data) {
        cleanup(publisher);
        const session = { token: data.token, options: data.options || {}, candidates: [], signalChain: Promise.resolve() }; publisher = session;
        try {
            session.capture = captureFactory(session.options);
            const peer = peerFor(session, true);
            session.capture.stream.getTracks().forEach(track => peer.addTrack(track, session.capture.stream));
            for (const sender of peer.getSenders()) {
                if (!sender.track || sender.track.kind !== 'video') continue;
                const parameters = sender.getParameters(); parameters.encodings ||= [{}]; parameters.encodings[0].maxBitrate = session.options.bitrate || 1200000;
                await sender.setParameters(parameters).catch(() => {});
            }
            await peer.setLocalDescription(await peer.createOffer());
            await send(session.token, 'offer', { type: peer.localDescription.type, sdp: peer.localDescription.sdp });
        } catch (error) { cleanup(session); if (publisher === session) publisher = null; await send(data.token, 'error', { stage: 'capture' }).catch(() => {}); }
    }
    async function relay(data) {
        if (!publisher || publisher.token !== data.token) {
            cleanup(publisher); publisher = { token: data.token, options: data.options || {}, candidates: [] };
        }
        const session = publisher;
        session.peer?.close(); session.peer = null;
        try {
            session.capture ||= captureFactory(session.options);
            clearInterval(session.relayTimer); let sending = false, sequence = 0;
            session.relayTimer = setInterval(async () => {
                if (sending || publisher !== session) return;
                sending = true;
                try {
                    const frame = session.capture.canvas.toDataURL('image/jpeg', .65);
                    if (frame.length <= (session.options.maxFrameBytes || 900000)) await post('monitorFrame', { token: session.token, sequence: ++sequence, frame });
                } catch { await send(session.token, 'error', { stage: 'relay' }).catch(() => {}); }
                finally { sending = false; }
            }, 1000 / Math.min(8, session.options.relayFps || 8));
        } catch { await send(data.token, 'error', { stage: 'relay-capture' }).catch(() => {}); }
    }
    return {
        async start(targetId) {
            this.stop();
            const started = ++generation;
            const data = await call('monitor.start', { targetId });
            if (started !== generation) {
                await call('monitor.stop', { token: data.token }).catch(() => {});
                return;
            }
            const session = { ...data, candidates: [], signalChain: Promise.resolve(), relay: false }; receiver = session;
            session.heartbeat = setInterval(() => send(session.token, 'heartbeat').catch(() => {}), 8000);
            session.timeout = setTimeout(() => fallback(session), 12000);
            await send(session.token, 'ready');
        },
        stop() {
            generation++;
            const session = receiver; receiver = null;
            cleanup(session);
            const video = document.querySelector('#monitor-video'); if (video) video.srcObject = null;
            if (session) call('monitor.stop', { token: session.token }).catch(() => {});
        },
        message(data) {
            if (data.kind === 'publisherStart') { publish(data); return; }
            if (data.kind === 'relayStart') { relay(data); return; }
            if (data.kind === 'closed') {
                if (receiver?.token === data.token) { cleanup(receiver); receiver = null; status(data.reason || 'Encerrada'); }
                if (publisher?.token === data.token) { cleanup(publisher); publisher = null; }
                return;
            }
            if (data.kind === 'frame' && receiver?.token === data.token) {
                const image = document.querySelector('#monitor-relay');
                if (image && /^data:image\/jpeg;base64,[A-Za-z0-9+/=]+$/.test(data.frame) && data.frame.length <= 900000) {
                    image.src = data.frame; image.hidden = false; status('AO VIVO · servidor');
                }
                return;
            }
            if (data.kind !== 'signal') return;
            const session = receiver?.token === data.token ? receiver : publisher?.token === data.token ? publisher : null;
            if (!session) return;
            session.signalChain = (session.signalChain || Promise.resolve()).then(async () => {
                if (data.signalKind === 'offer' && session === receiver) {
                    const peer = session.peer || peerFor(session);
                    await peer.setRemoteDescription(data.payload); await applyCandidates(session);
                    await peer.setLocalDescription(await peer.createAnswer());
                    await send(session.token, 'answer', { type: peer.localDescription.type, sdp: peer.localDescription.sdp });
                } else if (data.signalKind === 'answer' && session === publisher) {
                    await session.peer.setRemoteDescription(data.payload); await applyCandidates(session);
                } else if (data.signalKind === 'candidate') {
                    if (session.peer?.remoteDescription) await session.peer.addIceCandidate(data.payload);
                    else if (session.candidates.length < 128) session.candidates.push(data.payload);
                }
            }).catch(() => { if (session === receiver) fallback(session); else send(session.token, 'error', { stage: 'signaling' }).catch(() => {}); });
        }
    };
}

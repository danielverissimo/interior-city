(() => {
    'use strict';

    const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'vrp_notifycall';
    const root = document.getElementById('dispatch');
    const MAX_HISTORY = 10;
    const VISIBLE_MS = 10000;
    const history = [];
    let historyOpen = false;
    let quickInteract = false;
    let quickRecentOpen = false;
    let sequence = 0;

    const nui = async (name, payload = {}) => {
        try {
            await fetch(`https://${resource}/${name}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify(payload)
            });
        } catch (_) {}
    };

    const safeString = value => value === undefined || value === null ? '' : String(value);
    const color = rgba => {
        const c = Array.isArray(rgba) ? rgba : [255,55,70,255];
        const channel = (value,fallback) => {
            const parsed = Number(value);
            return Number.isFinite(parsed) ? Math.max(0,Math.min(255,parsed)) : fallback;
        };
        return `${channel(c[0],255)}, ${channel(c[1],55)}, ${channel(c[2],70)}`;
    };

    const icon = name => {
        const icons = {
            pin: '<svg viewBox="0 0 24 24"><path d="M12 22s7-6.1 7-13A7 7 0 1 0 5 9c0 6.9 7 13 7 13Zm0-10a3 3 0 1 1 0-6 3 3 0 0 1 0 6Z"/></svg>',
            phone: '<svg viewBox="0 0 24 24"><path d="M6.6 10.8a15.7 15.7 0 0 0 6.6 6.6l2.2-2.2c.3-.3.7-.4 1.1-.2 1.2.4 2.5.7 3.8.7.6 0 1 .4 1 1V20c0 .6-.4 1-1 1C10.8 21 3 13.2 3 3.7c0-.6.4-1 1-1h3.4c.6 0 1 .4 1 1 0 1.3.2 2.6.7 3.8.1.4 0 .8-.3 1.1l-2.2 2.2Z"/></svg>',
            clock: '<svg viewBox="0 0 24 24"><path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20Zm1 5v4.6l3.2 1.9-1 1.7-4.2-2.5V7h2Z"/></svg>',
            alert: '<svg viewBox="0 0 24 24"><path d="M12 2 1 21h22L12 2Zm1 14h-2v-2h2v2Zm0-4h-2V8h2v4Z"/></svg>',
            user: '<svg viewBox="0 0 24 24"><path d="M12 12a5 5 0 1 0 0-10 5 5 0 0 0 0 10Zm0 2c-5 0-9 2.5-9 5.5V22h18v-2.5C21 16.5 17 14 12 14Z"/></svg>',
            car: '<svg viewBox="0 0 24 24"><path d="m5 11 1.4-4.2A3 3 0 0 1 9.2 5h5.6a3 3 0 0 1 2.8 1.8L19 11l2 2v6h-2v2h-2v-2H7v2H5v-2H3v-6l2-2Zm2.3-1h9.4l-.8-2.4a1 1 0 0 0-.9-.6H9a1 1 0 0 0-.9.6L7.3 10ZM7 16a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3Zm10 0a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3Z"/></svg>'
        };
        return icons[name] || '';
    };

    const addMeta = (wrap, svgName, label, value) => {
        if (!value) return;
        const row = document.createElement('div');
        row.className = 'meta-row';
        row.innerHTML = `<span class="meta-icon">${icon(svgName)}</span>`;
        const content = document.createElement('div');
        content.className = 'meta-copy';
        const small = document.createElement('span');
        small.className = 'meta-label';
        small.textContent = label;
        const strong = document.createElement('span');
        strong.className = 'meta-value';
        strong.textContent = safeString(value);
        content.append(small,strong);
        row.appendChild(content);
        wrap.appendChild(row);
    };

    const createCard = (entry, interactive = false) => {
        const data = entry.data;
        const card = document.createElement('article');
        card.className = 'call-card';
        card.dataset.id = entry.id;
        card.style.setProperty('--accent-rgb',color(data.rgba));

        if (!interactive) {
            card.addEventListener('click',() => {
                if (!quickInteract) return;
                nui('quickWay',{ x: data.x, y: data.y });
                quickInteract = false;
                root.classList.remove('quick-interact');
            });
        }

        const head = document.createElement('div');
        head.className = 'call-head';

        const badge = document.createElement('div');
        badge.className = 'call-badge';
        badge.innerHTML = icon('alert');
        const badgeText = document.createElement('span');
        badgeText.textContent = safeString(data.code || '911');
        badge.appendChild(badgeText);

        const titleBox = document.createElement('div');
        titleBox.className = 'title-box';
        const title = document.createElement('h2');
        title.textContent = safeString(data.title || 'Novo chamado');
        const time = document.createElement('span');
        time.className = 'call-time';
        time.innerHTML = `${icon('clock')}<span>${safeString(data.time)}</span>`;
        titleBox.append(title,time);
        head.append(badge,titleBox);
        card.appendChild(head);

        if (data.text) {
            const text = document.createElement('p');
            text.className = 'call-text';
            text.textContent = safeString(data.text);
            card.appendChild(text);
        }

        const meta = document.createElement('div');
        meta.className = 'call-meta';
        addMeta(meta,'pin','LOCALIZAÇÃO',data.street);
        addMeta(meta,'user','SUSPEITO',data.criminal);
        addMeta(meta,'user','SOLICITANTE',data.name);
        addMeta(meta,'car','VEÍCULO',data.vehicle);
        card.appendChild(meta);

        const footer = document.createElement('div');
        footer.className = 'call-footer';

        const hint = document.createElement('span');
        hint.className = 'history-hint';
        hint.textContent = interactive ? 'ESC para fechar' : 'F1 interagir • F12 histórico';
        footer.appendChild(hint);

        if (interactive) {
            const actions = document.createElement('div');
            actions.className = 'call-actions';

            if (data.phone !== undefined && data.phone !== null && safeString(data.phone) !== '') {
                const phone = document.createElement('button');
                phone.type = 'button';
                phone.className = 'action-btn secondary';
                phone.innerHTML = `${icon('phone')}<span>LIGAR</span>`;
                phone.addEventListener('click',() => nui('phoneCall',{ phone: data.phone }));
                actions.appendChild(phone);
            }

            const route = document.createElement('button');
            route.type = 'button';
            route.className = 'action-btn primary';
            route.innerHTML = `${icon('pin')}<span>MARCAR ROTA</span>`;
            route.addEventListener('click',() => nui('setWay',{ x: data.x, y: data.y }));
            actions.appendChild(route);
            footer.appendChild(actions);
        }

        card.appendChild(footer);
        return card;
    };

    const renderQuickRecent = () => {
        root.innerHTML = '';
        root.classList.remove('history-open');
        root.classList.add('quick-history-open');

        const header = document.createElement('header');
        header.className = 'history-header quick-header';

        const title = document.createElement('div');
        const count = Math.min(history.length,3);
        title.innerHTML = `<strong>ÚLTIMAS OCORRÊNCIAS</strong><span>${count} ocorrência${count === 1 ? '' : 's'} • clique para marcar</span>`;

        const close = document.createElement('button');
        close.className = 'close-btn';
        close.type = 'button';
        close.textContent = '×';
        close.addEventListener('click',hideAll);

        header.append(title,close);
        root.appendChild(header);

        const recent = history.slice(-3).reverse();

        if (!recent.length) {
            const empty = document.createElement('div');
            empty.className = 'quick-empty';
            empty.textContent = 'Nenhuma ocorrência recebida recentemente.';
            root.appendChild(empty);
            nui('focusOff');
            return;
        }

        recent.forEach(entry => {
            const card = createCard(entry,false);
            card.classList.add('visible','quick-recent-card');
            card.addEventListener('click',() => {
                const data = entry.data || {};
                nui('quickWay',{ x:data.x, y:data.y });
                quickRecentOpen = false;
                quickInteract = false;
                root.classList.remove('quick-history-open','quick-interact');
            });
            root.appendChild(card);
        });
    };

    const renderHistory = () => {
        root.innerHTML = '';
        root.classList.remove('quick-history-open');
        root.classList.add('history-open');

        const header = document.createElement('header');
        header.className = 'history-header';
        const title = document.createElement('div');
        title.innerHTML = `<strong>CHAMADOS RECENTES</strong><span>${history.length} registro${history.length === 1 ? '' : 's'}</span>`;
        const close = document.createElement('button');
        close.className = 'close-btn';
        close.type = 'button';
        close.textContent = '×';
        close.addEventListener('click',hideAll);
        header.append(title,close);
        root.appendChild(header);

        [...history].reverse().forEach(entry => root.appendChild(createCard(entry,true)));
    };

    const showTransient = entry => {
        if (historyOpen) return;
        const card = createCard(entry,false);
        root.prepend(card);
        requestAnimationFrame(() => card.classList.add('visible'));
        window.setTimeout(() => {
            card.classList.remove('visible');
            card.classList.add('leaving');
            window.setTimeout(() => card.remove(),320);
        },VISIBLE_MS);
    };

    const addNotification = data => {
        const normalized = { ...(data || {}) };
        if (!normalized.time) {
            const now = new Date();
            normalized.time = `${String(now.getHours()).padStart(2,'0')}:${String(now.getMinutes()).padStart(2,'0')}`;
        }
        const entry = { id: ++sequence, data: normalized };
        history.push(entry);
        while (history.length > MAX_HISTORY) history.shift();
        showTransient(entry);
        if (historyOpen) renderHistory();
        if (quickRecentOpen) renderQuickRecent();
    };

    function hideAll() {
        historyOpen = false;
        quickRecentOpen = false;
        quickInteract = false;
        root.classList.remove('quick-interact');
        root.classList.remove('history-open');
        root.classList.remove('quick-history-open');
        root.innerHTML = '';
        nui('focusOff');
    }

    const showQuickRecent = () => {
        if (!history.length) {
            nui('focusOff');
            return;
        }

        historyOpen = false;
        quickInteract = false;
        quickRecentOpen = true;
        root.classList.remove('quick-interact','history-open');
        renderQuickRecent();
    };

    const quickFocusOff = () => {
        quickInteract = false;
        quickRecentOpen = false;
        root.classList.remove('quick-interact','quick-history-open');
        if (!historyOpen) root.innerHTML = '';
    };

    const showAll = () => {
        if (!history.length) return;
        quickFocusOff();
        quickRecentOpen = false;
        historyOpen = true;
        renderHistory();
        nui('focusOn');
    };

    window.addEventListener('message',event => {
        const payload = event.data || {};
        if (payload.action === 'notify') addNotification(payload.data);
        if (payload.action === 'showAll') showAll();
        if (payload.action === 'hideAll') hideAll();
        if (payload.action === 'showQuickRecent') showQuickRecent();
        if (payload.action === 'quickFocusOn') showQuickRecent();
        if (payload.action === 'quickFocusOff') quickFocusOff();
    });

    window.addEventListener('keyup',event => {
        if (event.key !== 'Escape') return;
        if (historyOpen || quickRecentOpen) {
            hideAll();
            return;
        }
        if (quickInteract) {
            quickFocusOff();
            nui('focusOff');
        }
    });
})();

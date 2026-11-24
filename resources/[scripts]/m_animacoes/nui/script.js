(() => {
    'use strict';

    const RESOURCE = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'm_animacoes';
    const $ = (selector) => document.querySelector(selector);
    const $$ = (selector) => [...document.querySelectorAll(selector)];

    const panelLayer = $('#panelLayer');
    const wheelLayer = $('#wheelLayer');
    const grid = $('#animationGrid');
    const emptyState = $('#emptyState');
    const searchInput = $('#searchInput');
    const resultCount = $('#resultCount');
    const allCount = $('#allCount');
    const favCount = $('#favCount');
    const favSlotsCount = $('#favSlotsCount');
    const favSlotsMax = $('#favSlotsMax');
    const favoriteSlots = $('#favoriteSlots');
    const sectionTitle = $('#sectionTitle');
    const wheelSvg = $('#wheelSvg');
    const wheelLabels = $('#wheelLabels');
    const wheelShell = $('#wheelShell');
    const wheelCenterTitle = $('#wheelCenterTitle');
    const wheelAllButton = $('#wheelAllButton');
    const toast = $('#toast');
    const toastTitle = $('#toastTitle');
    const toastMessage = $('#toastMessage');
    const removeFavouriteDialog = $('#removeFavouriteDialog');
    const removeFavouriteQuestion = $('#removeFavouriteQuestion');
    const removeFavouriteCancel = $('#removeFavouriteCancel');
    const removeFavouriteConfirm = $('#removeFavouriteConfirm');

    panelLayer.classList.add('is-hidden');
    wheelLayer.classList.add('is-hidden');
    toast.classList.add('is-hidden');
    document.documentElement.style.background = 'transparent';
    document.body.style.background = 'transparent';

    const state = {
        animations: [],
        filtered: [],
        favourites: [],
        favouriteSet: new Set(),
        maxFavourites: 8,
        filter: 'all',
        query: '',
        panelOpen: false,
        wheelOpen: false,
        wheelItems: [],
        wheelSelected: -1,
        toastTimer: null,
        searchTimer: null,
        favouriteToRemove: null,
        removingFavourite: false
    };

    const virtual = {
        canvas: null,
        columns: 0,
        cardHeight: 0,
        gap: 0,
        cardWidth: 0,
        rowHeight: 0,
        firstRow: -1,
        lastRow: -1,
        raf: 0,
        resizeTimer: null,
        itemCount: -1,
        cards: new Map()
    };

    const categoryNames = {
        all: 'Animações',
        favourites: 'Seus favoritos',
        dance: 'Danças',
        props: 'Animações com objetos',
        photo: 'Poses e fotos',
        vehicle: 'Animações em veículo'
    };

    const categoryLabels = {
        general: 'Animação',
        dance: 'Dança',
        props: 'Objeto',
        photo: 'Pose',
        vehicle: 'Veículo'
    };

    // Cards intentionally use one lightweight person icon for every animation.
    // This keeps the visual language consistent and avoids category-specific cube/object icons.
    const iconSvg = () => `<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="5" r="2.2"/><path d="M8.8 10.2 12 7.7l3.2 2.5M12 7.7v6.1M8.8 10.2l-2.6 3.1M15.2 10.2l2.6 3.1M12 13.8l-3 5.2M12 13.8l3 5.2"/></svg>`;

    const wheelPersonSvg = () => `<svg viewBox="0 0 48 48" aria-hidden="true"><circle cx="25" cy="8" r="4"/><path d="m21 15 5-3 6 5 6 2M25 13l-2 12-7 7M23 25l8 13M19 17l-8 7"/></svg>`;

    async function post(endpoint, data = {}) {
        try {
            const response = await fetch(`https://${RESOURCE}/${endpoint}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify(data)
            });
            return await response.json();
        } catch (_) {
            return { ok: false };
        }
    }

    function normalise(value) {
        return String(value || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
    }

    function prettyName(name) {
        return String(name || '').replace(/[_-]+/g, ' ').trim();
    }

    function escapeHtml(value) {
        return String(value).replace(/[&<>'"]/g, char => ({ '&':'&amp;', '<':'&lt;', '>':'&gt;', "'":'&#039;', '"':'&quot;' }[char]));
    }

    function isFavourite(name) {
        return state.favouriteSet.has(name);
    }

    function syncFavouriteSet() {
        state.favouriteSet = new Set(state.favourites);
    }

    function showToast(title, message) {
        toastTitle.textContent = title || 'Animações';
        toastMessage.textContent = message || '';
        toast.classList.remove('is-hidden');
        clearTimeout(state.toastTimer);
        state.toastTimer = setTimeout(() => toast.classList.add('is-hidden'), 2600);
    }

    function filteredAnimations() {
        const query = normalise(state.query);
        return state.animations.filter(anim => {
            const filterMatch = state.filter === 'all'
                || (state.filter === 'favourites' ? isFavourite(anim.nome) : anim.category === state.filter);
            const queryMatch = !query || anim._search.includes(query);
            return filterMatch && queryMatch;
        });
    }

    function readVirtualMetrics() {
        const style = getComputedStyle(grid);
        const columns = Math.max(1, Number.parseInt(style.getPropertyValue('--grid-cols'), 10) || 3);
        const cardHeight = Number.parseFloat(style.getPropertyValue('--card-height')) || 106;
        const gap = Number.parseFloat(style.getPropertyValue('--grid-gap')) || 8;
        const paddingLeft = Number.parseFloat(style.paddingLeft) || 0;
        const paddingRight = Number.parseFloat(style.paddingRight) || 0;
        const available = Math.max(1, grid.clientWidth - paddingLeft - paddingRight);
        const cardWidth = Math.max(1, (available - (columns - 1) * gap) / columns);
        return { columns, cardHeight, gap, cardWidth, rowHeight: cardHeight + gap };
    }

    function ensureVirtualCanvas() {
        if (virtual.canvas && virtual.canvas.isConnected) return virtual.canvas;
        grid.innerHTML = '';
        virtual.cards.clear();
        virtual.itemCount = -1;
        virtual.canvas = document.createElement('div');
        virtual.canvas.className = 'virtual-canvas';
        grid.appendChild(virtual.canvas);
        return virtual.canvas;
    }

    function updateVirtualCanvasHeight(metrics) {
        const rows = Math.ceil(state.filtered.length / metrics.columns);
        const totalHeight = rows > 0 ? (rows * metrics.rowHeight - metrics.gap) : 0;
        virtual.canvas.style.height = `${Math.max(totalHeight, grid.clientHeight)}px`;
    }

    function createCard(anim, index, metrics) {
        const row = Math.floor(index / metrics.columns);
        const column = index % metrics.columns;
        const card = document.createElement('article');
        card.className = 'animation-card';
        card.dataset.name = anim.nome;
        card.style.width = `${metrics.cardWidth}px`;
        card.style.height = `${metrics.cardHeight}px`;
        card.style.left = `${column * (metrics.cardWidth + metrics.gap)}px`;
        card.style.top = `${row * metrics.rowHeight}px`;
        card.innerHTML = `
            <div class="card-icon">${iconSvg()}</div>
            <div class="card-info">
                <strong title="${escapeHtml(anim._display)}">${escapeHtml(anim._display)}</strong>
                <span>${categoryLabels[anim.category] || 'Animação'}</span>
            </div>
            <button class="fav-button ${isFavourite(anim.nome) ? 'is-favourite' : ''}" type="button" aria-label="Favoritar" title="Favoritar">
                <svg viewBox="0 0 24 24"><path d="m12 3 2.75 5.57 6.15.9-4.45 4.33 1.05 6.12L12 17.02l-5.5 2.9 1.05-6.12L3.1 9.47l6.15-.9L12 3Z"/></svg>
            </button>`;
        return card;
    }

    function renderVirtualRows(force = false) {
        if (!state.panelOpen || !state.filtered.length || grid.classList.contains('is-hidden')) return;

        // As medidas do grid só mudam ao abrir, filtrar ou redimensionar.
        // Evita getComputedStyle/clientWidth a cada evento de scroll.
        const needsMeasure = force || !virtual.columns || !virtual.canvas || !virtual.canvas.isConnected;
        const metrics = needsMeasure ? readVirtualMetrics() : {
            columns: virtual.columns,
            cardHeight: virtual.cardHeight,
            gap: virtual.gap,
            cardWidth: virtual.cardWidth,
            rowHeight: virtual.rowHeight
        };
        const metricsChanged = metrics.columns !== virtual.columns
            || Math.abs(metrics.cardHeight - virtual.cardHeight) > .1
            || Math.abs(metrics.cardWidth - virtual.cardWidth) > .5
            || Math.abs(metrics.gap - virtual.gap) > .1;

        if (metricsChanged) {
            virtual.columns = metrics.columns;
            virtual.cardHeight = metrics.cardHeight;
            virtual.gap = metrics.gap;
            virtual.cardWidth = metrics.cardWidth;
            virtual.rowHeight = metrics.rowHeight;
            force = true;
        }

        ensureVirtualCanvas();
        if (force || virtual.itemCount !== state.filtered.length) {
            updateVirtualCanvasHeight(metrics);
            virtual.itemCount = state.filtered.length;
        }

        const totalRows = Math.ceil(state.filtered.length / metrics.columns);
        const overscan = 2;
        const firstRow = Math.max(0, Math.floor(grid.scrollTop / metrics.rowHeight) - overscan);
        const lastRow = Math.min(totalRows - 1, Math.floor((grid.scrollTop + grid.clientHeight) / metrics.rowHeight) + overscan);

        if (!force && firstRow === virtual.firstRow && lastRow === virtual.lastRow) return;
        virtual.firstRow = firstRow;
        virtual.lastRow = lastRow;

        const startIndex = firstRow * metrics.columns;
        const endIndex = Math.min(state.filtered.length, (lastRow + 1) * metrics.columns);

        if (force) {
            virtual.canvas.replaceChildren();
            virtual.cards.clear();
        } else {
            // Preserva cartões ainda visíveis e remove somente os que saíram
            // da janela. Evita recriar todos os elementos em cada rolagem.
            for (const [index, card] of virtual.cards) {
                if (index < startIndex || index >= endIndex) {
                    card.remove();
                    virtual.cards.delete(index);
                }
            }
        }

        const fragment = document.createDocumentFragment();
        for (let index = startIndex; index < endIndex; index++) {
            if (virtual.cards.has(index)) continue;
            const card = createCard(state.filtered[index], index, metrics);
            virtual.cards.set(index, card);
            fragment.appendChild(card);
        }
        virtual.canvas.appendChild(fragment);
    }

    function scheduleVirtualRender(force = false) {
        if (force) {
            if (virtual.raf) cancelAnimationFrame(virtual.raf);
            virtual.raf = requestAnimationFrame(() => {
                virtual.raf = 0;
                renderVirtualRows(true);
            });
            return;
        }
        if (virtual.raf) return;
        virtual.raf = requestAnimationFrame(() => {
            virtual.raf = 0;
            renderVirtualRows(false);
        });
    }

    function refreshGrid(resetScroll = true) {
        state.filtered = filteredAnimations();
        resultCount.textContent = state.filtered.length;
        grid.classList.toggle('is-hidden', state.filtered.length === 0);
        emptyState.classList.toggle('is-hidden', state.filtered.length !== 0);

        if (resetScroll) grid.scrollTop = 0;
        virtual.firstRow = -1;
        virtual.lastRow = -1;

        if (!state.filtered.length) {
            grid.innerHTML = '';
            virtual.canvas = null;
            virtual.cards.clear();
            virtual.itemCount = -1;
            return;
        }

        ensureVirtualCanvas();
        scheduleVirtualRender(true);
    }

    function setActiveFilter(filter) {
        state.filter = filter;
        $$('.nav-item').forEach(btn => btn.classList.toggle('is-active', btn.dataset.filter === filter));
        sectionTitle.textContent = categoryNames[filter] || categoryNames.all;
        refreshGrid(true);
    }

    function renderFavouriteSlots() {
        favoriteSlots.innerHTML = '';
        favSlotsCount.textContent = state.favourites.length;
        favSlotsMax.textContent = state.maxFavourites;
        favCount.textContent = state.favourites.length;
        allCount.textContent = state.animations.length;

        const fragment = document.createDocumentFragment();
        for (let index = 0; index < state.maxFavourites; index++) {
            const slot = document.createElement('div');
            const name = state.favourites[index];
            slot.className = `favorite-slot${name ? ' is-filled' : ''}`;
            slot.title = name ? prettyName(name) : `Slot ${index + 1}`;
            if (name) slot.dataset.name = name;
            slot.innerHTML = `<span>${name ? escapeHtml(prettyName(name)) : index + 1}</span>${name
                ? `<button class="favorite-remove" type="button" title="Remover ${escapeHtml(prettyName(name))} dos favoritos" aria-label="Remover ${escapeHtml(prettyName(name))} dos favoritos">&times;</button>`
                : ''}`;
            fragment.appendChild(slot);
        }
        favoriteSlots.appendChild(fragment);
    }

    // A remocao usa o mesmo callback do favorito comum; o servidor persiste em vRP UData.
    // Confirmacao customizada: nao abre alertas nativos do Chromium/CEF do FiveM.
    function closeRemoveFavouriteDialog(force = false) {
        if (state.removingFavourite && !force) return;
        state.favouriteToRemove = null;
        removeFavouriteDialog.classList.add('is-hidden');
        removeFavouriteDialog.setAttribute('aria-hidden', 'true');
        removeFavouriteConfirm.disabled = false;
        removeFavouriteCancel.disabled = false;
        removeFavouriteConfirm.textContent = 'Remover';
    }

    function openRemoveFavouriteDialog(name) {
        if (!state.panelOpen || state.removingFavourite || !isFavourite(name)) return;
        state.favouriteToRemove = name;
        removeFavouriteQuestion.textContent = `Deseja remover ${prettyName(name)} dos favoritos?`;
        removeFavouriteDialog.classList.remove('is-hidden');
        removeFavouriteDialog.setAttribute('aria-hidden', 'false');
        removeFavouriteCancel.focus();
    }

    async function confirmRemoveFavourite() {
        const name = state.favouriteToRemove;
        if (!name || state.removingFavourite || !isFavourite(name)) return;
        state.removingFavourite = true;
        removeFavouriteConfirm.disabled = true;
        removeFavouriteCancel.disabled = true;
        removeFavouriteConfirm.textContent = 'Removendo...';
        try {
            const response = await post('toggleFavourite', { name });
            if (response.ok && Array.isArray(response.favourites) && !response.favourites.includes(name)) {
                state.favourites = response.favourites;
                renderAllDynamic();
                closeRemoveFavouriteDialog(true);
                showToast('Favorito removido', `${prettyName(name)} foi removido dos favoritos.`);
            } else {
                showToast('Não foi possível remover', response.message || 'Tente novamente.');
            }
        } finally {
            state.removingFavourite = false;
            removeFavouriteConfirm.disabled = false;
            removeFavouriteCancel.disabled = false;
            removeFavouriteConfirm.textContent = 'Remover';
        }
    }

    function renderAllDynamic() {
        syncFavouriteSet();
        renderFavouriteSlots();
        if (state.filter === 'favourites') {
            // Somente a lista de favoritos muda de tamanho ao favoritar.
            refreshGrid(false);
            return;
        }
        // Nas demais categorias, atualiza só a estrela dos cartões na tela.
        for (const card of virtual.cards.values()) {
            const button = card.querySelector('.fav-button');
            if (button) button.classList.toggle('is-favourite', isFavourite(card.dataset.name));
        }
    }

    function openPanel(payload) {
        closeRemoveFavouriteDialog(true);
        state.removingFavourite = false;
        const incoming = Array.isArray(payload.animations) ? payload.animations : [];
        state.animations = incoming.map(anim => ({
            ...anim,
            category: anim.category || 'general',
            _display: prettyName(anim.nome),
            _search: normalise(anim.nome)
        }));
        state.favourites = Array.isArray(payload.favourites) ? payload.favourites : [];
        syncFavouriteSet();
        state.maxFavourites = Number(payload.maxFavourites) || 8;
        state.panelOpen = true;
        state.wheelOpen = false;
        document.removeEventListener('mousemove', handleWheelMouse);
        state.query = '';
        searchInput.value = '';
        panelLayer.classList.remove('is-hidden');
        wheelLayer.classList.add('is-hidden');
        renderFavouriteSlots();
        setActiveFilter('all');
        setTimeout(() => searchInput.focus(), 60);
    }

    function closePanelVisual() {
        closeRemoveFavouriteDialog(true);
        clearTimeout(state.searchTimer);
        state.panelOpen = false;
        panelLayer.classList.add('is-hidden');
        if (virtual.raf) {
            cancelAnimationFrame(virtual.raf);
            virtual.raf = 0;
        }
    }

    function polar(cx, cy, radius, angleDeg) {
        const angle = (angleDeg - 90) * Math.PI / 180;
        return { x: cx + radius * Math.cos(angle), y: cy + radius * Math.sin(angle) };
    }

    function donutPath(cx, cy, outer, inner, startAngle, endAngle) {
        if (endAngle - startAngle >= 359.9) endAngle = startAngle + 359.9;
        const p1 = polar(cx, cy, outer, startAngle);
        const p2 = polar(cx, cy, outer, endAngle);
        const p3 = polar(cx, cy, inner, endAngle);
        const p4 = polar(cx, cy, inner, startAngle);
        const largeArc = endAngle - startAngle > 180 ? 1 : 0;
        return `M ${p1.x} ${p1.y} A ${outer} ${outer} 0 ${largeArc} 1 ${p2.x} ${p2.y} L ${p3.x} ${p3.y} A ${inner} ${inner} 0 ${largeArc} 0 ${p4.x} ${p4.y} Z`;
    }

    function renderWheel() {
        const count = state.wheelItems.length;
        wheelSvg.innerHTML = '';
        wheelLabels.innerHTML = '';
        if (!count) return;

        const cx = 320, cy = 320, outer = 286, inner = 114;
        const step = 360 / count;
        const gap = Math.min(3.6, 12 / count);
        const svgFragment = document.createDocumentFragment();
        const labelFragment = document.createDocumentFragment();

        for (let i = 0; i < count; i++) {
            const start = i * step - step / 2 + gap / 2;
            const end = (i + 1) * step - step / 2 - gap / 2;
            const middle = i * step;
            const name = state.wheelItems[i];
            const empty = !name;

            const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
            path.setAttribute('d', donutPath(cx, cy, outer, inner, start, end));
            path.setAttribute('class', `wheel-segment${empty ? ' is-empty' : ''}${i === state.wheelSelected ? ' is-selected' : ''}`);
            path.dataset.index = i;
            svgFragment.appendChild(path);

            const labelPoint = polar(50, 50, 34, middle);
            const label = document.createElement('div');
            label.className = `wheel-label${empty ? ' is-empty' : ''}${i === state.wheelSelected ? ' is-selected' : ''}`;
            label.style.left = `${labelPoint.x}%`;
            label.style.top = `${labelPoint.y}%`;
            label.innerHTML = empty
                ? `<div class="wheel-empty-icon">—</div><strong>Nenhuma</strong><span>SLOT ${i + 1}</span>`
                : `<div class="wheel-emote-icon">${wheelPersonSvg()}</div><strong>${escapeHtml(prettyName(name))}</strong><span>FAVORITO ${i + 1}</span>`;
            labelFragment.appendChild(label);
        }

        const innerCircle = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
        innerCircle.setAttribute('cx', cx);
        innerCircle.setAttribute('cy', cy);
        innerCircle.setAttribute('r', inner - 7);
        innerCircle.setAttribute('class', 'wheel-ring-inner');
        svgFragment.appendChild(innerCircle);
        wheelSvg.appendChild(svgFragment);
        wheelLabels.appendChild(labelFragment);
    }

    function setWheelSelection(index) {
        if (index === state.wheelSelected) return;
        state.wheelSelected = index;
        const selectedName = index >= 0 ? state.wheelItems[index] : null;
        wheelCenterTitle.textContent = index < 0 ? 'Favoritos' : (selectedName ? prettyName(selectedName) : 'Nenhuma');

        wheelSvg.querySelectorAll('.wheel-segment').forEach((el, i) => el.classList.toggle('is-selected', i === index));
        wheelLabels.querySelectorAll('.wheel-label').forEach((el, i) => el.classList.toggle('is-selected', i === index));
    }

    function handleWheelMouse(event) {
        if (!state.wheelOpen || !state.wheelItems.length) return;
        const rect = wheelShell.getBoundingClientRect();
        const cx = rect.left + rect.width / 2;
        const cy = rect.top + rect.height / 2;
        const dx = event.clientX - cx;
        const dy = event.clientY - cy;
        const radius = Math.sqrt(dx * dx + dy * dy);
        const inner = rect.width * .18;
        const outer = rect.width * .45;

        if (radius < inner || radius > outer) {
            setWheelSelection(-1);
            return;
        }

        let angle = Math.atan2(dy, dx) * 180 / Math.PI + 90;
        if (angle < 0) angle += 360;
        const step = 360 / state.wheelItems.length;
        const index = Math.floor((angle + step / 2) / step) % state.wheelItems.length;
        setWheelSelection(index);
    }

    function openWheel(payload) {
        closeRemoveFavouriteDialog(true);
        const maxSlots = Math.max(1, Math.min(8, Number(payload.maxFavourites) || 8));
        const incoming = Array.isArray(payload.favourites) ? payload.favourites.slice(0, maxSlots) : [];

        // The wheel always has the configured amount of slots. Missing favourites are
        // represented by null so players can use the wheel with 0-7 saved animations too.
        state.maxFavourites = maxSlots;
        state.wheelItems = Array.from({ length: maxSlots }, (_, index) => incoming[index] || null);
        state.wheelSelected = -1;
        state.wheelOpen = true;
        document.addEventListener('mousemove', handleWheelMouse, { passive: true });
        state.panelOpen = false;

        panelLayer.classList.add('is-hidden');
        wheelLayer.classList.remove('is-hidden');
        wheelCenterTitle.textContent = 'Favoritos';
        renderWheel();
    }

    function closeWheelVisual() {
        document.removeEventListener('mousemove', handleWheelMouse);
        state.wheelOpen = false;
        state.wheelSelected = -1;
        wheelLayer.classList.add('is-hidden');
    }

    function resetUi() {
        closeRemoveFavouriteDialog(true);
        document.removeEventListener('mousemove', handleWheelMouse);
        clearTimeout(state.searchTimer);
        state.panelOpen = false;
        state.wheelOpen = false;
        state.wheelSelected = -1;
        state.query = '';
        panelLayer.classList.add('is-hidden');
        wheelLayer.classList.add('is-hidden');
        toast.classList.add('is-hidden');
        if (searchInput) searchInput.value = '';
        if (virtual.raf) {
            cancelAnimationFrame(virtual.raf);
            virtual.raf = 0;
        }
    }

    $$('.nav-item').forEach(btn => btn.addEventListener('click', () => setActiveFilter(btn.dataset.filter)));

    searchInput.addEventListener('input', () => {
        clearTimeout(state.searchTimer);
        state.searchTimer = setTimeout(() => {
            state.query = searchInput.value;
            refreshGrid(true);
        }, 110);
    });

    grid.addEventListener('scroll', () => scheduleVirtualRender(false), { passive: true });

    grid.addEventListener('click', async (event) => {
        const card = event.target.closest('.animation-card');
        if (!card) return;
        const name = card.dataset.name;
        if (!name) return;

        const favouriteButton = event.target.closest('.fav-button');
        if (!favouriteButton) {
            await post('playAnimation', { name });
            return;
        }

        event.stopPropagation();
        const response = await post('toggleFavourite', { name });
        if (Array.isArray(response.favourites)) state.favourites = response.favourites;
        if (response.message) showToast(response.ok ? 'Favoritos atualizados' : 'Limite de favoritos', response.message);
        renderAllDynamic();
    });

    favoriteSlots.addEventListener('click', (event) => {
        const removeButton = event.target.closest('.favorite-remove');
        if (!removeButton) return;
        event.stopPropagation();
        const slot = removeButton.closest('.favorite-slot');
        if (slot && slot.dataset.name) openRemoveFavouriteDialog(slot.dataset.name);
    });

    removeFavouriteCancel.addEventListener('click', () => closeRemoveFavouriteDialog());
    removeFavouriteConfirm.addEventListener('click', confirmRemoveFavourite);
    removeFavouriteDialog.addEventListener('click', (event) => {
        if (event.target === removeFavouriteDialog) closeRemoveFavouriteDialog();
    });

    // Opens the full /anim panel directly from the favourites wheel.
    wheelAllButton.addEventListener('click', async () => {
        if (!state.wheelOpen) return;
        await post('wheelOpenPanel');
    });

    // Wheel interaction is click-based. O only opens it; releasing O does nothing.
    wheelSvg.addEventListener('click', (event) => {
        if (!state.wheelOpen) return;

        const target = event.target;
        if (!target || !target.classList || !target.classList.contains('wheel-segment')) return;

        const index = Number(target.dataset.index);
        if (!Number.isInteger(index) || index < 0 || index >= state.wheelItems.length) return;

        const name = state.wheelItems[index];
        if (!name) return;

        post('wheelExecute', { name });
        closeWheelVisual();
    });

    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape') {
            event.preventDefault();

            if (!removeFavouriteDialog.classList.contains('is-hidden')) {
                closeRemoveFavouriteDialog();
                return;
            }
            if (state.wheelOpen) {
                post('wheelCancel');
                closeWheelVisual();
            } else if (state.panelOpen) {
                post('panelClose');
            }
            return;
        }

        if (state.panelOpen && event.ctrlKey && event.key.toLowerCase() === 'f') {
            event.preventDefault();
            searchInput.focus();
            searchInput.select();
        }
    });

    window.addEventListener('resize', () => {
        if (!state.panelOpen) return;
        clearTimeout(virtual.resizeTimer);
        virtual.resizeTimer = setTimeout(() => {
            virtual.firstRow = -1;
            virtual.lastRow = -1;
            scheduleVirtualRender(true);
        }, 80);
    });

    window.addEventListener('message', (event) => {
        const data = event.data || {};
        switch (data.action) {
            case 'panel:open': openPanel(data); break;
            case 'panel:close': closePanelVisual(); break;
            case 'wheel:open': openWheel(data); break;
            case 'wheel:close': closeWheelVisual(); break;
            case 'toast': showToast(data.title, data.message); break;
            case 'ui:reset': resetUi(); break;
        }
    });

    resetUi();
})();

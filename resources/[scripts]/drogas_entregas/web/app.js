(() => {
    'use strict';

    const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'drogas_entregas';
    const app = document.getElementById('app');
    const grid = document.getElementById('drugGrid');
    const closeButton = document.getElementById('closeButton');
    const confirmLayer = document.getElementById('confirmLayer');
    const confirmTitle = document.getElementById('confirmTitle');
    const confirmProduct = document.getElementById('confirmProduct');
    const cancelConfirm = document.getElementById('cancelConfirm');
    const acceptConfirm = document.getElementById('acceptConfirm');
    const reputationBadge = document.getElementById('reputationBadge');
    const reputationLabel = document.getElementById('reputationLabel');
    const reputationMeta = document.getElementById('reputationMeta');

    let imageBaseUrl = '';
    let drugs = [];
    let selected = null;
    let sending = false;
    let reputation = null;

    const nui = async (name, payload = {}) => {
        try {
            const response = await fetch(`https://${resource}/${name}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify(payload)
            });
            return await response.json();
        } catch (_) {
            return { ok: false };
        }
    };

    const money = value => Number(value || 0).toLocaleString('pt-BR');

    const renderReputation = data => {
        reputation = data && typeof data === 'object' ? data : null;
        const label = reputation ? String(reputation.label || 'INTACTA') : 'INTACTA';
        const color = reputation ? String(reputation.color || '#55d98b') : '#55d98b';
        const payment = reputation ? Number(reputation.paymentPercent ?? 100) : 100;

        reputationBadge.style.setProperty('--rep-color', color);
        reputationLabel.textContent = label;

        const required = reputation ? Number(reputation.cleanSalesRequired || 0) : 0;
        const progress = reputation ? Number(reputation.cleanSales || 0) : 0;
        if (required > 0) {
            reputationMeta.textContent = `GANHOS ${payment}% · RECUPERAÇÃO ${progress}/${required}`;
        } else {
            reputationMeta.textContent = `GANHOS ${payment}%`;
        }
    };
    const normalizedBase = value => {
        const text = String(value || '').trim();
        if (!text) return '';
        return text.endsWith('/') ? text : `${text}/`;
    };

    const fallbackIcon = () => {
        const wrap = document.createElement('div');
        wrap.className = 'image-fallback';
        wrap.innerHTML = '<svg viewBox="0 0 24 24"><path d="M6.4 3h11.2l1.1 3H21v2H3V6h2.3l1.1-3ZM5 10h14l-1.1 11H6.1L5 10Zm4 2v7h2v-7H9Zm4 0v7h2v-7h-2Z"/></svg>';
        return wrap;
    };

    const createCard = drug => {
        const card = document.createElement('article');
        card.className = `drug-card${Number(drug.stock || 0) <= 0 ? ' disabled' : ''}`;

        const imageWrap = document.createElement('div');
        imageWrap.className = 'drug-image-wrap';

        const img = document.createElement('img');
        img.className = 'drug-image';
        img.alt = String(drug.label || drug.item || 'Droga');
        img.src = `${imageBaseUrl}${encodeURIComponent(String(drug.image || drug.item || ''))}.png`;
        img.addEventListener('error', () => {
            img.remove();
            if (!imageWrap.querySelector('.image-fallback')) imageWrap.appendChild(fallbackIcon());
        }, { once: true });
        imageWrap.appendChild(img);

        const stock = document.createElement('span');
        stock.className = `stock-badge${Number(drug.stock || 0) <= 0 ? ' zero' : ''}`;
        stock.textContent = Number(drug.stock || 0) <= 0 ? 'SEM ESTOQUE' : `${Number(drug.stock || 0)}x NO INVENTÁRIO`;
        imageWrap.appendChild(stock);

        const body = document.createElement('div');
        body.className = 'drug-body';

        const titleWrap = document.createElement('div');
        titleWrap.className = 'drug-title-row';
        const titleBox = document.createElement('div');
        const title = document.createElement('h2');
        title.className = 'drug-title';
        title.textContent = String(drug.label || drug.item || 'Droga');
        const item = document.createElement('div');
        item.className = 'drug-item';
        item.textContent = String(drug.item || '');
        titleBox.append(title, item);
        titleWrap.appendChild(titleBox);

        const description = document.createElement('p');
        description.className = 'drug-description';
        description.textContent = String(drug.description || '');

        const stats = document.createElement('div');
        stats.className = 'stat-list';

        const qty = document.createElement('div');
        qty.className = 'stat';
        qty.innerHTML = `<span>Venda por ponto</span><strong>${Number(drug.minQuantity || 1)}–${Number(drug.maxQuantity || 1)} unidades</strong>`;

        const price = document.createElement('div');
        price.className = 'stat';
        const minPrice = Number(drug.minPricePerUnit || 0);
        const maxPrice = Number(drug.maxPricePerUnit || minPrice);
        price.innerHTML = `<span>Valor por unidade</span><strong>$${money(minPrice)}${maxPrice !== minPrice ? `–$${money(maxPrice)}` : ''}</strong>`;

        const risk = document.createElement('div');
        risk.className = 'stat';
        risk.innerHTML = `<span>Risco de denúncia</span><strong class="risk">${Number(drug.refusalChance || 0)}%</strong>`;

        stats.append(qty, price, risk);

        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'select-button';
        button.disabled = Number(drug.stock || 0) <= 0;
        button.textContent = button.disabled ? 'VOLTE AQUI COM A DROGA!' : 'SELECIONAR ROTA';
        button.addEventListener('click', () => openConfirm(drug));

        body.append(titleWrap, description, stats, button);
        card.append(imageWrap, body);
        return card;
    };

    const render = () => {
        grid.replaceChildren();
        drugs.forEach(drug => grid.appendChild(createCard(drug)));
    };

    const openConfirm = drug => {
        if (!drug || Number(drug.stock || 0) <= 0 || sending) return;
        selected = drug;
        confirmTitle.textContent = `Vender ${String(drug.label || drug.item || 'drogas')}?`;
        confirmProduct.innerHTML = `<strong>${String(drug.label || drug.item || 'Droga')}</strong> · ${Number(drug.minQuantity || 1)} a ${Number(drug.maxQuantity || 1)} unidade(s) por venda`;
        confirmLayer.classList.add('open');
        confirmLayer.setAttribute('aria-hidden', 'false');
    };

    const closeConfirm = () => {
        if (sending) return;
        selected = null;
        confirmLayer.classList.remove('open');
        confirmLayer.setAttribute('aria-hidden', 'true');
    };

    const hide = () => {
        selected = null;
        sending = false;
        document.body.classList.remove('ui-open');
        app.classList.remove('open');
        app.setAttribute('aria-hidden', 'true');
        confirmLayer.classList.remove('open');
        confirmLayer.setAttribute('aria-hidden', 'true');
    };

    const requestClose = async () => {
        if (sending) return;
        hide();
        await nui('close');
    };

    acceptConfirm.addEventListener('click', async () => {
        if (!selected || sending) return;
        sending = true;
        acceptConfirm.disabled = true;
        cancelConfirm.disabled = true;
        acceptConfirm.textContent = 'INICIANDO...';

        const result = await nui('startRoute', { key: selected.key });

        sending = false;
        acceptConfirm.disabled = false;
        cancelConfirm.disabled = false;
        acceptConfirm.textContent = 'Iniciar rota';

        if (result && result.ok === true) {
            hide();
        } else {
            closeConfirm();
        }
    });

    closeButton.addEventListener('click', requestClose);
    cancelConfirm.addEventListener('click', closeConfirm);

    window.addEventListener('keydown', event => {
        if (event.key !== 'Escape') return;
        if (confirmLayer.classList.contains('open')) {
            closeConfirm();
        } else if (app.classList.contains('open')) {
            requestClose();
        }
    });

    // Estado inicial obrigatório: a NUI nunca deve renderizar overlay ao carregar/reiniciar o resource.
    hide();

    window.addEventListener('message', event => {
        const data = event.data || {};

        if (data.action === 'open') {
            imageBaseUrl = normalizedBase(data.imageBaseUrl);
            drugs = Array.isArray(data.drugs) ? data.drugs : [];
            renderReputation(data.reputation);
            selected = null;
            sending = false;
            render();
            document.body.classList.add('ui-open');
            app.classList.add('open');
            app.setAttribute('aria-hidden', 'false');
            return;
        }

        if (data.action === 'reputation') {
            renderReputation(data.reputation);
            return;
        }

        if (data.action === 'close') {
            hide();
        }
    });
})();

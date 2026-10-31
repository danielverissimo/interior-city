// Local searchable chooser. All labels are text; no provider URLs or executable markup.
export const searchKey = value => String(value ?? '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLocaleLowerCase('pt-BR');
const element = (tag, text, className) => { const el = document.createElement(tag); if (text != null) el.textContent = text; if (className) el.className = className; return el; };
export function catalogPicker({ parent, title, options, selected = [], multiple = false, onChoose, onClose, locked = () => false }) {
    const root = element('section', null, 'form-picker'); root.setAttribute('aria-label', title);
    const search = element('input'); search.type = 'search'; search.placeholder = 'Buscar por nome ou código…'; search.setAttribute('aria-label', 'Buscar opções');
    const count = element('p', null, 'form-note'), results = element('div', null, 'form-picker-results'), actions = element('div', null, 'form-buttons');
    const values = new Set(selected.map(String));
    const close = () => { root.remove(); onClose?.(); };
    const button = (label, callback) => { const el = element('button', label); el.type = 'button'; el.onclick = callback; return el; };
    const finish = button('Adicionar selecionados', () => { if (!locked()) { onChoose([...values]); close(); } });
    actions.append(button('Cancelar seleção', close)); if (multiple) actions.append(finish);
    function render() {
        const query = searchKey(search.value), matches = options.filter(option => searchKey(`${option.label} ${option.value} ${option.description || ''}`).includes(query));
        count.textContent = `${matches.length} opções${multiple ? ` · ${values.size} selecionadas` : ''}`; finish.disabled = !values.size || locked(); results.replaceChildren();
        for (const option of matches.slice(0, 80)) {
            const row = element(multiple ? 'label' : 'button', null, 'form-picker-option');
            if (multiple) {
                const check = element('input'); check.type = 'checkbox'; check.checked = values.has(String(option.value));
                check.onchange = () => { if (locked()) return; if (check.checked) values.add(String(option.value)); else values.delete(String(option.value)); count.textContent = `${matches.length} opções · ${values.size} selecionadas`; finish.disabled = !values.size; }; row.append(check);
            } else { row.type = 'button'; row.onclick = () => { if (!locked()) { onChoose([String(option.value)]); close(); } }; }
            const text = element('span'); text.append(element('strong', option.label || option.value), element('small', String(option.value))); row.append(text); results.append(row);
        }
        if (!matches.length) results.append(element('p', 'Nenhuma opção encontrada.', 'form-note'));
        if (matches.length > 80) results.append(element('p', 'Refine a busca para localizar outras opções.', 'form-note'));
    }
    root.append(element('h3', title), search, count, results, actions); parent.append(root); search.oninput = render;
    search.onkeydown = event => { if (event.key === 'Enter') event.preventDefault(); if (event.key === 'Escape') { event.preventDefault(); event.stopPropagation(); close(); } };
    render(); search.focus(); return { root, close };
}

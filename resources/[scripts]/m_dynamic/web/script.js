const app = {
  modalCleanup: null,
  open({ targets = [], status = 'close', title = 'Ações rápidas' }) {
    this.closeModal();
    document.body.style.display = 'block';
    document.querySelector('.menu-title').textContent = title;
    const list = document.querySelector('.list');
    list.replaceChildren();
    this.updateStatus(document.querySelector('.status'), status);
    if (!targets.length) {
      const empty = document.createElement('p');
      empty.className = 'empty';
      empty.textContent = 'Nenhuma roupa salva. Volte e escolha Salvar.';
      list.appendChild(empty);
    }
    targets.forEach(target => list.appendChild(this.createTargetElement(target)));
  },
  createTargetElement(target) {
    const row = document.createElement('div');
    row.className = 'target-row';
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'target';
    if (target.image) {
      const image = document.createElement('img');
      image.src = target.image; image.alt = '';
      button.appendChild(image);
    }
    const text = document.createElement('span');
    text.className = 'target-text';
    const name = document.createElement('strong');
    name.textContent = target.name;
    text.appendChild(name);
    if (target.description) {
      const description = document.createElement('small');
      description.textContent = target.description;
      text.appendChild(description);
    }
    button.appendChild(text);
    if (target.type === 'menu') {
      const arrow = document.createElement('span');
      arrow.className = 'chevron'; arrow.textContent = '›';
      button.appendChild(arrow);
    }
    button.addEventListener('click', () => target.modal ? this.showModal() : this.sendRequest('target', { target }));
    row.appendChild(button);
    if (target.delete) {
      const trash = document.createElement('button');
      trash.type = 'button'; trash.className = 'trash';
      trash.title = 'Excluir ' + target.name;
      trash.setAttribute('aria-label', trash.title);
      const icon = document.createElement('img'); icon.src = './assets/trash.svg'; icon.alt = '';
      trash.appendChild(icon);
      trash.addEventListener('click', () => this.sendRequest('deleteOutfit', { target }));
      row.appendChild(trash);
    }
    return row;
  },
  showModal() {
    this.closeModal();
    const modal = document.querySelector('.modal');
    const input = modal.querySelector('input');
    modal.style.display = 'flex';
    input.value = '';
    input.focus();
    const save = () => {
      const name = input.value.trim();
      if (!name) { input.setCustomValidity('Digite um nome para a roupa.'); input.reportValidity(); return; }
      input.setCustomValidity('');
      this.sendRequest('saveOutfit', { name });
    };
    const cancel = () => this.closeModal();
    const onKey = e => { if (e.key === 'Enter') { e.preventDefault(); save(); } };
    const onInput = () => input.setCustomValidity('');
    const saveButton = document.querySelector('#save'), closeButton = document.querySelector('#close');
    saveButton.addEventListener('click', save);
    closeButton.addEventListener('click', cancel);
    input.addEventListener('keydown', onKey);
    input.addEventListener('input', onInput);
    this.modalCleanup = () => {
      saveButton.removeEventListener('click', save); closeButton.removeEventListener('click', cancel);
      input.removeEventListener('keydown', onKey); input.removeEventListener('input', onInput);
    };
  },
  closeModal() {
    if (this.modalCleanup) this.modalCleanup();
    this.modalCleanup = null;
    document.querySelector('.modal').style.display = 'none';
  },
  async sendRequest(endpoint, data) {
    try {
      const response = await fetch('https://' + GetParentResourceName() + '/' + endpoint, {
        method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: JSON.stringify(data)
      });
      if (!response.ok) throw Error('HTTP ' + response.status);
      await response.json();
      if (endpoint === 'saveOutfit' || endpoint === 'deleteOutfit') this.close();
    } catch (error) { console.error('[m_dynamic]', endpoint, error); }
  },
  updateStatus(element, status) {
    const back = status === 'back';
    element.src = './assets/' + (back ? 'back' : 'close') + '.svg';
    element.setAttribute('status', back ? 'back' : 'close');
    element.alt = back ? 'Voltar' : 'Fechar';
    element.parentElement.setAttribute('aria-label', element.alt);
  },
  goBack(element) {
    const endpoint = element.getAttribute('status') === 'back' ? 'back' : 'close';
    if (endpoint === 'close') this.close();
    this.sendRequest(endpoint, {});
  },
  close() {
    this.closeModal();
    document.body.style.display = 'none';
    document.querySelector('.list').replaceChildren();
  }
};
window.addEventListener('message', ({ data }) => {
  if (data.action === 'open') app.open(data);
  else if (data.action === 'close') app.close();
});
window.addEventListener('keydown', event => {
  if (event.key === 'Escape') {
    if (app.modalCleanup) app.closeModal();
    else { app.close(); app.sendRequest('close', {}); }
  }
});
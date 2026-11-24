const identityForm = {
  gender: 1,
  submitting: false,

  open({ reset = false }) {
    const form = document.querySelector('#whitelist');
    for (const input of form.querySelectorAll('article input')) input.value = '';
    form.querySelector('h1').innerHTML = reset
      ? 'RECRIE SEU <br> <strong>PERSONAGEM</strong>'
      : 'REGISTRO EM CARTÓRIO <br> <strong>DO PERSONAGEM</strong>';
    this.selectGender(form.querySelector('.gender'), 1);
    form.style.display = 'flex';
  },

  close() {
    document.querySelector('#whitelist').style.display = 'none';
  },

  selectGender(element, gender) {
    for (const option of document.querySelectorAll('#whitelist .gender')) {
      option.classList.toggle('selected', option === element);
    }
    this.gender = gender;
  },

  async submit() {
    if (this.submitting) return;
    const form = document.querySelector('#whitelist');
    const name = form.querySelector('#name').value.trim().normalize('NFC');
    const surname = form.querySelector('#surname').value.trim().normalize('NFC');
    const age = Number(form.querySelector('article #age').value);
    const validName = /^[A-Za-zÀ-ÖØ-öø-ÿ]{2,25}$/;
    if (!validName.test(name) || !validName.test(surname)) {
      notify.create('Use de 2 a 25 letras no nome e no sobrenome.');
      return;
    }
    if (!Number.isInteger(age) || age < 18 || age > 2147483647) {
      notify.create('Informe uma idade inteira de 18 anos ou mais.');
      return;
    }

    const button = form.querySelector('button');
    this.submitting = true;
    button.disabled = true;
    try {
      const resourceName = GetParentResourceName();
      const response = await fetch(`https://${resourceName}/registerIdentity`, {
        method: 'POST',
        body: JSON.stringify({ name, surname, age, sex: this.gender }),
      });
      const result = await response.json();
      if (result.ok !== true) throw new Error('Registro recusado');
      this.close();
    } catch {
      notify.create('Não foi possível registrar o personagem. Tente novamente.');
    } finally {
      this.submitting = false;
      button.disabled = false;
    }
  },
};

const notify = {
  create(text) {
    const notification = document.createElement('div');
    notification.className = 'notify';
    const message = document.createElement('p');
    message.textContent = text;
    notification.append(message);
    document.querySelector('.notify_list').append(notification);
    setTimeout(() => notification.remove(), 6000);
  },
};

function resetChar() {
  fetch(`https://${GetParentResourceName()}/resetChar`, { method: 'POST' });
}

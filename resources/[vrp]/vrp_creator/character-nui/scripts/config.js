// const containerVehicles = document.querySelector('.vehicles')
//   containerVehicles.innerHTML = config.vehicles.map((vehicle) => `
//       <div class = "vehicle" data-spawn="${vehicle.spawn}" onclick="whitelistApp.selectVehicle(this)" style="cursor: pointer;">
//         <div class = 'text'>
//             <h4>${vehicle.name}</h4>
//             <p>${vehicle.type}</p>
//         </div>
//         <img src="${vehicle.image}" alt="">
//       </div>
//   `).join(" ")

const post = async (url, data = {}, mock) => {
  const resourceName = window.GetParentResourceName ? GetParentResourceName() : 'vrp_creator';
  if (mock && !window.invokeNative) {
    return mock;
  }
  return fetch(`https://${resourceName}/${url}`, { method: 'POST', body: JSON.stringify(data) })
    .then(res => res.json());
};

const whitelistApp = {
  id: 120,
  currentPage: 1,
  resetMode: false,

  open: ({ id, reset = false }) => {
    const whitelist = document.querySelector('#whitelist');
    const sections = document.querySelectorAll('#whitelist section');

    whitelistApp.currentPage = 1;
    whitelistApp.resetMode = reset === true;
    whitelist.style.display = "flex";
    document.querySelector('#passport').innerHTML = id;
    whitelistApp.id = id;

    if (sections[0]) sections[0].style.display = 'flex';
    if (sections[1]) sections[1].style.display = 'none';
    if (sections[2]) sections[2].style.display = 'none';

    const button = document.querySelector('#whitelist button[onclick*="whitelistApp.step"]');
    if (button) button.innerHTML = whitelistApp.resetMode ? 'CONTINUAR' : 'PROSSEGUIR';

    const title = document.querySelector('#whitelist h1');
    if (title) {
      title.innerHTML = whitelistApp.resetMode
        ? 'RECRIE SEU <br> <strong>PERSONAGEM</strong>'
        : 'REALIZE SUA <br> <strong>WHITELIST</strong>';
    }

    const steps = document.querySelector('#whitelist .steps');
    if (steps) steps.style.display = whitelistApp.resetMode ? 'none' : 'flex';

    const name = document.getElementById('name');
    const surname = document.getElementById('surname');
    const age = document.querySelector('#whitelist article #age');
    if (name) name.value = '';
    if (surname) surname.value = '';
    if (age) age.value = '';

    document.querySelectorAll('#whitelist .steps .step').forEach((step, index) => {
      step.style.background = index === 0 ? '#2981FF' : '';
      step.style.color = index === 0 ? '#fff' : '';
    });
    document.querySelectorAll('#whitelist .line').forEach((line) => {
      line.style.background = '';
    });
  },
  step: () => {
    if (whitelistApp.currentPage === 1) {
      const name = document.getElementById('name').value;
      const surname = document.getElementById('surname').value;
      const age = document.querySelector('article #age').value;

      const regexName = /^[a-zA-Z]+$/;
      if (!regexName.test(name) || !regexName.test(surname)) {
        notify.create('Você não pode colocar nomes com caracteres especiais');
        return;
      }

      if (name.length < 3 || surname.length < 3) {
        notify.create('Você não pode colocar nomes com menos de 3 caracteres');
        return;
      }

      if (name.length > 25 || surname.length > 25) {
        notify.create('Você não pode colocar nomes com mais de 25 caracteres');
        return;
      }

      if (!name.trim() || !surname.trim() || age < 18 || age > 99) {
        notify.create('Campos incorreto, preencha todos! Verifique se a idade está entre 18 e 99 e se os nomes não possuem espaços.');
        return;
      }

      // Em reset/plástica, whitelist e escolha de veículo não fazem parte da recriação.
      // A identidade é salva primeiro no servidor; só após confirmação abrimos o editor visual.
      if (whitelistApp.resetMode) {
        whitelistApp.post('finishWhitelist', {
          name,
          surname,
          age: Number(age),
          resetIdentityOnly: true,
        }).then((res) => {
          if (res && res.ok === true) {
            document.querySelector('#whitelist').style.display = 'none';
          } else {
            notify.create('Não foi possível atualizar os dados do personagem. Tente novamente.');
          }
        }).catch(() => {
          notify.create('Não foi possível atualizar os dados do personagem. Tente novamente.');
        });
        return;
      }

      document.querySelectorAll('#whitelist section')[0].style.display = 'none';
      document.querySelectorAll('#whitelist section')[1].style.display = 'flex';
      document.querySelectorAll('#whitelist .steps .step')[1].style.background = '#2981FF';
      document.querySelectorAll('#whitelist .steps .step')[1].style.color = '#1e1e1e';
      document.querySelectorAll('#whitelist .line')[0].style.background = '#2981FF';
      document.querySelectorAll('#whitelist .line')[1].style.background = '#2981FF';
      // document.querySelector('#whitelist main img.title').src = './assets/icons/joinDiscord.svg';
      whitelistApp.currentPage = 2;
      return;
    }

    if (whitelistApp.currentPage === 2) {
      post('verify', {}, { whitelisted: true }).then((res) => {
        if (res.whitelisted) {
          document.querySelectorAll('#whitelist section')[1].style.display = 'none';
          document.querySelectorAll('#whitelist section')[2].style.display = 'flex';
          document.querySelector('#whitelist button').innerHTML = 'FINALIZAR';
          document.querySelectorAll('#whitelist .line')[1].style.background = '#2981FF';
          document.querySelectorAll('#whitelist .steps .step')[2].style.background = '#2981FF';
          document.querySelectorAll('#whitelist .steps .step')[2].style.color = '#fff';
          whitelistApp.currentPage = 3;
        }
      });
    }

    if (whitelistApp.currentPage === 3) {
      whitelistApp.post('finishWhitelist', {
        vehicle: document.querySelector("#whitelist article .vehicle.selected").dataset.spawn,
        name: document.querySelector('#whitelist #name').value,
        surname: document.querySelector('#whitelist #surname').value,
        age: Number(document.querySelector('#whitelist #age').value),
      });
      document.querySelector('#whitelist').style.display = 'none';
    }

  },
  close: () => {
    document.querySelector('#whitelist').style.display = 'none';
  },
  post: (url, data = {}, mock) => {
    const resourceName = window.GetParentResourceName ? GetParentResourceName() : 'vrp_creator';
    if (mock && !window.invokeNative) {
      return mock;
    }
    return fetch(`https://${resourceName}/${url}`, { method: 'POST', body: JSON.stringify(data) })
      .then(res => res.json());
  },
  copyId: () => {
    const copyFrom = document.createElement('textarea');
    copyFrom.innerHTML = whitelistApp.id;
    document.body.append(copyFrom);
    copyFrom.select();
    document.execCommand('copy');
    copyFrom.remove();

    notify.create('ID copiado para o seu CTRL+V');
  },
  redirect: () => {
    console.log(config.discordURL);
    window.invokeNative("openUrl", config.discordURL);
  },
  changeGender: (element, sex) => {
    document.querySelectorAll('#whitelist .buttons .gender').forEach((b) => b.classList.remove('selected'));
    element.classList.add('selected');
    whitelistApp.post("changeGender", { sex });
  },
  selectVehicle: (element) => {
    document.querySelector("#whitelist .vehicle.selected")?.classList.remove("selected");
    element.classList.add("selected");
  },
  confirm: () => {
    const name = document.querySelectorAll('#whitelist .fields input')[0].value;
    const surname = document.querySelectorAll('#whitelist .fields input')[1].value;
    const age = Number(document.querySelectorAll('#whitelist .fields input')[2].value);
    const find = document.querySelector('#whitelist select').value;
    if (whitelistApp.currentPage === 0) {
      const regexName = /^[a-zA-Z]+$/;
      if (!regexName.test(name) || !regexName.test(surname)) {
        notify.create('Você não pode colocar nomes com caracteres especiais');
        return;
      }
      if (!name.trim() || !surname.trim() || age < 18 || age > 99 || !find) {
        notify.create('Campos incorreto, preencha todos! Verifique se a idade está entre 18 e 99 e se os nomes não possuem espaços.');
        return;
      }
      document.querySelector('#whitelist .one .block_step').style.display = 'flex';
      document.querySelector('#whitelist .two .block_step').style.display = 'none';
      whitelistApp.currentPage = 1;
      return;
    }

    if (whitelistApp.currentPage === 1) {
      post("verify", {}, { whitelisted: true }).then((res) => {
        console.log(res);
        if (res.whitelisted) {
          document.querySelector('#whitelist .two .block_step').style.display = 'flex';
          document.querySelector('#whitelist .three .block_step').style.display = 'none';
          whitelistApp.currentPage = 2;
        }
      });
      return;
    }

    whitelistApp.post("finishWhitelist", {
      vehicle: document.querySelector("#whitelist .vehicles .vehicle.selected").dataset.spawn,
      name: document.querySelectorAll('#whitelist .fields input')[0].value,
      surname: document.querySelectorAll('#whitelist .fields input')[1].value,
      age: Number(document.querySelectorAll('#whitelist .fields input')[2].value),
      recommendation: Number(document.querySelector('#recommendation').value)
    });

    document.querySelector('#whitelist .one .block_step').style.display = 'none';
    document.querySelector('#whitelist .two .block_step').style.display = 'flex';
    document.querySelector('#whitelist .three .block_step').style.display = 'flex';
  }
};

const notify = {
  create: (text) => {
    const element = document.createElement("div")
    element.classList.add("notify")
    element.innerHTML = `
<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M9.23077 10.7692V5.38462C9.23077 5.18061 9.31181 4.98495 9.45607 4.84069C9.60033 4.69643 9.79599 4.61539 10 4.61539C10.204 4.61539 10.3997 4.69643 10.5439 4.84069C10.6882 4.98495 10.7692 5.18061 10.7692 5.38462V10.7692C10.7692 10.9732 10.6882 11.1689 10.5439 11.3132C10.3997 11.4574 10.204 11.5385 10 11.5385C9.79599 11.5385 9.60033 11.4574 9.45607 11.3132C9.31181 11.1689 9.23077 10.9732 9.23077 10.7692ZM20 6.4952V13.5048C20.0006 13.7069 19.9611 13.9071 19.8837 14.0938C19.8063 14.2805 19.6925 14.45 19.549 14.5923L14.5923 19.549C14.45 19.6925 14.2805 19.8063 14.0938 19.8837C13.9071 19.9611 13.7069 20.0006 13.5048 20H6.4952C6.29309 20.0006 6.09287 19.9611 5.90617 19.8837C5.71948 19.8063 5.55004 19.6925 5.4077 19.549L0.450969 14.5923C0.307488 14.45 0.193732 14.2805 0.116315 14.0938C0.0388971 13.9071 -0.000637922 13.7069 7.78356e-06 13.5048V6.4952C-0.000637922 6.29309 0.0388971 6.09287 0.116315 5.90617C0.193732 5.71948 0.307488 5.55004 0.450969 5.4077L5.4077 0.450969C5.55004 0.307488 5.71948 0.193732 5.90617 0.116315C6.09287 0.0388971 6.29309 -0.000637922 6.4952 7.78356e-06H13.5048C13.7069 -0.000637922 13.9071 0.0388971 14.0938 0.116315C14.2805 0.193732 14.45 0.307488 14.5923 0.450969L19.549 5.4077C19.6925 5.55004 19.8063 5.71948 19.8837 5.90617C19.9611 6.09287 20.0006 6.29309 20 6.4952ZM18.4615 6.4952L13.5048 1.53847H6.4952L1.53847 6.4952V13.5048L6.4952 18.4615H13.5048L18.4615 13.5048V6.4952ZM10 13.0769C9.77179 13.0769 9.54871 13.1446 9.35896 13.2714C9.16921 13.3982 9.02132 13.5784 8.93399 13.7892C8.84665 14 8.8238 14.232 8.86833 14.4559C8.91285 14.6797 9.02274 14.8853 9.18411 15.0467C9.34548 15.208 9.55107 15.3179 9.7749 15.3624C9.99872 15.407 10.2307 15.3841 10.4416 15.2968C10.6524 15.2094 10.8326 15.0616 10.9594 14.8718C11.0862 14.6821 11.1538 14.459 11.1538 14.2308C11.1538 13.9247 11.0323 13.6313 10.8159 13.4149C10.5995 13.1985 10.306 13.0769 10 13.0769Z" fill="#2981FF"/>
</svg>


      <div>
        <p>${text}</p>
      </div>
    `;
    document.querySelector('.notify_list').appendChild(element);
    notify.delete(element);
  },
  delete: (element) => {
    setTimeout(() => {
      element.remove()
    }, 6000);
  }
}

const resetChar = () => {
  fetch('https://vrp_creator/resetChar', { method: 'POST' })
}

/* if (!window.invokeNative) {
  document.body.style.background = '#1c1c1c'
  whitelistApp.open({ id: 1 })
} */
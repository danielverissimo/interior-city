const app = {
  selectedRoute: null,
  routes: [],

  init(routes) {
    this.routes = routes;
    this.render();
    this.setupEventListeners();
  },

  render() {
    document.body.style.display = 'flex';
    const sectionEl = document.querySelector('main');
    sectionEl.innerHTML = this.routes.map(this.createRouteHTML).join('');
    this.updateHeaderInfo(this.routes[0]);
    this.selectRoute(this.routes[0]);
  },

  createRouteHTML(route) {
    return `
      <div class="item" data-route-name="${route.name}">
        <div class="content">
          <div class="image">
            <img src="${route.icon}" alt="">
          </div>
          <div class="text">
            <div class="title">
              <h3>${route.name}</h3>
              <p>Escolha a região da rota para iniciar.</p>
            </div>
            <div class="buttons">
              <button data-region="south">SUL</button>
              <button data-region="north">NORTE</button>
              <button data-region="air">AÉREA</button>
              <button data-region="water">MARITIMA</button>
            </div>
          </div>
        </div>
        <button class="start">INICIAR</button>
      </div>
    `;
  },

  setupEventListeners() {
    document.querySelector('main').addEventListener('click', this.handleRouteClick.bind(this));
  },

  handleRouteClick(event) {
    const routeEl = event.target.closest('.item');
    if (!routeEl) return;

    const routeName = routeEl.dataset.routeName;
    const route = this.routes.find(r => r.name === routeName);

    if (event.target.classList.contains('start')) {
      this.startRoute(route, routeEl);
    } else if (event.target.closest('.buttons')) {
      this.selectRegion(event.target, route);
    } else {
      this.selectRoute(route);
    }
  },

  selectRegion(buttonEl, route) {
    if (!buttonEl.matches('button')) return;

    const buttonsEl = buttonEl.closest('.buttons').querySelectorAll('button');
    buttonsEl.forEach(button => button.classList.remove('selected'));
    buttonEl.classList.add('selected');

    this.selectRoute(route);
  },

  selectRoute(route) {
    this.selectedRoute = route;
    this.updateHeaderInfo(route);
  },

  updateHeaderInfo(route) {
    document.querySelector('#coins').textContent = `${route.coins}x`;
    document.querySelector('.multiplier').textContent = `${route.multiplier}x`;
  },

  startRoute(route, routeEl) {
    const selectedRegionEl = routeEl.querySelector('.buttons button.selected');
    if (!selectedRegionEl) return;

    const region = selectedRegionEl.dataset.region;
    this.sendRequest(`http://m_farm/start`, { route, region });
  },

  handleBoostClick() {
    if (!this.selectedRoute) return;
    this.sendRequest(`http://m_farm/boost`, { route: this.selectedRoute });
  },

  sendRequest(url, data) {
    fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
  },

  close() {
    document.body.style.display = 'none';
    document.location.reload(); // Ruan vc causa muito bugs, flavin utilizou essa metodologia pois, para resolver o problema seria muito mais complexo, visto que o o codigo está uma porcaria e muito ruim!!!!
  }
};

window.addEventListener('message', ({ data }) => {
  if (data.action === 'open') {
    app.init(data.routes);
  } else if (data.action === 'close') {
    app.close();
  }
});

window.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    app.close();
    app.sendRequest(`http://m_farm/close`);
  }
});


if (!window.invokeNative) {
  document.body.style.backgroundColor = '#1e1e1e';
  window.postMessage({
    action: 'open',
    routes: [
      {
        name: 'ROTAS DE PAPEL',
        icon: 'https://cdn.discordapp.com/attachments/1242116879661662349/1291923317388738620/image.png?ex=6701dcd9&is=67008b59&hm=28bd416557301eb8307cb7241e8e99d1cdedccd99a2927c4e135f618f3ace3ae&',
        coins: 100,
        multiplier: 1.5,
      },
      {
        name: 'ROTAS DE PAPEL2',
        icon: 'https://cdn.discordapp.com/attachments/1242116879661662349/1291923317388738620/image.png?ex=6701dcd9&is=67008b59&hm=28bd416557301eb8307cb7241e8e99d1cdedccd99a2927c4e135f618f3ace3ae&',
        coins: 60,
        multiplier: 1.2,
      },
      {
        name: 'ROTAS DE PAPEL 3',
        icon: 'https://cdn.discordapp.com/attachments/1242116879661662349/1291923317388738620/image.png?ex=6701dcd9&is=67008b59&hm=28bd416557301eb8307cb7241e8e99d1cdedccd99a2927c4e135f618f3ace3ae&',
        coins: 20,
        multiplier: 1.1,
      }
    ]
  });
}
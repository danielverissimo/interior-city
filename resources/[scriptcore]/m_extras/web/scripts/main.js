const intercom = {
  open: function(data) {
    this.updateTitle(data)
    this.updateOptions(data)
    document.querySelector('#intercom').style.display = 'flex'
  },
  updateOptions: function({ options }) {
    options.forEach(option => {
      document.querySelector('#intercom .options').innerHTML += `
        <div class="option" onclick="intercom.selectOption('${option}')">
          <div>
            <span>INTERFONAR</span>
            <div></div>
            <small>${option}</small>
          </div>
          <svg width="20" height="19" viewBox="0 0 20 19" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path fill-rule="evenodd" clip-rule="evenodd" d="M0.624503 11.8847C-0.208168 10.409 -0.208168 8.59095 0.624503 7.11529L3.29383 2.38471C4.1265 0.909045 5.66534 0 7.33068 0H12.6693C14.3347 0 15.8735 0.909044 16.7062 2.38471L19.3755 7.11529C20.2082 8.59095 20.2082 10.409 19.3755 11.8847L16.7062 16.6153C15.8735 18.091 14.3347 19 12.6693 19H7.33068C5.66534 19 4.1265 18.091 3.29383 16.6153L0.624503 11.8847ZM6.92351 10.5577L5.89801 10.3108C5.57758 9.95151 5.39539 9.4855 5.38526 8.99921C5.39539 8.51293 5.57758 8.04691 5.89801 7.68762L14.6147 5.58908V12.4093L8.9745 11.0515V11.8847C8.9745 12.4642 8.51537 12.934 7.949 12.934C7.38264 12.934 6.92351 12.4642 6.92351 11.8847V10.5577Z" fill="currentColor"/>
          </svg>
        </div>
      `
    })
  },
  updateTitle: function({ title }) {
    document.querySelector('#intercom .head h1').textContent = title
  },
  selectOption: function(option) {
    fetch(`https://${GetParentResourceName()}/INTERCOM_OPTION`, {
      method: 'POST',
      body: JSON.stringify({ option })
    })
  },
  close: function() {
    document.querySelector('#intercom').style.display = 'none'
    document.querySelector('#intercom .options').innerHTML = ''
  }
}

const domination = {
  open: function(data) {
    // this.updateInformations(data)
    document.querySelector('#domination').style.display = 'flex'
  },
  updateInformations: function({ informations }) {
    document.querySelectorAll('.information').forEach(element => element.style.display = 'none')

    document.querySelector('.information.name .text p').textContent = informations.name
    document.querySelector('.information.enemies .text p').textContent = informations.enemies
    document.querySelector('.information.organization .text p').textContent = informations.organization
    document.querySelector('.information.points .text p').textContent = informations.points
    document.querySelector('.information.allies .text p').textContent = informations.allies

    Object.keys(informations).forEach(info => document.querySelector('.information.'+info).style.display = 'flex')
  },
  close: function() {
    document.querySelector('#domination').style.display = 'none'
  }
}

window.addEventListener('keydown', ({ key }) => {
  if (key === 'Escape') {
    if (document.querySelector('#intercom').style.display === 'flex') {
      fetch(`https://${GetParentResourceName()}/close`)
      intercom.close()
    } 
  }
})

window.addEventListener('message', ({ data }) => {
  if (data.action === 'open:intercom') intercom.open(data)
  if (data.action === 'close:intercom') intercom.close()

  if (data.action === 'open:domination') domination.open(data)
  if (data.action === 'close:domination') domination.close()
  if (data.action === 'update:domination') domination.updateInformations(data)
})

if (!window.invokeNative) {
  document.body.style.background = '#1c1c1c'
  // window.postMessage({
  //   action: 'open:intercom',
  //   title: 'ROXOS',
  //   options: ['comprar', 'vender', 'parceria']
  // })

  window.postMessage({
    action: 'update:domination',
    informations: {
      name: 'Armas',
      enemies: '32/40',
      organization: 'Máfia',
      // points: '300/000',
      allies: '10'
    }
  })
}
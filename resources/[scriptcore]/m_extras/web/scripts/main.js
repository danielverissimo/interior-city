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

window.addEventListener('message', ({ data }) => {

  if (data.action === 'open:domination') domination.open(data)
  if (data.action === 'close:domination') domination.close()
  if (data.action === 'update:domination') domination.updateInformations(data)
})

if (!window.invokeNative) {
  document.body.style.background = '#1c1c1c'

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
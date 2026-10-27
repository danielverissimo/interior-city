
/* 
action = "open",
image = avatarURL,
id = user_id,
name = identity.nome .. " " .. identity.sobrenome,
rg = identity.registro,
birth = identity.idade,
telephone = identity.telefone,
org = org,
spouse = spouse, 
wallet = vRP.getMoney(user_id),
bank = vRP.getBankMoney(user_id),

carry = porte,
staff = isStaff,
vips = currentVips,
*/

window.addEventListener('message', ({ data }) => {
  if (data.action === 'close') {
    document.body.style.display = 'none'
  } else if (data.action === 'open') {
    document.querySelector('#icon').src = data.image || './assets/logo.png'
    document.querySelector('#name').innerHTML = data.name
    document.querySelector('#id').innerText = `ID ${data.id}`
    document.querySelector('#age').innerText = data.birth
    document.querySelector('#telephone').innerText = data.telephone
    document.querySelector('#org').innerText = data.org
    document.querySelector('#vips').innerText = Array.isArray(data.vips) && data.vips.length > 0 ? data.vips.join(', ') : 'Não possui'
    document.querySelector('#status').innerText = data.status_spouse
    document.querySelector('#emprego').innerText = data.emprego
    // document.querySelector('#spouse').innerText = data.spouse
    document.querySelector('#wallet').innerText = Number(data.wallet).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' })
    document.querySelector('#bank').innerText = Number(data.bank).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' })
    document.querySelector('#carry').innerText = data.carry ?? 'Não possui'


    document.body.style.display = 'flex'
  }
})

if (!window.invokeNative) {
  document.body.style.background = '#1c1c1c'
  window.postMessage({
    action: "open",
    image: '',
    id: Math.floor(Math.random() * 99999),
    name: "MAKAKERO",
    rg: Math.floor(Math.random() * 999999).toString(),
    birth: Math.floor(Math.random() * 80 + 18) + " ANOS",
    telephone: Math.floor(Math.random() * 999999999).toString(),
    org: ["POLICIA", "HOSPITAL", "MECANICO", "NENHUMA"][Math.floor(Math.random() * 4)],
    emprego: "Nenhum",
    spouse: ["SOLTEIRO", "CASADO"][Math.floor(Math.random() * 2)],
    wallet: Math.floor(Math.random() * 999999),
    bank: Math.floor(Math.random() * 9999999),
    carry: ["POSSUI", "NÃO POSSUI"][Math.floor(Math.random() * 2)],
    status_spouse: ["SOLTEIRO", "CASADO", "NAMORANDO"][Math.floor(Math.random() * 3)],
    vips: [["BRONZE", "PRATA", "OURO", "PLATINA"][Math.floor(Math.random() * 4)]],
  })
}
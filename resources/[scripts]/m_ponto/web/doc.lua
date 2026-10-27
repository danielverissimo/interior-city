SendNUIMessage({ action = 'open', data = {
  point = os.time() --- retorna o tempo que o player bateu ponto
} })

SendNUIMessage({ action = 'close' }) 

RegisterNUICallback('hideFrame', function(data, cb)
    cb(true)
end)

RegisterNUICallback('getRanking', function(data, cb)
  local payload = {
    { name = 'Joao' },
    { name = 'Cintino' },
    { name = 'Luiz tetao tetao tetao tetao tetao' },
    { name = 'Likizao' }
  }
    cb(payload)
end)

RegisterNUICallback('point', function(data, cb)
    print(data.status, data.point) -- O point não vai vir se o status for false, se for true, o point vai vir um os.time()
    cb(true)
end)

RegisterNUICallback('getEquipments', function(data, cb)
  local payload = {
    { name = 'name' },
    { name = 'image' },
    { name = 'name' },
    { name = 'image' },
    { name = 'name' },
    { name = 'image' },
    { name = 'name' },
    { name = 'image' },
    { name = 'name' },
    { name = 'image' },
}
    cb(payload)
end)

RegisterNUICallback('editUniform', function(data, cb)
    print(data.text, data.uniform)
    cb(true)
end)

RegisterNUICallback('getUniforms', function(data, cb)
    local payload = { -- Se quiser pode incrementar mais parâmetros no objeto, irei retornar ele no editUniform
      { name = 'name' },
      { name = 'image' },
      { name = 'name' },
      { name = 'image' },
      { name = 'name' },
      { name = 'image' },
      { name = 'name' },
      { name = 'image' },
      { name = 'name' },
      { name = 'image' },
  }
    cb(payload)
end)

RegisterNUICallback('equip', function(data, cb)
  -- Aqui você vai equipar o uniforme, colocar o jogador na frequencia da organização e adicionar seus equipamentos
  cb(true)
end)
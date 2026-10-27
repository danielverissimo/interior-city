return {
    -- Se você quiser configurar uma permissão para cada modo, utilize o formato abaixo:
    -- permission: { radio: 'permissao.jbl', bluetooth: 'permissao.bluetooth' },
  
    permission = 'player.som',
  
  command = 'som',
  prop = 'rojo_jblboombox01',
  propFallback = 'prop_boombox_01',
    
    -- Distância máxima (em metros) entre o jogador e o veículo/caixa de som
    -- Se essa distância for excedida, a música irá parar de tocar
    maxDistance = 1000000.0,
  
    dj = {
      {
        table = {204.31,-861.66,30.95},
        speaker = {202.99,-875.59,30.95},
        range = 50,
        volume = 150,
        permission = 'player.som' 
      }
    },
  
    range = { 
      -- Todos os números podem ser substituidos por [range, volume]
      -- ex: [48, 100] -> 48 metros com 100% de volume
      -- Por padrão, o script entende que um número sozinho é o alcance em metros, e o volume será 100%
      vehicle = {
        ['panto'] = 10, -- Padrão (48 metros & 100% de volume)

      },
  
      -- radio é a JBL, quando a música tocar fora de um veículo
      radio = {20, 50}, -- (20 metros & 50% de volume)
    },
    blacklist = {'spawn_do_veiculo'},
    allowBluetoothOnBikes = false,

    -- URLs de imagens da UI (configuráveis)
    uiImages = {
      -- Banner do topo (header)
      bannerUrl = 'https://media.discordapp.net/attachments/1411820081692020756/1436873050241892462/image.png?ex=69112fce&is=690fde4e&hm=528a903831920dbb79082f96c6e8d9b2e6237429c28141627c947fa53d4e0e9f&=&format=webp&quality=lossless&width=788&height=788',
      -- Avatar do perfil (imagem circular)
      avatarUrl = 'https://cdn.discordapp.com/attachments/1329602656762597519/1455064598557233297/W8Zf7FuOv9i3HHxbznB8BmSc6RIjLaAAAAAElFTkSuQmCC.png?ex=69535e02&is=69520c82&hm=a9ccf4e905b90b03c34ba5431c3b8d1ed64cf9080656cf24e8b2198acafdf6a3&',
    },

    -- Atenuação e suavização de volume por distância
    attenuation = {
      -- Mantém o volume estável quando perto (zona neutra)
      nearRadius = 1.5, -- metros
      -- Onde começa a reduzir o volume (percentual do alcance)
      fadeStartRatio = 0.5, -- 50% do range
      -- Suavização (0.0-1.0): quanto aproxima do volume alvo por tick
      smoothingFactor = 0.15,

      -- Específicos por tipo (opcional)
      vehicle = {
        nearRadius = 1.0,
        fadeStartRatio = 0.4,
        smoothingFactor = 0.15,
      },
      prop = {
        nearRadius = 1.5,
        fadeStartRatio = 0.5,
        smoothingFactor = 0.15,
      },
      dj = {
        nearRadius = 2.0,
        fadeStartRatio = 0.6,
        smoothingFactor = 0.2,
      },

      -- Limiar de movimento para reativar volume automático (evitar reativar ao mexer pouco)
      autoReactivateMovement = 0.5 -- metros
    },
}
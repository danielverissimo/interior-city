// Field contracts audited against mg_config_panel/web/app.js and resource APIs.
// Descriptors describe inputs, never new gameplay policy or persistence routes.
export const text = (key, label, extra = {}) => ({ key, label, type: 'text', ...extra });
export const num = (key, label, extra = {}) => ({ key, label, type: 'number', ...extra });
export const bool = (key, label, extra = {}) => ({ key, label, type: 'boolean', ...extra });
export const select = (key, label, options, extra = {}) => ({ key, label, type: 'select', options, ...extra });
export const item = (key, label, extra = {}) => ({ key, label, type: 'catalog', catalog: 'items', ...extra });
export const vehicle = (key, label, extra = {}) => ({ key, label, type: 'catalog', catalog: 'vehicles', ...extra });
export const object = (key, label, fields, extra = {}) => ({ key, label, type: 'object', fields, ...extra });
export const sequence = (key, label, entry, template, extra = {}) => ({ key, label, type: 'list', entry, template, ...extra });
export const dictionary = (key, label, entry, template, extra = {}) => ({ key, label, type: 'map', entry, template, ...extra });
export const coords = (key, label, extra = {}) => ({ key, label, type: 'coords', ...extra });
export const strings = (key, label, extra = {}) => sequence(key, label, text(null, 'Valor', { required: true, ...extra }), '', extra);
const fields = (...values) => values;
const xyz = () => ({ x: null, y: null, z: null });
const own = (label, entries, extra = {}) => object(null, label, entries, extra);
const permissions = (key = 'permissions', label = 'Permissões') => strings(key, label, { suggest: 'permissions' });
const itemCount = own('Item', [item('item', 'Item', { required: true }), num('qtd', 'Quantidade', { min: 1, integer: true, required: true })]);
const point = (label, array = false, heading = false) => coords(null, label, { array, heading });
const span = (label = 'Valores') => own(label, [num('min', 'Mínimo', { min: 0 }), num('max', 'Máximo', { min: 0 })], { range: ['min', 'max'] });
const blip = (key = 'blip', mode = 'garage') => object(key, 'Marcação no mapa', mode === 'garage' ? [
    bool('showBlip', 'Exibir blip no mapa'), text('name', 'Nome do blip'), num('blipId', 'Sprite do blip', { min: 0, integer: true, suggest: 'sprites' }),
    select('blipColor', 'Cor do blip', 'colors'), num('blipScale', 'Escala do blip', { min: 0.01 })
] : [bool('enabled', 'Exibir blip'), text('text', 'Nome do blip'), num('index', 'Sprite do blip', { min: 0, integer: true, suggest: 'sprites' }), select('color', 'Cor do blip', 'colors'), num('scale', 'Escala do blip', { min: 0.01 })]);
const advanced = (key, label) => ({ key, label, type: 'advanced' });
const uniform = (key, label = 'Uniforme') => ({ key, label, type: 'outfit' });
const groupTypes = ['', 'staff', 'org', 'emp', 'dm', 'vip'];
const orgTypes = ['', 'Armas', 'Municao', 'Drogas', 'Lavagem', 'Desmanche'];

export const FORM_SCHEMAS = {
    groups: fields(text('name', 'Nome do cargo', { required: true }), object('config', 'Propriedades do cargo', [
        select('gtype', 'Tipo do cargo', groupTypes, { custom: true }), num('salario', 'Salário', { min: 0, empty: '' }),
        select('ptr', 'PTR', [{ value: '', label: 'Não definido' }, { value: true, label: 'Ativado' }, { value: false, label: 'Desativado' }]),
        text('title', 'Título opcional'), text('orgName', 'Organização'), select('orgType', 'Tipo da organização', orgTypes, { custom: true })
    ]), permissions()),
    fac: fields(text('orgName', 'Organização', { required: true }), select('orgType', 'Tipo da organização', orgTypes, { custom: true, required: true }),
        item('goalItem', 'Item da meta', { required: true }), num('goalAmount', 'Quantidade da meta', { min: 1, required: true }), num('defaultReward', 'Recompensa da meta', { min: 0, required: true })),
    chests: fields(text('name', 'Nome', { required: true, immutable: true }), num('weight', 'Capacidade (kg)', { min: 0, required: true }), text('permission', 'Permissão', { suggest: 'permissions' }), coords('coords', 'Local do baú')),
    garages: fields(text('id', 'Identificador', { required: true }), select('type', 'Tipo da garagem', 'garageTypes', { required: true }),
        text('permiss', 'Permissão', { suggest: 'permissions' }), num('blipDistance', 'Distância do marcador', { min: 0.1 }), coords('coords', 'Local da garagem'),
        sequence('spawnCoords', 'Vagas de saída', point('Posição e direção', false, 'w'), { ...xyz(), w: 0 }, { minRows: 1, capture: true, heading: 'w', addLabel: 'Adicionar vaga', captureLabel: 'Posicionar nova vaga no jogo' })),
    garageTypes: fields(text('name', 'Nome do tipo', { immutable: true, required: true }), object('data', 'Configuração da garagem', [
        select('type', 'Modo da garagem', ['public', 'service'], { required: true }), blip(),
        object('listCars', 'Classes permitidas', [bool('vehicle', 'Carros e motos'), bool('boat', 'Barcos'), bool('heli', 'Helicópteros')], { when: [['data', 'type'], 'public'] }),
        sequence('vehicles', 'Veículos de serviço', own('Veículo', [vehicle('vehicle', 'Veículo de serviço', { required: true }), num('livery', 'Pintura / livery', { min: 0, integer: true, optional: true })]), { vehicle: '' }, { when: [['data', 'type'], 'service'] })
    ])),
    mapmarkings: fields(text('name', 'Nome exibido no mapa', { required: true }), num('sprite', 'Sprite / ícone', { min: 0, max: 10000, integer: true, suggest: 'sprites' }),
        select('color', 'Cor do mapa', 'colors'), num('scale', 'Escala', { min: 0.01, max: 100 }), bool('shortRange', 'Exibir somente próximo'), coords('coords', 'Local da marcação')),
    cloakroom: fields(text('name', 'Nome do fardamento / ponto', { required: true }), text('permission', 'Permissão', { suggest: 'permissions' }), coords('coords', 'Local do fardamento'),
        sequence('uniforms', 'Fardamentos', own('Fardamento', [text('name', 'Nome do fardamento', { required: true }), uniform(null)]), { name: 'Novo fardamento', masculino: {}, feminino: {} }, { outfit: true })),
    shops: fields(text('name', 'Nome da loja', { required: true }), object('data', 'Configuração da loja', [select('mode', 'Modo da loja', [{ value: 'buy', label: 'Compra' }, { value: 'sell', label: 'Venda' }], { required: true }),
        text('perm', 'Permissão', { suggest: 'permissions' }), bool('onlyWalletPayment', 'Somente dinheiro em mãos'),
        dictionary('items', 'Itens e preços', num(null, 'Preço', { min: 0, required: true }), 0, { keyCatalog: 'items', keyLabel: 'Item', addLabel: 'Adicionar item à loja' }),
        sequence('coords', 'Pontos da loja', own('Ponto da loja', [coords('coords', 'Posição'), bool('blip', 'Exibir blip neste ponto')]), { coords: xyz(), blip: false }, { capture: true, pointKey: 'coords', addLabel: 'Adicionar ponto da loja' }), blip('blip', 'shop')
    ])),
    clothing: fields(coords('coords', 'Local da loja de roupas')),
    barbershop: fields(coords('coords', 'Local da barbearia')),
    tattoo: fields(coords('coords', 'Local do estúdio de tatuagem')),
    desmanche: fields(text('name', 'Identificador', { required: true }), text('permissao', 'Permissão', { required: true, suggest: 'permissions' }), bool('precisa_de_item', 'Exigir item para iniciar'),
        sequence('itens_necessarios', 'Itens necessários', itemCount, { item: '', qtd: 1 }, { minRows: 1 }),
        coords('inicio', 'Início do desmanche'), coords('local_veiculo', 'Local do veículo'), coords('local_ferramentas', 'Local das ferramentas', { heading: 'w' }), coords('local_finalizar', 'Local de finalização')),
    desmancheSettings: fields(num('porcentagem_veiculocomum', 'Pagamento por veículo comum (0,35 = 35%)', { min: 0 }), num('porcentagem_veiculovip', 'Pagamento por veículo VIP (0,50 = 50%)', { min: 0 }),
        bool('desmanchar_proprio_veiculo', 'Permitir desmanchar o próprio veículo'), bool('desmanchar_veiculo_trabalho', 'Permitir desmanchar veículos de trabalho')),
    safezone: fields(text('name', 'Nome da zona segura', { required: true }), bool('debug', 'Ativar depuração do polígono'),
        sequence('zones', 'Polígonos', { type: 'polygon', label: 'Polígono' }, { minZ: null, maxZ: null, coords: [] }, { minRows: 1, addLabel: 'Adicionar polígono' })),
    safezoneSettings: fields(bool('useESX', 'Integração ESX'), bool('useWhitelist', 'Usar exceções de cargos'), num('checkLoopTime', 'Intervalo de verificação (ms)', { min: 50, integer: true }),
        sequence('whitelist', 'Exceções nas zonas seguras', own('Exceção', [text('job', 'Cargo / emprego', { required: true }), select('zone', 'Zona segura', 'zones', { required: true }), num('minGrade', 'Graduação mínima', { min: 0, integer: true })]), { job: '', zone: '', minGrade: 0 })),
    jobs: fields(object('job', 'Emprego', [num('total_nivel', 'Total de níveis', { min: 1, max: 50, integer: true, required: true }), coords('inicio', 'Local inicial', { array: true }),
        { key: null, type: 'levels', label: 'Níveis, experiência e pagamentos' }, uniform('uniforme', 'Uniformes do emprego')]), advanced('extra', 'Opções específicas do emprego')),
    jobsSettings: fields(coords('central', 'Central de empregos', { array: true }), coords('npc', 'Local e direção do NPC', { array: true, heading: 'w' })),
    robberies: fields(select('type', 'Tipo de roubo', 'robberyTypes', { required: true }), num('id', 'ID do local', { min: 1, integer: true, required: true }), coords(null, 'Local do roubo', { heading: 'h' })),
    robberySetups: fields(num('tempo', 'Tempo do roubo (s)', { min: 1 }), num('tempoEspera', 'Cooldown (min)', { min: 0 }), num('lspd', 'Policiais mínimos', { min: 0, integer: true }),
        dictionary('items', 'Recompensas do roubo', span(), { min: 0, max: 0 }, { keyCatalog: 'items', keyLabel: 'Item' }),
        dictionary('itemsNecessarios', 'Itens necessários', own('Requisito', [num('qtd', 'Quantidade necessária', { min: 1, integer: true })]), { qtd: 1 }, { keyCatalog: 'items', keyLabel: 'Item' })),
    robberySettings: fields(text('policePermission', 'Permissão da polícia', { suggest: 'permissions' }), permissions('blockedPermissions', 'Permissões bloqueadas'), num('policeBlipSeconds', 'Duração do blip policial (s)', { min: 1 })),
    houses: fields(text('name', 'Nome / identificador', { required: true }), select('type', 'Tipo da residência', ['Casa', 'Apartamento']),
        select('interior', 'Interior', 'interiors', { required: true }), num('price', 'Valor da residência', { min: 0 }), num('slot', 'Quantidade / vagas', { min: 1, integer: true }), num('trade', 'Valorização por venda', { min: 0 }), coords(null, 'Local da residência')),
    interiors: fields(text('name', 'Nome do interior', { required: true }), object('data', 'Modelo de interior', [select('type', 'Tipo recomendado', ['Casa', 'Apartamento']), num('valor', 'Valor de melhoria', { min: 0 }),
        num('residents', 'Moradores', { min: 1, integer: true }), num('vault', 'Capacidade do baú (kg)', { min: 0 }), num('fridge', 'Capacidade da geladeira', { min: 0 }),
        coords('interior', 'Entrada / saída do interior', { array: true }), coords('vaultCoords', 'Posição do baú', { array: true }), coords('wardobeCoords', 'Posição do guarda-roupas', { array: true })])),
    dealership: fields(vehicle('spawn', 'Veículo do estoque', { required: true, immutable: true }), num('stock', 'Quantidade em estoque', { min: 0, integer: true, required: true })),
    catalog: fields(text('spawn', 'Spawn / modelo', { required: true }), object('data', 'Veículo do servidor', [text('name', 'Nome exibido', { required: true }),
        num('price', 'Valor', { min: 0, required: true }), num('trunk', 'Porta-malas (kg)', { min: 0, required: true }), text('type', 'Tipo / categoria', { suggest: 'vehicleTypes' }), bool('banned', 'Veículo bloqueado') ])),
    dealershipSettings: fields(object('settings', 'Configurações gerais', [num('sellVehicle', 'Desconto na revenda (%)', { min: 0, max: 100 }), num('maxCars', 'Máximo padrão de carros', { min: 0, integer: true }),
        text('commandConce', 'Comando administrativo'), text('imagesDir', 'Diretório das imagens'), num('purchaseCooldown', 'Cooldown de compra (s)', { min: 0 }), num('sellCooldown', 'Cooldown de venda (s)', { min: 0 }),
        strings('notTop4Vehicles', 'Veículos fora do ranking', { catalog: 'vehicles' })]),
        object('testDrive', 'Test drive', [num('cooldownTestDriver', 'Tempo do test drive (s)', { min: 1 }), num('maxDistanceTestDriver', 'Distância máxima', { min: 1 }),
            sequence('locations', 'Locais do test drive', own('Local', [coords('coords', 'Entrada', { array: true }), coords('test_drive', 'Saída do veículo', { array: true, heading: 'w' })]), { coords: [null, null, null], test_drive: [null, null, null, 0] })]),
        sequence('vips', 'Descontos e vagas VIP', own('Benefício VIP', [text('permission', 'Permissão VIP', { required: true, suggest: 'permissions' }), num('discount', 'Desconto (%)', { min: 0, max: 100 }), num('maxCars', 'Vagas extras', { min: 0, integer: true })]), { permission: '', discount: 0, maxCars: 0 }),
        sequence('categories', 'Categorias da concessionária', own('Categoria', [text('id', 'Identificador', { required: true }), text('label', 'Nome exibido', { required: true })]), { id: '', label: '' })),
    residencesSettings: fields({ type: 'notice', label: 'Os destinos de logs das residências são administrados nos arquivos privados do servidor.' })
};

const vaultSettings = [text('policePermission', 'Permissão da polícia', { suggest: 'permissions' }), num('policeMinimum', 'Policiais mínimos', { min: 0, integer: true }),
    num('cooldownSeconds', 'Cooldown (s)', { min: 0 }), item('keycardItem', 'Item keycard'), num('keycardAmount', 'Quantidade de keycards', { min: 0, integer: true }), item('rewardItem', 'Item de recompensa'),
    num('rewardMin', 'Recompensa mínima', { min: 0 }), num('rewardMax', 'Recompensa máxima', { min: 0 }), num('hackBlocks', 'Blocos do hacking', { min: 1, integer: true }), num('hackSeconds', 'Tempo do hacking (s)', { min: 1 }), num('cancelDistance', 'Distância para cancelar', { min: 1 })];
FORM_SCHEMAS.vaults = fields(text('name', 'Nome do roubo'), object('settings', 'Regras dos cofres', vaultSettings),
    dictionary('banks', 'Bancos e cofres', own('Banco', [num('money', 'Dinheiro disponível', { min: 0 }),
        object('bankVault', 'Porta do cofre', [num('model', 'Modelo da porta'), coords(null, 'Posição da porta'), num('hStart', 'Direção inicial'), num('hEnd', 'Direção aberta')]),
        coords('startRobbing', 'Início do roubo', { heading: 'h' }), coords('cashPile', 'Pilha de dinheiro', { heading: 'h' })]),
        { money: 0, bankVault: { model: 0, ...xyz(), hStart: 0, hEnd: 0 }, startRobbing: { ...xyz(), h: 0 }, cashPile: { ...xyz(), h: 0 } }, { keyLabel: 'Nome do banco' }));
FORM_SCHEMAS.jewelry = fields(text('name', 'Nome do roubo'), object('settings', 'Regras da joalheria', [
    num('policeMinimum', 'Policiais mínimos', { min: 0, integer: true }), text('policePermission', 'Permissão da polícia'), num('robberyCooldown', 'Cooldown do roubo (s)', { min: 0 }),
    item('keycardItem', 'Item keycard'), num('keycardAmount', 'Quantidade de keycards', { min: 0, integer: true }), num('displayCooldown', 'Cooldown da vitrine (s)', { min: 0 }),
    num('hackSeconds', 'Tempo do hacking (s)', { min: 1 }), num('policeBlipSeconds', 'Duração do blip policial (s)', { min: 1 }), coords('hackCoords', 'Local do hacking', { array: true }),
    coords('centerCoords', 'Centro da área', { array: true }), num('centerRadius', 'Raio da área', { min: 0 }),
    sequence('bombLocations', 'Posições de C4', point('Posição de C4', true), [null, null, null], { capture: true, array: true }), strings('requiredWeapons', 'Armas permitidas'), num('doorId', 'ID da porta', { integer: true })]),
    sequence('rewards', 'Recompensas', own('Recompensa', [item('item', 'Item', { required: true }), text('name', 'Nome exibido'), num('min', 'Mínimo', { min: 0 }), num('max', 'Máximo', { min: 0 })], { range: ['min', 'max'] }), { item: '', name: '', min: 0, max: 0 }),
    sequence('displays', 'Vitrines', own('Vitrine', [num('id', 'ID da vitrine', { min: 1, integer: true }), coords(null, 'Posição da vitrine'), text('prop1', 'Modelo intacto'), text('prop2', 'Modelo quebrado'),
        num('xplayer', 'Posição do jogador: X'), num('yplayer', 'Posição do jogador: Y'), num('zplayer', 'Posição do jogador: Z'), num('heading', 'Direção do jogador')]), { id: 1, ...xyz(), prop1: '', prop2: '', xplayer: 0, yplayer: 0, zplayer: 0, heading: 0 }));
FORM_SCHEMAS.centralBank = fields(text('name', 'Nome do roubo'), object('settings', 'Regras do banco', [
    num('cops', 'Policiais mínimos', { min: 0, integer: true }), text('permCops', 'Permissão da polícia'), num('tempoReset', 'Tempo para reiniciar o roubo (s)', { min: 1 }),
    item('solda', 'Explosivo / solda'), num('itemQtd', 'Quantidade do explosivo', { min: 0, integer: true }), item('furadeira', 'Furadeira'), item('dinheiroSujo', 'Item de dinheiro'),
    num('minPegar', 'Mínimo por coleta', { min: 0 }), num('maxPegar', 'Máximo por coleta', { min: 0 }), num('safeMinimum', 'Mínimo do cofre', { min: 0 }), num('safeMax', 'Máximo do cofre', { min: 0 }),
    sequence('allowedBags', 'Modelos de bolsas permitidas', num(null, 'Modelo', { integer: true }), 0), sequence('drillSpawns', 'Spawns de furadeira', point('Posição', true, 'w'), [null, null, null, 0], { capture: true, array: true, heading: 'w' })]),
    sequence('banks', 'Bancos', own('Banco', [text('bankName', 'Nome do banco'),
        sequence('doors', 'Portas', own('Porta', [coords('coords', 'Posição da porta', { array: true }), text('object', 'Modelo da porta'), num('heading', 'Direção'), object('weldPosition', 'Posição de solda', [coords('coords', 'Local de solda', { array: true }), num('heading', 'Direção da solda')], { optionalGroup: true, template: { coords: [null, null, null], heading: 0 } }), num('time', 'Tempo de solda'), bool('frozen', 'Porta congelada')]), { coords: [null, null, null], object: '', heading: 0, weldPosition: { coords: [null, null, null], heading: 0 }, time: 0, frozen: true }),
        sequence('safes', 'Cofres', own('Cofre', [coords('coords', 'Local do cofre', { array: true }), num('heading', 'Direção'), bool('looted', 'Já coletado'), advanced('cam', 'Câmera do cofre')]), { coords: [null, null, null], heading: 0, looted: false, cam: {} }),
        object('money', 'Dinheiro do banco', [num('startMoney', 'Dinheiro inicial', { min: 0 }), num('amount', 'Valor atual', { min: 0 }), coords('boxPosition', 'Local da caixa', { array: true }), text('box', 'Modelo da caixa'), advanced('cam', 'Câmera da caixa')]),
        object('hacking', 'Hacking', [coords('coords', 'Local do hacking', { array: true }), num('heading', 'Direção')])]), { bankName: '', doors: [], safes: [], money: { startMoney: 0, amount: 0, boxPosition: [null, null, null] }, hacking: { coords: [null, null, null], heading: 0 } }));

export const CATALOG_METHODS = {
    fac: ['getItemList'], garages: ['getGarageTypes'], garageTypes: ['getServerVehicleCatalog'], shops: ['getItemList'],
    desmanche: ['getItemList'], jobs: ['getItemList', 'getServerVehicleCatalog'], robberySetups: ['getItemList'], jewelry: ['getItemList'], vaults: ['getItemList'], centralBank: ['getItemList'],
    dealership: ['getServerVehicleCatalog'], dealershipSettings: ['getServerVehicleCatalog']
};
export function schemaFor(viewId, action = false) {
    if (action) {
        if (viewId === 'fac') return [text('orgName', 'Organização', { required: true })];
        if (viewId === 'jobs') return [text('name', 'Emprego', { required: true })];
        if (viewId === 'catalog') return [strings('vehicles', 'Veículos para excluir', { catalog: 'vehicles', minRows: 1 })];
    }
    return FORM_SCHEMAS[viewId] || null;
}

export const FIELD_LABELS = {
    settings: 'Configurações', name: 'Nome', model: 'Modelo', index: 'Identificador', id: 'ID', type: 'Tipo', min: 'Mínimo', max: 'Máximo', qtd: 'Quantidade', amount: 'Quantidade', price: 'Preço', value: 'Valor',
    coords: 'Coordenadas', position: 'Posição', rotation: 'Rotação', heading: 'Direção', w: 'Direção', h: 'Direção', x: 'X', y: 'Y', z: 'Z', item: 'Item', image: 'Imagem',
    tempo_entrega: 'Tempo de entrega', cargas: 'Cargas', valor_min: 'Valor mínimo', valor_max: 'Valor máximo', rotas: 'Rotas', local_carga: 'Local de carga',
    duracao_pesca: 'Duração da pesca', locais_pesca: 'Locais de pesca', local_venda: 'Local de venda', item_necessario: 'Item necessário', peixes: 'Peixes', valores_venda: 'Valores de venda por nível',
    veiculos: 'Veículos', veiculo: 'Veículo', locais_retirada: 'Locais de retirada', locais_entrega: 'Locais de entrega', objetos: 'Objetos', terreno: 'Terreno',
    locais_mineracao: 'Locais de mineração', tempo_britadeira: 'Tempo da britadeira', tempo_picareta: 'Tempo da picareta', minerios: 'Minérios',
    taximetro: 'Taxímetro', ativo: 'Ativado', custo_bandeira: 'Custo da bandeira', custo_km: 'Custo por km', custo_base: 'Custo base', peds: 'Modelos de pedestres',
    modelos_lixo: 'Modelos de lixo', veiculo_escada_hash: 'Hash do veículo com escada', prop_escada: 'Modelo da escada', modelos_postes: 'Modelos de postes', tempo_reparo: 'Tempo de reparo',
    searchTimerSeconds: 'Tempo de busca (s)', policeBlipMilliseconds: 'Duração do blip policial (ms)', cashInteractDistance: 'Distância para coletar dinheiro', cashAnimationMilliseconds: 'Animação de coleta (ms)',
    robberyDuration: 'Duração do roubo (s)', boxes: 'Modelos das caixas', Full: 'Cheia', Half: 'Parcial', Empty: 'Vazia', cam: 'Câmera', xp: 'Posição de destino: X', yp: 'Posição de destino: Y', zp: 'Posição de destino: Z'
};
export function fieldLabel(key) { return FIELD_LABELS[key] || String(key).replace(/([a-z])([A-Z])/g, '$1 $2').replace(/_/g, ' ').replace(/^./, s => s.toUpperCase()); }

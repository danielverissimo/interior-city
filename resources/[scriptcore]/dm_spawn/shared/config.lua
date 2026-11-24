Config = {}

Config.Spawns = {
    {
        name = "Praça",
        image = "https://files.catbox.moe/4zmndw.png",
        coords = {218.87,-808.39,30.7},
    },
}

Config.Orgs_Spawns = {
    ['perm.vermelhos'] = {996.76,-97.46,74.32},
    ['perm.cv'] = {1318.88,-715.3,65.23},
    ['perm.central'] = {-1505.76,76.78,55.62},
    ['perm.bronks'] = {1292.87,-184.2,107.54},
    ['perm.cassino'] = {917.28,61.07,80.9},
}
-- ============================================================================
-- INTEGRAÇÃO: SUA CASA / SUA FACÇÃO
-- ============================================================================
-- Nomes reais dos resources da base. O dm_spawn apenas lê os JSONs persistidos
-- por eles, portanto não depende de ordem rígida de start.
Config.MansionsResource = "m_mansions"
Config.MansionsDataFile = "mansions.json"
Config.AdminPanelResource = "m_paineladm_v2"
Config.AdminPanelLocationsFile = "locations.json"

-- Moradores convidados também podem usar "Sua Casa". O dono sempre tem
-- prioridade caso o jogador esteja vinculado a mais de uma mansão.
Config.AllowMansionResidentsSpawn = true

-- Categorias administrativas que nunca devem virar "Sua Facção" apenas por
-- coincidência de nome de cargo.
Config.FactionIgnoredCategories = {
    "Geral",
    "STAFF",
    "Hospital"
}

-- Fallback de preferência para categorias que não possuem um local chamado
-- exatamente "Fac". Antes desta lista o sistema já prioriza automaticamente:
-- Fac > Local... > Interfone > Garagem Pública > primeiro local válido.
Config.FactionSpawnLocationNames = {
    "Entrada",
    "Spawn",
    "Sede"
}

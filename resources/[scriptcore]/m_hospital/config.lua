HospitalConfig = {}

-- ============================================================================
-- PAINÉIS DE GESTÃO
-- Hospital, Sport Racer e LSCustoms, isolados por organização.
-- ============================================================================
HospitalConfig.Panels = {
    Hospital = {
        command = "hp",
        aliases = {},
        organization = "Hospital",
        offDutyGroup = "PaisanaHospital",

        displayName = "Hospital",
        brand = "HOSPITAL",
        brandSubtitle = "Gestão de equipe",
        theme = "hospital",
        icon = "medical",
        metric = "calls",
        productivityRole = "medic",

        hierarchy = {
            { group = "Diretor",      label = "Diretor" },
            { group = "ViceDiretor",  label = "Vice-Diretor" },
            { group = "Gestao",       label = "Gestão" },
            { group = "Psiquiatra",   label = "Psiquiatra" },
            { group = "Medico",       label = "Médico" },
            { group = "Enfermeiro",   label = "Enfermeiro" },
            { group = "Socorrista",   label = "Socorrista" },
        },

        -- Quem pode promover/exonerar.
        managementGroups = {
            Diretor = true,
            ViceDiretor = true,
        },

        -- Quem pode contratar.
        hiringGroups = {
            Diretor = true,
            ViceDiretor = true,
        },

        initialRole = "Socorrista",

        texts = {
            actorStatus = "Equipe médica",
            teamTitle = "Equipe do Hospital",
            teamSubtitle = "Profissionais online organizados por hierarquia.",
            teamHeading = "Equipe online",
            teamDescription = "ID, identificação, cargo e situação no bate-ponto.",
            rankingTitle = "Ranking do Hospital",
            rankingSubtitle = "Tempo de serviço e chamados atendidos por profissional.",
            rankingHeading = "Ranking médico",
            rankingDescription = "Horas em serviço e chamados atendidos por profissional.",
            personColumn = "Profissional",
            teamEmpty = "Nenhum membro do Hospital está online agora.",
            rankingEmpty = "Ainda não existem dados de serviço no Hospital.",
            thirdStatLabel = "Chamados atendidos",
            thirdStatSmall = "total atendido",
            hireDescription = "O novo funcionário será cadastrado como Socorrista e deverá bater o ponto para entrar em serviço.",
        }
    },

    SportRacer = {
        command = nil,
        aliases = {}, -- /mec é compartilhado e resolve a oficina no servidor.
        organization = "SportRacer",
        offDutyGroup = "PaisanaSportRacer",

        displayName = "Sport Racer",
        brand = "SPORT RACER",
        brandSubtitle = "Gestão da oficina",
        theme = "mechanic",
        icon = "mechanic",
        metric = "hours",
        productivityRole = "mecanic",

        -- Ordem real dos cargos existentes na vRP (1 = maior cargo).
        hierarchy = {
            { group = "LiderSPORTRACER",      label = "Líder" },
            { group = "SubLiderSPORTRACER",   label = "Sub-Líder" },
            { group = "GerenteSPORTRACER",    label = "Gerente" },
            { group = "RecrutadorSPORTRACER", label = "Recrutador" },
            { group = "MembroSPORTRACER",     label = "Membro" },
            { group = "NovatoSPORTRACER",     label = "Novato" },
        },

        -- Liderança/gerência pode promover e exonerar.
        managementGroups = {
            LiderSPORTRACER = true,
            SubLiderSPORTRACER = true,
            GerenteSPORTRACER = true,
        },

        -- O cargo Recrutador possui perm.recrutador na vRP e também pode contratar.
        hiringGroups = {
            LiderSPORTRACER = true,
            SubLiderSPORTRACER = true,
            GerenteSPORTRACER = true,
            RecrutadorSPORTRACER = true,
        },

        initialRole = "NovatoSPORTRACER",

        texts = {
            actorStatus = "Equipe da oficina",
            teamTitle = "Equipe da Sport Racer",
            teamSubtitle = "Mecânicos online organizados por hierarquia.",
            teamHeading = "Equipe online",
            teamDescription = "ID, identificação, cargo e situação no bate-ponto.",
            rankingTitle = "Ranking da Sport Racer",
            rankingSubtitle = "Tempo de serviço registrado pelo bate-ponto.",
            rankingHeading = "Ranking da oficina",
            rankingDescription = "Horas em serviço acumuladas por mecânico.",
            personColumn = "Mecânico",
            teamEmpty = "Nenhum membro da Sport Racer está online agora.",
            rankingEmpty = "Ainda não existem horas registradas na Sport Racer.",
            thirdStatLabel = "Horas acumuladas",
            thirdStatSmall = "horas em serviço",
            hireDescription = "O novo funcionário será cadastrado como Novato e deverá bater o ponto para entrar em serviço.",
        }
    },

    LSCustoms = {
        command = nil, -- abertura somente pelo /mec com resolução server-side
        aliases = {},
        organization = "LSCustoms",
        offDutyGroup = "PaisanaLSCustoms",
        displayName = "LS Customs",
        brand = "LS CUSTOMS",
        brandSubtitle = "Gestão da oficina",
        theme = "lscustoms",
        icon = "mechanic",
        metric = "hours",
        productivityRole = "mecanic",

        -- Ordem validada no groups.json da vRP fornecida (7 cargos).
        hierarchy = {
            { group = "LiderLSCustoms",        label = "Líder" },
            { group = "SubLiderLSCustoms",     label = "Sub-Líder" },
            { group = "GerenteGeralLSCustoms", label = "Gerente Geral" },
            { group = "GerenteLSCustoms",      label = "Gerente" },
            { group = "SupervisorLSCustoms",   label = "Supervisor" },
            { group = "MecanicoLSCustoms",     label = "Mecânico" },
            { group = "EstagiarioLSCustoms",   label = "Estagiário" },
        },
        managementGroups = {
            LiderLSCustoms = true,
            SubLiderLSCustoms = true,
            GerenteGeralLSCustoms = true,
            GerenteLSCustoms = true,
        },
        -- O Estagiário tem perm.recrutador na vRP, preservando essa atribuição.
        hiringGroups = {
            LiderLSCustoms = true,
            SubLiderLSCustoms = true,
            GerenteGeralLSCustoms = true,
            GerenteLSCustoms = true,
            EstagiarioLSCustoms = true,
        },
        initialRole = "EstagiarioLSCustoms",
        texts = {
            actorStatus = "Equipe da LS Customs",
            teamTitle = "Equipe da LS Customs",
            teamSubtitle = "Mecânicos online organizados por hierarquia.",
            teamHeading = "Equipe online",
            teamDescription = "ID, identificação, cargo e situação no bate-ponto.",
            rankingTitle = "Ranking da LS Customs",
            rankingSubtitle = "Tempo de serviço registrado pelo bate-ponto.",
            rankingHeading = "Ranking da oficina",
            rankingDescription = "Horas em serviço acumuladas por mecânico.",
            personColumn = "Mecânico",
            teamEmpty = "Nenhum membro da LS Customs está online agora.",
            rankingEmpty = "Ainda não existem horas registradas na LS Customs.",
            thirdStatLabel = "Horas acumuladas",
            thirdStatSmall = "horas em serviço",
            hireDescription = "O novo funcionário será cadastrado como Estagiário e deverá bater o ponto para entrar em serviço.",
        }
    },
}

HospitalConfig.RefreshSeconds = 15

-- Compatibilidade com trechos antigos que ainda esperem as chaves do Hospital.
HospitalConfig.Command = HospitalConfig.Panels.Hospital.command
HospitalConfig.Organization = HospitalConfig.Panels.Hospital.organization
HospitalConfig.OffDutyGroup = HospitalConfig.Panels.Hospital.offDutyGroup
HospitalConfig.Hierarchy = HospitalConfig.Panels.Hospital.hierarchy
HospitalConfig.ManagementGroups = HospitalConfig.Panels.Hospital.managementGroups



-- ============================================================================
-- DIAGNÓSTICO MÉDICO
-- A opção aparece no painel médico do m_aux, mas toda a lógica/visual fica aqui
-- para manter o m_aux leve.
-- ============================================================================
HospitalConfig.Diagnosis = {
    enabled = true,
    permission = "perm.unizk",

    patientRadius = 3.5,
    thinkSeconds = 5,

    -- Pacientes abaixo desta porcentagem exigem diagnóstico antes de qualquer
    -- Tratamento Normal/Completo pelo painel médico.
    requiredBelowPercent = 40,

    -- Após concluir o diagnóstico, o mesmo médico possui alguns minutos para
    -- tratar aquele paciente sem precisar repetir a análise.
    validSeconds = 600,

    thinkingScenario = "WORLD_HUMAN_STAND_IMPATIENT",

    tablet = {
        model = "prop_cs_tablet",
        bone = 28422,
        position = { x = 0.00, y = -0.03, z = 0.00 },
        rotation = { x = 20.0, y = -90.0, z = 0.0 },
        animation = {
            dict = "amb@world_human_clipboard@male@base",
            anim = "base",
            flag = 49
        }
    },

    injuries = {
        {
            part = "head",
            label = "Cabeça",
            diagnoses = {
                "Trauma craniano leve",
                "Contusão na região craniana",
                "Cefaleia pós-impacto"
            }
        },
        {
            part = "chest",
            label = "Tórax",
            diagnoses = {
                "Contusão torácica",
                "Trauma costal",
                "Lesão muscular no tórax"
            }
        },
        {
            part = "abdomen",
            label = "Abdômen",
            diagnoses = {
                "Trauma abdominal",
                "Distensão abdominal",
                "Contusão na região abdominal"
            }
        },
        {
            part = "leftArm",
            label = "Braço esquerdo",
            diagnoses = {
                "Contusão no braço esquerdo",
                "Suspeita de entorse no braço esquerdo",
                "Trauma muscular no braço esquerdo"
            }
        },
        {
            part = "rightArm",
            label = "Braço direito",
            diagnoses = {
                "Contusão no braço direito",
                "Suspeita de entorse no braço direito",
                "Trauma muscular no braço direito"
            }
        },
        {
            part = "leftLeg",
            label = "Perna esquerda",
            diagnoses = {
                "Contusão na perna esquerda",
                "Suspeita de entorse na perna esquerda",
                "Trauma muscular na perna esquerda"
            }
        },
        {
            part = "rightLeg",
            label = "Perna direita",
            diagnoses = {
                "Contusão na perna direita",
                "Suspeita de entorse na perna direita",
                "Trauma muscular na perna direita"
            }
        }
    }
}

-- ============================================================================
-- SISTEMA AUTOMÁTICO DE MACAS
-- Continua exclusivo do Hospital e permanece no mesmo resource.
-- ============================================================================
HospitalConfig.Beds = {
    Model = 1631638868,
    ScanRadius = 90.0,
    ScanInterval = 1500,
    DrawDistance = 1.6,
    InteractionDistance = 1.35,
    PatientDistance = 3.5,

    HeadingOffset = 0.0,
    LieZOffset = 0.03,
    MarkerExtraDistance = 0.12,
    MarkerZOffset = 0.08,
    TextZOffset = 0.55,
    MarkerSide = -1,
}

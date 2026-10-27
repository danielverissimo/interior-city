Config = Config or {}

Config.DrawDistance = 2.0
Config.InteractionControl = 38 -- E
Config.CancelControl = 168 -- F7

Config.Drugs = {
    cocaina = {
        permissions = {
            "perm.ptr.staff"
        },
        reward = {
            item = "cocaina",
            amount = 2
        },
        locations = {
            producePasteBase = {
                x=-1105.25, y=4943.78, z=218.65, heading=251.07
            },

            collectAcid = { x=-1104.36, y=4946.44, z=218.65, action = { x=-1104.36, y=4946.44, z=218.65, heading = 250.58 } },
            placeAcid = { x=-1111.7, y=4942.46, z=218.65, action = { x=-1111.7, y=4942.46, z=218.65, heading = 71.61 } },
            mixAcidPasteBase = {
                x=-1111.77, y=4943.57, z=218.65, heading=69.54
            },

            takePan = { x=-1108.47, y=4946.52, z=218.65, action = { x=-1108.47, y=4946.52, z=218.65, heading = 252.73 } },
            placePan = { x=-1107.78, y=4939.6, z=218.65, heading = 247.28 },
            weigh = { x=-1107.78, y=4939.6, z=218.65, heading = 247.28 }
        },

        pasteBase = {
            inputItem = "folhadecoca",
            inputAmount = 10,
            outputItem = "pastabase",
            outputAmount = 5,
            duration = 60000
        },

        acidSeparation = {
            requirements = {
                { item = "pastabase", amount = 5 },
                { item = "acido", amount = 1 }
            },
            consumeItem = "acido",
            consumeAmount = 1
        },

        cocainePowderStage = {
            inputItem = "pastabase",
            inputAmount = 5,
            outputItem = "podecocaina",
            outputAmount = 10,
            duration = 30000,
            pourAnimationDuration = 8000
        },

        panRequirement = {
            item = "podecocaina",
            amount = 10
        },

        -- Props colocados na bancada.
        -- O Z serve apenas como ponto inicial do raycast; snapToSurface faz o
        -- objeto encostar automaticamente no tampo da mesa.
        props = {
            acidPlaced = {
                model = "bkr_prop_meth_hcacid",
                x=-1112.2, y=4942.94, z=219.45,
                snapToSurface = true,
                surfaceOffset = 0.002
            },
            panPlaced = {
                model = "bkr_prop_coke_metalbowl_01",
                x=-1106.5, y=4940.03, z=219.52,
                snapToSurface = true,
                surfaceOffset = 0.002
            },
            spatulaTemp = {
                model = "bkr_prop_coke_fullscoop_01a",
                x=-1107.08, y=4938.63, z=219.52,
                snapToSurface = true,
                surfaceOffset = 0.002
            },
            scalePlaced = {
                model = "bkr_prop_coke_scale_01",
                x=-1106.98, y=4939.25, z=219.52,
                heading = 160.67,
                snapToSurface = true,
                surfaceOffset = 0.002
            },
            powderPlaced = {
                model = "bkr_prop_coke_powder_02",
                x=-1106.98, y=4939.25, z=219.52,
                snapToSurface = true,
                surfaceOffset = 0.002
            }
        },

        -- Posição/rotação dos objetos enquanto o player carrega.
        -- Mantidos na vertical e centralizados à frente do corpo.
        carry = {
            acid = {
                model = "bkr_prop_meth_hcacid",
                bone = 28422,
                x = 0.00,
                y = -0.10,
                z = -0.18,
                rx = 00.0,
                ry = 0.5,
                rz = 0.1
            },

            pan = {
                model = "bkr_prop_coke_metalbowl_01",
                bone = 28422,
                x = 0.00,
                y = -0.08,
                z = -0.22,
                rx = 00.0,
                ry = 0.5,
                rz = 0.1
            },

            -- Espátula presa diretamente na mão direita.
            -- Ajuste fino pode ser feito aqui sem mexer no client.
            spatula = {
                model = "bkr_prop_coke_fullscoop_01a",
                bone = 57005,
                x = 0.05,
                y = 0.00,
                z = -0.02,
                rx = -80.0,
                ry = 0.0,
                rz = 10.0
            }
        },

        -- Configuração usada SOMENTE ao despejar o ácido na pasta base.
        -- Replica exatamente a posição acertada no Benzoato.
        pour = {
            acid = {
                model = "bkr_prop_meth_hcacid",
                bone = 57005,
                x = -0.15,
                y = 0.05,
                z = -0.20,
                rx = 0.35,
                ry = 90.0,
                rz = 20.0
            }
        }
    },

    maconha = {
        permissions = {
            "perm.ptr.staff"
        },
        reward = {
            item = "maconha",
            min = 3,
            max = 9
        },
        locations = {
            collectFertilizer = { x=114.37, y=6355.84, z=32.31, action = { x=114.37, y=6355.84, z=32.31, heading = 297.84 } }
        },

        -- 6 pontos independentes de plantio. O primeiro mantém a área original e
        -- os outros 5 foram distribuídos próximos a ela; todos podem ser ajustados
        -- aqui sem alterar o client. Cada ponto possui cronômetro próprio.
        planting = {
            interactionDistance = 1.15,

            fertilizerRequirement = { item = "adubo", amount = 5 },

            pickupAnimationTime = 2500,
            plantAnimationTime = 5000,
            waterAnimationTime = 5000,
            harvestAnimationTime = 10000,

            -- 30s depois de plantar, passa a pedir água.
            timeUntilWater = 30000,
            -- Depois de regado, leva mais 1 minuto para ficar pronto.
            timeAfterWater = 60000,

            potZOffset = -1.10,
            smallZOffset = -1.10,
            mediumZOffset = -1.10,
            largeZOffset = -1.10,

            -- Posição do pote aberto durante a animação, relativa ao ponto usado.
            fertilizerOpenOffset = { x = -1.28, y = -0.37, z = -1.10 },

            -- Cada ponto possui:
            -- action = posição onde o player aperta E / planta / rega / colhe.
            -- plants = posições EXATAS dos 3 pés pertencentes a este ponto.
            -- Ajuste livremente cada coordenada abaixo para encaixar no mapa.
            points = {
                {
                    action = { x=101.55, y=6354.13, z=31.38, heading=28.15 },
                    plants = {
                        { x=100.16, y=6354.61, z=31.41, heading=28.15 },
                        { x=100.97, y=6355.06, z=31.38, heading=28.15 }, ----
                        { x=101.99, y=6355.61, z=31.38, heading=28.15 }
                    }
                },
                {
                    action = { x=97.35, y=6352.48, z=31.38, heading=21.90 },
                    plants = {
                        { x=96.03, y=6353.25, z=31.43, heading=21.90 },
                        { x=96.79, y=6353.66, z=31.44, heading=21.90 }, -----
                        { x=97.86, y=6354.15, z=31.44, heading=21.90 }
                    }
                },
                {
                    action = { x=94.65, y=6351.76, z=31.38, heading=21.90 },
                    plants = {
                        { x=93.65, y=6352.46, z=31.43, heading=21.90 },
                        { x=94.54, y=6352.86, z=31.43, heading=21.90 }, -----
                        { x=95.34, y=6353.22, z=31.44, heading=21.90 }
                    }
                },
                {
                    action = { x=105.63, y=6346.77, z=31.38, heading=204.34 },
                    plants = {
                        { x=107.25, y=6346.53, z=31.38, heading=204.34 },
                        { x=106.22, y=6346.03, z=31.38, heading=204.34 }, --------
                        { x=105.06, y=6345.53, z=31.47, heading=204.34 }
                    }
                },
                {
                    action = { x=104.02, y=6349.75, z=31.38, heading=204.34 },
                    plants = {
                        { x=105.7, y=6349.28, z=31.38, heading=204.34 },
                        { x=104.73, y=6348.77, z=31.38, heading=204.34 }, --------
                        { x=103.46, y=6348.17, z=31.38, heading=204.34 }
                    }
                },
                {
                    action = { x=98.27, y=6348.07, z=31.38, heading=116.08 },
                    plants = {
                        { x=96.91, y=6348.49, z=31.43, heading=30.22 },
                        { x=97.23, y=6347.44, z=31.43, heading=30.22 }, -----------
                        { x=97.76, y=6346.34, z=31.44, heading=30.22 }
                    }
                }
            }
        },
        -- Abre espaço no MLO ORIGINAL sem editar o .ytyp.
        mapCleanup = {
            enabled = true,
            radius = 1.20,
            models = {
                -- Pés de maconha nativos
                "bkr_prop_weed_01_small_01a",
                "bkr_prop_weed_med_01a",
                "bkr_prop_weed_lrg_01a",
                "bkr_prop_weed_lrg_01b",

                -- Mangueiras/fios nativos dos canteiros
                "bkr_hose_a",
                "bkr_hose_b",
                "bkr_hose_c",
                "bkr_hose_d",
                "bkr_hose_e",
                "bkr_hose_f",
                "bkr_hose_g",
                "bkr_hose_h",
                "bkr_hose_i"
            }
        },

        props = {
            fertilizerOpen = { model = "bkr_prop_weed_bucket_open_01a", x=101.15, y=6351.86, z=31.38, zOffset = -1.10 },
            fertilizerCarry = {
                model = "bkr_prop_weed_bucket_01a",
                bone = 28422,
                x = 0.00,
                y = 0.10,
                z = -0.21,
                rx = 100.0,
                ry = 0.5,
                rz = 0.1
            }
        },

        -- Preparo/embalagem da maconha nas cadeiras próximas à mesa.
        -- O script procura automaticamente TODAS as cadeiras deste model
        -- dentro do raio configurado abaixo.
        preparation = {
            chairModel = -1281587804,
            searchCenter = { x = 115.20, y = 6361.65, z = 32.30 },
            searchRadius = 20.0,
            interactionDistance = 1.55,

            -- Posição do marker/texto relativa à rotação da cadeira.
            markerOffset = { x = 0.75, y = 0.0, z = 0.10 },

            -- Ajuste fino do ponto em que o ped senta, relativo à cadeira.
            -- Caso alguma cadeira específica fique alguns centímetros fora,
            -- estes 4 valores são os únicos que precisam ser ajustados.
            seatOffset = { x = 0.0, y = 0.0, z = 0.55 },

            -- Posição em que o ped será colocado ao terminar o preparo.
            -- O offset é relativo à própria cadeira, então funciona nas 5 cadeiras.
            exitOffset = { x = 0.85, y = 0.0, z = 0.0 },
            exitHeadingOffset = 90.0,
            seatHeadingOffset = 180.0,
            scenario = "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER",

            duration = 30000,

            -- Animação sentada de separação/embalagem. Sem tesoura.
            animation = {
                dict = "anim@amb@business@weed@weed_sorting_seated@",
                name = "sorter_right_sort_v3_sorter02",

                -- 49 = loop + somente parte superior do corpo + tarefa secundária.
                -- Mantém o ped sentado no scenario da cadeira enquanto apenas
                -- braços/mãos executam o preparo.
                flags = 49
            },

            -- Mesa usada visualmente durante o preparo. A mesa mais próxima da
            -- cadeira utilizada será encontrada automaticamente.
            tableModel = 304964818,
            tableSearchRadius = 4.5,

            -- Weed Brick Open. Estes objetos aparecem somente durante os 30s
            -- de preparo e são apagados ao finalizar.
            weedBrickModel = 3614851425,
            maxVisualBricks = 6,
            weedBrickHeightOffset = 0.025,
            weedBrickHeadingOffset = 0.0,

            -- Pacote de maconha segurado pelo ped durante o preparo.
            -- O bone/offset/rotação ficam aqui para facilitar o ajuste fino.
            handWeedProp = {
                model = 1413633517, -- xm3_prop_xm3_bag_weed_01a
                bone = 18905,       -- mão esquerda
                x = 0.10,
                y = 0.02,
                z = 0.00,
                rx = -80.0,
                ry = 0.0,
                rz = 10.0
            },

            -- Posições X/Y relativas à própria mesa. O Z é calculado
            -- automaticamente pelo topo do model da mesa.
            weedBrickOffsets = {
                { x = -0.42, y = -0.12 },
                { x =  0.42, y = -0.12 },
                { x = -0.42, y =  0.18 },
                { x =  0.42, y =  0.18 },
                { x =  0.00, y = -0.12 },
                { x =  0.00, y =  0.18 }
            },

            inputItem = "maconha",
            inputAmount = 10, -- lote mínimo: 10 maconhas
            outputItem = "malote-maconha",
            outputAmount = 2 -- cada lote de 10 gera 2 malotes
        }
    },

    metanfetamina = {
        permissions = {
            "perm.ptr.staff"
        },

        reward = {
            item = "metanfetamina",
            amount = 10
        },

        locations = {
            takeBenzoate = {
                x=1505.46, y=6391.92, z=20.79, heading=257.78
            },

            -- Benzoato e Toulene são despejados neste mesmo tanque.
            tank = {
                x=1493.28, y=6390.32, z=21.26, heading=167.29
            },

            takeToluene = {
                x=1485.70, y=6392.65, z=20.79, heading=78.19
            },

            finalMix = {
                x=1502.53, y=6393.77, z=20.79, heading=347.38
            }
        },

        ingredients = {
            benzoate = { item = "benzoato", amount = 2 },
            toluene = { item = "toulene", amount = 2 }
        },

        ephedrine = {
            duration = 60000,
            outputItem = "efedrina",
            outputAmount = 5
        },

        finalMix = {
            duration = 20000,
            requirements = {
                { item = "efedrina", amount = 5 },
                { item = "anfetamina", amount = 5 }
            },
            outputItem = "metanfetamina",
            outputAmount = 10
        },

        carry = {
            benzoate = {
                model = "bkr_prop_meth_sacid",
                bone = 28422,
                x = 0.00,
                y = -0.10,
                z = -0.18,
                rx = 00.0,
                ry = 0.5,
                rz = 0.1
            },

            toluene = {
                model = "bkr_prop_meth_toulene",
                bone = 28422,
                x = 0.00,
                y = -0.10,
                z = -0.18,
                rx = 00.0,
                ry = 0.5,
                rz = 0.1
            }
        },

        -- Configuração usada SOMENTE durante a animação de despejar.
        -- O bone 57005 é a mão direita, então o galão acompanha a mão do ped
        -- corretamente durante a animação do jerrycan.
        pour = {
            benzoate = {
                model = "bkr_prop_meth_sacid",
                bone = 57005,
                x = -0.15,
                y = 0.05,
                z = -0.20,
                rx = 0.35,
                ry = 90.0,
                rz = 20.0
            },

            toluene = {
                model = "bkr_prop_meth_toulene",
                bone = 57005,
                x = -0.15,
                y = 0.05,
                z = -0.20,
                rx = 0.35,
                ry = 90.0,
                rz = 20.0
            }
        },

        packingScene = {
            animDict = "anim@amb@business@meth@meth_smash_weight_check@",
            playerAnim = "break_weigh_v3_char01",

            -- Os props possuem clips próprios na mesma synchronized scene.
            objects = {
                {
                    model = "bkr_prop_meth_openbag_02",
                    anim = "break_weigh_v3_methbag01^2"
                },
                {
                    model = "bkr_prop_meth_openbag_02",
                    anim = "break_weigh_v3_methbag01^3"
                },
                {
                    model = "bkr_prop_meth_scoop_01a",
                    anim = "break_weigh_v3_scoop"
                }
            },

            -- Ajuste fino do ponto da scene, caso o clip fique alguns cm fora.
            offset = {
                x = 0.0,
                y = 0.0,
                z = 0.0
            },

            headingOffset = 0.0
        },

        props = {
            -- Dois props da mistura final, um ao lado do outro sobre a mesa.
            -- finalMixLeft = {
            --     model = 1404217665,
            --     x=1502.47, y=6394.36, z=21.59,
            --     heading=347.38,
            --     snapToSurface=true,
            --     surfaceOffset=0.002
            -- },

            finalMixRight = {
                model = 1404217665,
                x=1502.87, y=6394.36, z=21.59,
                heading=347.38,
                snapToSurface=true,
                surfaceOffset=0.002
            }
        }
    }
}

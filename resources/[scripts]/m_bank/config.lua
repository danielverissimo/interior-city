config = {}

config.token = ""

config.nomeBanco = "Banco"
config.imgBanco = "http://127.0.0.1/images/iconbank.png"


config.webhookSacar = ""
config.webhookDepositar = ""
config.webhookTransferir= ""

config.antiFlood = { status = true, ban = false, webhook = "" }
config.bancoBlips = { showBlip = true, bMapType = 207, bColor = 4, bText = "Banco", bScale = 0.5 }
config.atmBlips = { showBlip = false, bMapType = 207, bColor = 4, bText = "ATM", bScale = 0.2 }

config.bancos = {
	{x=149.87, y=-1040.82, z=29.38},
	{x=-1212.980, y=-330.841, z=37.787},
	{x=-2962.582, y=482.627, z=15.703},
	{x=-112.202, y=6469.295, z=31.626},
	{x=314.187, y=-278.621, z=54.170},
	{x=-351.534, y=-49.529, z=49.042},
	{x=241.54, y=225.37, z=106.29},
	{x=1175.064, y=2706.643, z=38.094},
}

config.atms = {
	{x=-254.33, y=-692.38, z=33.61, h=158.75, assaltavel=true, segundos=60}, -- Est.Vermelho
	{x=-2072.63, y=-317.22, z=13.32, h=266.46, assaltavel=true, segundos=60}, -- Pst Praia.
	{x=285.49, y=143.41, z=104.18, h=161.58, assaltavel=true, segundos=60}, -- Prox ao BC.
	{x=1138.24, y=-468.95, z=66.74, h=73.71, assaltavel=true, segundos=60}, -- Prox Barragem.
	{x=119.06, y=-883.69, z=31.13, h=70.87, assaltavel=true, segundos=60}, -- Praça
	{x=-712.94, y=-819.0, z=23.73, h=0.0, assaltavel=true, segundos=60}, -- Prox ao Vermelho
	{x=-821.63, y=-1081.92, z=11.14, h=31.19, assaltavel=true, segundos=60}, -- Prox ao HP
	{x=-282.98, y=6226.09, z=31.5, h=320.32, assaltavel=true, segundos=60}, -- Norte
	{x=-1315.75, y=-834.72, z=16.97, h=308.98, assaltavel=true, segundos=60}, -- Prox a Praia
	{x=288.81, y=-1282.31, z=29.64, h=269.3, assaltavel=true, segundos=60}, -- POSTO
	{x=147.56, y=-1035.74, z=29.35, h=164.41, assaltavel=false, segundos=60}, --Frente PRAÇA
	{x=145.97, y=-1035.08, z=29.35, h=158.75, assaltavel=false, segundos=60}, --Frente PRAÇA2
	{x=-526.56, y=-1222.98, z=18.46, h=153.08, assaltavel=false, segundos=60},
	{x=288.98, y=-1256.85, z=29.45, h=272.13, assaltavel=false, segundos=60},
	{x=33.27, y=-1348.24, z=29.5, h=175.75, assaltavel=false, segundos=60},
	{x=-56.91, y=-1752.17, z=29.43, h=51.03, assaltavel=false, segundos=60},
	{x=-717.58, y=-915.66, z=19.22, h=90.71, assaltavel=false, segundos=60},
	{x=380.76, y=323.41, z=103.57, h=161.58, assaltavel=false, segundos=60},
	{x=1153.65, y=-326.74, z=69.21, h=107.72, assaltavel=false, segundos=60},
	{x=89.65, y=2.5, z=68.31, h=334.49, assaltavel=false, segundos=60},
	{x=237.24, y=217.65, z=106.29, h=300.48, assaltavel=false, segundos=60},
	{x=2558.49, y=389.49, z=108.63, h=266.46, assaltavel=false, segundos=60},
	{x=-3240.61, y=1008.6, z=12.84, h=263.63, assaltavel=false, segundos=60},
	{x=1735.23, y=6410.53, z=35.04, h=150.24, assaltavel=false, segundos=60},
	{x=540.41, y=2671.0, z=42.16, h=2.84, assaltavel=false, segundos=60},
	{x=1968.13, y=3743.62, z=32.35, h=209.77, assaltavel=false, segundos=60},
	{x=2683.11, y=3286.59, z=55.25, h=238.12, assaltavel=false, segundos=60},
	{x=1703.06, y=4933.54, z=42.07, h=325.99, assaltavel=false, segundos=60},
	{x=-1827.12, y=785.01, z=138.31, h=127.56, assaltavel=false, segundos=60},
	{x=-3040.72, y=593.13, z=7.91, h=291.97, assaltavel=false, segundos=60},
	{x=1171.57, y=2702.58, z=38.18, h=0.0, assaltavel=false, segundos=60},
	{x=955.46, y=-1035.75, z=40.84, h=0.0, assaltavel=false, segundos=60},		-- caixa dentro da mecanica  955.46,-1035.75,40.84
	{x=1077.78, y=-776.54, z=58.25, h=181.42, assaltavel=true, segundos=60},    -- 
	{x=50.09, y=-1771.19, z=29.34, h=0.0, assaltavel=false, segundos=60},		--- caixa dentro da mec2 50.38,-1771.54,29.34
	{x=1152.44, y=-1535.07, z=35.39, h=0.0, assaltavel=false, segundos=60},		--- caixa dentro do HP Bahamas
	{x=778.66, y=1300.98, z=360.3, h=0.0, assaltavel=false, segundos=60},  	  -- pier   778.66,1300.98,360.3
	{x=-32.28, y=-1104.59, z=27.26, h=0.0, assaltavel=false, segundos=60}, --  -32.28,-1104.59,27.26  conce
}

return config
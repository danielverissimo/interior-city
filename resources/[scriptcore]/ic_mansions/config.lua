ICMConfig = {
    PreviousResource = 'm_mansions',
    StateFiles = {'state-a.json','state-b.json'}, CatalogFile = 'catalog.json',
    Resources = {Vrp='vrp',Inventory='inventory',Garage='m_garage',Doors='doorsv2'},
    AdminGroups = {dono=true,developer=true},
    CleanupGroups = {dono=true,developer=true,admin=true},
    AllowedVouchers = {
        valemansao500k='Vale Mansão 500K',valemansao1m='Vale Mansão 1M',
        valemansao8m='Vale Mansão 8M',valemansao10m='Vale Mansão 10M',
        valemansao100m='Vale Mansão 100M'
    },
    PurchaseDistance=2.0,ManagementNearestDistance=35.0,CleanupDistance=10.0,
    IptuCycleDays=20,BlipSprite=439,BlipColor=46,BlipScale=0.65,
    FurnitureAccessRadius=80.0,FurniturePlacementRadius=100.0,
    FurnitureEditDistance=2.2,FurnitureDrawDistance=160.0,
    FurnitureDefaultPrice=500,FurnitureSellPercent=15
}

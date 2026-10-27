-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
Tunnel = module("vrp","lib/Tunnel")
Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPC = Tunnel.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- PREPARE
------------------------------------------------------------------------------------------------------------------------------------------
vRP._prepare("vRP/selectAll","SELECT * FROM core_residences")
vRP._prepare("vRP/insertHouses","INSERT INTO core_residences(name,x,y,z,interiorType,intPrice,slot,trade) VALUES(@name,@x,@y,@z,@interiorType,@intPrice,@slot,@trade)")
vRP._prepare("vRP/selectcHouse","SELECT * FROM core_residences WHERE name = @name")
vRP._prepare("vRP/deleteHouse","DELETE FROM core_residences WHERE name = @name")
vRP._prepare("vRP/selectAppartment","SELECT * FROM core_homes WHERE name = @name AND number = @number")
vRP._prepare("vRP/selectOwner","SELECT * FROM core_homes WHERE name = @name AND number = @number AND owner = 1")
vRP._prepare("vRP/selectAP2","SELECT * FROM core_homes WHERE name = @name AND number = @number AND user_id = @user_id")
vRP._prepare("vRP/deleteAP","DELETE FROM core_homes WHERE name = @name AND number = @number")
vRP._prepare("vRP/buyAppartment","INSERT INTO `core_homes`(`name`,`interior`,`tax`,`price`,`user_id`,`residents`,`vault`,`owner`,`number`) VALUES(@name,@interior,@tax,@price,@user_id,@residents,@vault,1,@number)")
vRP._prepare("vRP/secondOwnerAP","INSERT INTO core_homes(name,interior,user_id,owner,number) VALUES(@name,@interior,@user_id,@owner,@number)")
vRP._prepare("vRP/updateInterior","UPDATE core_homes SET interior = @interior WHERE name = @name AND user_id = @user_id")
vRP._prepare("vRP/updateInterior2","UPDATE core_homes SET interior = @interior WHERE name = @name AND number = @number AND user_id = @user_id")

vRP._prepare("homes/selling","DELETE FROM core_homes WHERE name = @name")
vRP._prepare("homes/permissions","SELECT * FROM core_homes WHERE name = @name")
vRP._prepare("homes/updateTax","UPDATE core_homes SET tax = @tax WHERE name = @name")
vRP._prepare("homes/userOwnermissions","SELECT * FROM core_homes WHERE name = @name AND owner = 1")
vRP._prepare("homes/userList","SELECT * FROM core_homes WHERE user_id = @user_id")

vRP._prepare("homes/countUsers","SELECT COUNT(*) as qtd FROM core_homes WHERE user_id = @user_id")   --qtd de casas
vRP._prepare("homes/countHouses","SELECT houses FROM vrp_users WHERE id = @user_id")                    --qtd max de casas

vRP._prepare("homes/countPermissions","SELECT COUNT(*) as qtd FROM core_homes WHERE name = @name")
vRP._prepare("homes/removePermissions","DELETE FROM core_homes WHERE name = @name AND user_id = @user_id")
vRP._prepare("homes/userPermissions","SELECT * FROM core_homes WHERE name = @name AND user_id = @user_id")
vRP._prepare("homes/getVault","SELECT vault FROM core_homes WHERE name = @name")
vRP._prepare("homes/updateVault","UPDATE core_homes SET vault = vault + @vault WHERE name = @name AND owner = 1")
vRP._prepare("homes/updateOwner","UPDATE core_homes SET user_id = @nuser_id WHERE user_id = @user_id AND name = @name")
vRP._prepare("homes/newPermissions","INSERT INTO core_homes(name,interior,user_id,owner) VALUES(@name,@interior,@user_id,@owner)")
vRP._prepare("homes/buying","INSERT INTO core_homes(name,interior,tax,price,user_id,residents,vault,owner) VALUES(@name,@interior,@tax,@price,@user_id,@residents,@vault,1)")
vRP._prepare("homes/get_allvehs","SELECT * FROM vrp_vehicles")
vRP._prepare("homes/get_casas","SELECT * FROM core_homes")
vRP._prepare("homes/fullGarages","SELECT * FROM homes_garages")
vRP._prepare("homes/getGarages","SELECT * FROM homes_garages WHERE name = @name")
vRP._prepare("homes/setGarage","INSERT INTO homes_garages SET name = @name, xblip = @xblip, yblip = @yblip, zblip = @zblip, xspawn = @xspawn, yspawn = @yspawn, zspawn = @zspawn, hspawn = @hspawn")
vRP._prepare("homes/removeGarages","DELETE FROM homes_garages WHERE name = @name")
vRP._prepare("vRP/updateTicket","UPDATE `vrp_users` SET ticketCasa = ticketCasa - 1 WHERE id = @user_id")


vRP._prepare("residences/renameHomes","UPDATE core_homes SET name = @newName WHERE name = @oldName")
vRP._prepare("residences/renameGarage","UPDATE homes_garages SET name = @newName WHERE name = @oldName")

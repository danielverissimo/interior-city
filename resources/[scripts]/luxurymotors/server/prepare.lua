Prepare = {
    ['deluxe_dealership/createTable'] = "CREATE TABLE IF NOT EXISTS `bm_dealership_deluxe` ( `vehicle` varchar(50) NOT NULL, `stock` int(11) DEFAULT 0, PRIMARY KEY (`vehicle`) ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;",
    ['deluxe_dealership/getVehicles'] = "SELECT * FROM bm_dealership_deluxe",
    ['deluxe_dealership/updateStock'] = "UPDATE bm_dealership_deluxe SET stock = @stock WHERE vehicle = @vehicle",
    ['deluxe_dealership/removeVehicle'] = "DELETE FROM bm_dealership_deluxe WHERE vehicle = @vehicle",
    ['deluxe_dealership/addVehicle'] = "REPLACE INTO bm_dealership_deluxe(vehicle,stock) VALUES(@vehicle,@stock)",
    ['deluxe_dealership/createNewVehicleStock'] = "UPDATE bm_dealership_deluxe SET stock = @stock WHERE vehicle = @vehicle",
    ['deluxe_dealership/getVehicle'] = "SELECT veiculo FROM vrp_user_veiculos WHERE user_id = @user_id AND veiculo = @vehicle",
    ['deluxe_dealership/totalVehicles'] = "SELECT COUNT(veiculo) as qtd FROM vrp_user_veiculos WHERE user_id = @user_id",
    ['deluxe_dealership/addUserVehicle'] = "INSERT INTO vrp_user_veiculos(user_id,veiculo,ipva) VALUES(@user_id,@vehicle,@ipva)",
    ['deluxe_dealership/addUserVehicleTuning'] = "INSERT INTO vrp_user_veiculos(user_id,veiculo,ipva,tunagem) VALUES(@user_id,@vehicle,@ipva,@tunagem)",
    ['deluxe_dealership/removeUserVehicle'] = "DELETE FROM vrp_user_veiculos WHERE veiculo = @vehicle AND user_id = @user_id"
}
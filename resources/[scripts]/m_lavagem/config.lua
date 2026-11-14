Config = {}
Config.AdminPermissions = {'developer.permissao'} -- Adicione outras permissoes administrativas existentes na sua base.
Config.AdminGroups = {'dono'}
Config.DirtyItem = 'dirty_money'
Config.BleachItem = 'l-alvejante'
Config.MaxPerOperation = 10000000
Config.InteractionDistance = 3.0
Config.MaxServerDistance = 7.0
Config.Factions = {
  vanilla = {label='Vanilla', chest='Vanilla', permission='perm.vanilla', memberPermission='perm.vanilla', washGroups={'LiderVanilla','SubLiderVanilla','GerenteVanilla','MembroVanilla','NovatoVanilla','RecrutadorVanilla'},vaultGroups={'LiderVanilla','SubLiderVanilla'},washPermissions={},vaultPermissions={}, fee=30, perBleach=1000, enabled=true, blip=false, marker=true, name='Lavagem Vanilla', coords=nil},
  bahamas = {label='Bahamas', chest='Bahamas', permission='perm.bahamas', memberPermission='perm.bahamas', washGroups={'LiderBahamas','SubLiderBahamas','GerenteBahamas','MembroBahamas','NovatoBahamas','RecrutadorBahamas'},vaultGroups={'LiderBahamas','SubLiderBahamas'},washPermissions={},vaultPermissions={}, fee=30, perBleach=1000, enabled=true, blip=false, marker=true, name='Lavagem Bahamas', coords=nil}
}

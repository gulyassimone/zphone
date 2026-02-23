lib.callback.register('z-phone:server:GetEmails', function(source)
  local Player = xCore.GetPlayerBySource(source)
  if Player == nil then return false end

  local citizenid = Player.citizenid
  local result = MySQL.query.await(Q.GetEmails, { citizenid })

  if not result then
    return {}
  end

  return result
end)

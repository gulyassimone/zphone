lib.callback.register('z-phone:server:GetProfile', function(source)
  local Player = xCore.GetPlayerBySource(source)
  if Player == nil then return nil end

  local citizenid = Player.citizenid
  local result = MySQL.single.await(Q.GetProfile, {
    citizenid
  })

  if not result then
    local phone_number = math.random(81, 89) .. math.random(100000, 999999)
    local iban = math.random(7, 9) .. math.random(1000000000, 9999999999)
    local id = MySQL.insert.await(Q.InsertUser, {
      citizenid,
      Player.name,
      phone_number,
      iban,
      5000000
    })

    result = MySQL.single.await(Q.GetProfile, {
      citizenid
    })
  end

  result.name = Player.name
  result.job = {}
  result.job.name = Player.job.name
  result.job.label = Player.job.label
  result.signal = Config.Signal.Zones[Config.Signal.DefaultSignalZones].ChanceSignal
  result.serverId = source
  return result
end)

lib.callback.register('z-phone:server:UpdateProfile', function(source, body)
  local affectedRows = nil
  local Player = xCore.GetPlayerBySource(source)
  if Player ~= nil then
    local citizenid = Player.citizenid
    if body.type == 'avatar' then
      affectedRows = MySQL.update.await(Q.UpdateAvatar, {
        body.value, citizenid
      })
    elseif body.type == 'wallpaper' then
      affectedRows = MySQL.update.await(Q.UpdateWallpaper, {
        body.value, citizenid
      })
    elseif body.type == 'is_anonim' then
      affectedRows = MySQL.update.await(Q.UpdateAnon, {
        body.value, citizenid
      })
    elseif body.type == 'is_donot_disturb' then
      affectedRows = MySQL.update.await(Q.UpdateDnd, {
        body.value, citizenid
      })
    elseif body.type == 'frame' then
      affectedRows = MySQL.update.await(Q.UpdateFrame, {
        body.value, citizenid
      })
    elseif body.type == 'phone_height' then
      affectedRows = MySQL.update.await(Q.UpdatePhoneHeight, {
        body.value,
        citizenid
      })
    else
      lib.print.info("RETRIGER DETECTED, SHOULD BANN IF NEEDED")
    end

    if affectedRows then
      TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
        type = "Notification",
        from = "Setting",
        message = "Success updated!"
      })
      return true
    else
      return false
    end
  end

  return false
end)

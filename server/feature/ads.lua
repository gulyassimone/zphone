lib.callback.register('z-phone:server:GetAds', function(source)
  local Player = xCore.GetPlayerBySource(source)
  if Player == nil then return end

  local result = MySQL.query.await(Q.GetAds)
  if not result then
    return {}
  end

  return result
end)

lib.callback.register('z-phone:server:SendAds', function(source, body)
  local Player = xCore.GetPlayerBySource(source)

  if Player == nil then return end
  local citizenid = Player.citizenid

  local id = MySQL.insert.await(Q.InsertAd, {
    citizenid,
    body.media,
    body.content,
  })

  if not id then
    return false
  end

  TriggerClientEvent("z-phone:client:sendNotifInternal", -1, {
    type = "Notification",
    from = "Ads",
    message = Msg.Ads.NewAdPosted
  })
  return true
end)

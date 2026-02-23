lib.callback.register('z-phone:server:GetPhotos', function(source)
  local Player = xCore.GetPlayerBySource(source)
  if Player ~= nil then
    local citizenid = Player.citizenid

    local result = MySQL.query.await(Q.GetPhotos, {
      citizenid
    })

    if result then
      return result
    else
      return {}
    end
  end
  return {}
end)

lib.callback.register('z-phone:server:SavePhotos', function(source, body)
  local Player = xCore.GetPlayerBySource(source)
  if Player ~= nil then
    local citizenid = Player.citizenid
    local id = MySQL.insert.await(Q.InsertPhoto, {
      citizenid,
      body.url,
      body.location,
    })

    if id then
      return true
    else
      return false
    end
  end
  return false
end)

lib.callback.register('z-phone:server:DeletePhotos', function(source, body)
  local Player = xCore.GetPlayerBySource(source)
  if Player ~= nil then
    local citizenid = Player.citizenid
    MySQL.query.await(Q.DeletePhoto, {
      body.id,
      citizenid,
    })

    return true
  end
  return false
end)

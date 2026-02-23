lib.callback.register('z-phone:server:GetNews', function(source, body)
  local Player = xCore.GetPlayerBySource(source)
  if Player ~= nil then
    local resultNews = MySQL.query.await(Q.GetNews, { false })
    local resultNewsStream = MySQL.query.await(Q.GetNews, { true })

    return {
      news = resultNews,
      streams = resultNewsStream,
    }
  end

  return {}
end)

lib.callback.register('z-phone:server:CreateNews', function(source, body)
  local Player = xCore.GetPlayerBySource(source)

  if Player ~= nil then
    local citizenid = Player.citizenid
    local id = MySQL.insert.await(Q.InsertNews, {
      citizenid,
      Player.name,
      Player.job.name,
      body.cover_url,
      body.title,
      body.content,
      body.stream_url,
      body.stream_url == "" and 0 or 1
    })

    if id then
      TriggerClientEvent("z-phone:client:sendNotifInternal", -1, {
        type = "Notification",
        from = "News",
        message = "News from " .. Player.name
      })
      return true
    else
      return false
    end
  end

  return false
end)

lib.callback.register('z-phone:server:GetServiceJobs', function()
  local result = MySQL.query.await(Q.ListServiceJobs)

  if not result then
    return {}
  end

  return result
end)


lib.callback.register('z-phone:server:GetServices', function(source)
  local Player = xCore.GetPlayerBySource(source)
  if Player == nil then return false end

  local job = Player.job
  local citizenid = Player.citizenid
  local result = MySQL.query.await(Q.GetServices, { job.name })

  if not result then
    return {}
  end

  return result
end)


lib.callback.register('z-phone:server:SendMessageService', function(source, body)
  local Player = xCore.GetPlayerBySource(source)
  if Player == nil then return false end

  local jobName = body.job or (Player.job and Player.job.name)
  if not jobName or jobName == '' then
    return false
  end

  local citizenid = Player.citizenid
  local id = MySQL.insert.await(Q.InsertServiceMessage, {
    citizenid,
    body.message,
    jobName,
    body.cord,
  })

  if not id then
    return false
  end

  if xCore.GetPlayersByJob then
    local targets = xCore.GetPlayersByJob(jobName) or {}
    print(string.format('[z-phone][services] job=%s target_count=%d', tostring(jobName), #targets))

    local filtered = {}
    for idx, target in ipairs(targets) do
      local tName = (target.getName and target:getName()) or target.name or 'unknown'
      local tJob = target.job and target.job.name or 'unknown'
      local tSrc = target.source

      if not tSrc then
        print(string.format('[z-phone][services] skip idx=%d missing source name=%s job=%s', idx, tostring(tName),
          tostring(tJob)))
      elseif tJob ~= jobName then
        print(string.format('[z-phone][services] skip idx=%d source=%s name=%s job=%s (expected %s)', idx, tostring(tSrc),
          tostring(tName), tostring(tJob), tostring(jobName)))
      else
        filtered[#filtered + 1] = target
      end
    end

    print(string.format('[z-phone][services] filtered_count=%d', #filtered))

    for idx, target in ipairs(filtered) do
      local tName = (target.getName and target:getName()) or target.name or 'unknown'
      local tJob = target.job and target.job.name or jobName
      print(string.format('[z-phone][services] notify idx=%d source=%s name=%s job=%s', idx, tostring(target.source),
        tostring(tName), tostring(tJob)))
      TriggerClientEvent("z-phone:client:sendNotifMessage", target.source, {
        from = Msg.Services.Label,
        message = body.message,
        media = nil,
        from_citizenid = citizenid,
        is_service = true,
      })
    end
  end

  TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
    type = "Notification",
    from = Msg.Services.Label,
    message = Msg.Services.MessageSent
  })
  return true
end)

lib.callback.register('z-phone:server:SolvedMessageService', function(source, body)
  local Player = xCore.GetPlayerBySource(source)
  if Player == nil then return false end

  local citizenid = Player.citizenid
  MySQL.update.await(Q.SolveServiceMessage, {
    citizenid,
    body.reason,
    body.citizenid,
    body.service,
  })

  TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
    type = "Notification",
    from = Msg.Services.Label,
    message = Msg.Services.MessageSolved
  })

  return true
end)

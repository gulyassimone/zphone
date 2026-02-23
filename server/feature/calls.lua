local InCalls = {}

lib.callback.register('z-phone:server:StartCall', function(source, body)
  local Player = xCore.GetPlayerBySource(source)
  if not Player then return false end

  local citizenid = Player.citizenid
  local targetUser = MySQL.single.await(Q.GetUserByPhone, {
    body.to_phone_number
  })

  if not targetUser then
    return {
      is_valid = false,
      message = "Phone number not registered!"
    }
  end

  if targetUser.is_donot_disturb then
    return {
      is_valid = false,
      message = "Person is busy!"
    }
  end

  if InCalls[targetUser.citizenid] then
    TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
      type = "Notification",
      from = "Phone",
      message = "Person in a call!"
    })

    return {
      is_valid = false,
      message = "Person in a call!"
    }
  end

  local contactNameTarget = MySQL.scalar.await(Q.GetContactName, {
    citizenid,
    targetUser.citizenid
  })

  if not contactNameTarget then
    contactNameTarget = body.to_phone_number
  end

  local TargetPlayer = xCore.GetPlayerByIdentifier(targetUser.citizenid)
  if not TargetPlayer then
    TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
      type = "Notification",
      from = "Phone",
      message = "Person is unavailable to call!"
    })

    return {
      is_valid = false,
      message = "Person is unavailable to call!"
    }
  end

  local contactNameCaller = MySQL.scalar.await(Q.GetContactName, {
    targetUser.citizenid,
    citizenid
  })

  if not contactNameCaller then
    contactNameCaller = body.from_phone_number
  end

  if body.is_anonim then
    contactNameCaller = "Anonim"
    body.from_avatar = ""
  end

  TriggerClientEvent("z-phone:client:sendNotifIncomingCall", TargetPlayer.source, {
    from = contactNameCaller,
    photo = body.from_avatar,
    message = "Incoming call..",
    to_source = source,
    from_source = TargetPlayer.source,
    to_person_for_caller = contactNameTarget,
    to_photo_for_caller = targetUser.avatar,
    call_id = body.call_id
  })

  TriggerClientEvent("z-phone:client:sendNotifStartCall", source, {
    to_person = contactNameTarget,
    photo = targetUser.avatar,
    to_source = TargetPlayer.source,
    from_source = source,
  })

  MySQL.Async.insert(Q.InsertHistory, {
    citizenid,
    targetUser.citizenid,
    "OUT",
    body.is_anonim
  })

  MySQL.Async.insert(Q.InsertHistory, {
    targetUser.citizenid,
    citizenid,
    "IN",
    body.is_anonim
  })

  InCalls[citizenid] = true
  return {
    is_valid = true,
    to_source = TargetPlayer.source,
    message = "Waiting for response!"
  }
end)

lib.callback.register('z-phone:server:CancelCall', function(source, body)
  local Player1 = xCore.GetPlayerBySource(source)
  local Player2 = xCore.GetPlayerBySource(body.to_source)

  TriggerClientEvent("z-phone:client:closeCall", body.to_source)
  TriggerClientEvent("z-phone:client:closeCallSelf", source)

  InCalls[Player1.citizenid] = nil
  InCalls[Player2.citizenid] = nil

  return true
end)

lib.callback.register('z-phone:server:DeclineCall', function(source, body)
  local Player1 = xCore.GetPlayerBySource(source)
  local Player2 = xCore.GetPlayerBySource(body.to_source)

  InCalls[Player1.citizenid] = nil
  InCalls[Player2.citizenid] = nil

  TriggerClientEvent("z-phone:client:closeCallSelf", body.to_source)
  TriggerClientEvent("z-phone:client:closeCall", source)

  TriggerClientEvent("z-phone:client:sendNotifInternal", body.to_source, {
    type = "Notification",
    from = "Phone",
    message = "Call declined!"
  })
  return true
end)

lib.callback.register('z-phone:server:AcceptCall', function(source, body)
  local Player1 = xCore.GetPlayerBySource(source)
  local Player2 = xCore.GetPlayerBySource(body.to_source)

  InCalls[Player1.citizenid] = true
  InCalls[Player2.citizenid] = true

  -- CALLER
  TriggerClientEvent("z-phone:client:setInCall", body.to_source, {
    from = body.to_person_for_caller,
    photo = body.to_photo_for_caller,
    from_source = body.to_source,
    to_source = source,
    call_id = body.call_id
  })

  -- RECEIVER
  TriggerClientEvent("z-phone:client:setInCall", source, {
    from = body.from,
    photo = body.photo,
    from_source = source,
    to_source = body.to_source,
    call_id = body.call_id
  })

  return true
end)

lib.callback.register('z-phone:server:EndCall', function(source, body)
  local Player1 = xCore.GetPlayerBySource(source)
  local Player2 = xCore.GetPlayerBySource(body.to_source)

  InCalls[Player1.citizenid] = nil
  InCalls[Player2.citizenid] = nil

  TriggerClientEvent("z-phone:client:sendNotifInternal", body.to_source, {
    type = "Notification",
    from = "Phone",
    message = "Call ended!"
  })

  TriggerClientEvent("z-phone:client:closeCall", body.to_source)
  TriggerClientEvent("z-phone:client:closeCallSelf", source)

  return true
end)

lib.callback.register('z-phone:server:GetCallHistories', function(source)
  local Player = xCore.GetPlayerBySource(source)
  if not Player then return false end

  local citizenid = Player.citizenid
  local histories = MySQL.query.await(Q.GetHistories, {
    citizenid
  })

  if not histories then
    histories = {}
  end

  return histories
end)

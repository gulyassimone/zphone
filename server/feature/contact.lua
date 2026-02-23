lib.callback.register('z-phone:server:GetContacts', function(source)
  local Player = xCore.GetPlayerBySource(source)
  if Player ~= nil then
    local citizenid = Player.citizenid
    local result = MySQL.query.await(Q.GetContacts, {
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

lib.callback.register('z-phone:server:DeleteContact', function(source, body)
  local Player = xCore.GetPlayerBySource(source)
  if Player ~= nil then
    local citizenid = Player.citizenid
    MySQL.query.await(Q.DeleteContact, {
      citizenid,
      body.contact_citizenid
    })

    TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
      type = "Notification",
      from = "Contact",
      message = Msg.Contact.DeleteSuccess
    })
    return true
  end
  return false
end)

lib.callback.register('z-phone:server:UpdateContact', function(source, body)
  local Player = xCore.GetPlayerBySource(source)
  if Player ~= nil then
    local citizenid = Player.citizenid
    MySQL.update.await(Q.UpdateContact, {
      body.name,
      body.contact_citizenid,
      citizenid
    })

    TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
      type = "Notification",
      from = "Contact",
      message = Msg.Contact.UpdateSuccess
    })
    return true
  end
  return false
end)

lib.callback.register('z-phone:server:SaveContact', function(source, body)
  local Player = xCore.GetPlayerBySource(source)
  if Player ~= nil then
    local citizenid = Player.citizenid
    local phoneNumber = MySQL.single.await(Q.GetUserByPhone, {
      body.phone_number,
    })
    if not phoneNumber then
      TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
        type = "Notification",
        from = "Contact",
        message = Msg.Contact.PhoneNotRegistered
      })
      return false
    end

    local isDuplicate = MySQL.single.await(Q.CheckDuplicate, {
      phoneNumber.citizenid,
      citizenid
    })

    if isDuplicate then
      TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
        type = "Notification",
        from = "Contact",
        message = string.format(Msg.Contact.DuplicateContact, isDuplicate.contact_name)
      })
      return false
    end

    local contactId = MySQL.insert.await(Q.InsertContact, {
      citizenid,
      phoneNumber.citizenid,
      body.name
    })

    if body.request_id ~= 0 then
      MySQL.query.await("DELETE FROM zp_contacts_requests WHERE id = ?", { body.request_id })
    end

    TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
      type = "Notification",
      from = "Contact",
      message = Msg.Contact.SaveSuccess
    })
    return true
  end
  return false
end)

lib.callback.register('z-phone:server:GetContactRequest', function(source)
  local Player = xCore.GetPlayerBySource(source)
  if not Player then return false end

  local citizenid = Player.citizenid
  local requests = MySQL.query.await(Q.GetContactRequests, {
    citizenid
  })

  if not requests then
    requests = {}
  end

  return requests
end)

lib.callback.register('z-phone:server:ShareContact', function(source, body)
  local Player = xCore.GetPlayerBySource(source)
  if not Player then return false end

  local TargetPlayer = xCore.GetPlayerBySource(body.to_source)
  if not TargetPlayer then return false end

  local citizenid = Player.citizenid
  local targetCitizenID = TargetPlayer.citizenid
  MySQL.insert.await(Q.InsertContactRequest, {
    targetCitizenID,
    citizenid,
  })

  TriggerClientEvent("z-phone:client:sendNotifInternal", body.to_source, {
    type = "Notification",
    from = "Contact",
    message = Msg.Contact.RequestReceived
  })
  return true
end)


lib.callback.register('z-phone:server:DeleteContactRequest', function(source, body)
  MySQL.query.await(Q.DeleteContactRequest, { body.id })
  return true
end)

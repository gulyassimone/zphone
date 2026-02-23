lib.callback.register('z-phone:server:StartOrContinueChatting', function(source, body)
  local Player = xCore.GetPlayerBySource(source)
  if Player == nil then return nil end

  local citizenid = Player.citizenid

  if body.to_citizenid == citizenid then
    TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
      type = "Notification",
      from = "Message",
      message = "Cannot chat to your self!"
    })
    return nil
  end

  if body.phone_number then
    local userTarget = MySQL.single.await(Q.GetUserByPhone, {
      body.phone_number,
    })

    if not userTarget then
      TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
        type = "Notification",
        from = "Message",
        message = "Invalid phone number!"
      })
      return nil
    end

    body.to_citizenid = userTarget.citizenid
  end

  if body.to_citizenid == citizenid then
    TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
      type = "Notification",
      from = "Message",
      message = "Cannot chat to your self!"
    })
    return nil
  end

  local conversationid = MySQL.scalar.await(Q.GetConversationId, {
    citizenid,
    body.to_citizenid
  })

  if conversationid == nil then
    conversationid = MySQL.insert.await(Q.InsertConversation, {
      false,
    })

    local participanOne = MySQL.insert.await(Q.InsertParticipant, {
      conversationid,
      citizenid,
    })

    local participanOne = MySQL.insert.await(Q.InsertParticipant, {
      conversationid,
      body.to_citizenid,
    })
  end

  local result = MySQL.single.await(Q.GetChatting, {
    conversationid,
    citizenid
  })

  if result then
    return result
  else
    return nil
  end
end)

lib.callback.register('z-phone:server:GetChats', function(source)
  local Player = xCore.GetPlayerBySource(source)
  if Player ~= nil then
    local citizenid = Player.citizenid

    MySQL.Async.execute(Q.UpdateLastSeen, { citizenid })

    local result = MySQL.query.await(Q.GetChats, {
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

lib.callback.register('z-phone:server:GetChatting', function(source, body)
  local Player = xCore.GetPlayerBySource(source)

  if Player ~= nil then
    local citizenid = Player.citizenid
    local result = MySQL.query.await(Q.GetChatMessages, {
      body.conversationid
    })

    if result then
      return result
    else
      return {}
    end
  end
  return {}
end)

lib.callback.register('z-phone:server:SendChatting', function(source, body)
  local Player = xCore.GetPlayerBySource(source)

  if Player == nil then return false end
  local citizenid = Player.citizenid
  local id = MySQL.insert.await(Q.InsertMessage, {
    body.conversationid,
    citizenid,
    body.message,
    body.media,
  })

  if not id then return false end

  if not body.is_group then
    local contactName = MySQL.scalar.await(Q.GetContactName, { body.to_citizenid, citizenid, citizenid })
    if contactName then
      body.from = contactName
      body.from_citizenid = citizenid
      local TargetPlayer = xCore.GetPlayerByIdentifier(body.to_citizenid)
      if TargetPlayer ~= nil then
        TriggerClientEvent("z-phone:client:sendNotifMessage", TargetPlayer.source, body)
      end
    end
  else
    local participans = MySQL.query.await(Q.GetParticipants, { body.conversationid })

    if not participans then
      return false
    end

    for i, v in pairs(participans) do
      if v.citizenid ~= citizenid then
        local TargetPlayer = xCore.GetPlayerByIdentifier(v.citizenid)
        if TargetPlayer ~= nil then
          body.to_citizenid = v.citizenid
          body.from = body.conversation_name
          body.from_citizenid = citizenid
          TriggerClientEvent("z-phone:client:sendNotifMessage", TargetPlayer.source, body)
        end
      end
    end
  end

  return id
end)

lib.callback.register('z-phone:server:DeleteMessage', function(source, body)
  local Player = xCore.GetPlayerBySource(source)

  if Player == nil then return false end
  local citizenid = Player.citizenid

  MySQL.update.await(Q.DeleteMessage, {
    body.id,
    citizenid
  })

  return true
end)

lib.callback.register('z-phone:server:CreateGroup', function(source, body)
  local Player = xCore.GetPlayerBySource(source)

  if Player == nil then return false end
  local citizenid = Player.citizenid

  local users = MySQL.query.await(Q.GetUsersByPhones, { body.phone_numbers })

  if not users then
    return false
  end

  local conversationid = MySQL.insert.await(Q.InsertGroupConversation, {
    body.name,
    true,
    citizenid,
  })

  MySQL.insert.await(Q.InsertParticipant, {
    conversationid,
    citizenid,
  })

  for i, v in pairs(users) do
    MySQL.Async.insert(Q.InsertParticipant, {
      conversationid,
      v.citizenid,
    })

    if v.citizenid ~= citizenid then
      local TargetPlayer = xCore.GetPlayerByIdentifier(v.citizenid)
      if TargetPlayer ~= nil then
        TriggerClientEvent("z-phone:client:sendNotifInternal", TargetPlayer.source, {
          type = "Notification",
          from = "Message",
          message = "You invited to group " .. body.name
        })
      end
    end
  end

  MySQL.insert.await(Q.InsertGroupMessage, {
    conversationid,
    citizenid,
    "Created this group."
  })
  return conversationid
end)

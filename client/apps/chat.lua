RegisterNUICallback('new-or-continue-chat', function(body, cb)
  lib.callback('z-phone:server:StartOrContinueChatting', false, function(chatting)
    cb(chatting)
  end, body)
end)

RegisterNUICallback('get-chats', function(_, cb)
  lib.callback('z-phone:server:GetChats', false, function(chats)
    cb(chats)
  end)
end)

RegisterNUICallback('get-chatting', function(body, cb)
  lib.callback('z-phone:server:GetChatting', false, function(chatting)
    cb(chatting)
  end, body)
end)

RegisterNUICallback('send-chatting', function(body, cb)
  if not Net.ensureSignal() then
    cb(false)
    return
  end
  if not Net.ensureData(Config.App.InetMax.InetMaxUsage.MessageSend) then
    cb(false)
    return
  end

  lib.callback('z-phone:server:SendChatting', false, function(isOk)
    if isOk then
      Net.consume(Config.App.Message.Name, Config.App.InetMax.InetMaxUsage.MessageSend)
    end
    cb(isOk)
  end, body)
end)

RegisterNUICallback('delete-message', function(body, cb)
  lib.callback('z-phone:server:DeleteMessage', false, function(isOk)
    cb(isOk)
  end, body)
end)

RegisterNUICallback('create-group', function(body, cb)
  lib.callback('z-phone:server:CreateGroup', false, function(isOk)
    if (isOk) then
      TriggerEvent("z-phone:client:sendNotifInternal", {
        type = "Notification",
        from = "Message",
        message = "Group chat created!"
      })
    end
    cb(isOk)
  end, body)
end)

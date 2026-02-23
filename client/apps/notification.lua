local function dbg(msg)
  print(string.format('[z-phone][client] %s', msg))
end

local ringId = -1

local function stopRinging()
  dbg('stopRinging() called; sending StopOnSource')
  if ringId ~= -1 then
    StopSound(ringId)
    ReleaseSoundId(ringId)
    ringId = -1
  end
  TriggerServerEvent('InteractSound_SV:StopOnSource', 'ringing')
end

RegisterNetEvent('z-phone:client:sendNotifMessage', function(message)
  -- Default GTA SMS ping
  local sid = GetSoundId()
  pcall(PlaySoundFrontend, sid, "Text_Arrive_Tone", "Phone_SoundSet_Default", false)
  if sid ~= -1 then
    StopSound(sid)
    ReleaseSoundId(sid)
  end
  TriggerServerEvent('InteractSound_SV:PlayOnSource', 'monkeyopening', 0.2)
  if xCore.HasItemByName('phone') then
    if PhoneData.isOpen then
      SendNUIMessage({
        event = 'z-phone',
        notification = {
          type = "New Message",
          from = message.from,
          message = message.message,
          media = message.media,
          from_citizenid = message.from_citizenid,
          is_service = message.is_service,
        },
      })
    else
      SendNUIMessage({
        event = 'z-phone',
        outsideMessageNotif = {
          from = message.from,
          message = "New message!"
        },
      })
      -- Light-weight HUD ping without stealing focus
      xCore.Notify(string.format("SMS from %s", message.from or "Unknown"), 'info', 4000)
      -- Also mirror to the NUI notification pipeline so the HTML sound (message-sound.mp3) plays
      SendNUIMessage({
        event = 'z-phone',
        notification = {
          type = "New Message",
          from = message.from,
          message = message.message,
          media = message.media,
          from_citizenid = message.from_citizenid,
          is_service = message.is_service,
        },
      })
    end
  end
end)

RegisterNetEvent('z-phone:client:sendNotifInternal', function(message)
  if xCore.HasItemByName('phone') then
    if PhoneData.isOpen then
      SendNUIMessage({
        event = 'z-phone',
        notification = {
          type = "Notification",
          from = message.from,
          message = message.message
        },
      })
    else
      xCore.Notify(string.format("[%s] %s", message.from, message.message), 'info', 5000)
    end
  end
end)

RegisterNetEvent('z-phone:client:sendNotifIncomingCall', function(message)
  PhoneData.CallData.InCall = true
  PhoneData.CallData.CallId = message.call_id
  dbg(string.format('Incoming call start callId=%s from=%s', tostring(message.call_id), tostring(message.from)))

  if xCore.HasItemByName('phone') then
    if PhoneData.isOpen then
      SendNUIMessage({
        event = 'z-phone',
        notification = {
          type = 'Incoming Call',
          from = message.from,
          photo = message.photo,
          from_source = message.from_source,
          to_source = message.to_source,
          to_person_for_caller = message.to_person_for_caller,
          to_photo_for_caller = message.to_photo_for_caller,
          call_id = message.call_id
        },
      })
    else
      SendNUIMessage({
        event = 'z-phone',
        outsideCallNotif = {
          from = message.from,
          photo = message.photo,
          message = message.message,
          from_source = message.from_source,
          to_source = message.to_source,
          to_person_for_caller = message.to_person_for_caller,
          to_photo_for_caller = message.to_photo_for_caller,
          call_id = message.call_id
        },
      })
      -- Screen-side toast to indicate the incoming call without grabbing focus
      xCore.Notify(string.format("Incoming call: %s", message.from or "Unknown"), 'info', 5000)
      -- Mirror into the NUI notification pipeline so the HTML call-sound.mp3 is triggered
      SendNUIMessage({
        event = 'z-phone',
        notification = {
          type = 'Incoming Call',
          from = message.from,
          photo = message.photo,
          from_source = message.from_source,
          to_source = message.to_source,
          to_person_for_caller = message.to_person_for_caller,
          to_photo_for_caller = message.to_photo_for_caller,
          call_id = message.call_id
        },
      })
    end

    local RepeatCount = 0
    for _ = 1, Config.CallRepeats + 1, 1 do
      if not PhoneData.CallData.AnsweredCall then
        if RepeatCount + 1 ~= Config.CallRepeats + 1 then
          if PhoneData.CallData.InCall then
            RepeatCount = RepeatCount + 1
            dbg(string.format('Incoming ring tick=%s callId=%s', RepeatCount, tostring(PhoneData.CallData.CallId)))
            -- GTA native ring that is audible even without InteractSound assets
            if ringId == -1 then
              ringId = GetSoundId()
            end
            pcall(PlaySoundFrontend, ringId, "Dial_and_Remote_Ring", "Phone_SoundSet_Default", false)
            -- Keep InteractSound as optional extra volume if the sound exists
            TriggerServerEvent('InteractSound_SV:PlayOnSource', 'ringing', 1.0)
          else
            dbg('Incoming ring loop breaking because InCall is false')
            stopRinging()
            break
          end
          Wait(Config.RepeatTimeout)
        else
          dbg('Incoming ring timed out with no answer')
          PhoneData.CallData.CallId = nil
          PhoneData.CallData.InCall = false

          TriggerEvent("z-phone:client:sendNotifInternal", {
            type = "Notification",
            from = "Phone",
            message = "Call not answered"
          })
          lib.callback('z-phone:server:EndCall', false, function(_) end,
            { to_source = message.from_source })
          stopRinging()
          break
        end
      end
    end
    -- Safety stop in case we exit the loop without clearing the sound
    dbg('Incoming ring loop finished; forcing stopRinging()')
    stopRinging()
  end
end)

RegisterNetEvent('z-phone:client:sendNotifStartCall', function(message)
  if xCore.HasItemByName('phone') then
    SendNUIMessage({
      event = 'z-phone',
      notification = {
        type = 'Calling...',
        to_person = message.to_person,
        photo = message.photo,
        from_source = message.from_source,
        to_source = message.to_source,
      },
    })
  end
end)

RegisterNetEvent('z-phone:client:setInCall', function(message)
  PhoneData.CallData.AnsweredCall = true
  PhoneData.CallData.InCall = true
  PhoneData.CallData.CallId = message.call_id
  dbg(string.format('setInCall callId=%s from=%s', tostring(message.call_id), tostring(message.from)))
  stopRinging()
  exports['pma-voice']:addPlayerToCall(message.call_id)

  SendNUIMessage({
    event = 'z-phone',
    notification = {
      type = "In Call",
      from = message.from,
      photo = message.photo,
      from_source = message.from_source,
      to_source = message.to_source,
      call_id = message.call_id
    },
  })
end)

RegisterNetEvent('z-phone:client:closeCall', function()
  dbg('closeCall received')
  if PhoneData.CallData.InCall and PhoneData.CallData.AnsweredCall then
    DoPhoneAnimation('cellphone_text_in')
  end

  stopRinging()

  PhoneData.CallData.AnsweredCall = false
  PhoneData.CallData.InCall = false
  PhoneData.CallData.CallId = nil

  SendNUIMessage({
    event = 'z-phone',
    closeCall = {
      type = "CLOSE_CALL",
    },
  })
end)
RegisterNetEvent('z-phone:client:closeCallSelf', function()
  dbg('closeCallSelf received')
  if PhoneData.CallData.InCall then
    DoPhoneAnimation('cellphone_text_in')
  end
  stopRinging()

  if PhoneData.CallData.CallId then
    exports['pma-voice']:removePlayerFromCall(PhoneData.CallData.CallId)
  end

  PhoneData.CallData.AnsweredCall = false
  PhoneData.CallData.InCall = false
  PhoneData.CallData.CallId = nil

  SendNUIMessage({
    event = 'z-phone',
    closeCall = {
      type = "CLOSE_CALL",
    },
  })
end)

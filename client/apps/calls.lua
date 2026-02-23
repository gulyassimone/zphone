-- ============================================================================
-- Helpers
-- ============================================================================

local function getCallConfig()
  local repeats = tonumber((Config and Config.CallRepeats)) or 0
  local timeout = tonumber((Config and Config.RepeatTimeout)) or 1000
  return repeats, timeout
end

local function stopRinging(soundIdRef)
  -- soundIdRef: table wrapper { id = -1 } so we can mutate it inside functions
  if soundIdRef and soundIdRef.id and soundIdRef.id ~= -1 then
    StopSound(soundIdRef.id)
    ReleaseSoundId(soundIdRef.id)
    soundIdRef.id = -1
  end
  TriggerServerEvent('InteractSound_SV:StopOnSource', 'ringing')
end

local function playOutgoingRing(soundIdRef)
  if soundIdRef.id == -1 then
    soundIdRef.id = GetSoundId()
  end
  pcall(PlaySoundFrontend, soundIdRef.id, "Dial_and_Remote_Ring", "Phone_SoundSet_Default", false)
  TriggerServerEvent('InteractSound_SV:PlayOnSource', 'ringing', 1.0)
end

local function safeNumber(v)
  local n = tonumber(v)
  if n == nil then return nil end
  return n
end

local function GenerateCallId(caller, target)
  local c = safeNumber(caller)
  local t = safeNumber(target)
  if not c or not t then return nil end
  return math.ceil((c + t) / 100)
end

local function notifyInternal(from, message)
  TriggerEvent("z-phone:client:sendNotifInternal", {
    type = "Notification",
    from = from,
    message = message
  })
end

local function setCallAnimation()
  if PhoneData.isOpen then
    DoPhoneAnimation('cellphone_text_to_call')
  else
    DoPhoneAnimation('cellphone_call_listen_base')
  end
end

-- Runs the outgoing ring loop. Does NOT call cb().
-- On timeout, it cancels the call on server and notifies UI via SendNUIMessage.
local function startOutgoingRingLoop(callId, toSource)
  local callRepeats, repeatTimeout = getCallConfig()
  local ring = { id = -1 }

  local ticks = 0

  for _ = 1, callRepeats + 1 do
    -- break conditions first
    if PhoneData.CallData.AnsweredCall then
      stopRinging(ring)
      return
    end

    if not PhoneData.CallData.InCall or PhoneData.CallData.CallId ~= callId then
      stopRinging(ring)
      return
    end

    ticks = ticks + 1

    -- last tick => timeout
    if ticks > callRepeats then
      -- timeout: end local state + server cancel
      PhoneData.CallData.CallId = nil
      PhoneData.CallData.InCall = false

      notifyInternal("Phone", "Call not answered")

      lib.callback('z-phone:server:CancelCall', false, function(_)
        -- notify UI separately (do NOT call cb again)
        SendNUIMessage({
          event = 'z-phone',
          call = { type = "OUTGOING_TIMEOUT", call_id = callId }
        })
      end, { to_source = toSource })

      stopRinging(ring)
      return
    end

    -- play ring tick
    print(('[z-phone][client] outgoing ring tick=%s callId=%s'):format(ticks, tostring(callId)))
    playOutgoingRing(ring)

    Wait(repeatTimeout)
  end

  -- safety stop
  stopRinging(ring)
end

-- ============================================================================
-- NUI callbacks
-- ============================================================================

RegisterNUICallback('start-call', function(body, cb)
  -- Basic payload safety
  body = body or {}

  -- Guard: already in a call
  if PhoneData.CallData.InCall then
    notifyInternal("Phone", "You're in a call!")
    cb(false)
    return
  end

  -- Guard: signal / permission
  if not Net.ensureSignal() then
    cb(false)
    return
  end

  -- Ensure profile loaded
  Net.ensureProfile(function()
    -- Guard: profile must exist and have phone number
    if not Profile or not Profile.phone_number then
      -- (message was misleading before; this is a profile/phone issue, not data)
      notifyInternal("Phone", "Profile not loaded / missing phone number")
      cb(false)
      return
    end

    -- Guard: require enough data quota for calling
    local usage = Config.App and Config.App.InetMax and Config.App.InetMax.InetMaxUsage or {}
    local callCost = tonumber(usage.PhoneCall) or 0

    if callCost > 0 and not Net.ensureData(callCost) then
      cb(false)
      return
    end

    -- Validate target number
    if not body.to_phone_number then
      notifyInternal("Phone", "Missing target phone number")
      cb(false)
      return
    end

    -- Create call id safely
    local callId = GenerateCallId(Profile.phone_number, body.to_phone_number)
    if not callId then
      notifyInternal("Phone", "Invalid phone number(s)")
      cb(false)
      return
    end

    -- Prepare server payload
    body.call_id = callId
    body.is_anonim = Profile.is_anonim

    -- Ask server to start the call (authoritative validation)
    lib.callback('z-phone:server:StartCall', false, function(res)
      if not res or not res.is_valid then
        notifyInternal("Phone", (res and res.message) or "Call failed")
        cb(false)
        return
      end

      -- Mark call state
      PhoneData.CallData.InCall = true
      PhoneData.CallData.CallId = callId

      print(('[z-phone][client] outgoing call start callId=%s to=%s'):format(
        tostring(callId), tostring(body.to_phone_number)
      ))

      setCallAnimation()

      -- IMPORTANT: call cb exactly once (success)
      cb(res)

      -- Consume data only after server accepted the call
      if callCost > 0 then
        Net.consume(Config.App.Wallet.Name, callCost)
      end

      -- Start ring loop (no cb inside!)
      startOutgoingRingLoop(callId, res.to_source)
    end, body)
  end)
end)

RegisterNUICallback('cancel-call', function(body, cb)
  lib.callback('z-phone:server:CancelCall', false, function(isOk)
    cb(isOk)
  end, body)
end)

RegisterNUICallback('decline-call', function(body, cb)
  lib.callback('z-phone:server:DeclineCall', false, function(isOk)
    cb(isOk)
  end, body)
end)

RegisterNUICallback('end-call', function(body, cb)
  lib.callback('z-phone:server:EndCall', false, function(isOk)
    cb(isOk)
  end, body)
end)

RegisterNUICallback('accept-call', function(body, cb)
  setCallAnimation()
  PhoneData.CallData.InCall = true

  lib.callback('z-phone:server:AcceptCall', false, function(isOk)
    cb(isOk)
  end, body)
end)

RegisterNUICallback('get-call-histories', function(_, cb)
  lib.callback('z-phone:server:GetCallHistories', false, function(histories)
    cb(histories)
  end)
end)

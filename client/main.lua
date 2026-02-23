local nuiEventName = Shared.Constants.NuiEvent
local openCommand = Shared.Constants.Commands.OpenPhone
local getProfileEvent = Shared.Events.GetProfile
local hasPhoneEvent = Shared.Events.HasPhone

local function ensureProfileLoaded()
  if next(Profile) ~= nil then return end

  lib.callback(getProfileEvent, false, function(profile)
    Profile = profile or {}
  end)
end

CreateThread(function()
  Wait(500)
  ensureProfileLoaded()
end)

function GetStreetName()
  local pos = GetEntityCoords(PlayerPedId())
  local s1, s2 = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
  local street1 = GetStreetNameFromHashKey(s1)
  local street2 = GetStreetNameFromHashKey(s2)
  local streetLabel = street1
  if street2 ~= nil then
    streetLabel = streetLabel .. ' ' .. street2
  end

  return streetLabel
end

RegisterNUICallback('phone:getLocationText', function(_, cb)
  local coords = GetEntityCoords(PlayerPedId())
  local street = GetStreetName()
  local text = string.format("%s | %.2f, %.2f, %.2f", street, coords.x, coords.y, coords.z)

  cb({ text = text })
end)

RegisterNUICallback('phone:setWaypoint', function(_, cb)
  local coords = GetEntityCoords(PlayerPedId())
  SetNewWaypoint(coords.x, coords.y)
  cb(true)
end)

RegisterNUICallback('phone:setWaypointAt', function(data, cb)
  local x = tonumber(data and data.x)
  local y = tonumber(data and data.y)

  if not x or not y then
    cb({ ok = false })
    return
  end

  -- waypoint (térképen jel)
  SetNewWaypoint(x + 0.0, y + 0.0)

  -- route (útvonal) bekapcsolása: a GTA a waypointhoz automatikusan tud route-ot mutatni,
  -- de biztosra megyünk: létrehozunk egy blipet és route-ot kapcsolunk rá.

  -- töröld a korábbi gps blipet, ha van
  if PhoneData and PhoneData.GpsBlip then
    RemoveBlip(PhoneData.GpsBlip)
    PhoneData.GpsBlip = nil
  end

  local blip = AddBlipForCoord(x + 0.0, y + 0.0, 0.0)
  SetBlipSprite(blip, 8)      -- waypoint ikon
  SetBlipRoute(blip, true)
  SetBlipRouteColour(blip, 5) -- tetszőleges szín index

  if PhoneData then
    PhoneData.GpsBlip = blip
  end

  cb({ ok = true })
end)

local function ClearPhoneGpsRoute()
  if PhoneData and PhoneData.GpsBlip then
    SetBlipRoute(PhoneData.GpsBlip, false)
    RemoveBlip(PhoneData.GpsBlip)
    PhoneData.GpsBlip = nil
  end
end

local function DisableDisplayControlActions()
  DisableControlAction(0, 1, true)   -- disable mouse look
  DisableControlAction(0, 2, true)   -- disable mouse look
  DisableControlAction(0, 3, true)   -- disable mouse look
  DisableControlAction(0, 4, true)   -- disable mouse look
  DisableControlAction(0, 5, true)   -- disable mouse look
  DisableControlAction(0, 6, true)   -- disable mouse look
  DisableControlAction(0, 263, true) -- disable melee
  DisableControlAction(0, 264, true) -- disable melee
  DisableControlAction(0, 257, true) -- disable melee
  DisableControlAction(0, 140, true) -- disable melee
  DisableControlAction(0, 141, true) -- disable melee
  DisableControlAction(0, 142, true) -- disable melee
  DisableControlAction(0, 143, true) -- disable melee
  DisableControlAction(0, 177, true) -- disable escape
  DisableControlAction(0, 200, true) -- disable escape
  DisableControlAction(0, 202, true) -- disable escape
  DisableControlAction(0, 322, true) -- disable escape
  DisableControlAction(0, 245, true) -- disable chat
end


local function startAllInputBlocker()
  CreateThread(function()
    while PhoneData.isMessagesOpen do
      DisableAllControlActions(0)
      DisableAllControlActions(1)

      -- extra beton mozgás tiltás
      DisableControlAction(0, 30, true) -- move L/R
      DisableControlAction(0, 31, true) -- move F/B
      DisableControlAction(0, 21, true) -- sprint
      DisableControlAction(0, 22, true) -- jump

      -- hagyd meg, ami kell (különben beragadsz)
      EnableControlAction(0, 200, true) -- ESC / pause
      EnableControlAction(0, 177, true) -- back

      Wait(0)
    end
  end)
end


local function startInputBlocker()
  CreateThread(function()
    while PhoneData.isOpen do
      if not PhoneData.isMessagesOpen then
        DisableDisplayControlActions()
      end
      Wait(0)
    end
  end)
end

RegisterNUICallback('phone:setMessagesOpen', function(data, cb)
  local open = data and data.open == true
  PhoneData.isMessagesOpen = open

  if open then
    startAllInputBlocker()
  else
    ClearPhoneGpsRoute()
    -- back: csak a full blockot engedjük el, fókuszt a teljes close kezeli
  end
  cb('ok')
end)

function OpenPhone()
  -- Halott állapot ellenőrzés
  local ped = PlayerPedId()
  if IsPedFatallyInjured(ped) or (LocalPlayer and LocalPlayer.state and LocalPlayer.state.dead) then
    xCore.Notify("Nem tudsz telefont nyitni halottan!", 'error', 3000)
    return
  end

  local _, weaponHash = GetCurrentPedWeapon(PlayerPedId(), true)
  if weaponHash ~= GetHashKey("WEAPON_UNARMED") then
    xCore.Notify("Cannot open phone!", 'error', 3000)
    return
  end

  lib.callback(hasPhoneEvent, false, function(HasPhone)
    if HasPhone then
      PhoneData.PlayerData = xCore.GetPlayerData()
      Nui.open(nuiEventName)
      PhoneData.isOpen = true

      startInputBlocker()

      if not PhoneData.CallData.InCall then
        DoPhoneAnimation('cellphone_text_in')
      else
        DoPhoneAnimation('cellphone_call_to_text')
      end

      SetTimeout(250, function()
        DeleteNearbyPhoneProps(10.0)
        NewPhoneProp()
      end)
    else
      xCore.Notify("You don't have a phone", 'error', 3000)
    end
  end)
end

RegisterCommand(openCommand, function()
  local PlayerData = xCore.GetPlayerData()
  if not PhoneData.isOpen and PlayerData then
    OpenPhone()
  end
end)

RegisterKeyMapping(openCommand, 'Open Phone', 'keyboard', Config.OpenPhone)

RegisterNUICallback('close', function(_, cb)
  PhoneData.isMessagesOpen = false
  PhoneData.isOpen = false

  ClearPhoneGpsRoute()

  SetNuiFocus(false, false)
  SetNuiFocusKeepInput(false)

  if not PhoneData.CallData.InCall then
    DoPhoneAnimation('cellphone_text_out')
    SetTimeout(400, function()
      StopAnimTask(PlayerPedId(), PhoneData.AnimationData.lib, PhoneData.AnimationData.anim, 2.5)
      DeletePhone()
      DeleteNearbyPhoneProps(10.0)
      PhoneData.AnimationData.lib = nil
      PhoneData.AnimationData.anim = nil
      -- Play reanim animation when phone is put away, then return to idle
      local ped = PlayerPedId()
      local lib = 'cellphone@'
      local anim = 'cellphone_rein'
      LoadAnimation(lib)
      TaskPlayAnim(ped, lib, anim, 3.0, 3.0, 1000, 50, 0, false, false, false)
      -- Return to idle/base pose after reanim
      SetTimeout(700, function()
        local idleLib = 'move_m@walk'
        local idleAnim = 'idle'
        LoadAnimation(idleLib)
        TaskPlayAnim(ped, idleLib, idleAnim, 3.0, 3.0, 1000, 50, 0, false, false, false)
      end)
    end)
  else
    PhoneData.AnimationData.lib = nil
    PhoneData.AnimationData.anim = nil
    DoPhoneAnimation('cellphone_text_to_call')
  end
  Nui.close(nuiEventName)
  DeleteNearbyPhoneProps(10.0)

  cb('ok')
end)

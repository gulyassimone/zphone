local M = {
  state = {
    lastNui = nil,
    focus = false,
    cursor = false,
    keepInput = false,
    weapon = 'WEAPON_UNARMED',
    spawned = false,
    lastAnim = nil,
    nuiCallbacks = {},
  }
}

function M.install()
  _G.GetHashKey = function(name) return name end
  _G.PlayerPedId = function() return 1 end
  _G.GetCurrentPedWeapon = function() return true, M.state.weapon end
  _G.GetEntityCoords = function() return { x = 0.0, y = 0.0, z = 0.0 } end
  _G.GetStreetNameAtCoord = function() return 0, 0 end
  _G.GetStreetNameFromHashKey = function(hash) return hash or 'street' end

  _G.SendNUIMessage = function(payload) M.state.lastNui = payload end
  _G.SetNuiFocus = function(hasFocus, hasCursor)
    M.state.focus = hasFocus
    M.state.cursor = hasCursor
  end
  _G.SetNuiFocusKeepInput = function(state) M.state.keepInput = state end

  _G.CreateThread = function(fn) M.state.lastThread = fn end
  _G.Wait = function(_) end
  _G.SetTimeout = function(_, cb) cb() end

  _G.DisableControlAction = function() end
  _G.StopAnimTask = function() end
  _G.DeleteObject = function() end
  _G.GetClosestObjectOfType = function() return 0 end

  _G.DoPhoneAnimation = function(anim) M.state.lastAnim = anim end
  _G.NewPhoneProp = function() M.state.spawned = true end
  _G.DeletePhone = function() M.state.spawned = false end

  _G.RegisterCommand = function(name, cb)
    M.state.registeredCommand = { name = name, cb = cb }
  end
  _G.RegisterKeyMapping = function(name, _, _, key)
    M.state.keymap = { name = name, key = key }
  end
  _G.RegisterNUICallback = function(name, cb)
    M.state.nuiCallbacks[name] = cb
  end
end

function M.triggerNui(name, data)
  if M.state.nuiCallbacks[name] then
    M.state.nuiCallbacks[name](data or {}, function() end)
  end
end

function M.setWeapon(hash)
  M.state.weapon = hash
end

function M.reset()
  M.state.lastNui = nil
  M.state.focus = false
  M.state.cursor = false
  M.state.keepInput = false
  M.state.spawned = false
  M.state.lastAnim = nil
  M.state.nuiCallbacks = {}
  M.state.registeredCommand = nil
  M.state.keymap = nil
  M.state.weapon = 'WEAPON_UNARMED'
end

return M

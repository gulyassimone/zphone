Nui = Nui or {}

function Nui.push(payload)
  SendNUIMessage(payload)
end

function Nui.setFocus(hasFocus, hasCursor)
  if hasCursor == nil then
    hasCursor = hasFocus
  end
  SetNuiFocus(hasFocus, hasCursor)
end

function Nui.setFocusKeepInput(state)
  SetNuiFocusKeepInput(true)
end

function Nui.open(eventName)
  Nui.setFocus(true, true)
  SetNuiFocusKeepInput(true)
  Nui.push({
    event = eventName,
    isOpen = true,
  })
end

function Nui.close(eventName)
  Nui.push({
    event = eventName,
    isOpen = false,
  })
  Nui.setFocus(false, false)
  Nui.setFocusKeepInput(false)
end

local function safeCb(cb, payload)
  if cb then cb(payload) end
end

-- opts:
--   signal = true/false
--   dataCost = number|nil
--   appName = string|nil  (consume-hoz)
--   consumeOn = function(result) -> boolean  (mikor fogyasszon)
function Nui.guard(cb, opts, fn)
  opts = opts or {}

  if opts.signal and not Net.ensureSignal() then
    safeCb(cb, false)
    return
  end

  if opts.dataCost and not Net.ensureData(opts.dataCost) then
    safeCb(cb, false)
    return
  end

  -- a fn kap egy done(result) callbacket
  fn(function(result)
    if opts.dataCost and opts.appName then
      local okToConsume = true
      if type(opts.consumeOn) == 'function' then
        okToConsume = opts.consumeOn(result) == true
      end

      if okToConsume then
        Net.consume(opts.appName, opts.dataCost)
      end
    end

    safeCb(cb, result)
  end)
end

-- ============================================================================
-- Bank NUI helpers (stable response + less repetition)
-- ============================================================================

local function Ok(data)
  return { ok = true, data = data }
end

local function Fail(code, message, data)
  return { ok = false, error = { code = code, message = message }, data = data }
end

local function ToResult(res)
  -- Normalize server return into {ok,data,error}
  if type(res) == 'table' then
    if res.ok ~= nil then return res end
    -- plain table => success payload
    return Ok(res)
  end
  if type(res) == 'boolean' then
    return res and Ok(true) or Fail('FAILED', 'Operation failed')
  end
  if res == nil then
    return Fail('NIL', 'No response')
  end
  -- number/string/etc => treat as payload
  return Ok(res)
end

local function BankGuard(opts, fn)
  return function(body, cb)
    Nui.guard(cb, {
      signal    = opts.signal == true,
      dataCost  = opts.dataCost,
      appName   = opts.appName,

      -- IMPORTANT: quota consumption is based on normalized result.ok
      consumeOn = function(result)
        local r = ToResult(result)
        return r.ok == true
      end
    }, function(done)
      fn(body, function(serverRes)
        done(ToResult(serverRes))
      end)
    end)
  end
end

-- ============================================================================
-- get-bank (no guard, server is truth)
-- ============================================================================
RegisterNUICallback('get-bank', function(_, cb)
  Log.Debug('NUI get-bank request')
  Rpc.call('z-phone:server:GetBank', nil, function(bank)
    Log.Debug('NUI get-bank response received')
    cb(bank) -- FONTOS: ne Ok()-old
  end)
end)

-- ============================================================================
-- pay-invoice
-- ============================================================================
RegisterNUICallback('pay-invoice', BankGuard({
  signal   = true,
  dataCost = Config.App.InetMax.InetMaxUsage.BankPayInvoice,
  appName  = Config.App.Wallet.Name,
}, function(body, done)
  Rpc.call('z-phone:server:PayInvoice', body, done)
end))

-- ============================================================================
-- transfer-check
-- ============================================================================
RegisterNUICallback('transfer-check', BankGuard({
  signal   = true,
  dataCost = Config.App.InetMax.InetMaxUsage.BankCheckTransferReceiver,
  appName  = Config.App.Wallet.Name,
}, function(body, done)
  Rpc.call('z-phone:server:TransferCheck', body, done)
end))

-- ============================================================================
-- transfer
-- ============================================================================
RegisterNUICallback('transfer', BankGuard({
  signal   = true,
  dataCost = Config.App.InetMax.InetMaxUsage.BankTransfer,
  appName  = Config.App.Wallet.Name,
}, function(body, done)
  Rpc.call('z-phone:server:Transfer', body, function(res)
    Log.Debug(('NUI transfer server raw=%s'):format(res and json.encode(res) or tostring(res)))
    done(res)
  end)
end))

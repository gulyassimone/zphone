local function logBankTxn(src, txType, amount, desc)
  local ok, err = pcall(function()
    exports['omes_banking']:LogCustomTransaction(src, txType, amount, desc)
  end)
  if not ok then
    Log.Warn(('[bank] log txn failed src=%s type=%s amt=%s err=%s'):format(tostring(src), tostring(txType),
      tostring(amount), tostring(err)))
  end
end

lib.callback.register('z-phone:server:GetBank', function(source)
  local Player = xCore.GetPlayerBySource(source)
  if Player ~= nil then
    local citizenid = Player.citizenid

    Log.Debug('get bank for %s (src %s)', citizenid, source)

    local histories = xCore.bankHistories(citizenid)
    local bills = xCore.bankInvoices(citizenid)

    Log.Debug('[bank] fetched %s bills for %s', bills and #bills or 0, citizenid)

    return {
      histories = histories,
      bills = bills,
      balance = Player.money.bank
    }
  end
  return {}
end)

lib.callback.register('z-phone:server:PayInvoice', function(source, body)
  local Player = xCore.GetPlayerBySource(source)
  if Player == nil then
    TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
      type = "Notification",
      from = "Wallet",
      message = Msg.Bank.PayFailed
    })
    return false
  end

  if Player.money.bank < body.amount then
    TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
      type = "Notification",
      from = "Wallet",
      message = Msg.Bank.BalanceNotEnough
    })
    return false
  end

  local citizenid = Player.citizenid
  local invoice = xCore.bankInvoiceByCitizenID(body.id, citizenid)

  if not invoice then
    TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
      type = "Notification",
      from = "Wallet",
      message = Msg.Bank.PayFailed
    })
    return false
  end

  Player.removeAccountMoney('bank', invoice.amount, invoice.reason)

  xCore.AddMoneyBankSociety(invoice.society, invoice.amount, invoice.reason)
  xCore.deleteBankInvoiceByID(invoice.id)

  logBankTxn(source, 'invoice_pay', invoice.amount, invoice.reason or 'Invoice payment')

  TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
    type = "Notification",
    from = "Wallet",
    message = Msg.Bank.InvoicePaid
  })
  return true
end)

lib.callback.register('z-phone:server:TransferCheck', function(source, body)
  local Player = xCore.GetPlayerBySource(source)
  if Player == nil then
    TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
      type = "Notification",
      from = "Wallet",
      message = Msg.Bank.TransferCheckFailed
    })
    return {
      isValid = false,
      name = ""
    }
  end

  if not body then
    Log.Warn(('[bank] transfer-check missing body src=%s'):format(source))
    TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
      type = "Notification",
      from = "Wallet",
      message = Msg.Bank.TransferCheckFailed
    })
    return {
      isValid = false,
      name = ""
    }
  end

  local targetSource = tonumber(body.serverId or body.iban)
  Log.Debug(('[bank] transfer-check src=%s targetSrc=%s'):format(source, tostring(targetSource)))

  if not targetSource then
    TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
      type = "Notification",
      from = "Wallet",
      message = Msg.Bank.IbanNotRegistered
    })
    return {
      isValid = false,
      name = ""
    }
  end

  if targetSource == source then
    TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
      type = "Notification",
      from = "Wallet",
      message = Msg.Bank.CannotSelfTransfer
    })
    return {
      isValid = false,
      name = ""
    }
  end

  local ReceiverPlayer = xCore.GetPlayerBySource(targetSource)
  Log.Debug(('[bank] transfer-check receiver src=%s online=%s'):format(targetSource, ReceiverPlayer and 'yes' or 'no'))
  if ReceiverPlayer == nil then
    TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
      type = "Notification",
      from = "Wallet",
      message = Msg.Bank.ReceiverOffline
    })
    return {
      isValid = false,
      name = ""
    }
  end

  return {
    isValid = true,
    name = ReceiverPlayer.charinfo.firstname .. ' ' .. ReceiverPlayer.charinfo.lastname
  }
end)

lib.callback.register('z-phone:server:Transfer', function(source, body)
  local ok, result = xpcall(function()
    local Player = xCore.GetPlayerBySource(source)
    if Player == nil then
      TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
        type = "Notification",
        from = "Wallet",
        message = Msg.Bank.TransferCheckFailed
      })
      Log.Debug('[bank] transfer reply=false reason=no_player')
      return false
    end

    if not body then
      Log.Warn(('[bank] transfer missing payload src=%s'):format(source))
      TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
        type = "Notification",
        from = "Wallet",
        message = Msg.Bank.TransferCheckFailed
      })
      Log.Debug('[bank] transfer reply=false reason=no_body')
      return false
    end

    local amount = tonumber(body.total)
    local targetSource = tonumber(body.serverId or body.iban)
    local note = tostring(body.note or '')

    Log.Debug(('[bank] transfer src=%s total=%s targetSrc=%s'):format(source, tostring(amount), tostring(targetSource)))

    if not amount or amount <= 0 then
      TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
        type = "Notification",
        from = "Wallet",
        message = Msg.Bank.TransferCheckFailed
      })
      Log.Debug('[bank] transfer reply=false reason=amount_invalid')
      return false
    end

    if Player.money.bank < amount then
      TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
        type = "Notification",
        from = "Wallet",
        message = Msg.Bank.BalanceNotEnough
      })
      Log.Debug('[bank] transfer reply=false reason=insufficient_balance')
      return false
    end

    if not targetSource then
      TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
        type = "Notification",
        from = "Wallet",
        message = Msg.Bank.IbanNotRegistered
      })
      Log.Debug('[bank] transfer reply=false reason=target_missing')
      return false
    end

    if targetSource == source then
      TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
        type = "Notification",
        from = "Wallet",
        message = Msg.Bank.CannotSelfTransfer
      })
      Log.Debug('[bank] transfer reply=false reason=self_transfer')
      return false
    end

    local ReceiverPlayer = xCore.GetPlayerBySource(targetSource)
    Log.Debug(('[bank] transfer receiver src=%s online=%s'):format(targetSource, ReceiverPlayer and 'yes' or 'no'))
    if ReceiverPlayer == nil then
      TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
        type = "Notification",
        from = "Wallet",
        message = Msg.Bank.ReceiverOffline
      })
      Log.Debug('[bank] transfer reply=false reason=receiver_offline')
      return false
    end

    local senderReason = string.format("Transfer send: %s - to #%s", note, targetSource)
    local receiverReason = string.format("%s - from #%s", "Transfer received", source)
    Log.Debug(('[bank] transfer charging %s from src=%s'):format(tostring(amount), source))
    Player.removeAccountMoney('bank', amount, senderReason)
    ReceiverPlayer.addAccountMoney('bank', amount, receiverReason)
    Log.Debug(('[bank] transfer sent to src=%s done'):format(targetSource))

    logBankTxn(source, 'transfer_out', amount, senderReason)
    logBankTxn(ReceiverPlayer.source, 'transfer_in', amount, receiverReason)

    MySQL.Async.insert(Q.InsertEmail, {
      "wallet",
      Player.citizenid,
      Msg.Bank.TransferEmailSubject,
      string.format(Msg.Bank.TransferEmailBody, amount, targetSource, note)
    })

    TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
      type = "Notification",
      from = "Wallet",
      message = Msg.Bank.TransferSuccess
    })

    TriggerClientEvent("z-phone:client:sendNotifInternal", ReceiverPlayer.source, {
      type = "Notification",
      from = "Wallet",
      message = Msg.Bank.TransferReceived
    })

    Log.Debug('[bank] transfer reply=true')
    return true
  end, function(err)
    Log.Error(('[bank] transfer exception src=%s err=%s'):format(source, tostring(err)))
    return false
  end)

  if not ok then
    return false
  end

  if result == nil then
    Log.Error(('[bank] transfer returned nil src=%s'):format(source))
    return false
  end

  return result == true
end)

local function shouldTrackData()
  return Config.App.InetMax.EnableDataUsage ~= false
end

lib.callback.register('z-phone:server:GetInternetData', function(source)
  local Player = xCore.GetPlayerBySource(source)
  if Player == nil then return {} end

  local citizenid = Player.citizenid

  local topups = MySQL.query.await(Q.GetTopups, {
    citizenid,
    "CREDIT"
  })

  local usages = MySQL.query.await(Q.GetTopups, {
    citizenid,
    "USAGE"
  })

  local usageGroup = MySQL.query.await(Q.GetUsageGroup, {
    citizenid,
  })

  return {
    topup_histories = topups,
    usage_histories = usages,
    group_usage = usageGroup
  }
end)

lib.callback.register('z-phone:server:TopupInternetData', function(source, body)
  if not shouldTrackData() then return 0 end

  local Player = xCore.GetPlayerBySource(source)
  if Player == nil then return 0 end

  local citizenid = Player.citizenid
  if Player.money.bank < body.total then
    TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
      type = "Notification",
      from = "InetMax",
      message = Msg.InetMax.BankNotEnough
    })
    return false
  end

  local IncrementBalance = math.floor(body.total / Config.App.InetMax.TopupRate.Price) *
      Config.App.InetMax.TopupRate.InKB
  local id = MySQL.insert.await(Q.InsertHistory, {
    citizenid,
    "CREDIT",
    body.label,
    IncrementBalance
  })

  MySQL.update.await(Q.UpdateBalanceAdd, {
    IncrementBalance,
    citizenid
  })

  Player.removeAccountMoney('bank', body.total, "InetMax purchase")
  xCore.AddMoneyBankSociety(Config.App.InetMax.SocietySeller, body.total, "InetMax purchase")

  TriggerClientEvent("z-phone:client:sendNotifInternal", source, {
    type = "Notification",
    from = "InetMax",
    message = Msg.InetMax.PurchaseSuccess
  })

  MySQL.Async.insert(Q.InsertEmail, {
    "inetmax",
    Player.citizenid,
    Msg.InetMax.EmailSubject,
    string.format(Msg.InetMax.EmailBody, body.total, Config.App.InetMax.TopupRate.Price,
      Config.App.InetMax.TopupRate.InKB, "Success"),
  })

  return IncrementBalance
end)

local function UseInternetData(citizenid, app, totalInKB)
  if not shouldTrackData() then return end

  MySQL.Async.insert(Q.InsertHistory, {
    citizenid,
    "USAGE",
    app,
    totalInKB
  })

  MySQL.Async.execute(Q.UpdateBalanceSubtract, {
    totalInKB,
    citizenid
  })
end

RegisterNetEvent('z-phone:server:usage-internet-data', function(app, usageInKB)
  local src = source
  if Config.App.InetMax.IsUseInetMax and shouldTrackData() then
    local Player = xCore.GetPlayerBySource(src)
    if Player == nil then return false end

    local citizenid = Player.citizenid
    UseInternetData(citizenid, app, usageInKB)

    TriggerClientEvent("z-phone:client:usage-internet-data", src, app, usageInKB)
  end
end)

if Config.Core == "ESX" then
  xCore = {}
  local ESX = exports["es_extended"]:getSharedObject()
  local ox_inventory = exports.ox_inventory

  local function splitName(fullname)
    if not fullname or fullname == '' then return '', '' end

    local first, last = fullname:match("^(%S+)%s+(.+)$")
    return first or fullname, last or ''
  end

  xCore.GetPlayerBySource = function(source)
    local ply = ESX.GetPlayerFromId(source)
    if not ply then return nil end

    local fullname = ply.getName()
    local first, last = splitName(fullname)

    return {
      source = ply.source,
      citizenid = ply.identifier,
      name = fullname,
      charinfo = {
        firstname = first,
        lastname = last
      },
      job = {
        name = ply.getJob().name,
        label = ply.getJob().label
      },
      money = {
        cash = ply.getAccount('money').money,
        bank = ply.getAccount('bank').money,
      },
      removeCash = function(amount)
        ply.removeMoney(amount)
      end,
      removeAccountMoney = function(account, amount, reason)
        ply.removeAccountMoney(account, amount)
      end,
      addAccountMoney = function(account, amount, reason)
        ply.addAccountMoney(account, amount)
      end
    }
  end

  xCore.GetPlayerByIdentifier = function(identifier)
    local ply = ESX.GetPlayerFromIdentifier(identifier)
    if not ply then return nil end

    local fullname = ply.getName()
    local first, last = splitName(fullname)

    return {
      source = ply.source,
      citizenid = ply.identifier,
      name = fullname,
      charinfo = {
        firstname = first,
        lastname = last
      },
      job = {
        name = ply.getJob().name,
        label = ply.getJob().label
      },
      money = {
        cash = ply.getAccount('money').money,
        bank = ply.getAccount('bank').money,
      },
      removeCash = function(amount)
        ply.removeMoney(amount)
      end,
      removeAccountMoney = function(account, amount, reason)
        ply.removeAccountMoney(account, amount)
      end,
      addAccountMoney = function(account, amount, reason)
        ply.addAccountMoney(account, amount)
      end
    }
  end

  xCore.HasItemByName = function(source, item)
    return ox_inventory:GetItem(source, item, nil, false).count >= 1
  end

  xCore.GetPlayersByJob = function(jobName)
    if not jobName then return {} end

    local players = {}
    local extendedPlayers = ESX.GetExtendedPlayers(function(player)
      return player.getJob().name == jobName
    end)

    for _, ply in pairs(extendedPlayers or {}) do
      local wrapped = xCore.GetPlayerBySource(ply.source)
      if wrapped then
        players[#players + 1] = wrapped
      end
    end

    return players
  end

  xCore.AddMoneyBankSociety = function(society, amount, reason)
    local accountName = ('society_%s'):format(society)

    if not amount or amount <= 0 then
      Log.Warn(('[billing] skip invalid amount for %s: %s'):format(accountName, tostring(amount)))
      return
    end

    TriggerEvent('esx_addonaccount:getSharedAccount', accountName, function(acc)
      if not acc then
        Log.Warn(('[billing] shared account not found: %s'):format(accountName))
        return
      end
      acc.addMoney(amount)
      Log.Info(('[billing] added %s to %s (reason=%s)'):format(amount, accountName, reason or 'n/a'))
    end)
  end

  xCore.queryPlayerVehicles = function()
    -- state
    -- 1 = Garaged
    -- 2 = Impound
    -- 3 = Outside
    -- defaukl = Outside

    -- ADJUST QUERY FROM YOUR TABLE VEHICLE
    local query = [[
            select
                "default" as vehicle,
                v.plate,
                v.parking as garage,
                100 as fuel,
                100 as engine,
                100 as body,
                v.stored as state,
                DATE_FORMAT(now(), '%d %b %Y %H:%i') as created_at
            from owned_vehicles v WHERE v.owner = ? order by plate asc
        ]]

    return query
  end

  xCore.queryPlayerHouses = function()
    -- ADJUST QUERY FROM YOUR TABLE HOUSING
    local query = [[
        SELECT
                hl.id,
                hl.name,
                0 as tier,
                null as coords,
                0 as is_has_garage,
                1 AS is_house_locked,
                1 AS is_garage_locked,
                1 AS is_stash_locked,
                '[]' as keyholders
            FROM
                datastore_data hl
            WHERE hl.owner = ? and hl.name = 'property'
            ORDER BY hl.id DESC
        ]]

    return query
  end

  xCore.bankHistories = function(citizenid)
    -- Map OMES banking transaction rows into wallet-friendly entries
    local query = [[
            SELECT
                CASE
                    WHEN bt.type IN ('withdrawal','transfer_out','fee','savings_withdrawal','admin_withdrawal','admin_cash_removal','admin_transfer_out','account_transfer') THEN 'withdraw'
                    ELSE 'deposit'
                END AS type,
                COALESCE(bt.description, bt.type) AS label,
                bt.amount AS total,
                DATE_FORMAT(bt.date, '%d/%m/%Y %H:%i') AS created_at
            FROM banking_transactions bt
            WHERE bt.identifier = ?
            ORDER BY bt.date DESC
            LIMIT 50
        ]]

    local histories = MySQL.query.await(query, { citizenid })
    if not histories then
      histories = {}
    end

    return histories
  end

  xCore.bankInvoices = function(citizenid)
    local idNoPrefix = citizenid:gsub('^license:', '')
    local query = [[
            select
                pi.id,
                pi.target as society,
                pi.label as reason,
                pi.amount,
                pi.sender as sendercitizenid,
                DATE_FORMAT(now(), '%d/%m/%Y %H:%i') as created_at
            from billing as pi
            where pi.identifier in (?, ?) order by pi.id desc
        ]]

    local bills = MySQL.query.await(query, { citizenid, idNoPrefix })
    if not bills then
      bills = {}
    end

    return bills
  end

  xCore.bankInvoiceByCitizenID = function(id, citizenid)
    local idNoPrefix = citizenid:gsub('^license:', '')
    local query = [[
            select pi.id, pi.amount, pi.label as reason, pi.target as society, pi.amount from billing pi WHERE pi.id = ? and pi.identifier in (?, ?) LIMIT 1
        ]]

    return MySQL.single.await(query, { id, citizenid, idNoPrefix })
  end

  xCore.deleteBankInvoiceByID = function(id)
    local query = [[
            DELETE FROM billing WHERE id = ?
        ]]

    MySQL.query(query, { id })
  end
end

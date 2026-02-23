Net = Net or {}

local function isDataUsageEnabled()
  return Config.App.InetMax.EnableDataUsage ~= false and Config.App.InetMax.IsUseInetMax ~= false
end


local function notify(from, message)
  TriggerEvent("z-phone:client:sendNotifInternal", {
    type = "Notification",
    from = from,
    message = message
  })
end

function Net.ensureSignal()
  if IsAllowToSendOrCall() then return true end
  notify(Config.App.InetMax.Name, Config.MsgSignalZone)
  return false
end

function Net.ensureData(requiredKb)
  if not isDataUsageEnabled() then
    return true
  end

  if not Profile or not Profile.inetmax_balance then
    notify(Config.App.InetMax.Name, Config.MsgNotEnoughInternetData)
    return false
  end

  if Profile.inetmax_balance < requiredKb then
    notify(Config.App.InetMax.Name, Config.MsgNotEnoughInternetData)
    return false
  end

  return true
end

function Net.consume(appName, usageKb)
  if not isDataUsageEnabled() then return end

  TriggerServerEvent("z-phone:server:usage-internet-data", appName, usageKb)
  if Profile and Profile.inetmax_balance then
    Profile.inetmax_balance = Profile.inetmax_balance - usageKb
  end
end

-- Ensure profile is loaded before using Profile.*. Invokes cb(profile).
function Net.ensureProfile(cb)
  if Profile and next(Profile) ~= nil then
    cb(Profile)
    return
  end

  lib.callback('z-phone:server:GetProfile', false, function(profile)
    Profile = profile or {}
    cb(Profile)
  end)
end

return Net

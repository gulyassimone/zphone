RegisterNUICallback('get-ads', function(_, cb)
  lib.callback('z-phone:server:GetAds', false, function(ads)
    cb(ads)
  end)
end)

RegisterNUICallback('send-ads', function(body, cb)
  if not Net.ensureSignal() then
    cb(false)
    return
  end

  Net.ensureProfile(function()
    if not Net.ensureData(Config.App.InetMax.InetMaxUsage.AdsPost) then
      cb(false)
      return
    end

    lib.callback('z-phone:server:SendAds', false, function(isOk)
      if isOk then
        Net.consume(Config.App.Ads.Name, Config.App.InetMax.InetMaxUsage.AdsPost)
      end
      lib.callback('z-phone:server:GetAds', false, function(ads)
        cb(ads)
      end)
    end, body)
  end)
end)

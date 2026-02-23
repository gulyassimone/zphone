RegisterNUICallback('get-internet-data', function(_, cb)
  lib.callback('z-phone:server:GetInternetData', false, function(result)
    cb(result)
  end)
end)

RegisterNUICallback('topup-internet-data', function(body, cb)
  if not Net.ensureSignal() then
    cb(false)
    return
  end

  lib.callback('z-phone:server:TopupInternetData', false, function(purchaseInKB)
    Profile.inetmax_balance = Profile.inetmax_balance + purchaseInKB
    cb(purchaseInKB)
  end, body)
end)

RegisterNetEvent('z-phone:client:usage-internet-data', function(app, usageInKB)
  Profile.inetmax_balance = Profile.inetmax_balance - usageInKB
end)

RegisterNUICallback('get-services', function(_, cb)
  lib.callback('z-phone:server:GetServiceJobs', false, function(services)
    local list = {}

    for _, v in ipairs(services or {}) do
      list[#list + 1] = {
        logo = 'https://raw.githubusercontent.com/alfaben12/kmrp-assets/main/logo/business/goverment.png',
        service = v.label or v.name,
        job = v.name,
        type = v.type or 'General',
      }
    end

    lib.callback('z-phone:server:GetServices', false, function(messages)
      cb({ list = list, reports = messages })
    end)
  end)
end)

RegisterNUICallback('send-message-service', function(body, cb)
  if not Net.ensureSignal() then
    cb(false)
    return
  end
  if not Net.ensureData(Config.App.InetMax.InetMaxUsage.ServicesMessage) then
    cb(false)
    return
  end

  lib.callback('z-phone:server:SendMessageService', false, function(isOk)
    if isOk then
      Net.consume(Config.App.Services.Name, Config.App.InetMax.InetMaxUsage.ServicesMessage)
    end
    cb(isOk)
  end, body)
end)

RegisterNUICallback('solved-message-service', function(body, cb)
  lib.callback('z-phone:server:SolvedMessageService', false, function(isOk)
    cb(isOk)
  end, body)
end)

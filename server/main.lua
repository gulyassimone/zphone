local WebHook =
'https://discord.com/api/webhooks/1474789584914219180/ENA5YxY9GcB-9580lJ119sw3-y_TfQ3n4OkYkFiv7vjsCP3fXKnEAKuD_xYLev_lHe-8'

lib.callback.register('z-phone:server:HasPhone', function(source)
  return xCore.HasItemByName(source, 'phone')
end)

lib.callback.register('z-phone:server:GetWebhook', function(_)
  if WebHook ~= '' then
    return WebHook
  else
    print(
      'Set your webhook to ensure that your camera will work!!!!!! Set this on line 10 of the server sided script!!!!!')
    return nil
  end
end)

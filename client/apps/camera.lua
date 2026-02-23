local frontCam = false

local function SaveToInternalGallery()
  BeginTakeHighQualityPhoto()
  SaveHighQualityPhoto(0)
  FreeMemoryForHighQualityPhoto()
end

local function CellFrontCamActivate(activate)
  return Citizen.InvokeNative(0x2491A93618B7D838, activate)
end

RegisterNUICallback('TakePhoto', function(_, cb)
  -- SendNUIMessage({
  --     event = 'z-phone',
  --     isOpen = false,
  -- })

  SetNuiFocus(false, false)
  CreateMobilePhone(1)
  CellCamActivate(true, true)
  local takePhoto = true

  while takePhoto do
    if IsControlJustPressed(1, 27) then -- Toggle front/back
      frontCam = not frontCam
      CellFrontCamActivate(frontCam)
    elseif IsControlJustPressed(1, 177) then -- Cancel
      DestroyMobilePhone()
      CellCamActivate(false, false)
      cb(nil)
      takePhoto = false
    elseif IsControlJustPressed(1, 176) then -- Take pic
      pcall(PlaySoundFrontend, -1, "Camera_Shoot", "Phone_SoundSet_Default", false)
      lib.callback('z-phone:server:GetWebhook', false, function(hook)
        if not hook then
          xCore.Notify('Camera not setup', 'error', 3000)
          Log.Debug('[camera] missing webhook, abort')
          return
        end

        local state = GetResourceState('screenshot-basic')
        local hasExport = exports['screenshot-basic'] and exports['screenshot-basic'].requestScreenshotUpload ~= nil
        Log.Debug(string.format('[camera] webhook=%s state=%s hasExport=%s', tostring(hook), tostring(state),
          tostring(hasExport)))

        if state ~= 'started' or not hasExport then
          xCore.Notify('Screenshot service unavailable', 'error', 4000)
          Log.Debug(string.format('[camera] screenshot-basic not ready (state=%s, hasExport=%s)', tostring(state),
            tostring(hasExport)))
          DestroyMobilePhone()
          CellCamActivate(false, false)
          cb(nil)
          takePhoto = false
          return
        end

        local okCall, err = pcall(function()
          exports['screenshot-basic']:requestScreenshotUpload(tostring(hook), 'files[]', function(data)
            Log.Debug(string.format('[camera] upload callback payload len=%s', data and #data or 'nil'))
            if data then
              local head = data:sub(1, 160)
              Log.Debug(string.format('[camera] upload payload head=%s', head))
            end

            SaveToInternalGallery()
            local ok, image = pcall(json.decode, data)
            if not ok or not image or not image.attachments or not image.attachments[1] then
              Log.Debug(string.format('[camera] failed to decode image response: %s', tostring(data)))
              xCore.Notify('Upload failed', 'error', 4000)
              DestroyMobilePhone()
              CellCamActivate(false, false)
              cb(nil)
              takePhoto = false
              return
            end

            local url = image.attachments[1].proxy_url
            Log.Debug(string.format('[camera] photo stored at %s', tostring(url)))
            DestroyMobilePhone()
            CellCamActivate(false, false)
            cb(url)
            takePhoto = false
          end)
        end)

        if not okCall then
          Log.Debug(string.format('[camera] export call failed: %s', tostring(err)))
          xCore.Notify('Screenshot export missing', 'error', 4000)
          DestroyMobilePhone()
          CellCamActivate(false, false)
          cb(nil)
          takePhoto = false
        end
      end)
    end

    HideHudComponentThisFrame(7)
    HideHudComponentThisFrame(8)
    HideHudComponentThisFrame(9)
    HideHudComponentThisFrame(6)
    HideHudComponentThisFrame(19)
    HideHudAndRadarThisFrame()
    EnableAllControlActions(0)
    Wait(0)
  end

  Wait(1000)
  -- OpenPhone()
  SetNuiFocus(true, true)
  if not PhoneData.CallData.InCall then
    DoPhoneAnimation('cellphone_text_in')
  else
    DoPhoneAnimation('cellphone_call_to_text')
  end
end)

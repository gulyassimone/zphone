Sound = Sound or {}

function Sound.playFrontend(soundName, soundSet)
  PlaySoundFrontend(-1, soundName, soundSet or 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
end

function Sound.playInteract(soundName, volume)
  TriggerServerEvent('InteractSound_SV:PlayOnSource', soundName, volume or 0.3)
end

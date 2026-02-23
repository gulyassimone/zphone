local phoneProp = 0
local phoneModel = `prop_amb_phone`
local phoneModels = {
  `prop_amb_phone`,
  `prop_cs_phone_01`,
}

local function DeleteObjectSafe(entity)
  if entity == 0 then return end
  if not NetworkHasControlOfEntity(entity) then
    NetworkRequestControlOfEntity(entity)
    local tries = 0
    while tries < 10 and not NetworkHasControlOfEntity(entity) do
      Wait(0)
      tries = tries + 1
    end
  end
  SetEntityAsMissionEntity(entity, true, true)
  DeleteObject(entity)
  DeleteEntity(entity)
end

-- Load an animation dictionary and wait until it is ready.
function LoadAnimation(dict)
  RequestAnimDict(dict)
  while not HasAnimDictLoaded(dict) do
    Wait(1)
  end
end

-- Keep the current phone anim playing; if it stops, restart it.
local function CheckAnimLoop()
  CreateThread(function()
    while PhoneData.AnimationData.lib ~= nil and PhoneData.AnimationData.anim ~= nil do
      local ped = PlayerPedId()
      if not IsEntityPlayingAnim(ped, PhoneData.AnimationData.lib, PhoneData.AnimationData.anim, 3) then
        LoadAnimation(PhoneData.AnimationData.lib)
        TaskPlayAnim(ped, PhoneData.AnimationData.lib, PhoneData.AnimationData.anim, 3.0, 3.0, -1, 50, 0, false, false,
          false)
      end
      Wait(500)
    end
  end)
end

-- Spawn a phone prop and attach it to the player's hand.
function NewPhoneProp()
  DeletePhone()
  DeleteNearbyPhoneProps(5.0)
  RequestModel(phoneModel)
  while not HasModelLoaded(phoneModel) do
    Wait(1)
  end
  phoneProp = CreateObject(phoneModel, 1.0, 1.0, 1.0, 1, 1, 0)

  local bone = GetPedBoneIndex(PlayerPedId(), 28422)
  if phoneModel == `prop_cs_phone_01` then
    AttachEntityToEntity(phoneProp, PlayerPedId(), bone, 0.0, 0.0, 0.0, 50.0, 320.0, 50.0, 1, 1, 0, 0, 2, 1)
  else
    AttachEntityToEntity(phoneProp, PlayerPedId(), bone, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, 1, 0, 0, 2, 1)
  end
end

-- Remove the spawned phone prop if it exists.
function DeletePhone()
  if phoneProp ~= 0 then
    DeleteObjectSafe(phoneProp)
    phoneProp = 0
  end
end

-- Remove stray phone props near the player to prevent duplicates.
function DeleteNearbyPhoneProps(radius)
  local pos = GetEntityCoords(PlayerPedId(), false)
  for _, model in ipairs(phoneModels) do
    local tries = 0
    while tries < 5 do
      local object = GetClosestObjectOfType(pos.x, pos.y, pos.z, radius, model, false, false, false)
      if object ~= 0 then
        DeleteObjectSafe(object)
      else
        break
      end
      tries = tries + 1
      Wait(0)
    end
  end
end

-- Clean up if the resource stops to avoid stuck props.
AddEventHandler('onResourceStop', function(res)
  if res ~= GetCurrentResourceName() then return end
  DeleteNearbyPhoneProps(10.0)
  DeletePhone()
end)

-- Best-effort cleanup in case a previous restart left phones attached.
CreateThread(function()
  Wait(500)
  DeleteNearbyPhoneProps(15.0)
end)

-- Play a phone animation (in-car variant if seated) and track it for auto-replay.
function DoPhoneAnimation(anim)
  local ped = PlayerPedId()
  local AnimationLib = 'cellphone@'
  local AnimationStatus = anim
  if IsPedInAnyVehicle(ped, false) then
    AnimationLib = 'anim@cellphone@in_car@ps'
  end
  LoadAnimation(AnimationLib)
  TaskPlayAnim(ped, AnimationLib, AnimationStatus, 3.0, 3.0, -1, 50, 0, false, false, false)
  PhoneData.AnimationData.lib = AnimationLib
  PhoneData.AnimationData.anim = AnimationStatus
  CheckAnimLoop()
end

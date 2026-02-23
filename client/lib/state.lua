local function applyDefaults()
  local defaults = Shared.Types.PhoneDataDefaults
  PhoneData.SignalZone = defaults.SignalZone
  PhoneData.MetaData = {}
  PhoneData.isOpen = false
  PhoneData.PlayerData = nil
  PhoneData.AnimationData = {
    lib = nil,
    anim = nil,
  }
  PhoneData.CallData = {
    InCall = false,
    CallId = nil,
    AnsweredCall = false,
  }
end

PlayerJob = PlayerJob or {}
Profile = Profile or {}
PhoneData = PhoneData or {}
applyDefaults()

function ResetPhoneState()
  applyDefaults()
end

Shared = Shared or {}
Shared.Types = Shared.Types or {}

-- Default client-side phone state; kept here for a single source of truth
Shared.Types.PhoneDataDefaults = {
  SignalZone = Config.Signal.DefaultSignalZones,
  MetaData = {},
  isOpen = false,
  PlayerData = nil,
  AnimationData = {
    lib = nil,
    anim = nil,
  },
  CallData = {
    InCall = false,
    CallId = nil,
    AnsweredCall = false,
  },
}

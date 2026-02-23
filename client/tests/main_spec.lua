local Assert = require('client.tests.runner').Assert
local natives = require('client.tests.mocks.natives')
local libMock = require('client.tests.mocks.lib')
local xCoreMock = require('client.tests.mocks.xcore')

natives.install()

_G.Config = {
  OpenPhone = 'K',
  Signal = {
    DefaultSignalZones = 'none'
  }
}

_G.Shared = {
  Constants = {
    NuiEvent = 'z-phone',
    Commands = {
      OpenPhone = 'phone'
    }
  },
  Events = {
    GetProfile = 'z-phone:server:GetProfile',
    HasPhone = 'z-phone:server:HasPhone'
  },
  Types = {
    PhoneDataDefaults = {
      SignalZone = 'none'
    }
  }
}

_G.lib = libMock
_G.xCore = xCoreMock

require('client.lib.state')
require('client.lib.nui')
require('client.main')

local closeCallback = natives.state.nuiCallbacks['close']

local function resetState()
  natives.reset()
  libMock.reset()
  xCoreMock.reset()
  natives.state.nuiCallbacks['close'] = closeCallback
  ResetPhoneState()
end

describe('ResetPhoneState', function()
  it('resets phone data to defaults', function()
    PhoneData.SignalZone = 'custom'
    PhoneData.isOpen = true
    PhoneData.CallData.InCall = true
    PhoneData.PlayerData = { foo = 'bar' }

    ResetPhoneState()

    Assert.equals('none', PhoneData.SignalZone)
    Assert.is_false(PhoneData.isOpen)
    Assert.is_false(PhoneData.CallData.InCall)
    Assert.is_nil(PhoneData.PlayerData)
  end)
end)

describe('OpenPhone', function()
  before_each(function()
    resetState()
  end)

  it('opens phone when player has phone and is unarmed', function()
    libMock.__setHasPhone(true)
    natives.setWeapon('WEAPON_UNARMED')

    OpenPhone()

    Assert.is_true(PhoneData.isOpen)
    Assert.equals('z-phone', natives.state.lastNui.event)
    Assert.is_true(natives.state.focus)
  end)

  it('blocks opening when player has no phone item', function()
    libMock.__setHasPhone(false)
    natives.setWeapon('WEAPON_UNARMED')

    OpenPhone()

    Assert.is_false(PhoneData.isOpen)
    Assert.is_nil(natives.state.lastNui)
    Assert.equals('You don\'t have a phone', xCoreMock.notifyLog[1] and xCoreMock.notifyLog[1].msg or nil)
  end)

  it('blocks opening when player is armed', function()
    libMock.__setHasPhone(true)
    natives.setWeapon('WEAPON_PISTOL')

    OpenPhone()

    Assert.is_false(PhoneData.isOpen)
    Assert.equals('Cannot open phone!', xCoreMock.notifyLog[1] and xCoreMock.notifyLog[1].msg or nil)
  end)
end)

describe('NUI close callback', function()
  before_each(function()
    resetState()
    libMock.__setHasPhone(true)
    natives.setWeapon('WEAPON_UNARMED')
    OpenPhone()
    Assert.is_true(PhoneData.isOpen)
  end)

  it('clears focus, animation and state', function()
    natives.triggerNui('close')

    Assert.is_false(PhoneData.isOpen)
    Assert.is_false(natives.state.focus)
    Assert.is_false(natives.state.cursor)
    Assert.is_nil(PhoneData.AnimationData.lib)
    Assert.is_nil(PhoneData.AnimationData.anim)
  end)
end)

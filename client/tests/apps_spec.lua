local Assert = require('client.tests.runner').Assert
local natives = require('client.tests.mocks.natives')

-- Shared test scaffolding
local handlers = {}
local serverEvents = {}
local clientEvents = {}

Log = Log or {
  Debug = function(...) end,
  Info = function(...) end,
  Warn = function(...) end,
}

local existingRegisterNUICallback = RegisterNUICallback
function RegisterNUICallback(name, fn)
  handlers[name] = fn
  if existingRegisterNUICallback then existingRegisterNUICallback(name, fn) end
end

local function TriggerEvent(name, payload)
  clientEvents[#clientEvents + 1] = { name = name, payload = payload }
end

local function TriggerServerEvent(name, ...)
  serverEvents[#serverEvents + 1] = { name = name, args = { ... } }
end

-- Minimal globals
Config = Config or {}
Config.Debug = Config.Debug or false
Config.MsgSignalZone = Config.MsgSignalZone or 'no signal'
Config.MsgNotEnoughInternetData = Config.MsgNotEnoughInternetData or 'no data'
Config.CallRepeats = Config.CallRepeats or 0
Config.RepeatTimeout = Config.RepeatTimeout or 0
Config.App = Config.App or {}
Config.App.InetMax = Config.App.InetMax or { Name = 'Inet', InetMaxUsage = {} }
Config.App.InetMax.InetMaxUsage = Config.App.InetMax.InetMaxUsage or {}
Config.App.InetMax.InetMaxUsage.AdsPost = Config.App.InetMax.InetMaxUsage.AdsPost or 5
Config.App.InetMax.InetMaxUsage.BankTransfer = Config.App.InetMax.InetMaxUsage.BankTransfer or 5
Config.App.InetMax.InetMaxUsage.BankCheckTransferReceiver = Config.App.InetMax.InetMaxUsage.BankCheckTransferReceiver or
2
Config.App.InetMax.InetMaxUsage.MessageSend = Config.App.InetMax.InetMaxUsage.MessageSend or 1
Config.App.InetMax.InetMaxUsage.LoopsPostTweet = Config.App.InetMax.InetMaxUsage.LoopsPostTweet or 3
Config.App.InetMax.InetMaxUsage.LoopsPostComment = Config.App.InetMax.InetMaxUsage.LoopsPostComment or 2
Config.App.InetMax.InetMaxUsage.ServicesMessage = Config.App.InetMax.InetMaxUsage.ServicesMessage or 1
Config.App.Ads = Config.App.Ads or { Name = 'Ads' }
Config.App.Wallet = Config.App.Wallet or { Name = 'Wallet' }
Config.App.Message = Config.App.Message or { Name = 'Message' }
Config.App.Loops = Config.App.Loops or { Name = 'Loops' }
Config.App.Services = Config.App.Services or { Name = 'Services' }
Config.App.Camera = Config.App.Camera or { Name = 'Camera' }
Config.Services = Config.Services or { gov = { name = 'Gov', job = 'police', type = 'public' } }

Shared = Shared or { Events = {}, Constants = { NuiEvent = 'z-phone' } }
Shared.Types = Shared.Types or { PhoneDataDefaults = { SignalZone = 'none' } }

Profile = { inetmax_balance = 10, phone_number = '555', is_anonim = false }
PhoneData = PhoneData or { CallData = { InCall = false, AnsweredCall = false }, AnimationData = {} }

-- Net stub
Net = {
  ensureSignalCalled = 0,
  ensureDataCalled = 0,
  consumed = {},
}

function Net.ensureSignal()
  Net.ensureSignalCalled = Net.ensureSignalCalled + 1
  return true
end

function Net.ensureData(amount)
  Net.ensureDataCalled = Net.ensureDataCalled + 1
  if not Profile or not Profile.inetmax_balance then
    Profile.inetmax_balance = 10
  end
  return Profile.inetmax_balance >= amount
end

function Net.consume(app, amount)
  Net.consumed[#Net.consumed + 1] = { app = app, amount = amount }
  Profile.inetmax_balance = Profile.inetmax_balance - amount
end

function Net.ensureProfile(cb)
  if not Profile.inetmax_balance then
    Profile.inetmax_balance = 10
  end
  cb(Profile)
end

-- lib.callback stub with simple dispatcher
local testLib = {
  callback = function(name, _, cb, body)
    if name == 'z-phone:server:GetAds' then
      cb({ { id = 1 } })
    elseif name == 'z-phone:server:SendAds' then
      cb(true)
    elseif name == 'z-phone:server:GetBank' then
      cb({ balance = 100 })
    elseif name == 'z-phone:server:TransferCheck' or name == 'z-phone:server:Transfer' then
      cb(true)
    elseif name == 'z-phone:server:GetProfile' then
      cb(Profile)
    elseif name == 'z-phone:server:GetContacts' then
      cb({})
    elseif name == 'z-phone:server:GetEmails' then
      cb({ { institution = 'gov' } })
    elseif name == 'z-phone:server:GetPhotos' then
      cb({ { id = 1, url = 'x' } })
    elseif name == 'z-phone:server:SavePhotos' then
      cb(true)
    elseif name == 'z-phone:server:SendMessageService' then
      cb(true)
    elseif name == 'z-phone:server:GetProfile' then
      cb(Profile)
    elseif name == 'z-phone:server:UpdateProfile' then
      if body then Profile.name = body.name end
      cb(true)
    elseif name == 'z-phone:server:StartCall' then
      cb({ is_valid = true, message = 'ok', to_source = 2 })
    elseif name == 'z-phone:server:GetCallHistories' then
      cb({})
    elseif name == 'z-phone:server:GetWebhook' then
      cb('https://webhook')
    else
      cb(true)
    end
  end
}

-- Misc stubs used by app files
function IsAllowToSendOrCall() return true end

function GetStreetName() return 'Main St' end

function GetSoundId() return 1 end

function ReleaseSoundId(_) end

function StopSound(_) end

function PlaySoundFrontend(...) end

function DoPhoneAnimation(_) end

function Wait(_) end

function SetNuiFocus() end

function CreateMobilePhone() end

function CellCamActivate() end

function IsControlJustPressed(_, control)
  -- Simulate immediate cancel for camera (control 177)
  return control == 177
end

Rpc = Rpc or {}
function Rpc.call(name, body, cb)
  if name == 'z-phone:server:GetBank' then
    cb({ balance = 100 })
  elseif name == 'z-phone:server:PayInvoice' then
    cb(true)
  elseif name == 'z-phone:server:TransferCheck' then
    cb({ ok = true })
  elseif name == 'z-phone:server:Transfer' then
    cb(true)
  else
    cb(true)
  end
end

function DestroyMobilePhone() end

function CellFrontCamActivate(_) end

function GetResourceState(_) return 'started' end

exports = { ['screenshot-basic'] = { requestScreenshotUpload = function(_, _, cb) cb(
  '{"attachments":[{"proxy_url":"url"}]}') end } }
function pcall(fn, ...) return true, fn(...) end

json = {
  decode = function(_) return { attachments = { { proxy_url = 'url' } } } end,
  encode = function(tbl) return tostring(tbl) end,
}
function HideHudComponentThisFrame(_) end

function HideHudAndRadarThisFrame() end

function EnableAllControlActions(_) end

local testXCore = {
  Notify = function() end,
  HasItemByName = function() return true end,
  GetClosestPlayer = function() return 1, 1.0 end,
}
function PlayerPedId() return 1 end

function GetEntitySpeed(_) return 0 end

function IsPedRagdoll(_) return false end

function GetPlayerServerId(_) return 5 end

function GetEntityCoords() return { x = 0, y = 0, z = 0 } end

function SetTimeout(_, cb) cb() end

function GetCurrentPedWeapon() return true, 'WEAPON_UNARMED' end

function GetHashKey(name) return name end

function GenerateCallId()
  return 16
end

local function testSendNUIMessage(payload)
  if natives and natives.state then
    natives.state.lastNui = payload
  end
end
function RegisterKeyMapping() end

function RegisterCommand(_, _) end

-- Load app modules (registers callbacks into handlers)
require('client.lib.nui')
require('client.lib.state')
require('client.apps.ads')
require('client.apps.bank')
require('client.apps.calls')
require('client.apps.camera')
require('client.apps.contact')
require('client.apps.emails')
require('client.apps.chat')
require('client.apps.loops')
require('client.apps.photos')
require('client.apps.services')
require('client.apps.profile')

local function callNui(name, payload)
  Assert.is_true(handlers[name] ~= nil, 'callback ' .. name .. ' not registered')
  local result
  local function run()
    -- Re-assert required config defaults in case later requires overwrote them
    Config.App = Config.App or {}
    Config.App.InetMax = Config.App.InetMax or { Name = 'Inet', InetMaxUsage = {} }
    Config.App.InetMax.InetMaxUsage = Config.App.InetMax.InetMaxUsage or {}
    Config.App.InetMax.InetMaxUsage.AdsPost = Config.App.InetMax.InetMaxUsage.AdsPost or 5
    Config.App.InetMax.InetMaxUsage.BankTransfer = Config.App.InetMax.InetMaxUsage.BankTransfer or 5
    Config.App.InetMax.InetMaxUsage.BankCheckTransferReceiver = Config.App.InetMax.InetMaxUsage
    .BankCheckTransferReceiver or 2
    Config.App.InetMax.InetMaxUsage.MessageSend = Config.App.InetMax.InetMaxUsage.MessageSend or 1
    Config.App.InetMax.InetMaxUsage.LoopsPostTweet = Config.App.InetMax.InetMaxUsage.LoopsPostTweet or 3
    Config.App.InetMax.InetMaxUsage.LoopsPostComment = Config.App.InetMax.InetMaxUsage.LoopsPostComment or 2
    Config.App.InetMax.InetMaxUsage.ServicesMessage = Config.App.InetMax.InetMaxUsage.ServicesMessage or 1
    Config.App.InetMax.InetMaxUsage.PhoneCall = Config.App.InetMax.InetMaxUsage.PhoneCall or 1
    Config.App.Ads = Config.App.Ads or { Name = 'Ads' }
    Config.App.Wallet = Config.App.Wallet or { Name = 'Wallet' }
    Config.App.Message = Config.App.Message or { Name = 'Message' }
    Config.App.Loops = Config.App.Loops or { Name = 'Loops' }
    Config.App.Services = Config.App.Services or { Name = 'Services' }
    Config.Services = Config.Services or { gov = { name = 'Gov', job = 'police', type = 'public' } }
    Config.CallRepeats = Config.CallRepeats or 0
    Config.RepeatTimeout = Config.RepeatTimeout or 0
    Profile.inetmax_balance = Profile.inetmax_balance or 10

    handlers[name](payload, function(res)
      if result == nil then
        result = res
      end
    end)
  end
  -- Temporarily swap in test env so other specs keep their mocks
  local savedLib, savedXCore, savedSend, savedTrigEvt, savedTrigSrv = _G.lib, _G.xCore, _G.SendNUIMessage,
      _G.TriggerEvent, _G.TriggerServerEvent
  _G.lib = testLib
  _G.xCore = testXCore
  _G.SendNUIMessage = testSendNUIMessage
  _G.TriggerEvent = TriggerEvent
  _G.TriggerServerEvent = TriggerServerEvent
  run()
  _G.lib = savedLib
  _G.xCore = savedXCore
  _G.SendNUIMessage = savedSend
  _G.TriggerEvent = savedTrigEvt
  _G.TriggerServerEvent = savedTrigSrv
  return result
end

describe('ads app', function()
  before_each(function()
    Net.ensureSignalCalled = 0
    Net.ensureDataCalled = 0
    Net.consumed = {}
    Profile.inetmax_balance = 10
  end)

  it('blocks when no data', function()
    Profile.inetmax_balance = 0
    local res = callNui('send-ads', { text = 'x' })
    Assert.is_false(res)
  end)

  it('consumes data on success', function()
    local res = callNui('send-ads', { text = 'x' })
    Assert.equals(1, #Net.consumed)
    Assert.equals(Config.App.Ads.Name, Net.consumed[1].app)
    Assert.equals(Config.App.InetMax.InetMaxUsage.AdsPost, Net.consumed[1].amount)
    Assert.equals(5, Profile.inetmax_balance)
    Assert.is_true(res ~= false)
  end)
end)

describe('bank app', function()
  before_each(function()
    Net.consumed = {}
    Profile.inetmax_balance = 10
  end)

  it('transfer-check consumes data', function()
    local res = callNui('transfer-check', { iban = 'abc' })
    Assert.equals(Config.App.Wallet.Name, Net.consumed[1].app)
    Assert.equals(Config.App.InetMax.InetMaxUsage.BankCheckTransferReceiver, Net.consumed[1].amount)
    Assert.is_true(res ~= false)
  end)

  it('transfer consumes data', function()
    local res = callNui('transfer', { iban = 'abc', total = 1 })
    Assert.equals(Config.App.Wallet.Name, Net.consumed[1].app)
    Assert.equals(Config.App.InetMax.InetMaxUsage.BankTransfer, Net.consumed[1].amount)
    Assert.is_true(res ~= false)
  end)
end)

describe('chat app', function()
  before_each(function()
    Net.consumed = {}
    Profile.inetmax_balance = 10
  end)

  it('send-chatting consumes data on success', function()
    local res = callNui('send-chatting', { msg = 'hi' })
    Assert.equals(Config.App.Message.Name, Net.consumed[1].app)
    Assert.equals(Config.App.InetMax.InetMaxUsage.MessageSend, Net.consumed[1].amount)
    Assert.is_true(res ~= false)
  end)
end)

describe('loops app', function()
  before_each(function()
    Net.consumed = {}
    Profile.inetmax_balance = 10
  end)

  it('send-tweet consumes data on success', function()
    local tweets = callNui('send-tweet', { body = 'hi' })
    Assert.equals(Config.App.Loops.Name, Net.consumed[1].app)
    Assert.equals(Config.App.InetMax.InetMaxUsage.LoopsPostTweet, Net.consumed[1].amount)
    Assert.is_true(tweets ~= false)
  end)

  it('send-tweet-comments consumes data on success', function()
    local ok = callNui('send-tweet-comments', { body = 'hi' })
    Assert.equals(Config.App.Loops.Name, Net.consumed[1].app)
    Assert.equals(Config.App.InetMax.InetMaxUsage.LoopsPostComment, Net.consumed[1].amount)
    Assert.is_true(ok ~= false)
  end)
end)

describe('services app', function()
  before_each(function()
    Net.consumed = {}
    Profile.inetmax_balance = 10
  end)

  it('send-message-service consumes data on success', function()
    local ok = callNui('send-message-service', { body = 'help' })
    Assert.equals(Config.App.Services.Name, Net.consumed[1].app)
    Assert.equals(Config.App.InetMax.InetMaxUsage.ServicesMessage, Net.consumed[1].amount)
    Assert.is_true(ok ~= false)
  end)
end)

describe('photos app', function()
  it('save-photos returns true', function()
    local ok = callNui('save-photos', { url = 'x' })
    Assert.is_true(ok)
  end)
end)

describe('emails app', function()
  it('get-emails decorates avatars', function()
    local emails = callNui('get-emails')
    Assert.equals('https://raw.githubusercontent.com/alfaben12/kmrp-assets/main/logo/business/gov.png', emails[1].avatar)
  end)
end)

describe('profile app', function()
  it('update-profile refreshes Profile', function()
    Profile.name = 'old'
    local newProf = callNui('update-profile', { name = 'new' })
    Assert.equals('new', newProf.name)
  end)
end)

describe('camera app', function()
  it('TakePhoto cancels cleanly', function()
    local res = callNui('TakePhoto')
    Assert.is_nil(res)
  end)
end)

describe('calls app', function()
  it('start-call marks InCall', function()
    PhoneData.CallData.InCall = false
    PhoneData.CallData.AnsweredCall = false
    local res = callNui('start-call', { to_phone_number = '999' })
    Assert.is_true(res and res.is_valid)
  end)
end)

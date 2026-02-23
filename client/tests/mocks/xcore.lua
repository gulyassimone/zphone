local M = {
  notifyLog = {},
  playerData = { citizenid = 'cid-1' }
}

function M.GetPlayerData()
  return M.playerData
end

function M.Notify(msg, typ, time)
  M.notifyLog[#M.notifyLog + 1] = { msg = msg, typ = typ, time = time }
end

function M.reset()
  M.notifyLog = {}
end

return M

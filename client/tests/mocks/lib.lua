local M = {
  hasPhone = true,
  profile = { phone_number = '555-0001' },
  calls = {}
}

function M.__setHasPhone(val)
  M.hasPhone = val
end

function M.__setProfile(tbl)
  M.profile = tbl
end

function M.callback(name, _, cb)
  M.calls[#M.calls + 1] = name
  if name == Shared.Events.HasPhone then
    cb(M.hasPhone)
  elseif name == Shared.Events.GetProfile then
    cb(M.profile)
  else
    cb(nil)
  end
end

function M.reset()
  M.calls = {}
end

return M

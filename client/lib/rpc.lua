Rpc = Rpc or {}

function Rpc.call(name, args, cb)
  lib.callback(name, false, function(result)
    cb(result)
  end, args)
end

return Rpc

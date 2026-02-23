local runner = { suites = {}, current = nil }

local function fail(msg)
  error(msg, 2)
end

local function fmt(val)
  if type(val) == 'table' then
    local parts = {}
    for k, v in pairs(val) do
      parts[#parts + 1] = tostring(k) .. '=' .. tostring(v)
    end
    return '{' .. table.concat(parts, ',') .. '}'
  end
  return tostring(val)
end

local Assert = {}
function Assert.equals(a, b, msg)
  if a ~= b then fail(msg or ('expected ' .. fmt(b) .. ', got ' .. fmt(a))) end
end
function Assert.is_true(v, msg)
  if not v then fail(msg or 'expected true') end
end
function Assert.is_false(v, msg)
  if v then fail(msg or 'expected false') end
end
function Assert.is_nil(v, msg)
  if v ~= nil then fail(msg or 'expected nil') end
end

function describe(name, fn)
  local suite = { name = name, tests = {}, before_each = nil, after_each = nil }
  runner.suites[#runner.suites + 1] = suite
  runner.current = suite
  fn()
  runner.current = nil
end

function it(name, fn)
  runner.current.tests[#runner.current.tests + 1] = { name = name, fn = fn }
end

function before_each(fn)
  runner.current.before_each = fn
end

function after_each(fn)
  runner.current.after_each = fn
end

function runner.run()
  local passed, failed = 0, 0
  for _, suite in ipairs(runner.suites) do
    for _, test in ipairs(suite.tests) do
      local ok, err = pcall(function()
        if suite.before_each then suite.before_each() end
        test.fn()
        if suite.after_each then suite.after_each() end
      end)
      if ok then
        passed = passed + 1
      else
        failed = failed + 1
        print(string.format('[FAIL] %s / %s -> %s', suite.name, test.name, err))
      end
    end
  end
  print(string.format('Tests: %d passed, %d failed', passed, failed))
  if failed > 0 then os.exit(1) end
end

return {
  run = runner.run,
  Assert = Assert,
}

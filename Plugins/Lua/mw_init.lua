function _MWScriptInit ()
  __MWReturnBuffer = nil

  if not pcall(_putAccount) then
    username = ""
    password = ""
  end
end

function _putAccount ()
  local c = arg.linkable:config()
  local accountKey = c:objectAtPath(configPath("SelectedAccount"))
  username = c:objectAtPath(configPath("Accounts", accountKey, "username"))
  password = c:objectAtPath(configPath("Accounts", accountKey, "password"))
end

function _MWScriptReturnBuffer ()
  return __MWReturnBuffer
end

function send (msg, link)
  if arg._MWScriptResultHint == "return" then
    if __MWReturnBuffer then
      __MWReturnBuffer = __MWReturnBuffer .. "\n" .. msg
    else
      __MWReturnBuffer = msg
    end
  elseif arg._MWScriptResultHint == "outward" then
    if type(msg) == "string" then
      msg = new_lineString(msg)
    end
    if not link then
      link = "outward"
    end
    arg.linkable:link_send(msg, link)
  else
    error("unrecognized value of _MWScriptResultHint")
  end
end

function message (str)
  arg.linkable:link_send(new_lineString(str, "MWLocalRole"), "inward")
end

function playSound (str)
  arg.linkable:link_send(soundNamed(str), "inward")
end

local pinnedNames = { "dotfiles", "socials", "support" }

local function orderSessions()
  local position = 1
  for _, name in ipairs(pinnedNames) do
    local sessions, err = rex.call("session.list")
    if not sessions then rex.log(err); return end
    for index, session in ipairs(sessions.sessions) do
      if session.label == name then
        if index ~= position then
          local result, moveErr = rex.call("session.move", {
            session_id = session.session_id,
            before_session_id = sessions.sessions[position].session_id,
          })
          if not result then rex.log(moveErr) end
        end
        position = position + 1
        break
      end
    end
  end
end

local function sync(sessionId)
  local view, err = rex.session.view{session_id = sessionId}
  if not view then
    rex.log(err)
    return
  end
  for _, name in ipairs(pinnedNames) do
    if view.label == name then return end
  end
  local window = (view.windows or {})[1]
  if not window then return end

  local label = window.label or ""
  if label == "" or label:match("^Window %x+$") then
    if not window.focused_block_id then return end
    local title, titleErr = rex.block.call("com.superlogical.terminal", "title", {
      session_id = sessionId,
      block_id = window.focused_block_id,
    })
    if not title then
      rex.log(titleErr)
      return
    end
    label = title.title
  end

  -- Braille animation frames are three-byte UTF-8 characters in U+2800–U+28FF.
  label = label:gsub("^%s*\226[\160-\163][\128-\191]%s*", "")
    :gsub("%s+| zupo%s*$", "")
    :gsub("%c", "")
    :match("^%s*(.-)%s*$")
  local characters = {}
  for character in label:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    if #characters == 128 then break end
    characters[#characters + 1] = character
  end
  label = table.concat(characters)
  if label ~= "" and label ~= view.label then
    local result, renameErr = rex.session.set_label{session_id = sessionId, label = label}
    if not result then rex.log(renameErr) end
  end
end

local function attach(sessionId)
  assert(rex.session.attach{session_id = sessionId})
  sync(sessionId)
  orderSessions()
end

rex.on("session_created", function(_, ev) attach(ev.session.session_id) end)
rex.on("session_view_changed", function(ctx)
  sync(ctx.session_id)
  orderSessions()
end)
rex.on("session_moved", orderSessions)
rex.on("terminal.title_changed", function(ctx) sync(ctx.session_id) end)

local sessions, err = rex.call("session.list")
assert(sessions, err)
for _, session in ipairs(sessions.sessions) do
  attach(session.session_id)
end

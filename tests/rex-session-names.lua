local script = arg[1] or 'common/rex-session-names.lua'

local function run(pinSessions)
  local sessions = {
    {session_id='work', label='old', windows={
      {window_id='work-first', label='Window abc', focused_block_id='terminal'},
      {window_id='work-second', label='Second task'},
    }},
    {session_id='support', label='support', windows={
      {window_id='support-first', label='Window def', focused_block_id='terminal'},
    }},
    {session_id='socials', label='socials', windows={
      {window_id='socials-first', label='Window fed', focused_block_id='terminal'},
    }},
    {session_id='dotfiles', label='dotfiles', windows={
      {window_id='dotfiles-first', label='Window cba', focused_block_id='terminal'},
      {window_id='dotfiles-second', label='Fix aliases'},
    }},
  }
  local byId = {}
  for _, session in ipairs(sessions) do byId[session.session_id] = session end
  local title, events, writes = '⠋ Working | zupo', {}, 0
  rex = {
    args={pinSessions=pinSessions},
    log=function(err) error(err) end,
    on=function(event, callback) events[event]=callback end,
    call=function(method, args)
      if method=='session.list' then
        local result = {}
        for _, s in ipairs(sessions) do
          result[#result+1] = {session_id=s.session_id, label=s.label}
        end
        return {sessions=result}
      end
      writes = writes+1
      if method=='session.set_window_label' then
        for _, w in ipairs(byId[args.session_id].windows) do
          if w.window_id==args.window_id then w.label=args.label; return true end
        end
        error('missing window')
      end
      assert(method=='session.move')
      local moved
      for i,s in ipairs(sessions) do
        if s.session_id==args.session_id then moved=table.remove(sessions,i); break end
      end
      for i,s in ipairs(sessions) do
        if s.session_id==args.before_session_id then table.insert(sessions,i,moved); return true end
      end
      error('missing target')
    end,
    session={
      attach=function() return true end,
      view=function(args) return byId[args.session_id] end,
      set_label=function(args)
        writes = writes+1
        byId[args.session_id].label=args.label
        return true
      end,
    },
    block={call=function() return {title=title} end},
  }
  local function changed(id) events.session_view_changed({session_id=id}) end
  dofile(script)
  assert(byId.work.label=='Working')
  if pinSessions then
    assert(sessions[1].session_id=='dotfiles')
    assert(sessions[2].session_id=='socials')
    assert(sessions[3].session_id=='support')
    for _, id in ipairs({'dotfiles','socials','support'}) do
      assert(byId[id].windows[1].label==id)
      assert(byId[id].label==id)
    end
  else
    assert(sessions[1].session_id=='work')
    assert(sessions[2].session_id=='support')
    assert(byId.dotfiles.label=='Working')
    assert(byId.dotfiles.windows[1].label=='Window cba')
  end

  byId.work.windows[2].label='Background task'
  changed('work')
  assert(byId.work.label=='Working')
  byId.work.windows[1].label='First task'
  changed('work')
  assert(byId.work.label=='First task')

  local windows = byId.dotfiles.windows
  windows[1], windows[2] = windows[2], windows[1]
  changed('dotfiles')
  assert(byId.dotfiles.label=='Fix aliases')
  if pinSessions then assert(sessions[1].session_id=='dotfiles') end

  if pinSessions then
    local pinned = table.remove(sessions,1)
    sessions[#sessions+1] = pinned
    dofile(script)
    assert(sessions[1].session_id=='dotfiles')
    assert(byId.dotfiles.label=='Fix aliases')
  end

  table.remove(windows,1)
  changed('dotfiles')
  assert(byId.dotfiles.label==(pinSessions and 'dotfiles' or 'Working'))
  byId.work.windows[1].label='Window abc'
  title='Next task | zupo'
  events['terminal.title_changed']({session_id='work'})
  assert(byId.work.label=='Next task')
  local previousWrites = writes
  changed('work')
  assert(writes==previousWrites)
  byId.work.windows={}
  changed('work')
  assert(byId.work.label=='Next task')
  print('PASS: '..(pinSessions and 'zbook' or 'cruncher'))
end

run(true)
run(false)

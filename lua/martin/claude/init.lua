-- Claude Code in a Neovim split, backed by the tmux sessions kog-tui spawns.
--
-- Four jobs:
--   1. Show a Claude session in a right-hand vertical split.
--   2. Pick between the flows kog-tui has running (implement-issue, feedback, …).
--   3. Keep open buffers in sync with the edits Claude makes on disk.
--   4. Drop an `@file#Lx-y` reference for the visual selection into its prompt.
--
-- tmux still owns every Claude process, so sessions survive quitting Neovim —
-- we only ever attach a view. Selections are sent as a *reference*, never as the
-- selected text: it stays one line, which keeps us clear of Claude's TUI
-- bracketed-paste handling (upstream #3134 / #13183 hang on multi-line paste).

local tmux = require('martin.claude.tmux')

local M = {}

local config = {
  cmd = { 'claude' }, -- fallback when no kog-tui session is targeted
  width = 0.40,
  refresh_ms = 1000,
  startup_ms = 2500,
  prefix = '<leader>a', -- "ask claude"
  -- Inside the terminal every key belongs to Claude, so <leader>at cannot
  -- reach us. This buffer-local escape hatch hides the split, session intact.
  hide_key = '<C-q>',
  -- Enters tmux copy-mode to reach the pane's history; press again to keep
  -- paging up, then `q` to come back. See tmux.copy_mode for why this is needed.
  scroll_key = '<PageUp>',
}

local state = {
  job = nil,
  buf = nil,
  win = nil,
  cwd = nil,
  target = nil, -- { session, window, cwd, live, ticket } from tmux.sessions()
  timer = nil,
}

local function job_alive()
  return state.job ~= nil and state.buf ~= nil and vim.api.nvim_buf_is_valid(state.buf)
end

local function win_open()
  return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
end

local function target_width()
  return math.max(40, math.floor(vim.o.columns * config.width))
end

local function dress_win(win)
  local wo = vim.wo[win]
  wo.number = false
  wo.relativenumber = false
  wo.signcolumn = 'no'
  wo.winfixwidth = true
end

-- Poll for Claude's edits. `checktime` on an unchanged file is just a stat(), and
-- it refuses to touch a modified buffer, so this cannot clobber your own work.
local function start_refresh()
  if state.timer then
    return
  end
  vim.opt.autoread = true
  local timer = (vim.uv or vim.loop).new_timer()
  state.timer = timer
  timer:start(
    config.refresh_ms,
    config.refresh_ms,
    vim.schedule_wrap(function()
      if vim.fn.mode() == 'c' then
        return
      end
      pcall(vim.cmd, 'checktime')
    end)
  )
end

local function stop_refresh()
  if state.timer then
    state.timer:stop()
    state.timer:close()
    state.timer = nil
  end
end

--- Sessions for the worktree we are sitting in, falling back to everything when
--- the cwd is not a worktree (or has no sessions of its own).
--- @return table[] sessions, string|nil worktree root when actually scoped
local function scoped_sessions()
  local root = tmux.worktree_root((vim.uv or vim.loop).cwd())
  if not root then
    return tmux.sessions(), nil
  end
  local scoped = tmux.sessions_in(root)
  if #scoped == 0 then
    return tmux.sessions(), nil
  end
  return scoped, root
end

--- Settle on a session, then run `cb`. Adopts this worktree's session when
--- there is exactly one; asks when there are several (benchmark worktrees run
--- `claude` and `judge` at once); falls back to a plain `claude` only when the
--- worktree has nothing running, so we never spawn a stray session alongside
--- one you meant to talk to.
local function with_target(cb)
  if state.target or job_alive() then
    return cb()
  end

  local scoped, root = scoped_sessions()
  if not root then
    return cb()
  end

  local live = {}
  for _, e in ipairs(scoped) do
    if e.live then
      table.insert(live, e)
    end
  end

  if #live == 1 then
    state.target = live[1]
    return cb()
  end
  if #live == 0 then
    return cb()
  end
  M.pick({ after = cb })
end

local function spawn()
  -- `vnew`, not `vsplit`: jobstart({term=true}) converts the *current* buffer
  -- into a terminal, so it must never be the file you were editing.
  vim.cmd('botright vnew')
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(state.win, target_width())
  dress_win(state.win)

  local cmd, cwd = config.cmd, (vim.uv or vim.loop).cwd()
  if state.target then
    cmd = tmux.attach_cmd(state.target.session, state.target.window)
    cwd = state.target.cwd
  end
  state.cwd = cwd

  state.job = vim.fn.jobstart(cmd, {
    term = true,
    cwd = cwd,
    on_exit = function()
      -- Drop the corpse: without this the split keeps showing a dead
      -- "[Process exited 0]" terminal after the session or client goes away.
      local dead_buf, dead_win = state.buf, state.win
      state.job, state.buf, state.win = nil, nil, nil
      stop_refresh()
      vim.schedule(function()
        if dead_win and vim.api.nvim_win_is_valid(dead_win) then
          pcall(vim.api.nvim_win_close, dead_win, true)
        end
        if dead_buf and vim.api.nvim_buf_is_valid(dead_buf) then
          pcall(vim.api.nvim_buf_delete, dead_buf, { force = true })
        end
      end)
    end,
  })

  if state.job <= 0 then
    vim.notify('claude: failed to start a session', vim.log.levels.ERROR)
    state.job = nil
    return false
  end

  state.buf = vim.api.nvim_get_current_buf()
  vim.bo[state.buf].buflisted = false

  if state.target then
    local session = state.target.session
    vim.defer_fn(function()
      tmux.arm_autoclean(session)
    end, 1500)
  end

  if config.hide_key and config.hide_key ~= '' then
    for _, mode in ipairs({ 't', 'n' }) do
      vim.keymap.set(mode, config.hide_key, function()
        M.hide()
      end, { buffer = state.buf, desc = 'Claude: hide split (session keeps running)' })
    end
  end

  if state.target and config.scroll_key and config.scroll_key ~= '' then
    local session = state.target.session
    vim.keymap.set('t', config.scroll_key, function()
      tmux.copy_mode(session)
    end, { buffer = state.buf, desc = 'Claude: scroll back (tmux copy-mode)' })
  end

  start_refresh()
  return true
end

local function show()
  if win_open() then
    return true
  end
  if job_alive() then
    vim.cmd('botright vsplit')
    state.win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(state.win, state.buf)
    vim.api.nvim_win_set_width(state.win, target_width())
    dress_win(state.win)
    return true
  end
  return spawn()
end

local function focus_now()
  if not show() then
    return
  end
  vim.api.nvim_set_current_win(state.win)
  -- Scheduled: `startinsert` is swallowed if issued from inside a mapping.
  vim.schedule(function()
    if win_open() and vim.api.nvim_get_current_win() == state.win then
      vim.cmd('startinsert')
    end
  end)
end

function M.focus()
  with_target(focus_now)
end

function M.hide()
  if win_open() then
    vim.api.nvim_win_close(state.win, false)
  end
  state.win = nil
end

function M.toggle()
  if win_open() then
    M.hide()
  else
    M.focus()
  end
end

--- Drop the current view. Kills only our tmux client, never the session, so
--- every Claude process keeps running.
function M.detach()
  stop_refresh()
  if state.job then
    pcall(vim.fn.jobstop, state.job)
  end
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
  end
  state.job, state.buf, state.win = nil, nil, nil
end

--- Show one of kog-tui's Claude sessions.
function M.open(entry)
  -- A tmux client is bound to one session, so changing worktree needs a fresh
  -- attach; changing window within a worktree is just a select.
  local same_worktree = state.target and state.target.session == entry.session and job_alive()
  state.target = entry

  if same_worktree then
    tmux.select_window(entry.session, entry.window)
    if not show() then
      return
    end
  else
    M.detach()
    if not show() then
      return
    end
  end

  if not entry.live then
    tmux.resume(entry.session, entry.window)
    entry.live = true
  end
  M.focus()
end

function M.pick(opts)
  opts = opts or {}
  local sessions, root
  if opts.all then
    sessions, root = tmux.sessions(), nil
  else
    sessions, root = scoped_sessions()
  end

  if #sessions == 0 then
    vim.notify('claude: no kog-tui Claude sessions found', vim.log.levels.WARN)
    return
  end

  vim.ui.select(sessions, {
    prompt = root and ('Claude — ' .. vim.fs.basename(root)) or 'Claude — all worktrees',
    format_item = function(e)
      local mark = e.live and '●' or '○'
      local status = e.live and 'live' or 'dormant'
      -- Scoped to one worktree the ticket column is just noise.
      if root then
        return ('%s  %-9s  %s'):format(mark, e.window, status)
      end
      return ('%s  %-11s  %-9s  %s'):format(mark, e.ticket, e.window, status)
    end,
  }, function(choice)
    if not choice then
      return
    end
    M.open(choice)
    if opts.after then
      opts.after()
    end
  end)
end

-- Run `fn` with a session showing, allowing for startup if we had to spawn one.
local function ensure(fn)
  local fresh = not job_alive()
  if not show() then
    return
  end
  if fresh then
    vim.defer_fn(fn, config.startup_ms)
  else
    fn()
  end
end

-- Build `@path#Lx-y `. `l1 == nil` references the whole file.
local function reference(bufnr, l1, l2)
  if vim.bo[bufnr].buftype ~= '' then
    return nil, 'not a file buffer'
  end
  local abs = vim.api.nvim_buf_get_name(bufnr)
  if abs == '' then
    return nil, 'buffer has no file on disk yet'
  end

  -- Save so the lines Claude reads are the lines you are looking at. `noautocmd`
  -- skips BufWritePost, which keeps conform.nvim's format_after_save from firing:
  -- an async reformat would shift the very lines we are about to cite.
  if vim.bo[bufnr].modified then
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd('silent noautocmd write')
    end)
  end

  -- Relative to the session's own cwd, which is the worktree — not nvim's.
  local base = (state.target and state.target.cwd) or state.cwd or (vim.uv or vim.loop).cwd()
  local rel = vim.fs.relpath(base, abs) or abs
  if not l1 then
    return ('@%s '):format(rel)
  elseif l1 == l2 then
    return ('@%s#L%d '):format(rel, l1)
  end
  return ('@%s#L%d-%d '):format(rel, l1, l2)
end

--- Insert a reference into the session's prompt and hand you the cursor.
--- Deliberately no trailing Enter: you type the question in Claude's own input,
--- with its editing and multi-line support, and submit when ready.
function M.send_range(bufnr, l1, l2)
  with_target(function()
    ensure(function()
    if not job_alive() then
      return
    end
    local ref, err = reference(bufnr, l1, l2)
    if not ref then
      vim.notify('claude: ' .. err, vim.log.levels.WARN)
      return
    end
      if state.target then
        -- Address the window directly, so it lands even if the view moved.
        tmux.send(state.target.session, state.target.window, ref)
      else
        vim.api.nvim_chan_send(state.job, ref)
      end
      focus_now()
    end)
  end)
end

function M.send_selection()
  local bufnr = vim.api.nvim_get_current_buf()
  -- Still in visual mode here, so `v` is the anchor and `.` the cursor.
  local a = vim.fn.getpos('v')[2]
  local b = vim.fn.getpos('.')[2]
  if a > b then
    a, b = b, a
  end
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
  M.send_range(bufnr, a, b)
end

function M.setup(opts)
  config = vim.tbl_deep_extend('force', config, opts or {})

  local grp = vim.api.nvim_create_augroup('MartinClaude', { clear = true })

  vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'TermLeave', 'CursorHold' }, {
    group = grp,
    callback = function()
      pcall(vim.cmd, 'checktime')
    end,
  })

  -- With 'autoread' on this fires *only* when a file changed on disk AND the
  -- buffer has local edits (`:help FileChangedShell`) — a real conflict. Having a
  -- handler suppresses nvim's own W12 prompt, so re-request it via fcs_choice.
  vim.api.nvim_create_autocmd('FileChangedShell', {
    group = grp,
    callback = function(args)
      if vim.bo[args.buf].modified then
        vim.v.fcs_choice = 'ask'
        vim.notify(
          ('claude: %s changed on disk, but you have unsaved edits'):format(
            vim.fn.fnamemodify(vim.api.nvim_buf_get_name(args.buf), ':.')
          ),
          vim.log.levels.WARN
        )
      else
        vim.v.fcs_choice = 'reload'
      end
    end,
  })

  local p = config.prefix
  vim.keymap.set({ 'n', 'v' }, p .. 't', M.toggle, { desc = 'Claude: [t]oggle window' })
  vim.keymap.set('v', p .. 'q', M.send_selection, { desc = 'Claude: ask [q]uestion about selection' })
  vim.keymap.set('n', p .. 'p', function()
    M.pick()
  end, { desc = 'Claude: [p]ick session (this worktree)' })
  vim.keymap.set('n', p .. 'P', function()
    M.pick({ all = true })
  end, { desc = 'Claude: [P]ick session (all worktrees)' })

  vim.api.nvim_create_user_command('Claude', function()
    M.focus()
  end, { desc = 'Open/focus the Claude split' })
  vim.api.nvim_create_user_command('ClaudeToggle', function()
    M.toggle()
  end, { desc = 'Toggle the Claude split' })
  vim.api.nvim_create_user_command('ClaudePick', function(a)
    M.pick({ all = a.bang })
  end, { bang = true, desc = 'Pick a Claude session for this worktree (! for all)' })
end

return M

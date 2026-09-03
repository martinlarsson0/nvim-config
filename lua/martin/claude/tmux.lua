-- Discovery of, and addressing for, the Claude sessions kog-tui spawns.
--
-- kog-tui gives every worktree one tmux session named after its branch, with a
-- named window per flow: `claude` (/implement-issue, /implement-batch, /pr-review,
-- /pr-review-walkthrough), `feedback` (/address-pr-feedback), `grill-me`, `judge`.
-- `terminal`, `backend` and `frontend` are not Claude and are excluded.
--
-- Everything here drives tmux through its CLI rather than keystrokes, which is
-- what makes this work at all: nvim runs inside tmux, so the outer server grabs
-- the `C-b` prefix before the inner client could ever see it.

local M = {}

local CLAUDE_WINDOWS = { claude = true, feedback = true, ['grill-me'] = true, judge = true }

local function tmux(args)
  local result = vim.system(vim.list_extend({ 'tmux' }, args), { text = true }):wait()
  if result.code ~= 0 then
    return nil
  end
  return result.stdout or ''
end

function M.available()
  return vim.fn.executable('tmux') == 1
end

--- Name of our nvim-side view of `session`: a grouped session sharing its
--- windows but carrying its own current window, so selecting a window here
--- never moves the WezTerm client.
--- Per-process, so two nvim instances on the same worktree get their own view
--- and never tear down each other's client.
function M.view_name(session)
  return ('%s-nvim%d'):format(session, vim.fn.getpid())
end

local function is_view(session)
  return session:match('%-nvim%d*$') ~= nil
end

--- Pane pids that have a live `claude` somewhere beneath them.
---
--- Liveness cannot be read off `#{pane_current_command}`: kog-tui runs the flow
--- as `bash -c '... claude ...'`, so tmux reports `bash` for a *running* Claude
--- just as it does for a finished one that fell through to `exec $SHELL`. So walk
--- the real process tree instead — one ps call, then descend from each pane pid.
local function live_pane_pids(pane_pids)
  local result = vim.system({ 'ps', '-Ao', 'pid=,ppid=,comm=' }, { text = true }):wait()
  if result.code ~= 0 then
    return {}
  end

  local children, is_claude = {}, {}
  for line in (result.stdout or ''):gmatch('[^\n]+') do
    local pid, ppid, comm = line:match('^%s*(%d+)%s+(%d+)%s+(.+)$')
    if pid then
      pid, ppid = tonumber(pid), tonumber(ppid)
      children[ppid] = children[ppid] or {}
      table.insert(children[ppid], pid)
      if vim.fs.basename(vim.trim(comm)) == 'claude' then
        is_claude[pid] = true
      end
    end
  end

  local live = {}
  for _, root in ipairs(pane_pids) do
    local stack, seen = { root }, {}
    while #stack > 0 do
      local pid = table.remove(stack)
      if not seen[pid] then
        seen[pid] = true
        if is_claude[pid] then
          live[root] = true
          break
        end
        for _, child in ipairs(children[pid] or {}) do
          table.insert(stack, child)
        end
      end
    end
  end
  return live
end

--- Every Claude window kog-tui has spawned, across all worktrees.
--- Entries: { session, window, cwd, live, ticket }
function M.sessions()
  if not M.available() then
    return {}
  end
  local out = tmux({
    'list-panes', '-a', '-F',
    '#{session_name}\t#{window_name}\t#{pane_current_path}\t#{pane_pid}\t#{window_id}',
  })
  if not out then
    return {}
  end

  local rows, pids, seen_window = {}, {}, {}
  for line in out:gmatch('[^\n]+') do
    local session, window, cwd, pid, win_id = line:match('^(.-)\t(.-)\t(.-)\t(.-)\t(.-)$')
    -- A grouped view links the same windows, so dedupe on window id (not session
    -- name) or every pane is reported once per session in the group.
    if session and window and CLAUDE_WINDOWS[window] and not is_view(session) and not seen_window[win_id] then
      seen_window[win_id] = true
      pid = tonumber(pid)
      table.insert(rows, { session = session, window = window, cwd = cwd, pid = pid })
      table.insert(pids, pid)
    end
  end

  local live = live_pane_pids(pids)

  local entries = {}
  for _, r in ipairs(rows) do
    table.insert(entries, {
      session = r.session,
      window = r.window,
      cwd = r.cwd,
      live = live[r.pid] == true,
      ticket = r.session:match('^([A-Z]+%-%d+)') or r.session,
    })
  end

  table.sort(entries, function(a, b)
    if a.live ~= b.live then
      return a.live -- live sessions first
    end
    if a.ticket ~= b.ticket then
      return a.ticket < b.ticket
    end
    return a.window < b.window
  end)
  return entries
end

--- Command for a terminal buffer that attaches to `session`'s windows through a
--- fresh grouped view, starting on `window`. Recreated each time: the windows
--- live in the source session, so throwing the view away costs nothing.
--- `TMUX=` is required because nvim itself is running inside tmux.
function M.attach_cmd(session, window)
  local view = M.view_name(session)
  local q = vim.fn.shellescape
  return {
    'sh', '-c', table.concat({
      ('tmux kill-session -t %s 2>/dev/null'):format(q(view)),
      ('tmux new-session -d -t %s -s %s'):format(q(session), q(view)),
      ('tmux select-window -t %s'):format(q(view .. ':' .. window)),
      ('TMUX= tmux attach -t %s'):format(q(view)),
    }, '; '),
  }
end

--- Make the view self-destruct once our client goes away, so quitting nvim
--- leaves nothing behind and needs no blocking cleanup on exit. Arm this only
--- *after* attaching: with no client yet, tmux destroys the session instantly.
--- Destroying a view only unlinks the shared windows — the source session and
--- its Claude processes are untouched.
function M.arm_autoclean(session)
  tmux({ 'set-option', '-t', M.view_name(session), 'destroy-unattached', 'on' })
end

function M.select_window(session, window)
  tmux({ 'select-window', '-t', M.view_name(session) .. ':' .. window })
end

--- Literal text into a window's prompt. Addresses the source session, so it
--- lands whether or not our view happens to be looking at that window.
function M.send(session, window, text)
  tmux({ 'send-keys', '-t', session .. ':' .. window, '-l', text })
end

function M.submit(session, window)
  tmux({ 'send-keys', '-t', session .. ':' .. window, 'Enter' })
end

--- Restart a dormant window. `claude --resume` with no id opens Claude's own
--- picker, already scoped to that directory's transcripts — correct without us
--- having to track session ids per window ourselves.
function M.resume(session, window)
  M.send(session, window, 'claude --resume')
  M.submit(session, window)
end

--- Root of the git worktree containing `dir`, or nil if it isn't in a repo.
--- Inside a worktree this is the worktree itself, which is what scopes the picker.
function M.worktree_root(dir)
  local result = vim.system({ 'git', '-C', dir, 'rev-parse', '--show-toplevel' }, { text = true }):wait()
  if result.code ~= 0 then
    return nil
  end
  local root = vim.trim(result.stdout or '')
  return root ~= '' and vim.fs.normalize(root) or nil
end

--- Only the sessions whose cwd sits at or below `root`. `vim.fs.relpath` returns
--- nil for anything outside, which is the containment test we want.
function M.sessions_in(root)
  local scoped = {}
  for _, e in ipairs(M.sessions()) do
    if e.cwd and vim.fs.relpath(root, vim.fs.normalize(e.cwd)) then
      table.insert(scoped, e)
    end
  end
  return scoped
end

function M.kill_view(session)
  tmux({ 'kill-session', '-t', M.view_name(session) })
end

return M

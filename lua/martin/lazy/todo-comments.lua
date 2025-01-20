-- Highlight todo, notes, etc in comments
-- TODO: YEAH
-- HACK: WHAT
-- PERF: BAD
-- NOTE: WHAT
-- FIX: OPS
-- WARNING: WARNING WARNING WARNING
return {
	"folke/todo-comments.nvim",
	event = "VimEnter",
	dependencies = { "nvim-lua/plenary.nvim" },
	opts = { signs = false },
}

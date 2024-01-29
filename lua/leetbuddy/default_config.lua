local sep = require("plenary.path").path.sep

local default_config = {
  domain = "com", -- Change to "cn" for china website
  directory = vim.loop.os_homedir() .. sep .. ".leetcode",
  language = "py",
  debug = false,
  page_next = "<Right>",
  page_prev = "<Left>",
  code_dir = "solution",
  test_case_dir = "test_case",
  question_dir = "question",
}

return default_config

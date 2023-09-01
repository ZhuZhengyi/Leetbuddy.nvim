local utils = require("leetbuddy.utils")
local config = require("leetbuddy.config")
local qdata = require("leetbuddy.question")

local M = {}

function M.reset_question()
  if utils.is_in_folder(vim.api.nvim_buf_get_name(0), config.directory) then
    local slug_name = utils.get_current_buf_slug_name()

    local question = qdata.fetch_question_data(slug_name)
    local ext = utils.get_file_extension(vim.fn.expand("%:t"))
    local question_id = question["questionFrontendId"]
    local title = question["title"]
    local content = question["content"]

    for _, table in ipairs(question["codeSnippets"]) do
      if table.langSlug == utils.langSlugToFileExt[ext] then
        local code_src = string.format(config.code_template,
            question_id, title, content,
            config.code_tmpl_start, table.code, config.code_tmpl_end)
        vim.api.nvim_buf_set_lines(
          vim.api.nvim_get_current_buf(),
          0,
          -1,
          false,
          utils.split_string_to_table(code_src)
        )
        break
      end
    end

    local question_slug = string.format("%04d-%s", question_id, slug_name)
    local test_case_path = utils.get_test_case_path(question_slug)
    local test_case_file = io.open(test_case_path, "w")
    if test_case_file then
      test_case_file:write(question["sampleTestCase"])
      test_case_file:close()
    else
      print("Failed to open the file.")
    end
  end
end

return M

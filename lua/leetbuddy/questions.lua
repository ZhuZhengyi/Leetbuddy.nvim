local curl = require("plenary.curl")
local sep = require("plenary.path").path.sep
local config = require("leetbuddy.config")
local headers = require("leetbuddy.headers")
local utils = require("leetbuddy.utils")
local split = require("leetbuddy.split")

local M = {}

M.difficulty = nil
M.status = nil
M.skip = 0

local function display_questions(search_query)
  local graphql_endpoint = config.graphql_endpoint

  local variables = {
    skip = M.skip,
    limit = 20,
    filters = {
      difficulty = M.difficulty,
      searchKeywords = search_query,
      status = M.status,
    },
  }

  local query = [[
    query problemsetQuestionList($limit: Int, $skip: Int, $filters: QuestionListFilterInput) {
  ]] .. (config.domain == "cn" and [[
      problemsetQuestionList(
  ]] or [[
      problemsetQuestionList: questionList(
  ]]) .. [[
        categorySlug: ""
        skip: $skip
        limit: $limit
        filters: $filters
    ) {
  ]] .. (config.domain == "cn" and [[
          total
          questions {
            paidOnly
            titleCn
            frontendQuestionId
  ]] or [[
          total: totalNum
          questions: data {
            paidOnly: isPaidOnly
            titleCn: title
            frontendQuestionId: questionFrontendId
  ]]) .. [[
            difficulty
            isFavor
            status
            titleSlug
        }
      }
    }
  ]]

  local response =
    curl.post(graphql_endpoint, { headers = headers, body = vim.json.encode({ query = query, variables = variables }) })

  local data = vim.json.decode(response["body"])["data"]["problemsetQuestionList"]
  return (data ~= vim.NIL and data["questions"] or {})
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local make_entry = require("telescope.make_entry")
local entry_display = require("telescope.pickers.entry_display")

local opts = {}

local function update_status(sts, is_paid)
  if sts == vim.NIL and not is_paid then
    return " "
  end

  local statuses = {
    ac = "✔️",
    notac = "❌",
    AC = "✔️",
    TRIED = "❌",
  }
  local s = sts ~= vim.NIL and statuses[sts] or ""
  local c = is_paid and "👑" or ""
  return s .. c
end

local function gen_from_questions()
  local displayer = entry_display.create({
    separator = "",
    items = {
      { width = 6 },
      { width = 6 },
      { width = 60 },
      { width = 8 },
    },
  })

  local make_display = function(entry)
    return displayer({
      { entry.value.frontendQuestionId, "Number" },
      { update_status(entry.value.status, entry.value.paid_only), "Status" },
      { entry.value.titleCn, "Title" },
      { entry.value.difficulty, "Difficulty" },
    })
  end

  return function(o)
    local entry = {
      display = make_display,
      value = {
        frontendQuestionId = o.frontendQuestionId,
        status = o.status,
        titleCn = o.titleCn,
        slug = o.titleSlug,
        difficulty = o.difficulty,
        paid_only = o.paidOnly,
      },
      ordinal = string.format("%s %s %s %s", o.frontendQuestionId, o.status, o.titleCn, o.difficulty),
    }
    return make_entry.set_default_entry_mt(entry, opts)
  end
end

local function select_problem(prompt_bufnr)
  actions.close(prompt_bufnr)
  local problem = action_state.get_selected_entry()
  local question_slug = string.format("%04d-%s", problem["value"]["frontendQuestionId"], problem["value"]["slug"])

  local code_file_path = utils.get_code_file_path(question_slug, config.language)
  local test_case_path = utils.get_test_case_path(question_slug)

  if split.get_results_buffer() then
    vim.api.nvim_command("LBClose")
  end

  if not utils.file_exists(code_file_path) then
    vim.api.nvim_command(":silent !touch " .. code_file_path)
    vim.api.nvim_command(":silent !touch " .. test_case_path)
    vim.api.nvim_command("edit! " .. code_file_path)
    vim.api.nvim_command("LBReset")
  else
    vim.api.nvim_command("edit! " .. code_file_path)
  end
  vim.api.nvim_command("LBSplit")
  vim.api.nvim_command("LBQuestion")
end

local function filter_problems()
  -- local cancel = function() end
  return function(prompt)
    return display_questions(prompt)
  end
end

function M.questions()
  vim.cmd("LBCheckCookies")
  pickers
    .new(opts, {
      prompt_title = "Question",
      finder = finders.new_dynamic({
        fn = filter_problems(),
        entry_maker = gen_from_questions(),
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(_, map)
        map({ "n", "i" }, "<CR>", select_problem)
        map({ "n", "i" }, "<A-r>", function()
          M.difficulty = nil
          M.status = nil
          M.questions()
        end)
        map({ "n", "i" }, "<A-e>", function()
          M.difficulty = "EASY"
          M.questions()
        end)
        map({ "n", "i" }, "<A-m>", function()
          M.difficulty = "MEDIUM"
          M.questions()
        end)
        map({ "n", "i" }, "<A-h>", function()
          M.difficulty = "HARD"
          M.questions()
        end)
        map({ "n", "i" }, "<A-a>", function()
          M.status = "AC"
          M.questions()
        end)
        map({ "n", "i" }, "<A-y>", function()
          M.status = "NOT_STARTED"
          M.questions()
        end)
        map({ "n", "i" }, "<A-t>", function()
          M.status = "TRIED"
          M.questions()
        end)
        map({ "n", "i" }, config.page_prev, function()
          M.skip = M.skip >= 20 and M.skip - 20 or M.skip
          M.questions()
        end)
        map({ "n", "i" }, config.page_next, function()
          M.skip = M.skip + 20
          M.questions()
        end)
        return true
      end,
    })
    :find()
end


return M

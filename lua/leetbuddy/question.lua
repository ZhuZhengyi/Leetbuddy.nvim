local utils = require("leetbuddy.utils")
local curl = require("plenary.curl")
local config = require("leetbuddy.config")
local headers = require("leetbuddy.headers")

local M = {}

local question_content, previous_question_slug, question_id

local old_contents

local function question_display(contents, oldqbufnr)
  Qbufnr = oldqbufnr or vim.api.nvim_create_buf(true, true)

  local width = math.ceil(math.min(vim.o.columns, math.max(90, vim.o.columns - 20)))
  local height = math.ceil(math.min(vim.o.lines, math.max(25, vim.o.lines - 10)))

  local row = math.ceil(vim.o.lines - height) * 0.5 - 1
  local col = math.ceil(vim.o.columns - width) * 0.5 - 1

  vim.api.nvim_open_win(Qbufnr, true, {
    border = "rounded",
    style = "minimal",
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
  })

  if not oldqbufnr then
    local c = utils.pad(contents)
    vim.api.nvim_buf_set_lines(Qbufnr, 0, -1, true, c)
    vim.api.nvim_buf_set_option(Qbufnr, "swapfile", false)
    vim.api.nvim_buf_set_option(Qbufnr, "modifiable", false)
    vim.api.nvim_buf_set_option(Qbufnr, "buftype", "nofile")
    vim.api.nvim_buf_set_option(Qbufnr, "filetype", "markdown")
    vim.api.nvim_buf_set_option(Qbufnr, "buflisted", false)
    vim.api.nvim_buf_set_keymap(Qbufnr, "n", "<esc>", "<cmd>hide<CR>", { noremap = true })
    vim.api.nvim_buf_set_keymap(Qbufnr, "n", "q", "<cmd>hide<CR>", { noremap = true })
  end

  vim.api.nvim_buf_set_keymap(Qbufnr, "v", "q", "<cmd>hide<CR>", { noremap = true })
  if contents ~= old_contents then
    contents = utils.pad(contents, { pad_top = 1 })
    vim.api.nvim_buf_set_option(Qbufnr, "modifiable", true)
    vim.api.nvim_buf_set_lines(Qbufnr, 0, -1, true, contents)
    vim.api.nvim_buf_set_option(Qbufnr, "modifiable", false)
  end

  old_contents = contents

  return Qbufnr
end

local function fetch_question(slug)
    local question = M.fetch_question_data(slug)
    if question == vim.NIL then
        return "You don't have a premium plan"
    end
    return question["questionFrontendId"] .. ". " .. question["title"] .. "\n" .. question["content"]
end

function M.fetch_question_data(slug)
    vim.cmd("silent !LBCheckCookies")

    local variables = {
        titleSlug = slug,
    }

    local query = [[
    query questionData($titleSlug: String!) {
        question(titleSlug: $titleSlug) {
            questionId
            questionFrontendId
            sampleTestCase
        ]] .. (config.domain == "cn" and [[
            title: translatedTitle
            content: translatedContent
        ]] or [[
            title
            content
        ]]) .. [[
            codeSnippets {
                lang
                langSlug
                code
            }
        }
    }
    ]]

    local response = curl.post(
        config.graphql_endpoint,
        { headers = headers, body = vim.json.encode({ query = query, variables = variables }) }
    )

    local question = vim.json.decode(response["body"])["data"]["question"]

    question_id = question["questionId"]
    if question["content"] == vim.NIL then
        return vim.NIL
    end
    question["content"] = utils.format_content(question["content"])

    return question
end

function M.question()
  if utils.is_in_folder(vim.api.nvim_buf_get_name(0), config.directory) then
    local question_slug = utils.get_current_buf_slug_name()
    if previous_question_slug ~= question_slug then
      question_content = utils.split_string_to_table(fetch_question(question_slug))
    end

    previous_question_slug = question_slug
    question_display(question_content, Qbufnr)
  end
end

function M.get_question_id()
  if not question_id then
    local question_slug = utils.get_current_buf_slug_name()
    local _ = fetch_question(question_slug)
  end
  return question_id
end

return M

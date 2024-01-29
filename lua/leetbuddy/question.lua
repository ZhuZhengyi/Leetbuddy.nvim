local utils = require("leetbuddy.utils")
local curl = require("plenary.curl")
local config = require("leetbuddy.config")
local headers = require("leetbuddy.headers")

local M = {}

local question_content, previous_question_slug, question_id

local old_contents

local function display_question_content(contents, oldqbufnr)
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

local function encode_question_content(slug)
    local question_data = M.fetch_question_data(slug)
    if question_data == vim.NIL then
        return "You don't have a premium plan"
    end
    return string.format("# %s.%s\r\n\r\n%s", question_data["questionFrontendId"], question_data["title"], question_data["content"])
end

function M.fetch_question_data(slug)
    vim.cmd("silent !LBCheckCookies")

    local variables = {
        titleSlug = slug,
    }
    local query = config.domain == "cn" and [[
    query questionData($titleSlug: String!) {
        question(titleSlug: $titleSlug) {
            questionId
            questionFrontendId
            difficulty
            sampleTestCase
            acRate
            title: translatedTitle
            content: translatedContent
            codeSnippets {
                lang
                langSlug
                code
            }
        }
    }
    ]] or [[
    query questionData($titleSlug: String!) {
        question(titleSlug: $titleSlug) {
            questionId
            questionFrontendId
            difficulty
            sampleTestCase
            acRate
            title
            content
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
    local ok, data = pcall(vim.json.decode, response["body"])
    if not ok then
        utils.Debug("cookies decode error: " .. response)
        return
    end
    local question_data = data["data"]["question"]
    question_id = question_data["questionId"]
    if question_data["content"] == vim.NIL then
        print(string.format("question[%s] is paidOnly", slug))
        utils.Debug("fetch question data error, slug: ".. slug)
        return vim.NIL
    end
    question_data["content"] = utils.tr_html_to_txt(question_data["content"])

    return question_data
end

function M.question()
    if not utils.is_in_folder(vim.api.nvim_buf_get_name(0), config.directory) then
        utils.Debug("file not in leetbuddy base dir!")
        return
    end

    local question_slug = utils.get_cur_buf_slug()
    if previous_question_slug ~= question_slug then
        question_content = utils.split_string_to_table(encode_question_content(question_slug))
        previous_question_slug = question_slug
    end

    display_question_content(question_content, Qbufnr)
end

function M.get_question_id(slug)
  if not question_id then
    M.fetch_question_data(slug)
  end
  return question_id
end

return M

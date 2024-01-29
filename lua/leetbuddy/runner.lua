local curl = require("plenary.curl")
local config = require("leetbuddy.config")
local headers = require("leetbuddy.headers")
local utils = require("leetbuddy.utils")
local question = require("leetbuddy.question")
local display = require("leetbuddy.display")
local split = require("leetbuddy.split")

local timer = vim.loop.new_timer()
local request_mode = {
    test = {
        endpoint = "interpret_solution",
        response_id = "interpret_id",
    },
    submit = {
        endpoint = "submit",
        response_id = "submission_id",
    },
}

local M = {}

local function submit_task(mode)
    local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
    local code = utils.read_file_contents(vim.fn.expand("%:p"))
    code = utils.get_content_by_range(code, config.code_tmpl_start, config.code_tmpl_end)

    local question_slug = utils.get_slug_by_file(file)

    local endpoint_url = string.format("%s/problems/%s/%s/", config.website, question_slug, request_mode[mode]["endpoint"])

    local extra_headers = {
        ["Referer"] = string.format("%s/problems/%s", config.website, utils.get_slug_by_file(question_slug))
    }

    local new_headers = vim.tbl_deep_extend("force", headers, extra_headers)

    local body = {
        lang = utils.langSlugToFileExt[utils.get_file_extension(vim.fn.expand("%:t"))],
        question_id = question.get_question_id(question_slug),
        typed_code = code,
    }

    if mode == "test" then
        local input_path = utils.get_cur_buf_test_case_path()
        local test_body_extra = {
            data_input = utils.read_file_contents(input_path),
            judge_type = "small",
        }

        for key, value in pairs(test_body_extra) do
            body[key] = value
        end
    end

    local response = curl.post(endpoint_url, {
        headers = new_headers,
        body = vim.json.encode(body),
    })

    if config.debug then
        print("Response from " .. endpoint_url)
        utils.P(response["body"])
    end
    local id = vim.json.decode(response["body"])[request_mode[mode]["response_id"]]
    return id
end

local function check_task(id, mode)
    local json_data

    local question_slug = utils.get_cur_buf_slug()
    local extra_headers = {
        ["Referer"] = string.format("%s/problems/%s/submissions/", config.website, question_slug),
    }

    local new_headers = vim.tbl_deep_extend("force", headers, extra_headers)
    if id then
        local status_url = string.format("%s/submissions/detail/%s/check", config.website, id)
        local status_response = curl.get(status_url, {
            headers = new_headers,
        })
        json_data = vim.fn.json_decode(status_response.body)
        if config.debug then
            print("Response from " .. status_url)
            utils.P(json_data)
        end
        if json_data["state"] == "SUCCESS" then
            timer:stop()
            local results_buffer = split.get_results_buffer()
            local test_case_path = utils.get_cur_buf_test_case_path()
            display.display_results(false, results_buffer, json_data, mode, test_case_path)
            return
        end
    end
end

function M.run(mode)
    vim.cmd("silent !LBCheckCookies")
    local results_buffer = split.get_results_buffer()
    display.display_results(true, results_buffer)
    local id = submit_task(mode)
    timer:start(
        100,
        1000,
        vim.schedule_wrap(function()
            check_task(id, mode)
        end)
    )
end

function M.test()
    M.run("test")
end

function M.submit()
    M.run("submit")
end

return M

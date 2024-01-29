local config = require("leetbuddy.config")
local template = require("leetbuddy.template")
local sep = require("plenary.path").path.sep

M = {}

M.langSlugToFileExt = {
  ["cpp"] = "cpp",
  ["java"] = "java",
  ["py"] = "python3",
  ["c"] = "c",
  ["cs"] = "csharp",
  ["js"] = "javascript",
  ["rb"] = "ruby",
  ["swift"] = "swift",
  ["go"] = "golang",
  ["scala"] = "scala",
  ["kt"] = "kotlin",
  ["rs"] = "rust",
  ["php"] = "php",
  ["ts"] = "typescript",
  ["rkt"] = "racket",
  ["erl"] = "erlang",
  ["ex"] = "elixir",
  ["dart"] = "dart",
}

function M.split_string_to_table(str)
  local lines = {}
  for line in str:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  return lines
end

function M.pad(contents, opts)
  vim.validate({ contents = { contents, "t" }, opts = { opts, "t", true } })
  opts = opts or {}
  local left_padding = (" "):rep(opts.pad_left or 1)
  local right_padding = (" "):rep(opts.pad_right or 1)
  for i, line in ipairs(contents) do
    contents[i] = string.format("%s%s%s", left_padding, line:gsub("\r", ""), right_padding)
  end
  if opts.pad_top then
    for _ = 1, opts.pad_top do
      table.insert(contents, 1, "")
    end
  end
  if opts.pad_bottom then
    for _ = 1, opts.pad_bottom do
      table.insert(contents, "")
    end
  end
  return contents
end

function M.find_file_inside_folder(folderpath, foldername)
  local folder = io.popen("ls " .. folderpath)
  if folder ~= vim.NIL then
      local files_str = folder:read("*all")

      for line in files_str:gmatch("%s*(.-)%s*\n") do
          if foldername == line then
              return true
          end
      end
  end
  return false
end

function M.is_in_folder(file, folder)
  return string.sub(file, 1, string.len(folder)) == folder
end

function M.get_cur_buf_test_case_path()
    local file_name = M.get_cur_buf_file_name()
    return M.get_test_case_path(file_name)
end

function M.get_cur_buf_file_name()
  return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t:r")
  --return file_name
end

function M.get_cur_buf_slug()
  local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t:r")
  return M.get_slug_by_file(file)
end

function M.get_slug_by_file(file)
  return string.gsub(string.gsub(file, "^%d+%.", ""), "%.[^.]+$", "")
end

function M.get_file_name_by_slug(question_id, slug)
    return string.format("%d.%s", question_id, slug)
end

function M.read_file_contents(path)
  local file = io.open(path, "r")
  if file then
    local contents = file:read("*a")
    file:close()
    return contents
  end
  return nil
end

function M.file_exists(name)
   local f = io.open(name, "r")
   return f ~= nil and io.close(f)
end
--
function M.get_content_by_range(content, start_flag, end_flag)
    local from = nil
    if start_flag ~= nil then
        local _from = string.find(content, start_flag)
        from = _from
    end
    if from == nil then
        return content
    end

    local to = nil
    if end_flag ~= nil then
        local _, _to = string.find(content, end_flag)
        to = _to
    end
    if to == nil then
        to = -1
    end

    return string.sub(content, from, to)
end

function M.get_file_extension(filename)
  local _, _, extension = string.find(filename, "%.([^%.]+)$")
  return extension
end

function M.strip_file_extension(file)
  local lastDotIndex = file:find("%.[^%.]*$")
  return file:sub(1, lastDotIndex - 1)
end

function M.tr_html_to_txt(content)
    local entities = {
        { "amp", "&" },
        { "apos", "'" },
        { "#x27", "'" },
        { "#x2F", "/" },
        { "#39", "'" },
        { "#47", "/" },
        { "lt", "<" },
        { "gt", ">" },
        { "nbsp", " " },
        { "quot", '"' },
    }

    local img_urls = {}
    content = content:gsub("<img.-src=[\"'](.-)[\"'].->", function(url)
        table.insert(img_urls, url)
        return "##IMAGE##"
    end)
    content = string.gsub(content, "<[^>]+>", "")

    for _, url in ipairs(img_urls) do
        content = string.gsub(content, "##IMAGE##", url, 1)
    end

    for _, entity in ipairs(entities) do
        content = string.gsub(content, "&" .. entity[1] .. ";", entity[2])
    end

    return content
end

function M.get_code_file_path(file_name, ext)
  local code_dir_path = string.format("%s%s%s", config.directory, sep, config.code_dir)
  if not M.file_exists(code_dir_path) then
    vim.api.nvim_command(string.format(":silent !mkdir %s", code_dir_path))
  end

  return string.format("%s%s%s.%s", code_dir_path, sep, file_name , ext)
end

function M.get_test_case_path(file_name)
  local test_case_dir_path = string.format("%s%s%s", config.directory, sep, config.test_case_dir)
  if not M.file_exists(test_case_dir_path) then
    vim.api.nvim_command(string.format(":silent !mkdir %s", test_case_dir_path))
  end

  return string.format("%s%s%s.txt", test_case_dir_path , sep, file_name)
end

function M.get_question_path(file_name)
  local question_dir_path = string.format("%s%s%s", config.directory, sep, config.question_dir)
  if not M.file_exists(question_dir_path) then
    vim.api.nvim_command(string.format(":silent !mkdir %s", question_dir_path))
  end

  return string.format("%s%s%s.md", question_dir_path, sep, file_name)
end

function M.get_question_number_from_file_name(file_name)
  local number = string.match(file_name, "^0*(%d+)%-")

  if number then
    number = tonumber(number)
    return number
  end
  return nil
end

function M.split_test_case_inputs(test_path, num_tests)
  local test_input = M.read_file_contents(test_path)
  local all_parameters = {}
  for param in string.gmatch(test_input, "([^\n]+)") do
    table.insert(all_parameters, param)
  end

  local params_per_test = math.floor(#all_parameters / num_tests)

  local test_case_inputs = {}
  for i = 1, num_tests do
    local test_input_i = {}
    local start_param_idx = (i - 1) * params_per_test + 1
    local end_param_idx = start_param_idx + params_per_test - 1
    for j = start_param_idx, end_param_idx do
      table.insert(test_input_i, all_parameters[j])
    end
    table.insert(test_case_inputs, test_input_i)
  end

  return test_case_inputs
end

function M.is_in_table(tab, val)
  for _, value in ipairs(tab) do
    if value == val then
      return true
    end
  end

  return false
end

function M.encode_code_by_templ(question_data)
    local code_template = template[question_data.lang]
    if code_template == nil then
        return question_data.code
    end
    return string.format(code_template.code,
        question_data.question_id, question_data.title,
        config.domain, question_data.slug,
        question_data.question_id, question_data.lang,question_data.slug,
        question_data.difficulty, question_data.ac_rate,
        question_data.content,
        question_data.test_case,
        code_template.code_tmpl_start,
        question_data.code,
        code_template.code_tmpl_end
    )
end

M.Debug = function(v)
    if config.debug then
        print(vim.inspect(v))
    end
    return v
end

M.P = function(v)
    if config.debug then
        print(vim.inspect(v))
    end
    return v
end

return M

vim.env.LAZY_STDPATH = ".repro"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

require("lazy.minit").repro({
  spec = {

    {
      "mfussenegger/nvim-dap",
      dependencies = {
        "igorlfs/nvim-dap-view",
        -- virtual text for the debugger
        {
          "theHamsta/nvim-dap-virtual-text",
          opts = {},
        },
      },
      keys = {
        {
          "<leader>dr",
          function()
            require("dap").repl.toggle()
          end,
          desc = "Toggle REPL",
        },
        {
          "<leader>dw",
          function()
            require("dap.ui.widgets").hover()
          end,
          desc = "Widgets",
        },
        {
          "<F5>",
          function()
            require("dap").continue()
          end,
          desc = "Debugger: Start",
        },
        {
          "<F9>",
          function()
            require("dap").toggle_breakpoint()
          end,
          desc = "Debugger: Toggle Breakpoint",
        },
        {
          "<F33>", -- Control+F9
          function()
            require("dap").clear_breakpoints()
          end,
          desc = "Debugger: Clear All Breakpoints",
        },
        {
          "<F17>", -- Shift+F5
          function()
            require("dap").terminate()
          end,
          desc = "Debugger: Stop",
        },
        {
          "<F29>", -- Control+F5
          function()
            require("dap").restart_frame()
          end,
          desc = "Debugger: Restart",
        },
        {
          "<F6>",
          function()
            require("dap").pause()
          end,
          desc = "Debugger: Pause",
        },
        {
          "<F7>",
          function()
            require("dap").reverse_continue()
          end,
          "Debugger: Reverse",
        },
        {
          "<F10>",
          function()
            require("dap").step_over()
          end,
          desc = "Debugger: Step Over",
        },
        {
          "<F11>",
          function()
            require("dap").step_into()
          end,
          desc = "Debugger: Step Into",
        },
        {
          "<F23>", -- Shift+F11
          function()
            require("dap").step_out()
          end,
          desc = "Debugger: Step Out",
        },
      },

      config = function()
        -- add jsonc support to launch.json support
        local vscode = require("dap.ext.vscode")
        local json = require("plenary.json")
        ---@diagnostic disable-next-line: duplicate-set-field
        vscode.json_decode = function(str)
          return vim.json.decode(json.json_strip_comments(str))
        end

        local dap = require("dap")
        dap.adapters["netcoredbg"] = {
          type = "executable",
          command = "netcoredbg",
          args = { "--interpreter=vscode" },
        }
        dap.adapters["codelldb"] = {
          type = "executable",
          command = "codelldb",
        }
        -- js-debug
        for _, adapterType in ipairs({ "node", "chrome", "msedge" }) do
          local pwaType = "pwa-" .. adapterType

          dap.adapters[pwaType] = {
            type = "server",
            host = "localhost",
            port = "${port}",
            executable = {
              command = "js-debug",
              args = { "${port}" },
            },
          }

          -- Define adapters without the "pwa-" prefix for VSCode compatibility
          dap.adapters[adapterType] = function(cb, config)
            local nativeAdapter = dap.adapters[pwaType]

            config.type = pwaType

            if type(nativeAdapter) == "function" then
              nativeAdapter(cb, config)
            else
              cb(nativeAdapter)
            end
          end
        end

        local function get_dll()
          return coroutine.create(function(dap_run_co)
            local items = vim.fn.globpath(vim.fn.getcwd(), "**/bin/Debug/**/*.dll", true, true)
            local opts = {
              format_item = function(path)
                return vim.fn.fnamemodify(path, ":t")
              end,
            }
            local function cont(choice)
              if choice == nil then
                return nil
              else
                coroutine.resume(dap_run_co, choice)
              end
            end

            vim.ui.select(items, opts, cont)
          end)
        end
        dap.configurations.cs = {
          {
            type = "netcoredbg",
            name = "NetCoreDbg: Launch",
            request = "launch",
            cwd = "${fileDirname}",
            program = get_dll,
          },
        }

        local js_filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" }

        for _, language in ipairs(js_filetypes) do
          if not dap.configurations[language] then
            dap.configurations[language] = {
              {
                type = "node",
                request = "launch",
                name = "Launch file",
                program = "${file}",
                cwd = "${workspaceFolder}",
              },
              {
                type = "node",
                request = "attach",
                name = "Attach",
                processId = "${command:pickProcess}",
                cwd = "${workspaceFolder}",
              },
            }
          end
        end
      end,
    },

    {
      "mrcjkb/rustaceanvim",
      ft = { "rust" },
      opts = {
        server = {
          default_settings = {
            -- rust-analyzer language server configuration
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                buildScripts = {
                  enable = true,
                },
              },
              -- Add clippy lints for Rust if using rust-analyzer
              checkOnSave = true,
              -- Enable diagnostics if using rust-analyzer
              diagnostics = {
                enable = true,
              },
              procMacro = {
                enable = true,
                ignored = {
                  ["async-trait"] = { "async_trait" },
                  ["napi-derive"] = { "napi" },
                  ["async-recursion"] = { "async_recursion" },
                },
              },
              files = {
                excludeDirs = {
                  ".direnv",
                  ".git",
                  ".github",
                  ".gitlab",
                  "bin",
                  "node_modules",
                  "target",
                  "venv",
                  ".venv",
                },
              },
            },
          },
        },
      },
    },

    {
      "igorlfs/nvim-dap-view",
      lazy = false,
      keys = {
        {
          "<leader>du",
          function()
            require("dap-view").toggle()
          end,
          desc = "Dap UI",
        },
        {
          "<leader>de",
          function()
            require("dap-view").add_expr()
          end,
          desc = "Watch",
          mode = { "n", "x" },
        },
        {
          "<leader>ds",
          function()
            require("dap-view").show_view("sessions")
          end,
          desc = "Show Session",
        },
        {
          "<leader>dW",
          function()
            require("dap-view").show_view("watches")
          end,
          desc = "Show Watch",
        },
        {
          "<leader>dB",
          function()
            require("dap-view").show_view("breakpoints")
          end,
          desc = "Show Breakpoints",
        },
      },
      opts = {
        auto_toggle = true,
        windows = {
          terminal = {
            width = 0.4,
            position = "right",
            start_hidden = false,
          },
        },
        winbar = {
          sections = {
            "watches",
            "scopes",
            "exceptions",
            "sessions",
            "breakpoints",
            "threads",
            "repl",
          },
        },
      },
      config = function(_, opts)
        local dap = require("dap")
        local dapview = require("dap-view")
        local breakpoints = require("dap.breakpoints")

        dapview.setup(opts)

        local function store_breakpoints()
          local filename = vim.api.nvim_buf_get_name(0)
          local buf_id = vim.api.nvim_get_current_buf()
          local buf_breakpoints = breakpoints.get()[buf_id]

          if #filename == 0 then
            return
          end

          vim.g.DAP_BREAKPOINTS = { [filename] = buf_breakpoints }
        end

        local function load_breakpoints()
          local current_bps = breakpoints.get()
          local saved_bps = vim.g.DAP_BREAKPOINTS or {}
          local bufs_to_restore = {}

          -- Find the new loaded buffer.
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            local file_name = vim.api.nvim_buf_get_name(buf)

            local breakpoints_not_loaded = current_bps[buf] == nil
            local has_saved_breakpoints = not vim.tbl_isempty(saved_bps[file_name] or {})

            if breakpoints_not_loaded and has_saved_breakpoints then
              bufs_to_restore[file_name] = buf
            end
          end

          for filename, buf_id in pairs(bufs_to_restore) do
            for _, bp in pairs(saved_bps[filename]) do
              local line = bp.line
              local o = {
                condition = bp.condition,
                log_message = bp.logMessage,
                hit_condition = bp.hitCondition,
              }
              breakpoints.set(o, buf_id, line)
            end
          end
        end

        dap.listeners.before.event_initialized["dapui_config"] = function()
          load_breakpoints()
        end

        dap.listeners.after.event_initialized["dapui_config"] = function()
          -- dapview.open()
          require("dap-view.vim-sessions").load_session_hook()
        end
        vim.api.nvim_create_autocmd("VimLeavePre", {
          callback = function()
            store_breakpoints()
          end,
        })
      end,
    },
  },
})

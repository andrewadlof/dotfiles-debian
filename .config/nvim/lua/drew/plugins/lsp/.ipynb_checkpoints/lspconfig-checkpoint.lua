return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "folke/neodev.nvim", opts = {} },
  },
  config = function()
    -- import lspconfig plugin
    local lspconfig = require("lspconfig")

    -- import mason_lspconfig plugin
    local mason_lspconfig = require("mason-lspconfig")

    -- import cmp-nvim-lsp plugin
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    local keymap = vim.keymap -- for conciseness

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        -- Buffer local mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local opts = { buffer = ev.buf, silent = true }

        -- set keybinds
        opts.desc = "Show LSP references"
        keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

        opts.desc = "Go to declaration"
        keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

        opts.desc = "Show LSP definitions"
        keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

        opts.desc = "Show LSP implementations"
        keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

        opts.desc = "Show LSP type definitions"
        keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

        opts.desc = "See available code actions"
        keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

        opts.desc = "Smart rename"
        keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

        opts.desc = "Show buffer diagnostics"
        keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

        opts.desc = "Show line diagnostics"
        keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

        opts.desc = "Go to previous diagnostic"
        keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

        opts.desc = "Go to next diagnostic"
        keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

        opts.desc = "Show documentation for what is under cursor"
        keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

        opts.desc = "Restart LSP"
        keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
      end,
    })

    -- used to enable autocompletion (assign to every lsp server config)
    local capabilities = cmp_nvim_lsp.default_capabilities()

    -- Change the Diagnostic symbols in the sign column (gutter)
    -- (not in youtube nvim video)
    local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    end

    mason_lspconfig.setup_handlers({
      -- default handler for installed servers
      function(server_name)
        lspconfig[server_name].setup({
          capabilities = capabilities,
        })
      end,
      ["svelte"] = function()
        -- configure svelte server
        lspconfig["svelte"].setup({
          capabilities = capabilities,
          on_attach = function(client, bufnr)
            vim.api.nvim_create_autocmd("BufWritePost", {
              pattern = { "*.js", "*.ts" },
              callback = function(ctx)
                -- Here use ctx.match instead of ctx.file
                client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
              end,
            })
          end,
        })
      end,
      ["graphql"] = function()
        -- configure graphql language server
        lspconfig["graphql"].setup({
          capabilities = capabilities,
          filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
        })
      end,
      ["emmet_ls"] = function()
        -- configure emmet language server
        lspconfig["emmet_ls"].setup({
          capabilities = capabilities,
          filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
        })
      end,
      ["lua_ls"] = function()
        -- configure lua server (with special settings)
        lspconfig["lua_ls"].setup({
          capabilities = capabilities,
          settings = {
            Lua = {
              -- make the language server recognize "vim" global
              diagnostics = {
                globals = { "vim" },
              },
              completion = {
                callSnippet = "Replace",
              },
            },
          },
        })
      end,
      ["ruff_lsp"] = function()
        -- configure ruff language server
        lspconfig["ruff_lsp"].setup({
          capabilities = capabilities,
          init_options = {
            settings = {
              -- Configure Ruff settings based on pyproject.toml
              args = {},
              exclude = {
                ".bzr", ".direnv", ".eggs", ".git", ".git-rewrite", ".hg",
                ".ipynb_checkpoints", ".mypy_cache", ".nox", ".pants.d",
                ".pyenv", ".pytest_cache", ".pytype", ".ruff_cache", ".svn",
                ".tox", ".venv", ".vscode", "__pypackages__", "_build",
                "buck-out", "build", "dist", "node_modules", "site-packages", "venv"
              },
              lineLength = 88,
              indentWidth = 4,
              targetVersion = "py311",
              format = {
                quoteStyle = "double",
                indentStyle = "space",
                skipMagicTrailingComma = true,
                lineEnding = "auto",
                docstringCodeFormat = true,
                docstringCodeLineLength = "dynamic"
              },
              lint = {
                select = { "E4", "E7", "E9", "F" },
                ignore = { "E402" },
                fixable = {"*"},
                unfixable = {},
                dummyVariableRgx = "^(_+|(_+[a-zA-Z0-9_]*[a-zA-Z0-9]+?))$"
              }
            }
          },
          -- Configure organizeImports and fixAll on save
          on_attach = function(client, bufnr)
            if client.supports_method("textDocument/formatting") then
              vim.api.nvim_create_autocmd("BufWritePre", {
                buffer = bufnr,
                callback = function()
                  -- Organize imports and apply fixes before saving
                  vim.lsp.buf.code_action({
                    context = {
                      only = { "source.organizeImports" }
                    },
                    apply = true
                  })
                  vim.lsp.buf.format({ bufnr = bufnr, async = false })
                end,
              })
            end
          end,
        })
      end,
    })
  end,
}
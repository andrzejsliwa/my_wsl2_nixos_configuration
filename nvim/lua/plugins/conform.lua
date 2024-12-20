return {
  "stevearc/conform.nvim",
  optional = true,
  opts = {
    formatters_by_ft = {
      nix = { "alejandra" },
      eruby = { "htmlbeautifier" },
      ruby = { "standardrb" },
      lua = { "stylua" },
      markdown = { "markdownlint" },
      yaml = { "yamlfix" },
      javascript = { "prettierd", "prettier" },
      typescript = { "prettierd", "prettier" },
      json = { "jq" },
    },
  },
}

# markdown-todo.nvim

Extended todo-item syntax for markdown.

A simple implementation of [neorg](https://github.com/nvim-neorg/neorg)'s [todo_items](https://github.com/nvim-neorg/neorg/wiki/Todo-Items) but for markdown.

---

[Demo](https://youtu.be/Bi9JiW5nSig?t=410)

![2023-07-17-17-12-08](https://github.com/thenbe/markdown-todo.nvim/assets/33713262/8aa0302c-21c3-4d30-a5c8-2316e92e411b)

## Keys

- `<leader>tu`: Mark as Undone
- `<leader>tp`: Mark as Pending
- `<leader>td`: Mark as Done
- `<leader>th`: Mark as On Hold
- `<leader>tc`: Mark as Cancelled
- `<leader>ti`: Mark as Important
- `<leader>tr`: Mark as Recurring
- `<leader>ta`: Mark as Ambiguous

## Install

```lua
-- lazy.nvim
{
	"thenbe/markdown-todo.nvim",
	ft = { "md", "markdown" },
	config = true,
}
```

## Credits

- [neorg](https://github.com/nvim-neorg/neorg)

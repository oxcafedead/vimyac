# vimyac - HttpYac for vim/neovim

This tiny plugin just wraps the [HttpYac](https://httpyac.github.io) CLI to quickly execute HTTP requests from vim.\
Similar to [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) for VSCode or 
[HTTP Client](https://www.jetbrains.com/help/idea/http-client-in-product-code-editor.html) for IntelliJ IDEA.

## Installation

Just install using your favorite plugin manager.\
Example for `vim-plug`:

```vim
Plug 'oxcafedead/vimyac'
```

## Requirements

Please note: as the plugin is just a wrapper for the HttpYac CLI, you need to have it installed on your system.\
You can install it in various ways, the only requirement is that the `httpyac` command should be available in your PATH.\
For example, you can install it using npm:

```sh
npm install -g httpyac
```

## Usage

By default, plugin provides the following commands:

- `:ExecYac` - Execute the request which matches the current line. Default keybinding is `<leader>yr`
- `:ExecYacAll` - Execute all requests in the current file. Default keybinding is `<leader>ya`

**Important:** the buffer should be saved before executing the request.

### Demonstration

![Demo](./demo.gif)

# vimyac - HttpYac for vim/neovim

This tiny plugin just wraps the [HttpYac](https://httpyac.github.io) CLI to quickly execute HTTP requests from vim.\
Similar to [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) for VSCode or 
[HTTP Client](https://www.jetbrains.com/help/idea/http-client-in-product-code-editor.html) for IntelliJ IDEA.

## Requirements

Please note: as the plugin is just a wrapper for the HttpYac CLI, you need to have the latter installed on your system.\
You can install it in various ways, the only requirement is that the `httpyac` command should be available in your PATH.\
For example, you can install it using npm:

```sh
npm install -g httpyac
```

## Installation

Just install using your favorite plugin manager.\
Example for `vim-plug`:

```vim
Plug 'oxcafedead/vimyac'
```

## Usage

By default, plugin provides the following commands:

- `:YacExec` - Execute the request which matches the current line. Default keybinding is `<leader>yr`
- `:YacExecAll` - Execute all requests in the current file. Default keybinding is `<leader>ya`

Supports everything that HttpYac supports, including variables, environments, auth schemas, etc.\
Additional arguments can be passed to the `httpyac` command for the flexibility, for example:

```vim
:YacExec --timeout 5000
```

You can get familiar with all the rich features of the awesome HttpYac tool by visiting the [official documentation](https://httpyac.github.io).

### Demonstration

![Demo](./demo.gif)

### Limitations

- The buffer has to be saved before executing the request
- The vim current directory should match the directory of the http file
- Plugin is a wrapper for the CLI, so it doesn't provide any additional features like syntax highlighting, etc.

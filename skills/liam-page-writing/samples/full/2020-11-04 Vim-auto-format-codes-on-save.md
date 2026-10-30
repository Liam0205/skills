---
title: "让 Vim 在保存文件时自动格式化代码"
url: https://liam.page/2020/11/04/Vim-auto-format-codes-on-save/
date: 2020-11-04
categories: ["Computer Skills"]
tags: ["Format", "Vim", "Clang-format"]
---

写代码时，遵循一定的代码风格是很有必要的。对于这种机械性的工作，我们的主张是要寻找自动化的解决方案。

对于 Vim 和 C++ 的组合，这里推荐以下搭配，并辅以适当配置：

- clang-format

- [vim-autoformat 插件](https://github.com/Chiel92/vim-autoformat)

配置分为两部分。一是实现在保存文件时自动格式化代码；二是实现在 visual 模式下格式化部分代码。

```vim
autocmd FileType c,cpp autocmd BufWritePre * :Autoformat
```

这里对 C 和 C++ 代码，在保存文件之前，自动执行 :Autoformat，以便使用 vim-autoformat 插件调用 clang-format 格式化代码。

```vim
" autoformat
nnoremap <leader>ff :call FormatCode("", "file")<CR>
vnoremap <leader>ff :call FormatCode(visualmode(), "file")<CR>
nnoremap <leader>gf :call FormatCode("", "Google")<CR>
vnoremap <leader>gf :call FormatCode(visualmode(), "Google")<CR>
nnoremap <leader>cf :call FormatCode("", "Chromium")<CR>
vnoremap <leader>cf :call FormatCode(visualmode(), "Chromium")<CR>
nnoremap <leader>lf :call FormatCode("", "LLVM")<CR>
vnoremap <leader>lf :call FormatCode(visualmode(), "LLVM")<CR>

func! FormatCode(exe_mode, style) range
  if a:exe_mode == ""
    let firstline_no = 1
    let lastline_no = line("$")
  else
    let firstline_no = a:firstline
    let lastline_no = a:lastline
  endif
  let l:save_formatdef = g:formatdef_clangformat
  let l:tmpa = join(["clang-format --lines=", firstline_no, ":", lastline_no], "")
  let g:formatdef_clangformat = "'" . l:tmpa . " --assume-filename=' . bufname('%') . ' -style=" . a:style . "'"
  let formatcommand = ":Autoformat"
  exec formatcommand
  let g:formatdef_clangformat = l:save_formatdef
endfunc
```

这里利用 range 函数，根据调用时的所在的模式的不同，格式化整个文件，或者是在 Visual 模式下格式化选中的行。
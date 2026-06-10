# VIM (Vi Impoved) Things related to Julia

* VIM supports natively Julia syntax highlighting using the `JuliaEditorSupport/julia-vim` Plugin. Essentially,
```
call plug#begin('~/.vim/plugged')
" https://github.com/JuliaEditorSupport/julia-vim/blob/master/INSTALL.md
Plug 'JuliaEditorSupport/julia-vim'
call plug#end()
```
* useful key codes:
  * `Ctrl+k * X` &rarr; ×   (`\times`, cross-product)
  * `Ctrl+k R T` &rarr; √   (`\sqrt`, square-root)
  * Greek Letters: Ctrl+k * \<letter\> &rarr; \<greek letter\>
    for instance: `Ctrl+k * a` &rarr; α (`\alpha`),    `Ctrl+k * G` &rarr; Γ  (`\Gamma`)

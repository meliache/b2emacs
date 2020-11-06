# b2emacs --- basf2 helper functions for EMACS


This package is intended for scientists in the Belle II collaboration that work
with the [Belle II Analysis Software Framework](https://doi.org/10.1007/s41781-018-0017-9) (basf2, currently still
collaboration-internal). It provides functions for getting help on basf2 modules
and basf2 variable from withing EMACS.

This package does not provide any IDE features for working with C++ or python.
For that, I recommend using other packages, e.g.
[elpy](https://github.com/jorgenschaefer/elpy) for python and
[lsp-mode](https://github.com/emacs-lsp/lsp-mode) for C++ editing. This package
only provides basf2-specific help that those packages are missing. See the
collaboration-internal https://confluence.desy.de/x/8wx6B for more tipps on
using EMACS with basf2.

## Installation

### Normal installation with manual cloning

First clone the package with:
``` bash
git clone https://github.com/meliache/b2emacs /path/to/b2emacs
```

Then, add the following lines to your [emacs
init](https://www.gnu.org/software/emacs/manual/html_node/emacs/Init-File.html)
file (usually `.emacs` or `.emacs.d/init.el`) :

``` elisp
(add-to-list 'load-path "/path/to/b2emacs/")
(require 'b2emacs)
```

If you use the excellent [use-package](https://github.com/jwiegley/use-package),
add the following lines:

``` elisp
(use-package b2emacs
  :load-path "/path/to/b2emacs/"
  :ensure nil)
```

### With straight.el

This requires that you have set up the
[straight.el](https://github.com/raxod502/straight.el) package manager, which
uses git for managing packages and is a substitute for the built-in `package.el`
If you use straight, you don't need to clone the package manually, straight will
handle that for you:

``` elisp
(straight-use-package
 '(b2emacs :type git :host github :repo "meliache/b2emacs" :branch  "main"))
```

## Usage

First make sure you have basf2 set up before running emacs or ensure in some other way
that the basf2 environment variables are set in emacs. Then you will be able to
use the interactive helper-functions that this package provides. Either call
them interactively with

```
M-x <function-name>
```

or bind them to some keybindings, e.g. with

``` elisp
(define-key python-mode-map (kbd "C-h C-b v") #'basf2-describe-variable)
(define-key python-mode-map (kbd "C-h C-b m") #'basf2-describe-module)
```

With the interactive functions

- `basf2-describe-variable`
- `basf2-describe-module`

You will be prompted to select a basf2 variable/module name with autocompletion
and once you have selected a candidate, a window with the description will open.

For using these functions efficently, I really recommend using an
incremental completion package for emacs, either the built-in
[https://www.masteringemacs.org/article/introduction-to-ido-mode](ido), or the
installable [ivy](https://github.com/abo-abo/swiper) or
<https://github.com/emacs-helm/helm>.

Furthermore, the package provides functions for getting the description of the
basf2 variable/module that the point (cursor) is currently on:

- `basf2-variable-at-point`
- `basf2-module-at-point`

Also, you can just run `basf2-variables-help`, which will just open the output
of `basf2 variables.py` in a help-window.

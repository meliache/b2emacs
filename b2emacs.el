;;; b2emacs --- basf2 helper functions for EMACS  -*-  lexical-binding: t -*-; coding: utf-8 -*-

;; Author: Michael Eliachevitch <meliache@uni-bonn.de>
;; Homepage: https://github.com/meliache/b2emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;; Commentary:

;; Package intended for scientists in the Belle II collaboration that work with
;; the Belle II Analysis Software Framework (basf2, currently still
;; collaboration-internal). It provides functions for getting help on basf2
;; modules and basf2 variable from withing EMACS.

;; This package does not provide any IDE features for working with C++ or
;; python. For that, I recommend using other packages, e.g. elpy for python and
;; lsp-mode for C++ editing. This package only provides basf2-specific help that
;; those packages are missing. See the collaboration-internal
;; https://confluence.desy.de/x/8wx6B for more tipps on using EMACS with basf2.

;;; Code:

;; In contrast to `python-shell-send-string` and similar existing functions
;; this does not interact with with an inferior python process. Also I cannot
;; just use `shell-command-to-string " python3 -c '...'`, because that does not
;; use python from the current exec-path, but creates a subshell with a clean
;; environment.
(defun python-command-to-string (command)
  "Run python3 with COMMAND and return output."
  (with-output-to-string
    (with-current-buffer standard-output
      (call-process "python3" nil t nil "-c" command))))

;;;###autoload
(defun fixstyle-buffer ()
  "Format python or C++ buffer to confirm to Belle II style guidelines."
  (interactive)
  (shell-command  (concat "b2code-style-fix" " " buffer-file-name)))

(defun basf2-available-modules ()
  "Return list of available basf2 modules."
  (split-string (python-command-to-string "
from basf2 import list_available_modules
for k in list_available_modules().keys():
    print(k)")))

;;;###autoload
(defun basf2-describe-module (module)
  "Open description of MODULE in help-window. Supports autocompletion when run interactively."
  (interactive
   (list
    (completing-read "Describe basf2 module: " (basf2-available-modules))))
  (let ((module-description
          (shell-command-to-string  (format "%s -m %s" (executable-find "basf2") module))))
    (with-help-window "*basf2-module-description*"
      (princ module-description))))


(defun basf2-available-variables ()
  "Return list of available variable names."
  (split-string (python-command-to-string "
from variables import variables as vm
for var in vm.getVariables():
    print(var.name)")))

;;;###autoload
(defun basf2-describe-variable (var)
  "Describe basf2 variable VAR. Supports autocompletion when run interactively."
  (interactive
   (list
    (completing-read "Describe basf2 variable: " (basf2-available-variables))))
  (with-help-window "*basf2-variable*"
    (princ (python-command-to-string (format "
from variables import variables as vm
var = vm.getVariable('%s')
print('Variable:', var.name)
print('\\n', var.description) " var)))))

;;;###autoload
(defun basf2-variable-at-point ()
  "Describe basf2 variable under the cursor position."
  (interactive)
  (basf2-describe-variable (symbol-at-point)))

;;;###autoload
(defun basf2-module-at-point ()
  "Describe basf2 module under the cursor position."
  (interactive)
  (basf2-describe-module (symbol-at-point)))

;;;###autoload
(defun basf2-variables-help ()
  "Open help buffer with a list of all basf2 variables and their descriptions."
  (interactive)
  (with-help-window "*basf2-variables*"
    (call-process "basf2" nil "*basf2-variables*" nil "variables.py")))

(provide 'b2emacs)
;;; b2emacs.el ends here

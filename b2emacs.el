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
(require 'help-mode)
(require 'thingatpt)
(require 'json)

;; Taken from Malabarba in https://emacs.stackexchange.com/a/3208
(defun basf2--assoc-recursive (alist &rest keys)
  "Recursively find KEYS in ALIST."
  (while keys
    (setq alist (cdr (assoc (pop keys) alist))))
  alist)

;; Taken from wasamasa  in https://emacs.stackexchange.com/a/33626
(defun basf2--alist-keys (alist)
  "Helper function to return all keys of an ALIST."
  (mapcar 'car alist))

;; In contrast to `python-shell-send-string` and similar existing functions
;; this does not interact with with an inferior python process. Also I cannot
;; just use `shell-command-to-string " python3 -c '...'`, because that does not
;; use python from the current exec-path, but creates a subshell with a clean
;; environment.
(defun basf2--python-command-to-string (command)
  "Run python3 with COMMAND and return output."
  (with-output-to-string
    (with-current-buffer standard-output
      (call-process "python3" nil t nil "-c" command))))

;;;###autoload
(defun fixstyle-buffer ()
  "Format python or C++ buffer to confirm to Belle II style guidelines."
  (interactive)
  (shell-command  (concat "b2code-style-fix" " " buffer-file-name)))

(defun basf2--available-modules ()
  "Return list of available basf2 modules."
  (split-string (basf2--python-command-to-string "
from basf2 import list_available_modules
for k in list_available_modules().keys():
    print(k)")))

;;;###autoload
(defun basf2-describe-module (module)
  "Open description of MODULE in help-window. Supports autocompletion when run interactively."
  (interactive
   (list
    (completing-read "Describe basf2 module: " (basf2--available-modules))))
  (let ((module-description
          (shell-command-to-string  (format "%s -m %s" (executable-find "basf2") module))))
    (with-help-window "*basf2-module*"
      (princ module-description))))


(defun basf2--get-variable-info-alist ()
  "Return alist with available variable names as keys and their group and description as values."
  (let ((variables-info-json-string (basf2--python-command-to-string "
import json
from variables import variables as vm
variables = vm.getVariables()
variable_info_dict = {
    var.name: {
        'group': var.group,
        'description': var.description,
    }
    for var in variables
}
print(json.dumps(variable_info_dict))"))
        (json-key-type 'string))
    (json-read-from-string variables-info-json-string)))



;;;###autoload
(defun basf2-describe-variable (var-name variable-info-alist)
  "Describe basf2 variable VAR-NAME using info from VARIABLE-INFO-ALIST. Supports autocompletion when run interactively."
  (interactive
   (let* ((variable-info-alist (basf2--get-variable-info-alist))
          (variable-names (basf2--alist-keys variable-info-alist)))
    (list
     (completing-read "Describe basf2 variable: " variable-names)
     variable-info-alist)))
  (with-help-window "*basf2-variable*"
    (princ (format "Variable: %s\nGroup: %s\nDescription: %s"
                   var-name
                   (basf2--assoc-recursive variable-info-alist var-name "group")
                   (basf2--assoc-recursive variable-info-alist var-name "description")))))

(defun basf2--get-meta-variable-base-name (meta-variable-name)
  "Get the base name of a META-VARIABLE-NAME which includes the signature.

The meta variable names from `vm.getNames()` include the
signature in the name. However, this is problematic when using
`symbol-at-point` for obtaining variable names, since those don't
include that signature. To match those two, this function is
needed to obtain the base names before the parantheses."
  (car (split-string meta-variable-name "[\(\)]+" t " ")))

;;;###autoload
(defun basf2-variable-at-point ()
  "Describe basf2 variable under the cursor position."
  (interactive)
  (let* ((variable-infos (basf2--get-variable-info-alist))
         ;; define alist which maps the base name of a metavariable (as returned
         ;; by symbol-at-point) to the full name with the signature as returned
         ;; by vm.getNames()
         (variable-names-by-base-name
          (mapcar
           (lambda (var-info) (cons (basf2--get-meta-variable-base-name (car var-info)) (car var-info)))
           variable-infos))
         (variable-name (cdr (assoc (symbol-name (symbol-at-point)) variable-names-by-base-name))))
    (basf2-describe-variable variable-name variable-infos)))

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

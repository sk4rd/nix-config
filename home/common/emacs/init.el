;;; init.el --- Emacs configuration -*- lexical-binding: t; -*-

;;; Sane defaults

;; Disable package.el (Nix manages packages)
(setq package-enable-at-startup nil)

;; Clean UI
(tool-bar-mode -1)
(scroll-bar-mode -1)
(menu-bar-mode -1)
(setq inhibit-startup-message t)
(setq use-short-answers t)

;; UTF-8 everywhere
(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8)

;; Relative line numbers in prog-mode
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(setq display-line-numbers-type 'relative)

;; Quality of life
(electric-pair-mode 1)
(save-place-mode 1)
(recentf-mode 1)
(savehist-mode 1)
(global-auto-revert-mode 1)

;; Indentation
(setq-default indent-tabs-mode nil)
(setq-default tab-width 2)

;; Keep backups and auto-saves out of the way
(setq backup-directory-alist '(("." . "~/.emacs.d/backups"))
      auto-save-file-name-transforms '((".*" "~/.emacs.d/auto-saves/" t))
      auto-save-list-file-prefix "~/.emacs.d/auto-saves/.saves-"
      create-lockfiles nil)

;;; Theme

(use-package modus-themes
  :ensure nil
  :config
  (load-theme 'modus-vivendi-tinted t))

;;; Modeline

(use-package nerd-icons
  :ensure nil)

(use-package doom-modeline
  :ensure nil
  :init
  (doom-modeline-mode 1))

;;; Minibuffer completion

(use-package vertico
  :ensure nil
  :init
  (vertico-mode 1))

(use-package orderless
  :ensure nil
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :ensure nil
  :init
  (marginalia-mode 1))

(use-package consult
  :ensure nil
  :bind
  (("C-x b" . consult-buffer)
   ("C-s" . consult-line)
   ("M-g g" . consult-goto-line)
   ("M-s r" . consult-ripgrep)))

;;; In-buffer completion

(use-package corfu
  :ensure nil
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  :init
  (global-corfu-mode 1))

(use-package cape
  :ensure nil
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file))

;;; which-key

(use-package which-key
  :ensure nil
  :init
  (which-key-mode 1))

;;; Magit

(use-package magit
  :ensure nil
  :bind ("C-x g" . magit-status))

;;; Org-mode

(use-package org
  :ensure nil
  :custom
  (org-directory "~/org")
  (org-agenda-files '("~/org"))
  (org-todo-keywords '((sequence "TODO(t)" "NEXT(n)" "WAITING(w@)" "|" "DONE(d!)" "CANCELLED(c@)")))
  (org-log-into-drawer t)
  (org-capture-templates
   '(("t" "Task" entry (file+headline "~/org/tasks.org" "Inbox")
      "* TODO %?\n  %U\n  %a")
     ("n" "Note" entry (file+headline "~/org/notes.org" "Notes")
      "* %?\n  %U")
     ("j" "Journal" entry (file+datetree "~/org/journal.org")
      "* %?\n  %U"))))

;;; Org-roam

(use-package org-roam
  :ensure nil
  :custom
  (org-roam-directory "~/org/roam")
  (org-roam-capture-templates
   '(("d" "default" plain "%?"
      :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                         "#+title: ${title}\n")
      :unnarrowed t)
     ("r" "reference" plain "%?"
      :target (file+head "reference/%<%Y%m%d%H%M%S>-${slug}.org"
                         "#+title: ${title}\n#+filetags: :reference:\n")
      :unnarrowed t)
     ("p" "project" plain "%?"
      :target (file+head "project/%<%Y%m%d%H%M%S>-${slug}.org"
                         "#+title: ${title}\n#+filetags: :project:\n")
      :unnarrowed t)))
  (org-roam-dailies-directory "daily/")
  :bind
  (("C-c n f" . org-roam-node-find)
   ("C-c n i" . org-roam-node-insert)
   ("C-c n l" . org-roam-buffer-toggle)
   ("C-c n c" . org-roam-capture)
   ("C-c n d" . org-roam-dailies-goto-today))
  :config
  (org-roam-db-autosync-mode 1))

;;; Tree-sitter

(setq major-mode-remap-alist
      '((js-mode . js-ts-mode)
        (javascript-mode . js-ts-mode)
        (json-mode . json-ts-mode)
        (css-mode . css-ts-mode)))

;;; Eglot

(use-package eglot
  :ensure nil
  :hook (js-ts-mode . eglot-ensure)
  :custom
  (eglot-autoshutdown t))

;;; Nix-mode

(use-package nix-mode
  :ensure nil
  :mode "\\.nix\\'")

;;; js2-mode

(use-package js2-mode
  :ensure nil
  :custom
  (js2-basic-offset 2))

;;; rainbow-delimiters

(use-package rainbow-delimiters
  :ensure nil
  :hook (prog-mode . rainbow-delimiters-mode))

;;; envrc

(use-package envrc
  :ensure nil
  :init
  (envrc-global-mode 1))

;;; init.el ends here

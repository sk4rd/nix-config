;; Nix manages packages.
(setq package-enable-at-startup nil)

;; Improve startup responsiveness and LSP throughput.
(setq gc-cons-threshold (* 100 1024 1024)
      gc-cons-percentage 0.6
      read-process-output-max (* 1024 1024)
      inhibit-compacting-font-caches t)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 24 1024 1024)
                  gc-cons-percentage 0.1)))

(require 'use-package)
(setq use-package-always-ensure nil)

;; Core behavior
(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8-unix)
(setq inhibit-startup-message t
      use-short-answers t
      ring-bell-function 'ignore
      switch-to-buffer-obey-display-actions t
      tab-always-indent 'complete)

(tool-bar-mode -1)
(scroll-bar-mode -1)
(menu-bar-mode -1)
(global-hl-line-mode 1)
(global-auto-revert-mode 1)
(electric-pair-mode 1)
(show-paren-mode 1)
(save-place-mode 1)
(savehist-mode 1)
(recentf-mode 1)

(setq-default indent-tabs-mode nil
              tab-width 2)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(setq display-line-numbers-type 'relative)

(let ((backup-dir (expand-file-name "backups/" user-emacs-directory))
      (autosave-dir (expand-file-name "auto-saves/" user-emacs-directory)))
  (make-directory backup-dir t)
  (make-directory autosave-dir t)
  (setq backup-directory-alist `(("." . ,backup-dir))
        auto-save-file-name-transforms `((".*" ,autosave-dir t))
        auto-save-list-file-prefix (concat autosave-dir ".saves-")
        create-lockfiles nil))

(set-face-attribute 'default nil :family "FiraCode Nerd Font" :height 100)

;; UI
(use-package doom-themes
  :custom
  (doom-themes-enable-bold t)
  (doom-themes-enable-italic t))

(defvar my/theme-dark 'doom-one
  "Primary dark theme.")

(defvar my/theme-light 'doom-one-light
  "Primary light theme.")

(defvar my/theme-variant 'dark
  "Current theme variant, either `dark' or `light'.")

(defun my/load-theme-variant (variant)
  "Load theme VARIANT (`dark' or `light')."
  (mapc #'disable-theme custom-enabled-themes)
  (pcase variant
    ('dark (load-theme my/theme-dark t))
    ('light (load-theme my/theme-light t)))
  (setq my/theme-variant variant))

(defun my/toggle-theme-variant ()
  "Toggle between dark and light themes."
  (interactive)
  (my/load-theme-variant (if (eq my/theme-variant 'dark) 'light 'dark)))

(my/load-theme-variant 'dark)

(use-package nerd-icons)

(use-package doom-modeline
  :hook (after-init . doom-modeline-mode)
  :custom
  (doom-modeline-minor-modes nil)
  (doom-modeline-buffer-file-name-style 'truncate-upto-project))

(use-package which-key
  :init
  (which-key-mode 1)
  :custom
  (which-key-idle-delay 0.5)
  (which-key-sort-order #'which-key-key-order-alpha))

;; Minibuffer completion
(setq completion-ignore-case t
      read-buffer-completion-ignore-case t
      read-file-name-completion-ignore-case t)

(use-package vertico
  :init
  (vertico-mode 1))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :after vertico
  :init
  (marginalia-mode 1))

(use-package consult
  :bind (("C-x b" . consult-buffer)
         ("C-s" . consult-line)
         ("M-g g" . consult-goto-line)
         ("M-g f" . consult-flymake)
         ("M-s r" . consult-ripgrep)
         ("M-y" . consult-yank-pop)
         ("C-x C-r" . consult-recent-file)
         ("C-c i" . consult-imenu)))

(use-package embark
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim)
         ("C-h B" . embark-bindings))
  :init
  (setq prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :after (embark consult))

;; In-buffer completion
(use-package corfu
  :init
  (global-corfu-mode 1)
  (corfu-history-mode 1)
  (corfu-popupinfo-mode 1)
  :custom
  (corfu-auto t)
  (corfu-auto-prefix 2)
  (corfu-auto-delay 0.08)
  (corfu-cycle t)
  (corfu-preselect 'prompt)
  (corfu-preview-current nil)
  :bind (:map corfu-map
              ("M-SPC" . corfu-insert-separator)
              ("TAB" . corfu-next)
              ([tab] . corfu-next)
              ("S-TAB" . corfu-previous)
              ([backtab] . corfu-previous)
              ("RET" . corfu-insert)))

(use-package nerd-icons-corfu
  :after (nerd-icons corfu)
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(use-package cape
  :init
  (defun my/add-extra-capfs ()
    "Add generic CAPFs without overriding LSP CAPF order."
    (add-hook 'completion-at-point-functions #'cape-file t t)
    (add-hook 'completion-at-point-functions #'cape-dabbrev t t))
  (add-hook 'prog-mode-hook #'my/add-extra-capfs)
  (add-hook 'text-mode-hook #'my/add-extra-capfs))

(use-package yasnippet
  :init
  (yas-global-mode 1))

(use-package yasnippet-snippets
  :after yasnippet)

;; Navigation / editing QoL
(use-package avy
  :bind (("M-j" . avy-goto-char-timer)))

(use-package ace-window
  :bind (("M-o" . ace-window)
         ("C-x o" . ace-window))
  :custom
  (aw-scope 'frame)
  (aw-background t)
  (aw-dispatch-always nil)
  (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  :config
  (set-face-attribute 'aw-leading-char-face nil :height 2.0 :weight 'bold))

(use-package olivetti
  :custom
  (olivetti-body-width 120)
  (olivetti-minimum-body-width 90))

(defvar-local my/zen--line-numbers-were-on nil
  "Non-nil when line numbers were enabled before entering zen mode.")

(defun my/toggle-zen-mode ()
  "Toggle centered editing for focused work."
  (interactive)
  (if (bound-and-true-p olivetti-mode)
      (progn
        (olivetti-mode -1)
        (when my/zen--line-numbers-were-on
          (display-line-numbers-mode 1))
        (setq-local my/zen--line-numbers-were-on nil))
    (setq-local my/zen--line-numbers-were-on display-line-numbers)
    (olivetti-mode 1)
    (display-line-numbers-mode -1)))

(use-package expand-region
  :bind (("C-=" . er/expand-region)))

(use-package smartparens
  :hook ((prog-mode org-mode) . smartparens-mode)
  :config
  (require 'smartparens-config))

(use-package multiple-cursors
  :bind (("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)
         ("C-c C-<" . mc/mark-all-like-this)))

(use-package undo-fu
  :bind (("C-z" . undo-fu-only-undo)
         ("C-S-z" . undo-fu-only-redo)))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; Projects and buffers
(use-package project
  :ensure nil
  :bind-keymap ("C-c p" . project-prefix-map))

(global-set-key (kbd "C-x C-b") #'ibuffer)

(tab-bar-mode 1)
(setq tab-bar-show 1
      tab-bar-close-button-show nil
      tab-bar-new-button-show nil)

(defun my/consult-ripgrep-project ()
  "Run ripgrep from project root when available."
  (interactive)
  (if-let ((project (project-current)))
      (consult-ripgrep (project-root project))
    (consult-ripgrep default-directory)))

;; File tree
(use-package treemacs
  :defer t
  :bind (("C-x t t" . treemacs)
         ("C-x t f" . treemacs-find-file))
  :custom
  (treemacs-width 35)
  (treemacs-follow-after-init t)
  (treemacs-is-never-other-window t)
  (treemacs-show-hidden-files nil)
  :config
  (treemacs-follow-mode 1)
  (treemacs-filewatch-mode 1)
  (when (executable-find "git")
    (treemacs-git-mode 'deferred)))

;; Language modes
(use-package nix-mode
  :mode "\\.nix\\'")

(dolist (mode-remap '((js-mode . js-ts-mode)
                      (javascript-mode . js-ts-mode)
                      (typescript-mode . typescript-ts-mode)
                      (json-mode . json-ts-mode)
                      (css-mode . css-ts-mode)))
  (add-to-list 'major-mode-remap-alist mode-remap))

(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))

;; Fast LSP client (built-in)
(setq eglot-send-changes-idle-time 0.15)

(use-package eglot
  :ensure nil
  :hook ((js-ts-mode . eglot-ensure)
         (typescript-ts-mode . eglot-ensure)
         (tsx-ts-mode . eglot-ensure)
         (python-mode . eglot-ensure)
         (python-ts-mode . eglot-ensure)
         (nix-mode . eglot-ensure))
  :bind (:map eglot-mode-map
              ("C-c l a" . eglot-code-actions)
              ("C-c l r" . eglot-rename)
              ("C-c l f" . eglot-format)
              ("C-c l o" . eglot-code-action-organize-imports)
              ("C-c l q" . eglot-shutdown))
  :custom
  (eglot-autoshutdown t)
  (eglot-events-buffer-size 0)
  (eglot-sync-connect nil)
  :config
  (add-to-list 'eglot-server-programs
               '((js-ts-mode typescript-ts-mode tsx-ts-mode)
                 . ("vtsls" "--stdio")))
  (add-to-list 'eglot-server-programs
               '((nix-mode) . ("nixd")))
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode)
                 . ("pyright-langserver" "--stdio"))))

(use-package flymake
  :ensure nil
  :bind (("M-n" . flymake-goto-next-error)
         ("M-p" . flymake-goto-prev-error)))

(use-package envrc
  :init
  (envrc-global-mode 1))

;; Formatting
(use-package apheleia
  :hook ((js-ts-mode . apheleia-mode)
         (typescript-ts-mode . apheleia-mode)
         (tsx-ts-mode . apheleia-mode)
         (json-ts-mode . apheleia-mode)
         (css-ts-mode . apheleia-mode)
         (nix-mode . apheleia-mode))
  :config
  (setf (alist-get 'prettier apheleia-formatters)
        (if (executable-find "prettier")
            '("prettier" "--stdin-filepath" filepath)
          '("npx" "prettier" "--stdin-filepath" filepath)))
  (setf (alist-get 'nixfmt apheleia-formatters)
        '("nixfmt"))
  (dolist (mode '(js-ts-mode
                  typescript-ts-mode
                  tsx-ts-mode
                  json-ts-mode
                  css-ts-mode))
    (setf (alist-get mode apheleia-mode-alist) 'prettier))
  (setf (alist-get 'nix-mode apheleia-mode-alist) 'nixfmt))

;; Git
(use-package magit
  :bind (("C-x g" . magit-status)))

(use-package diff-hl
  :hook ((prog-mode . diff-hl-mode)
         (dired-mode . diff-hl-dired-mode)
         (magit-post-refresh . diff-hl-magit-post-refresh)))

;; Notes / Org
(use-package org
  :ensure nil
  :bind (("C-c a" . org-agenda)
         ("C-c c" . org-capture))
  :custom
  (org-directory "~/org")
  (org-agenda-files '("~/org/tasks.org" "~/org/notes.org" "~/org/projects.org"))
  (org-log-into-drawer t)
  (org-hide-emphasis-markers t)
  (org-src-fontify-natively t)
  (org-src-tab-acts-natively t)
  (org-confirm-babel-evaluate nil)
  (org-todo-keywords
   '((sequence "TODO(t)" "NEXT(n)" "WAITING(w@)" "|" "DONE(d!)" "CANCELLED(c@)")))
  (org-capture-templates
   '(("t" "Task" entry (file+headline "~/org/tasks.org" "Inbox")
      "* TODO %?\n  %U\n  %a")
     ("n" "Note" entry (file+headline "~/org/notes.org" "Notes")
      "* %?\n  %U")
     ("j" "Journal" entry (file+datetree "~/org/journal.org")
      "* %?\n  %U")))
  :config
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (shell . t)
     (python . t))))

(use-package denote
  :bind (("C-c n n" . denote)
         ("C-c n o" . denote-open-or-create)
         ("C-c n l" . denote-link)
         ("C-c n r" . denote-rename-file))
  :custom
  (denote-directory (expand-file-name "~/org/denote"))
  (denote-known-keywords '("emacs" "nix" "typescript" "project" "notes"))
  (denote-infer-keywords t)
  (denote-sort-keywords t)
  :config
  (denote-rename-buffer-mode 1))

;; Leader key: C-c m
(defvar my/leader-map (make-sparse-keymap))
(define-key global-map (kbd "C-c m") my/leader-map)

(defun my/leader-prefix (key)
  "Create and register a sub-keymap under `my/leader-map'."
  (let ((map (make-sparse-keymap)))
    (define-key my/leader-map (kbd key) map)
    map))

(let ((file-map (my/leader-prefix "f"))
      (buffer-map (my/leader-prefix "b"))
      (project-map (my/leader-prefix "p"))
      (git-map (my/leader-prefix "g"))
      (notes-map (my/leader-prefix "n"))
      (workspace-map (my/leader-prefix "w"))
      (toggle-map (my/leader-prefix "t")))
  (define-key file-map (kbd "f") #'find-file)
  (define-key file-map (kbd "r") #'consult-recent-file)
  (define-key file-map (kbd "s") #'save-buffer)

  (define-key buffer-map (kbd "b") #'consult-buffer)
  (define-key buffer-map (kbd "k") #'kill-current-buffer)
  (define-key buffer-map (kbd "i") #'ibuffer)

  (define-key project-map (kbd "p") #'project-switch-project)
  (define-key project-map (kbd "f") #'project-find-file)
  (define-key project-map (kbd "g") #'my/consult-ripgrep-project)
  (define-key project-map (kbd "t") #'treemacs)

  (define-key git-map (kbd "g") #'magit-status)

  (define-key notes-map (kbd "c") #'org-capture)
  (define-key notes-map (kbd "a") #'org-agenda)
  (define-key notes-map (kbd "n") #'denote)
  (define-key notes-map (kbd "o") #'denote-open-or-create)

  (define-key workspace-map (kbd "n") #'tab-bar-new-tab)
  (define-key workspace-map (kbd "c") #'tab-bar-close-tab)
  (define-key workspace-map (kbd "l") #'tab-bar-switch-to-next-tab)
  (define-key workspace-map (kbd "h") #'tab-bar-switch-to-prev-tab)
  (define-key workspace-map (kbd "r") #'tab-bar-rename-tab)
  (define-key workspace-map (kbd "w") #'ace-window)

  (define-key toggle-map (kbd "t") #'treemacs)
  (define-key toggle-map (kbd "l") #'display-line-numbers-mode)
  (define-key toggle-map (kbd "h") #'my/toggle-theme-variant)
  (define-key toggle-map (kbd "z") #'my/toggle-zen-mode))

(with-eval-after-load 'which-key
  (which-key-add-key-based-replacements
    "C-c m f" "files"
    "C-c m b" "buffers"
    "C-c m p" "projects"
    "C-c m g" "git"
    "C-c m n" "notes"
    "C-c m w" "workspace"
    "C-c m t" "toggles"
    "C-c m t h" "theme toggle"
    "C-c m t z" "zen mode"))

(provide 'init)

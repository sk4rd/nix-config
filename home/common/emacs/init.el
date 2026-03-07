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

;; Welcome screen
(setq inhibit-startup-screen t
      initial-scratch-message nil)

(defconst my/welcome-buffer-name "*Welcome*"
  "Name of the startup welcome buffer.")

(defface my/welcome-title-face
  '((t (:inherit default :weight bold :height 1.0)))
  "Face used for the welcome title.")

(defface my/welcome-subtitle-face
  '((t (:inherit shadow :height 1.0)))
  "Face used for small startup metadata.")

(defface my/welcome-section-face
  '((t (:inherit default :weight bold :height 1.1)))
  "Face used for section headers.")

(defface my/welcome-key-face
  '((t (:inherit font-lock-keyword-face :weight bold)))
  "Face used for displayed keybindings.")

(defconst my/welcome-title-art
  '("• ▌ ▄ ·. ▪  ▄ •▄       .▄▄ ·     ▄▄▄ .• ▌ ▄ ·.  ▄▄▄·  ▄▄· .▄▄ ·  "
    "·██ ▐███▪██ █▌▄▌▪▪     ▐█ ▀.     ▀▄.▀··██ ▐███▪▐█ ▀█ ▐█ ▌▪▐█ ▀.  "
    "▐█ ▌▐▌▐█·▐█·▐▀▀▄· ▄█▀▄ ▄▀▀▀█▄    ▐▀▀▪▄▐█ ▌▐▌▐█·▄█▀▀█ ██ ▄▄▄▀▀▀█▄ "
    "██ ██▌▐█▌▐█▌▐█.█▌▐█▌.▐▌▐█▄▪▐█    ▐█▄▄▌██ ██▌▐█▌▐█ ▪▐▌▐███▌▐█▄▪▐█ "
    "▀▀  █▪▀▀▀▀▀▀·▀  ▀ ▀█▄▀▪ ▀▀▀▀      ▀▀▀ ▀▀  █▪▀▀▀ ▀  ▀ ·▀▀▀  ▀▀▀▀  ")
  "ASCII art title rendered in the welcome buffer.")

(defconst my/welcome-key-groups
  '(("Leader map (custom): C-c m"
     ("C-c m f f" "find file")
     ("C-c m f r" "recent files")
     ("C-c m b b" "switch buffer")
     ("C-c m p p" "switch project")
     ("C-c m p g" "project ripgrep")
     ("C-c m g g" "magit status")
     ("C-c m n c" "org capture")
     ("C-c m w n" "new tab")
     ("C-c m t h" "toggle theme")
     ("C-c m t z" "toggle zen mode"))
    ("Search and navigation"
     ("C-s" "search in buffer")
     ("M-s r" "ripgrep")
     ("C-c i" "imenu")
     ("M-j" "avy jump")
     ("M-o" "ace-window")
     ("C-x t t" "treemacs")
     ("C-x t f" "treemacs find file"))
    ("LSP and diagnostics"
     ("C-c l a" "code actions")
     ("C-c l r" "rename symbol")
     ("C-c l f" "format buffer")
     ("C-c l o" "organize imports")
     ("M-n / M-p" "next/previous diagnostic"))
    ("Notes and knowledge"
     ("C-c a" "org agenda")
     ("C-c c" "org capture")
     ("C-c n n" "new denote note")
     ("C-c n o" "open or create denote")
     ("C-c n l" "denote link")
     ("C-c n r" "rename denote note"))
    ("Editing and buffers"
     ("C-=" "expand region")
     ("C-> / C-<" "next/previous multi-cursor")
     ("C-z / C-S-z" "undo / redo")
     ("C-x b" "consult buffer")
     ("C-x C-b" "ibuffer")
     ("C-x C-r" "recent file")
     ("C-x g" "magit status")))
  "Keybinding groups rendered in the startup welcome screen.")

(defconst my/welcome-quick-actions
  '(("[f] Find file" . find-file)
    ("[r] Recent files" . consult-recent-file)
    ("[b] Switch buffer" . consult-buffer)
    ("[p] Switch project" . project-switch-project)
    ("[i] Open init.el" . my/welcome-open-user-init))
  "Quick actions rendered near the top of the welcome screen.")

(defconst my/welcome-tips-text
  "Tips: use which-key after prefixes (e.g. C-c m), and press g to refresh this screen."
  "Tips text rendered at the bottom of the welcome screen.")

(defun my/welcome--doom-color (name fallback)
  "Return Doom color NAME when available, otherwise FALLBACK."
  (if (fboundp 'doom-color)
      (or (doom-color name) fallback)
    fallback))

(defun my/welcome--lerp (a b ratio)
  "Linearly blend A to B by RATIO."
  (+ (* (- 1.0 ratio) a) (* ratio b)))

(defun my/welcome--blend-colors (from to ratio)
  "Blend FROM and TO colors by RATIO and return a hex color."
  (if (require 'color nil t)
      (let* ((from-rgb (color-name-to-rgb from))
             (to-rgb (color-name-to-rgb to))
             (r (my/welcome--lerp (nth 0 from-rgb) (nth 0 to-rgb) ratio))
             (g (my/welcome--lerp (nth 1 from-rgb) (nth 1 to-rgb) ratio))
             (b (my/welcome--lerp (nth 2 from-rgb) (nth 2 to-rgb) ratio)))
        (color-rgb-to-hex r g b 2))
    from))

(defun my/welcome--shade-color (color percent)
  "Return COLOR lightened or darkened by PERCENT."
  (if (require 'color nil t)
      (if (>= percent 0)
          (color-lighten-name color percent)
        (color-darken-name color (- percent)))
    color))

(defun my/welcome--insert-key-row (key description)
  "Insert one keybinding row with KEY and DESCRIPTION."
  (insert "  "
          (propertize (format "%-14s" key) 'face 'my/welcome-key-face)
          description
          "\n"))

(defun my/welcome--body-columns ()
  "Return welcome content width in columns."
  (cond
   ((and (bound-and-true-p olivetti-mode)
         (integerp olivetti-body-width))
    olivetti-body-width)
   ((and (bound-and-true-p olivetti-mode)
         (null olivetti-body-width))
    (+ fill-column 2))
   (t
    (window-body-width (selected-window)))))

(defun my/welcome--insert-centered-line (text &optional face)
  "Insert TEXT centered in the current window, optionally using FACE."
  (let* ((text-width (string-width text))
         (body-cols (my/welcome--body-columns))
         (padding (max 0 (/ (- body-cols text-width) 2))))
    (insert (make-string padding ?\s))
    (insert (if face (propertize text 'face face) text))
    (insert "\n")))

(defun my/welcome--insert-key-group (title rows)
  "Insert a group TITLE with keybinding ROWS."
  (insert (propertize title 'face 'my/welcome-section-face)
          "\n")
  (dolist (row rows)
    (my/welcome--insert-key-row (car row) (cadr row)))
  (insert "\n"))

(defun my/welcome-open-user-init ()
  "Open the main init file."
  (interactive)
  (find-file-existing user-init-file))

(defun my/welcome-run-command (button)
  "Run the command attached to BUTTON."
  (call-interactively (button-get button 'my-command)))

(defun my/welcome--insert-quick-actions ()
  "Insert interactive quick actions."
  (insert (propertize "Quick actions\n" 'face 'my/welcome-section-face))
  (let ((first t))
    (dolist (entry my/welcome-quick-actions)
      (unless first
        (insert "   "))
      (setq first nil)
      (insert-text-button
       (car entry)
       'my-command (cdr entry)
       'action #'my/welcome-run-command
       'follow-link t
       'help-echo (format "Run %s" (cdr entry)))))
  (insert "\n\n"))

(defun my/welcome-enforce-nowrap ()
  "Keep welcome buffer lines unwrapped even with Olivetti active."
  (visual-line-mode -1)
  (setq-local truncate-lines t
              word-wrap nil
              truncate-partial-width-windows t))

(defun my/welcome-render ()
  "Render the startup welcome buffer."
  (let ((inhibit-read-only t)
        (recent-count (if (boundp 'recentf-list) (length recentf-list) 0))
        (slime-base (my/welcome--doom-color 'blue "#51afef")))
    (when (and (bound-and-true-p olivetti-mode)
               (fboundp 'olivetti-set-buffer-windows))
      (olivetti-set-buffer-windows))
    (my/welcome-enforce-nowrap)
    (erase-buffer)
    (let* ((slime-bright (my/welcome--shade-color slime-base 14))
           (slime-deep (my/welcome--shade-color slime-base -32))
           (line-count (max 1 (length my/welcome-title-art)))
           (index 0))
      (dolist (line my/welcome-title-art)
        (let* ((ratio (if (> line-count 1)
                          (/ (float index) (1- line-count))
                        0.0))
               (color (my/welcome--blend-colors slime-bright slime-deep ratio)))
          (my/welcome--insert-centered-line
           line
           `(:inherit my/welcome-title-face :foreground ,color)))
        (setq index (1+ index))))
    (insert "\n")
    (my/welcome--insert-centered-line
     (format "Ready in %s  |  %s recent files  |  %s"
             (emacs-init-time)
             recent-count
             (format-time-string "%Y-%m-%d %H:%M"))
     'my/welcome-subtitle-face)
    (insert "\n")
    (my/welcome--insert-quick-actions)
    (dolist (group my/welcome-key-groups)
      (my/welcome--insert-key-group (car group) (cdr group)))
    (insert (propertize my/welcome-tips-text 'face 'my/welcome-subtitle-face))
    (goto-char (point-min))))

(define-derived-mode my/welcome-mode special-mode "Welcome"
  "Major mode for the startup welcome screen."
  (setq-local cursor-type nil)
  (when (require 'olivetti nil t)
    (setq-local olivetti-body-width 120
                olivetti-minimum-body-width 90)
    (setq olivetti-mode-on-hook nil
          olivetti-recall-visual-line-mode-entry-state nil)
    (olivetti-mode 1))
  (my/welcome-enforce-nowrap)
  (display-line-numbers-mode -1))

(defun my/welcome-buffer ()
  "Get and prepare the welcome buffer."
  (let ((buffer (get-buffer-create my/welcome-buffer-name)))
    (with-current-buffer buffer
      (my/welcome-mode))
    ;; Render only after the buffer is attached to a real window so centering
    ;; uses final on-screen geometry on first draw.
    (set-window-buffer (selected-window) buffer)
    (with-current-buffer buffer
      (my/welcome-render))
    buffer))

(defun my/welcome-refresh ()
  "Refresh the welcome screen."
  (interactive)
  (when (derived-mode-p 'my/welcome-mode)
    (my/welcome-render)))

(define-key my/welcome-mode-map (kbd "g") #'my/welcome-refresh)
(define-key my/welcome-mode-map (kbd "f") #'find-file)
(define-key my/welcome-mode-map (kbd "r") #'consult-recent-file)
(define-key my/welcome-mode-map (kbd "b") #'consult-buffer)
(define-key my/welcome-mode-map (kbd "p") #'project-switch-project)
(define-key my/welcome-mode-map (kbd "i") #'my/welcome-open-user-init)

(setq initial-buffer-choice
      (lambda ()
        (when (null command-line-args-left)
          (my/welcome-buffer))))

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
  (setq my/theme-variant variant)
  (when-let ((buffer (get-buffer my/welcome-buffer-name)))
    (with-current-buffer buffer
      (when (derived-mode-p 'my/welcome-mode)
        (my/welcome-render)))))

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
  (olivetti-minimum-body-width 90)
  (olivetti-mode-on-hook nil)
  (olivetti-recall-visual-line-mode-entry-state nil))

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
  :hook ((prog-mode . apheleia-mode)
         (text-mode . apheleia-mode)
         (conf-mode . apheleia-mode))
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

;; -*- lexical-binding: t; -*-
(setq inhibit-startup-screen t initial-scratch-message nil
      ring-bell-function #'ignore
      use-short-answers t
      sentence-end-double-space nil)

(setq-default indent-tabs-mode nil
              tab-width 4
              fill-column 80
              require-final-newline t)

(column-number-mode 1)
(show-paren-mode 1)
(electric-pair-mode 1)
(delete-selection-mode 1)
(global-auto-revert-mode 1)
(menu-bar-mode -1)
(when (fboundp 'tool-bar-mode)
  (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1))

(add-hook 'prog-mode-hook #'display-line-numbers-mode)

(require 'windmove)
(global-set-key (kbd "C-c <left>") #'windmove-left)
(global-set-key (kbd "C-c <right>") #'windmove-right)
(global-set-key (kbd "C-c <up>") #'windmove-up)
(global-set-key (kbd "C-c <down>") #'windmove-down)

(require 'which-key)
(setq which-key-idle-delay 0.5)
(which-key-mode 1)

(let* ((cache-directory "@emacsCacheDirectory@")
       (backup-directory (expand-file-name "backups/" cache-directory))
       (auto-save-directory (expand-file-name "auto-saves/" cache-directory)))
  (dolist (directory (list cache-directory backup-directory auto-save-directory))
    (make-directory directory t))

  ;; Keep recovery files without littering the directories being edited.
  (setq backup-directory-alist `(("." . ,backup-directory))
        backup-by-copying t
        version-control t
        kept-new-versions 5
        kept-old-versions 2
        delete-old-versions t
        auto-save-file-name-transforms `((".*" ,auto-save-directory t))
        auto-save-list-file-prefix (expand-file-name ".saves-" auto-save-directory)
        create-lockfiles nil
        custom-file (expand-file-name "custom.el" cache-directory)
        savehist-file (expand-file-name "history" cache-directory)
        save-place-file (expand-file-name "places" cache-directory)
        recentf-save-file (expand-file-name "recentf" cache-directory)
        recentf-max-saved-items 50
        project-list-file (expand-file-name "projects" cache-directory))
  (load custom-file 'noerror 'nomessage))

(add-to-list 'custom-theme-load-path
             (file-name-directory (locate-library "neon-flux-theme")))
(load-theme 'neon-flux t)
(set-face-attribute 'default nil :family "JetBrainsMono NFM")

(savehist-mode 1)
(save-place-mode 1)
(recentf-mode 1)

(require 'vertico)
(setq vertico-cycle t)
(vertico-mode 1)

(require 'orderless)
(setq completion-styles '(orderless basic)
      completion-category-defaults nil
      completion-category-overrides '((file (styles partial-completion basic))))

(require 'marginalia)
(marginalia-mode 1)

(require 'consult)
(require 'consult-xref)
(setq xref-show-xrefs-function #'consult-xref
      xref-show-definitions-function #'consult-xref)

(require 'embark)
(global-set-key (kbd "C-.") #'embark-act)
(global-set-key (kbd "C-;") #'embark-dwim)
(global-set-key (kbd "C-h B") #'embark-bindings)
(setq prefix-help-command #'embark-prefix-help-command)

(require 'embark-consult)
(add-hook 'embark-collect-mode-hook #'consult-preview-at-point-mode)

(require 'cape)
(add-to-list 'completion-at-point-functions #'cape-file)
(add-to-list 'completion-at-point-functions #'cape-dabbrev)

(require 'corfu)
(setq corfu-cycle t
      corfu-auto t
      corfu-auto-delay 0.2
      corfu-auto-prefix 2
      corfu-preselect 'prompt
      completion-cycle-threshold 3)
(global-corfu-mode 1)

(global-set-key [remap switch-to-buffer] #'consult-buffer)
(global-set-key [remap switch-to-buffer-other-window] #'consult-buffer-other-window)
(global-set-key [remap switch-to-buffer-other-frame] #'consult-buffer-other-frame)
(global-set-key [remap yank-pop] #'consult-yank-pop)
(global-set-key [remap goto-line] #'consult-goto-line)
(global-set-key [remap imenu] #'consult-imenu)
(global-set-key (kbd "C-x C-r") #'consult-recent-file)
(global-set-key (kbd "M-s l") #'consult-line)
(global-set-key (kbd "M-s r") #'consult-ripgrep)
(consult-customize consult-ripgrep :preview-key '(:debounce 0.3 any))

(require 'org)
(require 'org-capture)
(require 'org-agenda)
(require 'org-datetree)
(require 'org-timer)
(setq org-directory (file-name-as-directory
                     (expand-file-name "@emacsNotesDirectory@"))
      org-agenda-files (mapcar (lambda (file) (expand-file-name file org-directory))
                              '("tasks.org" "inbox.org"))
      org-default-notes-file (expand-file-name "inbox.org" org-directory)
      org-archive-location (concat (expand-file-name "archive/%s_archive" org-directory)
                                   "::")
      org-todo-keywords '((sequence "TODO(t)" "DOING(p)" "|" "DONE(d)"))
      org-log-done 'time
      org-startup-indented t
      org-hide-emphasis-markers t)

(dolist (directory '("" "roam/concepts" "roam/references" "roam/projects" "archive"))
  (make-directory (expand-file-name directory org-directory) t))
(dolist (file '("inbox.org" "tasks.org" "journal.org"))
  (let ((path (expand-file-name file org-directory)))
    (unless (file-exists-p path)
      ;; Exclusive creation also protects notes created concurrently.
      (condition-case nil
          (write-region "" nil path nil 'silent nil 'excl)
        (file-already-exists nil)))))

(setq org-capture-templates
      `(("i" "Inbox" entry (file ,org-default-notes-file)
         "* %?\n%U\n%i\n")
        ("t" "Task" entry (file ,(expand-file-name "tasks.org" org-directory))
         "* TODO %?\n%U\n%i\n")
        ("l" "Learning session" entry
         (file ,(expand-file-name "tasks.org" org-directory))
         "* TODO %^{Activity}\n:PROPERTIES:\n:Effort: %^{Duration (h:mm)|0:20|0:10|0:30}\n:END:\n%?"
         :empty-lines 1)
        ("j" "Journal" entry
         (file+olp+datetree ,(expand-file-name "journal.org" org-directory))
         "* %<%H:%M> %?\n%i\n")))

(defun my/org-agenda-skip-unprocessed-inbox ()
  "Exclude inbox headings without an actionable TODO from the agenda."
  (when (and (equal (buffer-file-name) org-default-notes-file)
             (not (member (org-get-todo-state) org-not-done-keywords)))
    (save-excursion (or (outline-next-heading) (point-max)))))
(setq org-agenda-skip-function-global #'my/org-agenda-skip-unprocessed-inbox)

(setq org-agenda-custom-commands
      '(("l" "Learning today"
         ((agenda ""
                  ((org-agenda-overriding-header "Schedule — this week")
                   (org-agenda-span 'week)
                   (org-agenda-start-on-weekday 1)
                   (org-agenda-skip-scheduled-if-done t)
                   (org-agenda-skip-deadline-if-done t)))
          (todo "DOING"
                ((org-agenda-overriding-header "In progress")))
          (todo "TODO"
                ((org-agenda-overriding-header "Ready to study")
                 (org-agenda-skip-function
                  '(org-agenda-skip-entry-if 'scheduled 'deadline))
                 (org-agenda-sorting-strategy '(effort-up category-keep))))
          (agenda ""
                  ((org-agenda-overriding-header "Completed — last seven days")
                   (org-agenda-start-day "-6d")
                   (org-agenda-start-on-weekday nil)
                   (org-agenda-span 7)
                   (org-agenda-show-log 'only)
                   (org-agenda-log-mode-items '(closed))
                   (org-agenda-show-all-dates nil)
                   (org-agenda-use-time-grid nil)
                   (org-agenda-skip-function-global nil))))
         ((org-agenda-prefix-format
           '((agenda . " %?-12t% s%?-6e ")
             (todo . " %-6e ")))))))

(defun my/org-learning-agenda ()
  "Show the learning schedule, available sessions, and recent completions."
  (interactive)
  (org-agenda nil "l"))

(defun my/org-learning-start ()
  "Start the session at point using its Effort, from Org or the agenda."
  (interactive)
  (when org-timer-start-time
    (user-error "Stop the current Org timer with C-c n x first"))
  (let ((marker (cond
                 ((derived-mode-p 'org-agenda-mode)
                  (or (org-get-at-bol 'org-hd-marker)
                      (user-error "Select a session in the agenda")))
                 ((derived-mode-p 'org-mode) (point-marker))
                 (t (user-error "Select a session in Org or its agenda")))))
    (org-with-point-at marker
      (org-back-to-heading t)
      (unless (member (org-get-todo-state) '("TODO" "DOING"))
        (user-error "Select a TODO or DOING session"))
      (let* ((effort (or (org-entry-get nil org-effort-property)
                         (read-string "Session duration (h:mm): " nil nil "0:20")))
             (minutes (condition-case nil
                          (org-duration-to-minutes effort)
                        (error (user-error "Use a duration such as 0:20")))))
        (unless (and (> minutes 0) (= minutes (floor minutes)))
          (user-error "The duration must be a positive whole number of minutes"))
        (org-set-effort nil effort)
        (org-timer-set-timer (floor minutes))
        (org-todo "DOING")))
    (when (derived-mode-p 'org-agenda-mode)
      (org-agenda-redo))))

(defun my/org-journal-today ()
  "Open today's date tree in the same journal used by capture."
  (interactive)
  (find-file (expand-file-name "journal.org" org-directory))
  (widen)
  (org-datetree-find-date-create (calendar-current-date))
  (org-show-context)
  (org-show-subtree))

(defun my/consult-notes ()
  "Search all note content with Consult."
  (interactive)
  (consult-ripgrep org-directory))

(require 'org-roam)
(setq org-roam-directory (expand-file-name "roam/" org-directory)
      org-roam-db-location (expand-file-name "org-roam.db" "@emacsCacheDirectory@")
      org-roam-capture-templates
      '(("d" "Note" plain "%?"
         :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n")
         :unnarrowed t)))
(org-roam-db-autosync-mode 1)

(require 'org-modern)
(require 'org-appear)
(add-hook 'org-mode-hook #'visual-line-mode)
(add-hook 'org-mode-hook #'org-modern-mode)
(add-hook 'org-mode-hook #'org-appear-mode)
(add-hook 'org-agenda-finalize-hook #'org-modern-agenda)

(global-set-key (kbd "C-c n c") #'org-capture)
(global-set-key (kbd "C-c n a") #'my/org-learning-agenda)
(global-set-key (kbd "C-c n A") #'org-agenda)
(global-set-key (kbd "C-c n t") #'my/org-learning-start)
(global-set-key (kbd "C-c n x") #'org-timer-stop)
(global-set-key (kbd "C-c n f") #'org-roam-node-find)
(global-set-key (kbd "C-c n i") #'org-roam-node-insert)
(global-set-key (kbd "C-c n b") #'org-roam-buffer-toggle)
(global-set-key (kbd "C-c n d") #'my/org-journal-today)
(global-set-key (kbd "C-c n s") #'my/consult-notes)

(require 'magit)
(global-set-key (kbd "C-x g") #'magit-status)

(require 'diff-hl)
(global-diff-hl-mode 1)
(add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh)

(require 'vterm)
(global-set-key (kbd "C-c t") #'vterm)
(setq vterm-max-scrollback 10000)

(require 'project)
(setq project-switch-commands
      '((project-find-file "Find file")
        (consult-ripgrep "Search")
        (project-dired "Dired")
        (project-switch-to-buffer "Buffer")
        (project-vc-dir "VC-Dir")
        (project-compile "Compile")
        (project-eshell "Eshell")))
(define-key project-prefix-map (kbd "g") #'consult-ripgrep)

(require 'dired)
(setq dired-listing-switches "-alh --group-directories-first"
      dired-dwim-target t
      dired-auto-revert-buffer #'dired-directory-changed-p
      global-auto-revert-non-file-buffers t)
(add-hook 'dired-mode-hook #'dired-hide-details-mode)

(require 'breadcrumb)
(breadcrumb-mode 1)

(require 'markdown-mode)
(dolist (key '("C-c <left>" "C-c <right>"
               "C-c <up>" "C-c <down>"))
  (define-key markdown-mode-map (kbd key) nil))
(setq markdown-fontify-code-blocks-natively t
      markdown-command '("@emacsPandoc@" "--from=gfm" "--to=html5")
      markdown-live-preview-window-function #'markdown-live-preview-window-eww
      markdown-split-window-direction 'right)
(add-to-list 'auto-mode-alist '("\\(?:\\`\\|/\\)README\\.md\\'" . gfm-mode))

(require 'gptel)
(defun my/gptel-project-chat (original name &optional key initial interactivep)
  "With a prefix, choose a project and open its dedicated chat."
  (interactive
   (lambda (spec)
     (if current-prefix-arg
         (list (project-prompt-project-dir) nil
               (and (use-region-p)
                    (buffer-substring (region-beginning) (region-end)))
               t)
       (advice-eval-interactive-spec spec))))
  (if (and interactivep current-prefix-arg)
      (let* ((root (file-name-as-directory (expand-file-name name)))
             (default-directory root)
             (buffer (funcall original
                              (format "*gptel: %s*" root)
                              key initial interactivep)))
        (with-current-buffer buffer
          (setq-local default-directory root))
        buffer)
    (funcall original name key initial interactivep)))
(advice-add 'gptel :around #'my/gptel-project-chat)

(setq gptel-display-buffer-action
      '((display-buffer-in-side-window)
        (side . right)
        (slot . 0)
        (window-width . 0.33)
        (body-function . select-window))
      gptel-default-mode 'org-mode)
(require 'gptel-openai-oauth)
(gptel-make-openai-oauth "OpenAI-sub"
  :models '((gpt-6.1-sol
             :description "Complex coding and agentic workflows"
             :reasoning-effort "medium"
             :capabilities (media tool-use json responses-api)
             :mime-types ("image/jpeg" "image/png" "image/gif" "image/webp"))
            (gpt-6-luna
             :description "Efficient model for focused tasks"
             :reasoning-effort "medium"
             :capabilities (media tool-use json responses-api)
             :mime-types ("image/jpeg" "image/png" "image/gif" "image/webp"))))
(require 'gptel-ollama)
(gptel-make-ollama "Ollama"
  :host "localhost:11434"
  :stream t
  :models '((qwen3.8:27b
             :capabilities (media tool-use)
             :mime-types ("image/jpeg" "image/png" "image/webp"))))
(add-hook 'gptel-prompt-transform-functions
          (lambda (fsm)
            (when (gptel-ollama-p gptel-backend)
              (setq-local gptel-include-reasoning nil)
              (plist-put (gptel-fsm-info fsm) :include-reasoning nil))))
(setq-default gptel-backend (gptel-get-backend "OpenAI-sub")
              gptel-model 'gpt-6-luna)

(gptel-make-preset 'explain
  :description "Learn how code works"
  :system
  "Act as a programming tutor.
Explain concepts progressively.
Focus on why the code works.
Ask guiding questions when useful.
Do not solve exercises unless requested.")

(gptel-make-preset 'design
  :description "Discuss architecture"
  :system
  "Act as a software design partner.
Explore simple solutions first.
Explain tradeoffs and alternatives.
Follow existing project conventions.
Leave architectural decisions to me.")

(gptel-make-preset 'implement
  :description "Assist with implementation"
  :system
  "Act as a pair programmer.
Suggest small, understandable changes.
Explain why each change is necessary.
Avoid unnecessary abstractions.
Present code for me to apply manually.")

(require 'gptel-agent)
(gptel-agent-update)
;; Ordinary chats get web tools; the full agent preset is opt-in.
(setq-default gptel-tools (mapcar #'gptel-get-tool '("WebSearch" "WebFetch"))
              gptel-use-tools t
              gptel-confirm-tool-calls t)

(global-set-key (kbd "C-c g") #'gptel)
(global-set-key (kbd "C-c r") #'gptel-rewrite)
(global-set-key (kbd "C-c RET") #'gptel-send)

(require 'nix-mode)
(add-to-list 'auto-mode-alist '("\\.nix\\'" . nix-mode))

(require 'eldoc-box)
(require 'eglot)
(require 'consult-flymake)
(setq-default eglot-workspace-configuration
              '(:nixd (:formatting (:command ["nixfmt"]))))
(global-set-key (kbd "C-c e a") #'eglot-code-actions)
(global-set-key (kbd "C-c e r") #'eglot-rename)
(global-set-key (kbd "C-c e f") #'eglot-format-buffer)
(global-set-key (kbd "C-c e d") #'consult-flymake)
(global-set-key (kbd "C-c e D") #'flymake-show-project-diagnostics)
(global-set-key (kbd "C-c e h") #'eldoc-doc-buffer)
(add-hook 'eglot-managed-mode-hook
          (lambda ()
            (eldoc-box-hover-mode
             (if (and (eglot-managed-p) (display-graphic-p)) 1 -1))))
(add-to-list 'eglot-server-programs '(nix-mode . ("nixd")))

(defun my/eglot-format-nix-on-save ()
  "Format Nix buffers only while Eglot is managing them."
  (when (and (derived-mode-p 'nix-mode) (eglot-managed-p))
    (eglot-format-buffer)))

(add-hook 'nix-mode-hook #'eglot-ensure)
(add-hook 'nix-mode-hook
          (lambda ()
            (add-hook 'before-save-hook #'my/eglot-format-nix-on-save nil t)))

(require 'envrc)
(global-set-key (kbd "C-c e v") envrc-command-map)
(envrc-global-mode 1)

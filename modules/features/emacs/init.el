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
(delete-selection-mode 1)
(global-auto-revert-mode 1)
(menu-bar-mode -1)
(when (fboundp 'tool-bar-mode)
  (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1))

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
        recentf-max-saved-items 50)
  (load custom-file 'noerror 'nomessage))

(add-to-list 'custom-theme-load-path
             (file-name-directory (locate-library "neon-flux-theme")))
(load-theme 'neon-flux t)
(set-face-attribute 'default nil :family "JetBrainsMono NFM")

(savehist-mode 1)
(save-place-mode 1)
(recentf-mode 1)

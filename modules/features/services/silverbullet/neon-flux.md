---
tags: meta
---
# Neon Flux

Managed by `nix-config`; edit the theme there, not in this page.
The palette is shared with the Neon Flux desktop theme. Reload SilverBullet
(or run **System: Reload**) after syncing this page.

```space-style
/* priority: -100 */
html:root, html:root[data-theme] {
  color-scheme: dark;
  --root-background-color: @canvas@;
  --root-color: @text@;
  --ui-accent-color: @accent@;
  --ui-accent-text-color: @accent@;
  --ui-accent-contrast-color: @canvas@;
  --ui-surface-background-color: @surface@;
  --ui-surface-color: @text@;
  --ui-surface-subtle-color: @muted@;
  --ui-surface-border-color: @border@;
  --ui-surface-section-background-color: @raised@;
  --ui-surface-hover-background-color: @currentLine@;
  --highlight-color: @selection@;
  --link-color: @accent@;
  --link-missing-color: @warning@;
  --link-invalid-color: @error@;
  --meta-color: @purple@;
  --meta-subtle-color: @comment@;
  --subtle-color: @muted@;
  --subtle-background-color: @currentLine@;
  --top-color: @text@;
  --top-background-color: @surface@;
  --top-border-color: @structure@;
  --top-sync-error-color: @error@;
  --top-sync-error-background-color: @raised@;
  --top-saved-color: @success@;
  --top-unsaved-color: @warning@;
  --top-loading-color: @muted@;
  --panel-background-color: @surface@;
  --panel-border-color: @border@;
  --bhs-background-color: @surface@;
  --bhs-border-color: @border@;
  --modal-color: @text@;
  --modal-background-color: @surface@;
  --modal-border-color: @structure@;
  --modal-backdrop-color: @canvas@CC;
  --modal-header-label-color: @accent@;
  --modal-help-background-color: @raised@;
  --modal-help-color: @muted@;
  --modal-selected-option-background-color: @selection@;
  --modal-selected-option-color: @text@;
  --modal-hint-background-color: @structure@;
  --modal-hint-color: @text@;
  --modal-hint-inactive-background-color: @raised@;
  --modal-hint-inactive-color: @muted@;
  --modal-description-color: @muted@;
  --modal-selected-option-description-color: @accentBright@;
  --notifications-background-color: @raised@;
  --notifications-border-color: @border@;
  --notification-info-background-color: @surface@;
  --notification-error-background-color: @surface@;
  --notification-warning-background-color: @surface@;
  --button-background-color: @raised@;
  --button-hover-background-color: @selection@;
  --button-color: @text@;
  --button-border-color: @border@;
  --primary-button-background-color: @accent@;
  --primary-button-hover-background-color: @accentBright@;
  --primary-button-color: @canvas@;
  --primary-button-border-color: @accent@;
  --text-field-background-color: @raised@;
  --progress-background-color: @raised@;
  --progress-sync-color: @success@;
  --progress-index-color: @accent@;
  --action-button-background-color: transparent;
  --action-button-color: @muted@;
  --action-button-hover-color: @accentBright@;
  --action-button-active-color: @accent@;
  --editor-caret-color: @accent@;
  --editor-selection-background-color: @selection@;
  --editor-panels-bottom-color: @text@;
  --editor-panels-bottom-background-color: @surface@;
  --editor-panels-bottom-border-color: @border@;
  --editor-completion-detail-color: @muted@;
  --editor-completion-detail-selected-color: @accentBright@;
  --editor-list-bullet-color: @structure@;
  --editor-heading-color: @accent@;
  --editor-heading-meta-color: @comment@;
  --editor-hashtag-background-color: @raised@;
  --editor-hashtag-color: @hot@;
  --editor-hashtag-border-color: @border@;
  --editor-ruler-color: @border@;
  --editor-naked-url-color: @accent@;
  --editor-code-color: @text@;
  --editor-link-color: @accent@;
  --editor-link-url-color: @info@;
  --editor-link-meta-color: @comment@;
  --editor-wiki-link-page-background-color: @currentLine@;
  --editor-wiki-link-page-color: @accent@;
  --editor-wiki-link-page-missing-color: @warning@;
  --editor-wiki-link-page-invalid-color: @error@;
  --editor-wiki-link-color: @purple@;
  --editor-command-button-color: @accent@;
  --editor-command-button-background-color: @raised@;
  --editor-command-button-hover-background-color: @selection@;
  --editor-command-button-meta-color: @comment@;
  --editor-command-button-border-color: @border@;
  --editor-line-meta-color: @comment@;
  --editor-meta-color: @purple@;
  --editor-table-head-background-color: @raised@;
  --editor-table-head-color: @accentBright@;
  --editor-table-even-background-color: @currentLine@;
  --editor-blockquote-background-color: @currentLine@;
  --editor-blockquote-color: @muted@;
  --editor-blockquote-border-color: @structure@;
  --editor-code-background-color: @currentLine@;
  --editor-struct-color: @purple@;
  --editor-highlight-background-color: @selection@;
  --editor-code-comment-color: @comment@;
  --editor-code-variable-color: @text@;
  --editor-code-typename-color: @info@;
  --editor-code-string-color: @warning@;
  --editor-code-number-color: @hot@;
  --editor-code-operator-color: @accentBright@;
  --editor-code-info-color: @muted@;
  --editor-code-atom-color: @hot@;
  --editor-frontmatter-background-color: @surface@;
  --editor-frontmatter-color: @muted@;
  --editor-frontmatter-marker-color: @structure@;
  --editor-widget-background-color: @raised@;
  --editor-task-marker-color: @structure@;
  --editor-task-state-color: @success@;
  --editor-directive-mark-color: @purple@;
  --editor-directive-color: @muted@;
  --editor-directive-background-color: @currentLine@;
  --editor-panels-bottom-input-background-color: @raised@;
  --editor-panels-bottom-button-background-image: none;
  --editor-panels-bottom-button-active-background-image: none;
  --editor-font: "JetBrainsMono NFM", "JetBrains Mono", "iA-Mono", monospace;
  --danger-color: @error@;
  --danger-contrast-color: @canvas@;
  --success-color: @success@;
  --alert-error-background-color: @surface@;
  --alert-error-color: @error@;
  --alert-error-border-color: @error@;
  --alert-warning-background-color: @surface@;
  --alert-warning-color: @warning@;
  --alert-warning-border-color: @warning@;
  --alert-info-background-color: @surface@;
  --alert-info-color: @info@;
  --alert-info-border-color: @info@;
  --badge-background-color: @raised@;
  --badge-color: @accentBright@;
}
#sb-main .cm-editor .cm-activeLine { background: @currentLine@; }
#sb-main .cm-editor .cm-gutters {
  background: @canvas@;
  color: @muted@;
  border-color: @border@;
}
#sb-main .cm-editor .cm-activeLineGutter { color: @accent@; }
#sb-main .cm-editor .sb-keyword { color: @purple@; }
#sb-main .cm-editor .sb-comment { color: @comment@; font-style: italic; }
```

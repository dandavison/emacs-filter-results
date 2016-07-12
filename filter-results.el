;;; filter-results.el --- filter search results
;; Version: 0.0.1
;; Author: dandavison7@gmail.com
;; Keywords: search filter exclude
;; URL: https://github.com/dandavison/emacs-filter-results

(require 'cl)

(defvar search-files-mode-map (make-sparse-keymap))

(defvar search-files-max-line-width 300
  "Output lines will be truncated to this width to avoid slowing down emacs")

(define-derived-mode search-files-mode
  compilation-mode "search-files"
  "Major mode for search-files results buffer.
\\{search-files-mode-map}"

  (add-hook 'compilation-finish-functions
            'search-files-clean-up-compilation-buffer nil t))

(define-key search-files-mode-map "/" 'search-files-filter-results)
(define-key search-files-mode-map [(control /)] 'search-files-undo)
(define-key search-files-mode-map "\C-k" 'search-files-kill-line)
(define-key search-files-mode-map "\C-_" 'search-files-undo)
(define-key search-files-mode-map "\C-xu" 'search-files-undo)
(define-key search-files-mode-map [(super z)] 'search-files-undo)

(defun search-files-filter-results (&optional arg)
  "Filter search results, retaining matching lines.

With prefix argument, retain non-matching lines."
  (interactive "P")
  (search-files-do-in-results-buffer
   (if arg 'delete-matching-lines 'delete-non-matching-lines) 'from-beginning))

(defun search-files-kill-line ()
  "Kill line in search results buffer"
  (interactive)
  (search-files-do-in-results-buffer 'kill-line))

(defun search-files-undo ()
  "Undo in search results buffer"
  (interactive)
  (search-files-do-in-results-buffer 'undo))

(defun search-files-do-in-results-buffer (fn &optional do-from-beginning)
  (let ((buffer-read-only nil))
    (save-excursion
      (when do-from-beginning (goto-char (point-min)))
      (call-interactively fn))))

(defun search-files-truncate-lines (string)
  "Truncates lines to `search-files-max-line-width'"
  (mapconcat
   (lambda (line) (truncate-string-to-width line search-files-max-line-width))
   (split-string string "[\n\r]+")
   "\n"))

(defun search-files-clean-up-compilation-buffer (&optional buf ignored)
  (with-current-buffer (or buf (current-buffer))
    (let ((buffer-read-only nil)
          (grep-match-re "^[^: ]+:[0-9]+:"))
      (save-excursion
        (goto-char (point-min))
        (delete-region (point)
                       (progn
                         (re-search-forward grep-match-re)
                         (point-at-bol)))
        (goto-char (point-max))
        (delete-region (progn
                         (re-search-backward grep-match-re)
                         (forward-line 1)
                         (point-at-bol))
                       (point))))))

(require 'helm)

(defvar helm-filter-mode-buffer "*helm filter*")

(defun helm-filter-mode-action (-ignored)
  (switch-to-buffer helm-filter-mode-buffer)
  (let ((buffer-read-only nil))
    (delete-region (point-min) (point-max))
    (insert
     (with-current-buffer helm-last-buffer
       (search-files-truncate-lines (buffer-string))))
    (goto-char (point-min))
    (search-files-clean-up-compilation-buffer)
    (search-files-mode)))

(provide 'search-files)
;;; search-files.el ends here

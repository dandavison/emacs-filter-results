;;; filter-results.el --- filter search results
;; Version: 0.0.1
;; Author: dandavison7@gmail.com
;; Keywords: search filter exclude
;; URL: https://github.com/dandavison/emacs-filter-results

(require 'cl)

(defvar filter-results-buffer "*Filter Results*")

(defvar filter-results-mode-map (make-sparse-keymap))

(defvar filter-results-max-line-width 300
  "Output lines will be truncated to this width to avoid slowing down emacs")

(define-derived-mode filter-results-mode
  compilation-mode "filter-results"
  "Major mode for filter-results results buffer.
\\{filter-results-mode-map}"

  (add-hook 'compilation-finish-functions
            'filter-results-clean-up-compilation-buffer nil t))

(define-key filter-results-mode-map "/" 'filter-results-filter-results)
(define-key filter-results-mode-map [(control /)] 'filter-results-undo)
(define-key filter-results-mode-map "\C-k" 'filter-results-kill-line)
(define-key filter-results-mode-map "\C-_" 'filter-results-undo)
(define-key filter-results-mode-map "\C-xu" 'filter-results-undo)
(define-key filter-results-mode-map [(super z)] 'filter-results-undo)

(defun filter-results-filter-results (&optional arg)
  "Filter search results, retaining matching lines.

With prefix argument, retain non-matching lines."
  (interactive "P")
  (filter-results-do-in-results-buffer
   (if arg 'delete-matching-lines 'delete-non-matching-lines) 'from-beginning))

(defun filter-results-kill-line ()
  "Kill line in search results buffer"
  (interactive)
  (filter-results-do-in-results-buffer 'kill-line))

(defun filter-results-undo ()
  "Undo in search results buffer"
  (interactive)
  (filter-results-do-in-results-buffer 'undo))

(defun filter-results-do-in-results-buffer (fn &optional do-from-beginning)
  (let ((buffer-read-only nil))
    (save-excursion
      (when do-from-beginning (goto-char (point-min)))
      (call-interactively fn))))

(defun filter-results-truncate-lines (string)
  "Truncates lines to `filter-results-max-line-width'"
  (mapconcat
   (lambda (line) (truncate-string-to-width line filter-results-max-line-width))
   (split-string string "[\n\r]+")
   "\n"))

(defun filter-results-clean-up-compilation-buffer (&optional buf ignored)
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


(defun filter-results-helm-action (&optional ignored)
  (switch-to-buffer filter-results-buffer)
  (let ((buffer-read-only nil))
    (delete-region (point-min) (point-max))
    (insert
     (with-current-buffer helm-last-buffer
       (filter-results-truncate-lines (buffer-string))))
    (goto-char (point-min))
    (filter-results-clean-up-compilation-buffer)
    (filter-results-mode)))

(provide 'filter-results)
;;; filter-results.el ends here

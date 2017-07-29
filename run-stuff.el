;;; run-stuff.el --- a simple package                     -*- lexical-binding: t; -*-

;; Copyright (C) 2017  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>
;; Keywords: lisp
;; Version: 0.0.1

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Run commands from the region or current line,
;; with some simple specifiers to control behavior.

;;; Usage

;; (run-stuff-command-on-region-or-line)
;;
;; A command to execute the current selection or the current line.
;; 
;; - '$ ' Run in terminal.
;; - '~ ' Open with default mime type (works for paths too).
;; - 'http://' or 'https://' opens in a web-browser.
;; - Open in terminal if its a directory.
;; - Default to running the command without a terminal
;;   when none of the conditions above succeed.
;;
;; Note that there is support for line splitting,
;; so long commands may be split over multiple lines.
;; This is done using the '\' character, when executing the current line
;; all following lines which end with '\' will be included.
;;
;; So you can for define a shell command as follows:
;;
;; $ make \
;;   -C /my/project \
;;   --no-print-directory \
;;   --keep-going
;;
;; The entire block will be detected so you can run the command
;; with your cursor over any of these lines, without needing to move to the first.

;;; Code:

(defcustom run-stuff-open-command
  "xdg-open"
  "Used to run open files with their default mime type."
  :group 'run-stuff
  :safe #'stringp)

(defcustom run-stuff-terminal-command
  "xterm"
  "Used to run commands in a terminal,
the following text is to be executed."
  :group 'run-stuff
  :safe #'stringp)

(defcustom run-stuff-terminal-execute-flag
  "-e"
  "Used to run commands in a terminal,
the following text is to be executed."
  :group 'run-stuff
  :safe #'stringp)


(require 'subr-x)

(defun run-stuff--extract-split-lines (line-terminate-char)
  "Extract line(s) at point.
Multiple lines (below the current) are extracted
if they end with a backslash character.
Returns the line(s) as a string with no properties."
  (interactive)
  (save-excursion
    (let* ((start (line-beginning-position))
           (end start)
           (iterate t)
           (new-end))
      (while iterate
        (setq new-end (line-end-position))
        ;; could be more efficient?
        (setq new-end-ws
              (save-excursion
                (end-of-line)
                (skip-syntax-backward "-") (point)))
        (if (> new-end end)
            (progn
              (setq end new-end)
              (setq end-ws new-end-ws)
              (if (char-equal (char-before end-ws) line-terminate-char)
                  (forward-line)
                  (setq iterate nil)))
            (setq iterate nil)))
      (buffer-substring-no-properties start end))))

(defun run-stuff--extract-split-lines-search-up (line-terminate-char)
  "A version of run-stuff--extract-split-lines-joined which
detects lines above the current one"
  (interactive)
  (save-excursion
    (let* ((prev (line-beginning-position))
           (iterate t))
      (while iterate
        ;; could be more efficient?
        (setq above-new-end-ws
              (save-excursion
                (forward-line -1)
                (end-of-line)
                (skip-syntax-backward "-") (point)))
        (if (< above-new-end-ws prev)
            (progn
              (setq prev above-new-end-ws)
              (setq end-ws above-new-end-ws)
              (if (char-equal (char-before end-ws) line-terminate-char)
                  (forward-line -1)
                  (setq iterate nil)))
            (setq iterate nil)))
      (run-stuff--extract-split-lines line-terminate-char))))


(defun run-stuff--extract-split-lines-search-up-joined (line-terminate-char)
  "A version of run-stuff--extract-split-lines which
joins lines and removes the line-terminate-char"
  (let ((line-terminate-str (char-to-string line-terminate-char)))
    (mapconcat
     (function
      (lambda (s)
        (string-trim-right (string-remove-suffix line-terminate-str (string-trim s)))))
     (split-string (run-stuff--extract-split-lines-search-up line-terminate-char) "\n") " ")))



;;;###autoload
(defun run-stuff-command-on-region-or-line ()
  "Run selected text in a terminal or use the current line."
  (interactive)
  (let ((command
         (if (use-region-p)
             (buffer-substring (region-beginning) (region-end)) ;; current selection
             ;; (thing-at-point 'line t) ;; current line
             ;; a version that can extract multiple lines!
             (run-stuff--extract-split-lines-search-up-joined ?\\))))
    (cond
     ;; Run as command in terminal.
     ((string-prefix-p "$ " command)
      (call-process
       run-stuff-terminal-command nil 0 nil
       run-stuff-terminal-execute-flag
       (string-trim-left (string-remove-prefix "$ " command))))
     ;; Open the file with the default mime type.
     ((string-prefix-p "~ " command)
      (call-process
       run-stuff-open-command nil 0 nil
       (string-trim-left (string-remove-prefix "~ " command))))
     ;; Open the URL (web browser)
     ((or
       (string-prefix-p "http://" command)
       (string-prefix-p "https://" command))
      (call-process run-stuff-open-command nil 0 nil command))
     ;; Open terminal at path.
     ((file-directory-p command)
      ;; Expand since it may be relative to the current file.
      (let ((default-directory (expand-file-name command)))
        (call-process run-stuff-terminal-command nil 0 nil)))
     ;; Default, run directly without a terminal.
     (t
      (shell-command command)))))

(provide 'run-stuff)
;;; run-stuff.el ends here

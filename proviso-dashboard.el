;;; proviso-dashboard.el --- a dashboard for proviso projects
;; Copyright (C) 2018  Dan Harms (dharms)
;; Author: Dan Harms <enniomore@icloud.com>
;; Created: Wednesday, May 16, 2018
;; Version: 1.0
;; Modified Time-stamp: <2018-05-16 17:28:18 dharms>
;; Modified by: Dan Harms
;; Keywords: tools proviso projects
;; URL: https://github.com/articuluxe/proviso.git
;; Package-Requires: ((emacs "24.4"))

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
;; A dashboard for a project overview.
;;

;;; Code:
(require 'proviso-core)

(defvar proviso-dashboard-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "t" 'ignore)
    map))

(defconst proviso-dashboard-buffer-name "*projects*"
  "Buffer name for `proviso-dashboard' mode.")


(define-derived-mode proviso-dashboard-mode special-mode
  "Dashboard"
  "Major mode for providing an overview of a proviso project.
\\<proviso-dashboard-mode-map>
"
  (setq buffer-read-only t)
  (setq truncate-lines t)
  )

;;;###autoload
(defun proviso-dashboard-show ()
  "Show a dashboard."
  (interactive)
  (proviso-dashboard-create (proviso-current-project)))

(defun proviso-dashboard-create (proj)
  "Create a dashboard for project PROJ."
  (interactive)
  (with-current-buffer (get-buffer-create proviso-dashboard-buffer-name)
    (let ((buffer-read-only nil))
      (erase-buffer)
      (proviso-dashboard-mode)
      (princ "Project:")
      (insert (propertize (proviso-get proj :project-name)
                          'face 'success))
      (princ "\n---------------\n")
      (princ "Root:")
      (insert (propertize (proviso-get proj :root-dir)
                          'face '(bold)))
      )))

(defun proviso-dashboard-refresh-buffer ()
  "Refresh the dashboard."
  (interactive)
  (kill-buffer proviso-dashboard-buffer-name)
  (proviso-dashboard-create (proviso-current-project))
  (switch-to-buffer proviso-dashboard-buffer-name))

(provide 'proviso-dashboard)
;;; proviso-dashboard.el ends here
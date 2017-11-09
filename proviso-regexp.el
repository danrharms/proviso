;;; proviso-regexp.el --- proviso regex manipulations
;; Copyright (C) 2017  Dan Harms (dharms)
;; Author: Dan Harms <enniomore@icloud.com>
;; Created: Wednesday, November  8, 2017
;; Version: 1.0
;; Modified Time-stamp: <2017-11-08 17:50:44 dharms>
;; Modified by: Dan Harms
;; Keywords: tools project proviso
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
;; Provides utilities to manage regular expressions in proviso.
;;

;;; Code:

(defun proviso-regexp-glob-to-regex (glob)
  "Convert a shell glob pattern GLOB to a regular expression."
  (let ((result ""))
    (dolist (ch (append glob nil) result)
      (setq
       result
       (concat
        result
        (cond ((eq ch ?*)
               ".*")
              ((eq ch ?.)
               "\\.")
              (t
               (char-to-string ch))))))))

(provide 'proviso-regexp)
;;; proviso-regexp.el ends here

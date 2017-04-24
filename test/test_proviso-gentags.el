#!/bin/sh
":"; exec "$EMACSX" --quick --script "$0" -- "$@" # -*- mode: emacs-lisp; -*-
;;; test_proviso-gentags.el --- test proviso gentags
;; Copyright (C) 2017  Dan Harms (dharms)
;; Author: Dan Harms <enniomore@icloud.com>
;; Created: Monday, April 24, 2017
;; Version: 1.0
;; Modified Time-stamp: <2017-04-24 17:52:15 dharms>
;; Modified by: Dan Harms
;; Keywords: proviso project tags gentags

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

;;

;;; Code:
(load-file "test/proviso-test-common.el")
(require 'proviso)

(ert-deftest proviso-gentags-test-tags ()
  (proviso-test-reset-all)
  (let ((base (file-name-directory load-file-name))
        file-contents)
    (cl-letf (((symbol-function 'proviso--load-file)
               (lambda (_)
                 (proviso-eval-string file-contents))))
      ;; open file
      (setq file-contents "
 (defun do-init (proj)
   (proviso-put proj :proj-alist
               '( (:name \"first\" :dir \"\")
                  (:name \"second\" :dir \"d/\")
                  (:name \"third\" :dir \"d2/\")
                  (:name \"fourth\" :dir \"/home/\")
                  )))
 (proviso-define \"c\" :initfun 'do-init)
")
      (find-file (concat base "a/b/c/d/dfile1"))
      (should (proviso-name-p (proviso-get proviso-local-proj :project-name)))
      (should (string= (proviso-get proviso-local-proj :root-dir)
                       (concat base "a/b/c/")))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c"))
      (should (equal (proviso-get proviso-local-proj :tags-alist)
                     (list (concat base "a/b/c/" "\\(.*\\)$")
                           (concat base "a/b/c/.tags/fourth-tags")
                           (concat base "a/b/c/.tags/third-tags")
                           (concat base "a/b/c/.tags/second-tags")
                           (concat base "a/b/c/.tags/first-tags")
                                   )))

      ;; clean up buffers
      (kill-buffer "dfile1")
      )))

(ert-run-tests-batch-and-exit (car argv))

;;; test_proviso-gentags.el ends here

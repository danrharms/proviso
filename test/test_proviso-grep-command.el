#!/bin/sh
":"; exec "$EMACSX" --quick --script "$0" -- "$@" # -*- mode: emacs-lisp; -*-
;;; test_proviso-grep-command.el --- test proviso grep-command
;; Copyright (C) 2017  Dan Harms (dharms)
;; Author: Dan Harms <enniomore@icloud.com>
;; Created: Wednesday, May  3, 2017
;; Version: 1.0
;; Modified Time-stamp: <2017-09-14 08:53:03 dharms>
;; Modified by: Dan Harms
;; Keywords: proviso project grep command

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
;; Test proviso grep command creation functionality.
;;

;;; Code:
(load-file "test/proviso-test-common.el")
(require 'proviso)

(ert-deftest proviso-grep-cmd-test-create-cmd-exclude ()
  (let ((base (file-name-directory load-file-name))
        (proviso-grep-file-whitelist '("*.cpp" "*.hpp"))
        (proviso-grep-file-blacklist '("*moc_*" "*qrc_*"))
        (proviso-grep-dir-blacklist '("*.git"))
        )
    (should (string= (proviso-grep--create-grep-str)
                     (concat
                      " \"(\" -name \"*moc_*\" -o -name \"*qrc_*\" -o -path \"*.git\" \")\" "
                      "-prune -o -type f \"(\" -name \"*.cpp\" -o -name \"*.hpp"
                      "\" \")\" -print0 | xargs -0 grep -Isn ")))
    ))

(ert-deftest proviso-grep-cmd-test-create-cmd-exclude-empty-file-blacklist ()
  (let ((base (file-name-directory load-file-name))
        (proviso-grep-file-whitelist '("*.cpp" "*.hpp"))
        (proviso-grep-file-blacklist '())
        (proviso-grep-dir-blacklist '("*.git"))
        )
    (should (string= (proviso-grep--create-grep-str)
                     (concat
                      " \"(\" -path \"*.git\" \")\" "
                      "-prune -o -type f \"(\" -name \"*.cpp\" -o -name \"*.hpp"
                      "\" \")\" -print0 | xargs -0 grep -Isn ")))
    ))

(ert-deftest proviso-grep-cmd-test-create-cmd-exclude-empty-dir-blacklist ()
  (let ((base (file-name-directory load-file-name))
        (proviso-grep-file-whitelist '("*.cpp" "*.hpp"))
        (proviso-grep-file-blacklist '("*moc_*" "*qrc_*"))
        (proviso-grep-dir-blacklist '())
        )
    (should (string= (proviso-grep--create-grep-str)
                     (concat
                      " \"(\" -name \"*moc_*\" -o -name \"*qrc_*\" \")\" "
                      "-prune -o -type f \"(\" -name \"*.cpp\" -o -name \"*.hpp"
                      "\" \")\" -print0 | xargs -0 grep -Isn ")))
    ))

(ert-deftest proviso-grep-cmd-test-create-cmd-exclude-empty-dir-and-file-blacklist ()
  (let ((base (file-name-directory load-file-name))
        (proviso-grep-file-whitelist '("*.cpp" "*.hpp"))
        (proviso-grep-file-blacklist '())
        (proviso-grep-dir-blacklist '())
        )
    (should (string= (proviso-grep--create-grep-str)
                     (concat
                      " -type f \"(\" -name \"*.cpp\" -o -name \"*.hpp"
                      "\" \")\" -print0 | xargs -0 grep -Isn ")))
    ))

(ert-deftest proviso-grep-cmd-test-create-cmd-no-include ()
  (let ((base (file-name-directory load-file-name))
        (proviso-grep-file-whitelist '())
        (proviso-grep-file-blacklist '("*moc_*" "*qrc_*"))
        (proviso-grep-dir-blacklist '("*.git" "*.svn"))
        )
    (should (string= (proviso-grep--create-grep-str)
                     (concat
                      " \"(\" -name \"*moc_*\" -o -name \"*qrc_*\" -o -path \"*.git\" -o -path \"*.svn\" \")\" "
                      "-prune -o -type f -print0 | xargs -0 grep -Isn ")))
    ))

(ert-deftest proviso-grep-cmd-test-create-cmd-no-exclude-or-include ()
  (let ((base (file-name-directory load-file-name))
        (proviso-grep-file-whitelist '())
        (proviso-grep-file-blacklist '())
        (proviso-grep-dir-blacklist '())
        )
    (should (string= (proviso-grep--create-grep-str)
                     (concat
                      " -type f -print0 | xargs -0 grep -Isn ")))
    ))

(ert-deftest proviso-grep-cmd-open-project-dir ()
  (proviso-test-reset-all)
  (let* ((base (file-name-directory load-file-name))
         (default-directory base)
         file-contents read-result)
    (cl-letf (((symbol-function 'proviso--load-file)
               (lambda (_)
                 (proviso-eval-string file-contents)))
              ((symbol-function 'completing-read)
               (lambda (_ _2)
                 read-result))
              ((symbol-function 'read-directory-name)
               (lambda (_ _2 _3 _4)
                 read-result))
              ((symbol-function 'proviso--query-error)
               (lambda (_ err)
                 (message "proviso-query-error: %s" err))))
      ;; test grep without a current project
      (should (eq (proviso-current-project-root) nil))
      ;; empty settings; no arg uses default-directory
      (should (equal (proviso-grep--create-command)
                     (concat "find -P " (directory-file-name base)
                             (proviso-grep--create-grep-str)
                     )))
      ;; empty settings; arg 4 uses default-directory
      (should (equal (proviso-grep--create-command 4)
                     (concat "find -P " (directory-file-name base)
                             (proviso-grep--create-grep-str)
                             )))
      ;; empty settings: arg 16 reads dir from user
      (setq read-result (concat (directory-file-name base) "/a/b/c/d/e/"))
      (should (equal (proviso-grep--create-command 16)
                     (concat "find -P "
                             (concat (directory-file-name base) "/a/b/c/d/e")
                             (proviso-grep--create-grep-str)
                     )))
      ;; open file
      (setq file-contents "
 (defun do-init (proj)
   (proviso-put proj :proj-alist
               '( (:name \"base\" :dir \"d/e/\")
                  (:name \"two\" :dir \"d/e/f\")
                  )))
 (proviso-define \"c\" :initfun 'do-init)
")
      (find-file (concat base "a/b/c/d/dfile1"))
      (should (proviso-name-p (proviso-get proviso-local-proj :project-name)))
      (should (string= (proviso-get proviso-local-proj :root-dir)
                       (concat base "a/b/c/")))
      (should (string= (proviso-current-project-root)
                       (concat base "a/b/c/")))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c"))
      (should (equal (proviso-get proviso-local-proj :grep-dirs)
                     (list
                      (concat base "a/b/c/d/e/")
                      (concat base "a/b/c/d/e/f/")
                      (concat base "a/b/c/"))))
      ;; no arg takes from the first element of dirs
      (should (equal (proviso-grep--create-command)
                     (concat "find -P " base "a/b/c/d/e"
                             (proviso-grep--create-grep-str)
                             )))
      ;; arg 4 lets user select dir
      (setq read-result (concat base "/a/b/c/d/e/f/"))
      (should (equal (proviso-grep--create-command 4)
                     (concat "find -P " base "a/b/c/d/e/f"
                             (proviso-grep--create-grep-str)
                     )))
      ;; arg 16 asks user for dir
      (setq read-result (concat base "/a/b/c/d/e/f/"))
      (should (equal (proviso-grep--create-command 16)
                     (concat "find -P " base "a/b/c/d/e/f"
                             (proviso-grep--create-grep-str)
                     )))

      ;; clean up buffers
      (kill-buffer "dfile1")
      )))

(ert-run-tests-batch-and-exit (car argv))

;;; test_proviso-grep-command.el ends here

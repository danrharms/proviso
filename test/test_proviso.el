#!/bin/sh
":"; exec "$VISUAL" --quick --script "$0" -- "$@" # -*- mode: emacs-lisp; -*-
;;; test_proviso.el --- test projects
;; Copyright (C) 2016-2019  Dan Harms (dharms)
;; Author: Dan Harms <enniomore@icloud.com>
;; Created: Friday, December  9, 2016
;; Version: 1.0
;; Modified Time-stamp: <2019-10-03 09:01:00 dharms>
;; Modified by: Dan Harms
;; Keywords: tools projects test

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
;; Proviso tests.
;;

;;; Code:
(load-file "test/proviso-test-common.el")
(require 'proviso)

;; tests
(ert-deftest proviso-compile-test()
  (let ((byte-compile-error-on-warn t))
    (should (byte-compile-file load-file-name))
    (delete-file (byte-compile-dest-file load-file-name) nil)))

(ert-deftest proviso-open-project-test ()
  (proviso-test-reset-all)
  (let ((base (file-name-directory load-file-name))
        (file-contents "")
        buffers)
    (cl-letf (((symbol-function 'proviso--eval-file)
               (lambda (_)
                 (unless (string-empty-p (string-trim file-contents))
                   (car (read-from-string file-contents))))))
      ;; open first file, init new project
      (should (not proviso-local-proj))
      (find-file (concat base "a/b/c/d/dfile1"))
      (push "dfile1" buffers)
      (should proviso-local-proj)
      (should (equal proviso-proj-alist
                     (list (cons (concat base "a/b/c/")
                                 (concat "c#" base "a/b/c/")))))
      (should (eq proviso-local-proj proviso-curr-proj))
      (should (eq (proviso-get proviso-local-proj :inited) t))
      (should (string= (concat base "a/b/c/")
                       (proviso-get proviso-local-proj :root-dir)))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c"))
      (should (string= (proviso-get proviso-local-proj :project-uid)
                       (concat "c#" base "a/b/c/")))
      (should (string= (proviso-get proviso-local-proj :scratch-dir)
                       (concat base "a/b/c/")))
      ;; open 2nd file, same project
      (find-file (concat base "a/b/c/d/dfile2"))
      (push "dfile2" buffers)
      (should (eq (proviso-get proviso-local-proj :inited) t))
      (should (equal proviso-proj-alist
                     (list (cons (concat base "a/b/c/")
                                 (concat "c#" base "a/b/c/")))))
      (should (eq proviso-local-proj proviso-curr-proj))
      (should (string= (concat base "a/b/c/")
                       (proviso-get proviso-local-proj :root-dir)))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c"))
      (should (string= (proviso-get proviso-local-proj :project-uid)
                       (concat "c#" base "a/b/c/")))
      (should (string= (proviso-get proviso-local-proj :scratch-dir)
                       (concat base "a/b/c/")))
      ;; open 3rd file, new project
      (setq file-contents " ")
      (find-file (concat base "a/b/c2/d2/dfile3"))
      (push "dfile3" buffers)
      (should (equal proviso-proj-alist
                     (list (cons (concat base "a/b/c2/")
                                 (concat "c2#" base "a/b/c2/"))
                           (cons (concat base "a/b/c/")
                                 (concat "c#" base "a/b/c/")))))
      (should (eq proviso-local-proj proviso-curr-proj))
      (should (string= (concat base "a/b/c2/")
                       (proviso-get proviso-local-proj :root-dir)))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c2"))
      (should (string= (proviso-get proviso-local-proj :project-uid)
                       (concat "c2#" base "a/b/c2/")))
      (should (string= (proviso-get proviso-local-proj :scratch-dir)
                       (concat base "a/b/c2/")))
      (should (eq (proviso-get proviso-local-proj :inited) t))
      ;; clean up buffers
      (dolist (b buffers) (kill-buffer b))
      )))

(ert-deftest proviso-open-project-override-name ()
  (proviso-test-reset-all)
  (let ((base (file-name-directory load-file-name))
        (file-contents "")
        buffers)
    (cl-letf (((symbol-function 'proviso--eval-file)
               (lambda (_)
                 (unless (string-empty-p (string-trim file-contents))
                   (car (read-from-string file-contents))))))
      ;; open first file, init new project
      (setq file-contents "(:project-name \"override\")")
      (should (not proviso-local-proj))
      (find-file (concat base "a/b/c/d/dfile1"))
      (push "dfile1" buffers)
      (should proviso-local-proj)
      (should (equal proviso-proj-alist
                     (list (cons (concat base "a/b/c/")
                                 (concat "override#" base "a/b/c/")))))
      (should (eq proviso-local-proj proviso-curr-proj))
      (should (eq (proviso-get proviso-local-proj :inited) t))
      (should (string= (concat base "a/b/c/")
                       (proviso-get proviso-local-proj :root-dir)))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "override"))
      (should (string= (proviso-get proviso-local-proj :project-uid)
                       (concat "override#" base "a/b/c/")))
      (should (string= (proviso-get proviso-local-proj :scratch-dir)
                       (concat base "a/b/c/")))
      ;; clean up buffers
      (dolist (b buffers) (kill-buffer b))
      )))

(ert-deftest proviso-open-project-ignore-errors-project-file ()
  (proviso-test-reset-all)
  (let ((base (file-name-directory load-file-name))
        (file-contents "")
        buffers)
    (cl-letf (((symbol-function 'proviso--eval-file)
               (lambda (_)
                 (ignore-errors
                   (unless (string-empty-p (string-trim file-contents))
                     (car (read-from-string file-contents)))))))
      ;; open first file, init new project
      (setq file-contents "(invalid elisp")
      (should (not proviso-local-proj))
      (find-file (concat base "a/b/c/d/dfile1"))
      (push "dfile1" buffers)
      (should proviso-local-proj)
      (should (equal proviso-proj-alist
                     (list (cons (concat base "a/b/c/")
                                 (concat "c#" base "a/b/c/")))))
      (should (eq proviso-local-proj proviso-curr-proj))
      (should (eq (proviso-get proviso-local-proj :inited) t))
      (should (string= (concat base "a/b/c/")
                       (proviso-get proviso-local-proj :root-dir)))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c"))
      (should (string= (proviso-get proviso-local-proj :project-uid)
                       (concat "c#" base "a/b/c/")))
      (should (string= (proviso-get proviso-local-proj :scratch-dir)
                       (concat base "a/b/c/")))
      ;; clean up buffers
      (dolist (b buffers) (kill-buffer b))
      )))

(ert-deftest proviso-open-project-test-git-should-be-ignored-due-to-proviso-file ()
  (proviso-test-reset-all)
  (let ((base (file-name-directory load-file-name))
        (file-contents "")
        buffers)
    (cl-letf (((symbol-function 'proviso--eval-file)
               (lambda (_)
                 (unless (string-empty-p (string-trim file-contents))
                   (car (read-from-string file-contents))))))
      ;; problematic to check-in a .git subdir, so we'll just create it here
      (require 'dired-aux)
      (dired-create-directory (concat base "a/b/c/d/gitsubdir/.git"))
      ;; open file, init new project
      ;; The file would be inside a .git project, except that there exists an
      ;; over-arching .proviso file, which will be favored.
      (find-file (concat base "a/b/c/d/gitsubdir/g/gfile"))
      (push "gfile" buffers)
      (should (equal proviso-proj-alist
                     (list (cons (concat base "a/b/c/")
                                 (concat "c#" base "a/b/c/")))))
      (should (eq proviso-local-proj proviso-curr-proj))
      (should (eq (proviso-get proviso-local-proj :inited) t))
      (should (string= (concat base "a/b/c/")
                       (proviso-get proviso-local-proj :root-dir)))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c"))
      (should (string= (proviso-get proviso-local-proj :project-uid)
                       (concat "c#" base "a/b/c/")))
      (should (string= (proviso-get proviso-local-proj :scratch-dir)
                       (concat base "a/b/c/")))
      (dired-delete-file (concat base "a/b/c/d/gitsubdir/.git") 'always)
      (dolist (b buffers) (kill-buffer b))
      )))

(ert-deftest proviso-open-project-test-git-project ()
  (proviso-test-reset-all)
  (let ((base (file-name-directory load-file-name))
        (file-contents "")
        buffers)
    (cl-letf (((symbol-function 'proviso--eval-file)
               (lambda (_)
                 (unless (string-empty-p (string-trim file-contents))
                   (car (read-from-string file-contents))))))
      ;; problematic to check-in a .git subdir, so we'll just create it here
      (require 'dired-aux)
      (dired-create-directory (concat base "a/gitproject/.git"))
      ;; open file, init new project
      (find-file (concat base "a/gitproject/g2/gfile2"))
      (push "gfile2" buffers)
      (should (equal proviso-proj-alist
                     (list (cons (concat base "a/gitproject/")
                                 (concat "gitproject#" base "a/gitproject/")))))
      (should (eq proviso-local-proj proviso-curr-proj))
      (should (eq (proviso-get proviso-local-proj :inited) t))
      (should (string= (concat base "a/gitproject/")
                       (proviso-get proviso-local-proj :root-dir)))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "gitproject"))
      (should (string= (proviso-get proviso-local-proj :project-uid)
                       (concat "gitproject#" base "a/gitproject/")))
      (should (string= (proviso-get proviso-local-proj :scratch-dir)
                       (concat base "a/gitproject/")))
      (dired-delete-file (concat base "a/gitproject/.git") 'always)
      (dolist (b buffers) (kill-buffer b))
      )))

(ert-deftest proviso-open-provisional-project-none ()
  (proviso-test-reset-all)
  (let ((base (temporary-file-directory))
        (file-contents "")
        buffers)
    (cl-letf (((symbol-function 'proviso--eval-file)
               (lambda (_)
                 (unless (string-empty-p (string-trim file-contents))
                   (car (read-from-string file-contents))))))
      (delete-directory (concat base "m") t)
      (make-directory (concat base "m/n") t)
      (write-region "" nil (concat base "m/n/nfile1"))
      (should-not proviso-local-proj)
      (find-file (concat base "m/n/nfile1"))
      (push "nfile1" buffers)
      (should-not proviso-local-proj)
      (should (equal proviso-proj-alist nil))
      (should (equal proviso-path-alist nil))
      ;; clean up buffers
      (dolist (b buffers) (kill-buffer b))
      )))

(ert-deftest proviso-open-provisional-project-test ()
  (proviso-test-reset-all)
  (let ((base (temporary-file-directory))
        (file-contents "")
        buffers)
    (cl-letf (((symbol-function 'proviso--eval-file)
               (lambda (_)
                 (unless (string-empty-p (string-trim file-contents))
                   (car (read-from-string file-contents))))))
      (delete-directory (concat base "m") t)
      (delete-directory (concat base "p") t)
      (make-directory (concat base "m/n") t)
      (make-directory (concat base "p/q") t)
      (write-region "" nil (concat base "m/n/nfile1"))
      (write-region "" nil (concat base "m/n/nfile2"))
      (write-region "" nil (concat base "p/q/qfile1"))
      ;; open first file, init new project
      (proviso-define-project "neon" '(("/m/")))
      (proviso-define-project "fog" '(("/p")))
      (should-not proviso-local-proj)
      (find-file (concat base "m/n/nfile1"))
      (push "nfile1" buffers)
      (should proviso-local-proj)
      (should (eq proviso-local-proj proviso-curr-proj))
      (should (eq (proviso-get proviso-local-proj :inited) t))
      (should (equal proviso-proj-alist
                     (list (cons (concat base "m/")
                                 (concat "neon#" base "m/")))))
      (should (equal proviso-path-alist
                     (list
                      (list "/p" "fog")
                      (list "/m/" "neon"))))
      (should (string= (concat base "m/")
                       (proviso-get proviso-local-proj :root-dir)))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "neon"))
      (should (string= (proviso-get proviso-local-proj :project-uid)
                       (concat "neon#" base "m/")))
      (should (string= (proviso-get proviso-local-proj :scratch-dir)
                       (concat base "m/")))
      ;; open 2nd file, same project
      (find-file (concat base "m/n/nfile2"))
      (push "nfile2" buffers)
      (should (eq (proviso-get proviso-local-proj :inited) t))
      (should (equal proviso-proj-alist
                     (list (cons (concat base "m/")
                                 (concat "neon#" base "m/")))))
      (should (eq proviso-local-proj proviso-curr-proj))
      (should (string= (concat base "m/")
                       (proviso-get proviso-local-proj :root-dir)))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "neon"))
      (should (string= (proviso-get proviso-local-proj :project-uid)
                       (concat "neon#" base "m/")))
      (should (string= (proviso-get proviso-local-proj :scratch-dir)
                       (concat base "m/")))
      ;; open 3rd file, new project
      (setq file-contents " ")
      (find-file (concat base "p/qfile1"))
      (push "qfile1" buffers)
      (should (equal proviso-proj-alist
                     (list (cons (concat base "p/")
                                 (concat "fog#" base "p/"))
                           (cons (concat base "m/")
                                 (concat "neon#" base "m/")))))
      (should (eq proviso-local-proj proviso-curr-proj))
      (should (string= (concat base "p/")
                       (proviso-get proviso-local-proj :root-dir)))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "fog"))
      (should (string= (proviso-get proviso-local-proj :scratch-dir)
                       (concat base "p/")))
      (should (eq (proviso-get proviso-local-proj :inited) t))
      ;; clean up buffers
      (dolist (b buffers) (kill-buffer b))
      )))

(ert-deftest proviso-test-open-provisional-project-invalid-stem ()
  (proviso-test-reset-all)
  (let ((base (temporary-file-directory))
        (file-contents "")
        buffers)
    (cl-letf (((symbol-function 'proviso--eval-file)
               (lambda (_)
                 (unless (string-empty-p (string-trim file-contents))
                   (car (read-from-string file-contents))))))
      (delete-directory (concat base "main") t)
      (delete-directory (concat base "secondary") t)
      (make-directory (concat base "main/n") t)
      (make-directory (concat base "secondary/q") t)
      (write-region "" nil (concat base "main/n/nfile1"))
      (write-region "" nil (concat base "main/n/nfile2"))
      (write-region "" nil (concat base "secondary/q/qfile1"))
      ;; open first file, init new project
      (proviso-define-project "neon" '(("/main")))
      (proviso-define-project "fog" '(("/second"))) ;intentional error
      (should-not proviso-local-proj)
      (find-file (concat base "main/n/nfile1"))
      (push "nfile1" buffers)
      (should proviso-local-proj)
      (should (eq proviso-local-proj proviso-curr-proj))
      (should (eq (proviso-get proviso-local-proj :inited) t))
      (should (equal proviso-proj-alist
                     (list (cons (concat base "main/")
                                 (concat "neon#" base "main/")))))
      ;; note that provisional project "secondary" has an invalid stem
      ;; "/second" specified; these stems need to match an entire directory
      ;; path, since they are used to determine the root directory.
      ;; For this reason, the project "secondary" will not be found.
      (should (equal proviso-path-alist
                     (list
                      (list "/second" "fog")
                      (list "/main" "neon"))))
      (should (string= (concat base "main/")
                       (proviso-get proviso-local-proj :root-dir)))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "neon"))
      (should (string= (proviso-get proviso-local-proj :project-uid)
                       (concat "neon#" base "main/")))
      (should (string= (proviso-get proviso-local-proj :scratch-dir)
                       (concat base "main/")))
      ;; open up file from other project
      (find-file (concat base "secondary/qfile1"))
      (push "qfile1" buffers)
      (should (equal proviso-proj-alist
                     (list
                      (cons (concat base "main/")
                            (concat "neon#" base "main/")))))
      (should (not proviso-local-proj))
      ;; clean up buffers
      (dolist (b buffers) (kill-buffer b))
      )))

(ert-deftest proviso-test-provisional-project-unwriteable ()
  (proviso-test-reset-all)
  (let* ((home (expand-file-name "~/"))
         (base (file-name-directory (directory-file-name home)))
         (file-contents "")
         buffers)
    (cl-letf (((symbol-function 'proviso--eval-file)
               (lambda (_)
                 (unless (string-empty-p (string-trim file-contents))
                   (car (read-from-string file-contents))))))
      (proviso-define-project "neon" (list (list base)))
      (should-not proviso-local-proj)
      (find-file (concat home ".bashrc"))
      (push ".bashrc" buffers)
      (should proviso-local-proj)
      (should (eq proviso-local-proj proviso-curr-proj))
      (should (eq (proviso-get proviso-local-proj :inited) t))
      (should (equal proviso-proj-alist
                     (list (cons base
                                 (concat "neon#" base)))))
      (should (equal proviso-path-alist
                     (list (list base "neon"))))
      (should (string= (concat base "")
                       (proviso-get proviso-local-proj :root-dir)))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "neon"))
      (should (string= (proviso-get proviso-local-proj :project-uid)
                       (concat "neon#" base "")))
      (should (string= (proviso-get proviso-local-proj :scratch-dir)
                       (file-name-as-directory
                        (concat home ".proviso.d/projects/"
                                (replace-regexp-in-string "/\\|\\\\" "!"
                                                          base t t)))))
      ;; clean up buffers
      (dolist (b buffers) (kill-buffer b))
      )))

(ert-deftest proviso-open-provisional-project-props ()
  (proviso-test-reset-all)
  (let ((base (temporary-file-directory))
        (file-contents "")
        buffers)
    (cl-letf (((symbol-function 'proviso--eval-file)
               (lambda (_)
                 (unless (string-empty-p (string-trim file-contents))
                   (car (read-from-string file-contents))))))
      (delete-directory (concat base "m") t)
      (make-directory (concat base "m/n") t)
      (write-region "" nil (concat base "m/n/nfile1"))
      ;; open first file, init new project
      (proviso-define-project "neon" '(("/m/")) :tag1 'value1)
      (should-not proviso-local-proj)
      (find-file (concat base "m/n/nfile1"))
      (push "nfile1" buffers)
      (should proviso-local-proj)
      (should (eq proviso-local-proj proviso-curr-proj))
      (should (eq (proviso-get proviso-local-proj :inited) t))
      (should (equal proviso-path-alist
                     (list (list "/m/" "neon"))))
      (should (equal proviso-proj-alist
                     (list (cons (concat base "m/")
                                 (concat "neon#" base "m/")))))
      (should (string= (concat base "m/")
                       (proviso-get proviso-local-proj :root-dir)))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "neon"))
      (should (string= (proviso-get proviso-local-proj :project-uid)
                       (concat "neon#" base "m/")))
      (should (string= (proviso-get proviso-local-proj :scratch-dir)
                       (concat base "m/")))
      (should (eq (proviso-get proviso-local-proj :tag1)
                  'value1))
      ;; clean up buffers
      (dolist (b buffers) (kill-buffer b))
      )))

(ert-deftest proviso-open-project-override-provisional-project ()
  (proviso-test-reset-all)
  (let ((base (file-name-directory load-file-name))
        (file-contents "")
        buffers)
    (cl-letf (((symbol-function 'proviso--eval-file)
               (lambda (_)
                 (unless (string-empty-p (string-trim file-contents))
                   (car (read-from-string file-contents))))))
      (proviso-define-project "actual" '(("a/b")) :tag "real" :tag2 "present")
      (should-not proviso-local-proj)
      ;; open first file, init new project.
      ;; Real project files override provisional projects
      ;; this provisional project is overridden by the real project file
      (setq file-contents "(:tag \"overridden\" :tag1 \"also\")")
      (should (not proviso-local-proj))
      (find-file (concat base "a/b/c/d/dfile1"))
      (push "dfile1" buffers)
      (should proviso-local-proj)
      (should (equal proviso-proj-alist
                     (list (cons (concat base "a/b/")
                                 (concat "actual#" base "a/b/")))))
      (should (eq proviso-local-proj proviso-curr-proj))
      (should (eq (proviso-get proviso-local-proj :inited) t))
      (should (string= (concat base "a/b/")
                       (proviso-get proviso-local-proj :root-dir)))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "actual"))
      (should (string= (proviso-get proviso-local-proj :project-uid)
                       (concat "actual#" base "a/b/")))
      (should (string= (proviso-get proviso-local-proj :scratch-dir)
                       (concat base "a/b/")))
      (should (string= (proviso-get proviso-local-proj :tag)
                       "real"))
      (should (string= (proviso-get proviso-local-proj :tag1)
                       "also"))
      (should (string= (proviso-get proviso-local-proj :tag2)
                       "present"))
      ;; clean up buffers
      (dolist (b buffers) (kill-buffer b))
      )))

(ert-run-tests-batch-and-exit (car argv))

;;; test_proviso.el ends here

;;; test_proviso-grep.el --- test proviso grep dirs
;; Copyright (C) 2017-2020  Dan Harms (dharms)
;; Author: Dan Harms <enniomore@icloud.com>
;; Created: Saturday, April  1, 2017
;; Version: 1.0
;; Modified Time-stamp: <2020-01-20 08:51:28 Dan.Harms>
;; Modified by: Dan.Harms
;; Keywords: tools proviso project grep test
;; Package-Requires: ((emacs "25.1"))

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

(ert-deftest proviso-grep-open-project-empty-dir ()
  (proviso-test-reset-all)
  (let (file-contents)
    (cl-letf (((symbol-function 'proviso--eval-file)
               (lambda (_)
                 (unless (string-empty-p (string-trim file-contents))
                   (car (read-from-string file-contents))))))
      ;; open file
      (setq file-contents "(
:initfun (lambda (proj)
   (proviso-put proj :proj-alist
               '( (:name \"base\" :dir \"\")
                  )))
)")
      (find-file (concat base-test-dir "a/b/c/d/dfile1"))
      (should (string= (proviso-get proviso-local-proj :root-dir)
                       (concat base-test-dir "a/b/c/")))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c"))
      (should (equal (proviso-get proviso-local-proj :grep-dirs)
                     (list (concat base-test-dir "a/b/c/"))))
      ;; clean up buffers
      (kill-buffer "dfile1")
      )))

(ert-deftest proviso-grep-open-project-absolute-dir ()
  (proviso-test-reset-all)
  (let (file-contents)
    (cl-letf (((symbol-function 'proviso--eval-file)
               (lambda (_)
                 (unless (string-empty-p (string-trim file-contents))
                   (car (read-from-string file-contents))))))
      ;; open file
      (setq file-contents (concat "(
:initfun (lambda (proj)
   (proviso-put proj :proj-alist
               '( (:name \"base\" :dir \""
                                  (file-name-as-directory absolute-root-dir)
                                  "\")
                  )))
)"))
      (find-file (concat base-test-dir "a/b/c/d/dfile1"))
      (should (string= (proviso-get proviso-local-proj :root-dir)
                       (concat base-test-dir "a/b/c/")))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c"))
      (should (equal (proviso-get proviso-local-proj :grep-dirs)
                     (list (file-name-as-directory absolute-root-dir)
                           (concat base-test-dir "a/b/c/"))))
      ;; clean up buffers
      (kill-buffer "dfile1")
      )))

(ert-deftest proviso-grep-open-project-relative-dir ()
  (proviso-test-reset-all)
  (let (file-contents)
    (cl-letf (((symbol-function 'proviso--eval-file)
               (lambda (_)
                 (unless (string-empty-p (string-trim file-contents))
                   (car (read-from-string file-contents))))))
      ;; open file
      (setq file-contents "(
:initfun (lambda (proj)
   (proviso-put proj :proj-alist
               '( (:name \"base\" :dir \"d/\")
                  )))
)")
      (find-file (concat base-test-dir "a/b/c/d/dfile1"))
      (should (string= (proviso-get proviso-local-proj :root-dir)
                       (concat base-test-dir "a/b/c/")))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c"))
      (should (equal (proviso-get proviso-local-proj :grep-dirs)
                     (list (concat base-test-dir "a/b/c/d/")
                           (concat base-test-dir "a/b/c/"))))
      ;; clean up buffers
      (kill-buffer "dfile1")
      )))

(ert-deftest proviso-grep-open-project-no-dir ()
  (proviso-test-reset-all)
  (let (file-contents)
    (cl-letf (((symbol-function 'proviso--eval-file)
               (lambda (_)
                 (unless (string-empty-p (string-trim file-contents))
                   (car (read-from-string file-contents))))))
      ;; open file
      (setq file-contents "")
      (find-file (concat base-test-dir "a/b/c/d/dfile1"))
      (should (string= (proviso-get proviso-local-proj :root-dir)
                       (concat base-test-dir "a/b/c/")))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c"))
      ;; no dirs specified, so just the root dir
      (should (equal (proviso-get proviso-local-proj :grep-dirs)
                     (list (concat base-test-dir "a/b/c/"))))
      ;; clean up buffers
      (kill-buffer "dfile1")
      )))

(ert-deftest proviso-grep-open-project-no-trailing-slashes ()
  (proviso-test-reset-all)
  (let (file-contents)
    (cl-letf (((symbol-function 'proviso--eval-file)
               (lambda (_)
                 (unless (string-empty-p (string-trim file-contents))
                   (car (read-from-string file-contents))))))
      ;; open file
      (setq file-contents (concat "(
:initfun (lambda (proj)
   (proviso-put proj :proj-alist
               '( (:name \"one\" :dir \"\")
                  (:name \"two\" :dir \""
                                  absolute-root-dir
                                  "\")
                  (:name \"three\" :dir \"d\")
                  )))
)"))
      (find-file (concat base-test-dir "a/b/c/d/dfile1"))
      (should (string= (proviso-get proviso-local-proj :root-dir)
                       (concat base-test-dir "a/b/c/")))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c"))
      (should (equal (proviso-get proviso-local-proj :grep-dirs)
                     (list
                      (concat base-test-dir "a/b/c/")
                      (file-name-as-directory absolute-root-dir)
                      (concat base-test-dir "a/b/c/d/")
                      )))
      ;; open 2nd file, same project
      (find-file (concat base-test-dir "a/b/c/d/dfile2"))
      (should (string= (proviso-get proviso-local-proj :root-dir)
                       (concat base-test-dir "a/b/c/")))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c"))
      (should (equal (proviso-get proviso-local-proj :grep-dirs)
                     (list
                      (concat base-test-dir "a/b/c/")
                      (file-name-as-directory absolute-root-dir)
                      (concat base-test-dir "a/b/c/d/")
                      )))
      ;; open 3rd file, new project
      (setq file-contents "(
:initfun (lambda (proj)
   (proviso-put proj :proj-alist
               '( (:name \"base\" :dir \"d2/\")
                  )))
)")
      (find-file (concat base-test-dir "a/b/c2/d2/dfile3"))
      (should (string= (proviso-get proviso-local-proj :root-dir)
                       (concat base-test-dir "a/b/c2/")))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c2"))
      (should (equal (proviso-get proviso-local-proj :grep-dirs)
                     (list
                      (concat base-test-dir "a/b/c2/d2/")
                      (concat base-test-dir "a/b/c2/")
                      )))
      ;; switch back to initial buffer
      (switch-to-buffer "dfile1")
      (run-hooks 'post-command-hook)    ;simulate interactive use
      (should (string= (proviso-get proviso-local-proj :root-dir)
                       (concat base-test-dir "a/b/c/")))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c"))
      (should (eq proviso-local-proj proviso-curr-proj))
      (should (equal (proviso-get proviso-local-proj :grep-dirs)
                     (list
                      (concat base-test-dir "a/b/c/")
                      (file-name-as-directory absolute-root-dir)
                      (concat base-test-dir "a/b/c/d/")
                      )))

      ;; clean up buffers
      (kill-buffer "dfile1")
      (kill-buffer "dfile2")
      (kill-buffer "dfile3")
      )))


;;; test_proviso-grep.el ends here

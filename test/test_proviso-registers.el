;;; test_proviso-registers.el --- test proviso registers
;; Copyright (C) 2017-2020  Dan Harms (dharms)
;; Author: Dan Harms <enniomore@icloud.com>
;; Created: Tuesday, April  4, 2017
;; Version: 1.0
;; Modified Time-stamp: <2020-01-20 08:54:49 Dan.Harms>
;; Modified by: Dan.Harms
;; Keywords: tools proviso project registers test
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

(defun proviso-register-reset-registers()
  (set-register ?c nil)
  (set-register ?r nil)
  (set-register ?1 nil)
  (set-register ?2 nil)
  )

(ert-deftest proviso-register-test-root-register ()
  (proviso-test-reset-all)
  (proviso-register-reset-registers)
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
      (should (equal (get-register ?r) (cons 'file (concat base-test-dir "a/b/c/"))))
      (should (equal (get-register ?c) (cons 'file (concat base-test-dir "a/b/c/"))))
      (should (equal (get-register ?1) nil))
      ;; clean up buffers
      (kill-buffer "dfile1")
      )))

(ert-deftest proviso-register-test-empty-dir ()
  (proviso-test-reset-all)
  (proviso-register-reset-registers)
  (let (file-contents)
    (cl-letf (((symbol-function 'proviso--eval-file)
               (lambda (_)
                 (unless (string-empty-p (string-trim file-contents))
                   (car (read-from-string file-contents))))))
      ;; open file
      (setq file-contents "(
:initfun (lambda (proj)
   (proviso-put proj :proj-alist
               '( (:name \"base\" :dir \"\" :register ?1)
                  )))
)")
      (find-file (concat base-test-dir "a/b/c/d/dfile1"))
      (should (string= (proviso-get proviso-local-proj :root-dir)
                       (concat base-test-dir "a/b/c/")))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c"))
      (should (equal (get-register ?r) (cons 'file (concat base-test-dir "a/b/c/"))))
      (should (equal (get-register ?c) (cons 'file (concat base-test-dir "a/b/c/"))))
      (should (equal (get-register ?1) (cons 'file (concat base-test-dir "a/b/c/"))))
      ;; clean up buffers
      (kill-buffer "dfile1")
      )))

(ert-deftest proviso-register-test-relative-dir ()
  (proviso-test-reset-all)
  (proviso-register-reset-registers)
  (let (file-contents)
    (cl-letf (((symbol-function 'proviso--eval-file)
               (lambda (_)
                 (unless (string-empty-p (string-trim file-contents))
                   (car (read-from-string file-contents))))))
      ;; open file
      (setq file-contents "(
:initfun (lambda (proj)
   (proviso-put proj :proj-alist
               '( (:name \"base\" :dir \"d/\" :register ?1)
                  )))
)")
      (find-file (concat base-test-dir "a/b/c/d/dfile1"))
      (should (string= (proviso-get proviso-local-proj :root-dir)
                       (concat base-test-dir "a/b/c/")))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c"))
      (should (equal (get-register ?r) (cons 'file (concat base-test-dir "a/b/c/"))))
      (should (equal (get-register ?c) (cons 'file (concat base-test-dir "a/b/c/d/"))))
      (should (equal (get-register ?1) (cons 'file (concat base-test-dir "a/b/c/d/"))))
      ;; clean up buffers
      (kill-buffer "dfile1")
      )))

(ert-deftest proviso-register-test-absolute-dir ()
  (proviso-test-reset-all)
  (proviso-register-reset-registers)
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
                                  absolute-root-dir
                                  "\" :register ?1)
                  )))
)"))
      (find-file (concat base-test-dir "a/b/c/d/dfile1"))
      (should (string= (proviso-get proviso-local-proj :root-dir)
                       (concat base-test-dir "a/b/c/")))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c"))
      (should (equal (get-register ?r) (cons 'file (concat base-test-dir "a/b/c/"))))
      (should (equal (get-register ?c) (cons 'file absolute-root-dir)))
      (should (equal (get-register ?1) (cons 'file absolute-root-dir)))
      ;; clean up buffers
      (kill-buffer "dfile1")
      )))

(ert-deftest proviso-register-test-build-dirs-relative ()
  (proviso-test-reset-all)
  (proviso-register-reset-registers)
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
                                  "\" :register ?1)
                  ))
   (proviso-put proj :build-subdirs
               '( (:name \"subdir\" :dir \"d2/\" :register ?2)
                  )))
)"))
      (find-file (concat base-test-dir "a/b/c/d/dfile1"))
      (should (string= (proviso-get proviso-local-proj :root-dir)
                       (concat base-test-dir "a/b/c/")))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c"))
      (should (equal (get-register ?r) (cons 'file (concat base-test-dir "a/b/c/"))))
      (should (equal (get-register ?c) (cons 'file (file-name-as-directory absolute-root-dir))))
      (should (equal (get-register ?1) (cons 'file (file-name-as-directory absolute-root-dir))))
      (should (equal (get-register ?2) (cons 'file (concat base-test-dir "a/b/c/d2/"))))
      ;; clean up buffers
      (kill-buffer "dfile1")
      )))

(ert-deftest proviso-register-test-build-dirs-absolute ()
  (proviso-test-reset-all)
  (proviso-register-reset-registers)
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
                                  "\" :register ?1)
                  ))
   (proviso-put proj :build-subdirs
               '( (:name \"subdir\" :dir \""
                                  (file-name-as-directory absolute-root-dir)
                                  "\" :register ?2)
                  )))
)"))
      (find-file (concat base-test-dir "a/b/c/d/dfile1"))
      (should (string= (proviso-get proviso-local-proj :root-dir)
                       (concat base-test-dir "a/b/c/")))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c"))
      (should (equal (get-register ?r) (cons 'file (concat base-test-dir "a/b/c/"))))
      (should (equal (get-register ?c) (cons 'file (file-name-as-directory absolute-root-dir))))
      (should (equal (get-register ?1) (cons 'file (file-name-as-directory absolute-root-dir))))
      (should (equal (get-register ?2) (cons 'file (file-name-as-directory absolute-root-dir))))
      ;; clean up buffers
      (kill-buffer "dfile1")
      )))

(ert-deftest proviso-register-test-build-dirs-empty-dir ()
  (proviso-test-reset-all)
  (proviso-register-reset-registers)
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
                                  "\" :register ?1)
                  ))
   (proviso-put proj :build-subdirs
               '( (:name \"subdir\" :dir \"\" :register ?2)
                  )))
)"))
      (find-file (concat base-test-dir "a/b/c/d/dfile1"))
      (should (string= (proviso-get proviso-local-proj :root-dir)
                       (concat base-test-dir "a/b/c/")))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c"))
      (should (equal (get-register ?r) (cons 'file (concat base-test-dir "a/b/c/"))))
      (should (equal (get-register ?c) (cons 'file (file-name-as-directory absolute-root-dir))))
      (should (equal (get-register ?1) (cons 'file (file-name-as-directory absolute-root-dir))))
      (should (equal (get-register ?2) (cons 'file (concat base-test-dir "a/b/c/"))))
      ;; clean up buffers
      (kill-buffer "dfile1")
      )))

(ert-deftest proviso-register-test-no-project-file ()
  (proviso-test-reset-all)
  (proviso-register-reset-registers)
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
      (should (equal (get-register ?r) (cons 'file (concat base-test-dir "a/b/c/"))))
      ;; clean up buffers
      (kill-buffer "dfile1")
      )))

;; (ert-deftest proviso-register-test-remote ()
;;   (proviso-test-reset-all)
;;   (proviso-register-reset-registers)
;;   (let (file-contents)
;;     (cl-letf (((symbol-function 'proviso--eval-file)
;;                (lambda (_)
;;                  (proviso-eval-string file-contents)))
;;               ((symbol-function 'proviso--compute-remote-props)
;;                (lambda (dir)
;;                  (list "viking" dir "/ssh:dharms@viking:")))
;;               ((symbol-function 'file-remote-p)
;;                (lambda (_) nil))
;;               ((symbol-function 'tramp-tramp-file-p)
;;                (lambda (_) nil))
;;               ((symbol-function 'proviso-tags-compute-tags-dir)
;;                (lambda (proj dir)
;;                  (let ((base (or (getenv "EMACS_TAGS_DIR") "~"))
;;                        (sub (or (proviso-get proj :tags-subdir) ".tags/"))
;;                        dest)
;;                    (unless dir (setq dir default-directory))
;;                    ;; (unless (tramp-tramp-file-p dir)
;;                      ;; in the local case, set the base according to the project
;;                      (setq base dir);)
;;                    (setq dest (concat (file-name-as-directory base)
;;                                       (file-name-as-directory sub)))
;;                    ;; (if (tramp-tramp-file-p dir)
;;                        (concat dest (file-name-as-directory
;;                                      (proviso-tags-compute-remote-subdir-stem proj))))))
;;                      ;; dest))))
;;               )
;;       ;; open file
;;       (setq file-contents "
;;  (defun do-init (proj)
;;    (proviso-put proj :proj-alist
;;                '( (:name \"base\" :dir \"d/\" :register ?1)
;;                   )))
;;  (proviso-define-project \"c\" :initfun 'do-init)
;; ")
;;       (find-file (concat base-test-dir "a/b/c/d/dfile1"))
;;       (should (proviso-name-p (proviso-get proviso-local-proj :project-name)))
;;       (should (string= (proviso-get proviso-local-proj :root-dir)
;;                        (concat base-test-dir "a/b/c/")))
;;       (should (string= (proviso-get proviso-local-proj :project-name)
;;                        "c"))
;;       (should (equal (get-register ?r) (cons 'file (concat base-test-dir "a/b/c/"))))
;;       (should (equal (get-register ?c) (cons 'file (concat base-test-dir "a/b/c/d/"))))
;;       (should (equal (get-register ?1) (cons 'file (concat base-test-dir "a/b/c/d/"))))
;;       ;; clean up buffers
;;       (kill-buffer "dfile1")
;;       )))

(ert-deftest proviso-register-test-switch-projects ()
  (proviso-test-reset-all)
  (proviso-register-reset-registers)
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
                                  "\" :register ?1)
                  ))
   (proviso-put proj :build-subdirs
               '( (:name \"subdir\" :dir \"d2/\" :register ?2)
                  )))
)"))
      (find-file (concat base-test-dir "a/b/c/d/dfile1"))
      (should (string= (proviso-get proviso-local-proj :root-dir)
                       (concat base-test-dir "a/b/c/")))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c"))
      (should (equal (get-register ?r) (cons 'file (concat base-test-dir "a/b/c/"))))
      (should (equal (get-register ?c) (cons 'file (file-name-as-directory absolute-root-dir))))
      (should (equal (get-register ?1) (cons 'file (file-name-as-directory absolute-root-dir))))
      (should (equal (get-register ?2) (cons 'file (concat base-test-dir "a/b/c/d2/"))))
      (should (eq proviso-local-proj proviso-curr-proj))
      ;; open 2nd file, same project
      (find-file (concat base-test-dir "a/b/c/d/dfile2"))
      (should (string= (proviso-get proviso-local-proj :root-dir)
                       (concat base-test-dir "a/b/c/")))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c"))
      (should (eq proviso-local-proj proviso-curr-proj))
      (should (eq proviso-local-proj proviso-curr-proj))
      (should (equal (get-register ?r) (cons 'file (concat base-test-dir "a/b/c/"))))
      (should (equal (get-register ?c) (cons 'file (file-name-as-directory absolute-root-dir))))
      (should (equal (get-register ?1) (cons 'file (file-name-as-directory absolute-root-dir))))
      (should (equal (get-register ?2) (cons 'file (concat base-test-dir "a/b/c/d2/"))))
      ;; open 3rd file, new project
      (setq file-contents "(
:initfun (lambda (proj)
   (proviso-put proj :proj-alist
               '( (:name \"base\" :dir \"\" :register ?1)
                  ))
   (proviso-put proj :build-subdirs
               '( (:name \"subdir\" :dir \"d2/\" :register ?2)
                  )))
)")
      (find-file (concat base-test-dir "a/b/c2/d2/dfile3"))
      (should (string= (proviso-get proviso-local-proj :root-dir)
                       (concat base-test-dir "a/b/c2/")))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c2"))
      (should (eq proviso-local-proj proviso-curr-proj))
      (should (eq proviso-local-proj proviso-curr-proj))
      (should (equal (get-register ?r) (cons 'file (concat base-test-dir "a/b/c2/"))))
      (should (equal (get-register ?c) (cons 'file (concat base-test-dir "a/b/c2/"))))
      (should (equal (get-register ?1) (cons 'file (concat base-test-dir "a/b/c2/"))))
      (should (equal (get-register ?2) (cons 'file (concat base-test-dir "a/b/c2/d2/"))))
      ;; switch back to initial buffer
      (switch-to-buffer "dfile1")
      (run-hooks 'post-command-hook)    ;simulate interactive use
      (should (string= (proviso-get proviso-local-proj :root-dir)
                       (concat base-test-dir "a/b/c/")))
      (should (string= (proviso-get proviso-local-proj :project-name)
                       "c"))
      (should (eq proviso-local-proj proviso-curr-proj))
      (should (eq proviso-local-proj proviso-curr-proj))
      (should (equal (get-register ?r) (cons 'file (concat base-test-dir "a/b/c/"))))
      (should (equal (get-register ?c) (cons 'file (file-name-as-directory absolute-root-dir))))
      (should (equal (get-register ?1) (cons 'file (file-name-as-directory absolute-root-dir))))
      (should (equal (get-register ?2) (cons 'file (concat base-test-dir "a/b/c/d2/"))))
      ;; clean up buffers
      (kill-buffer "dfile1")
      (kill-buffer "dfile2")
      (kill-buffer "dfile3")
      )))



;;; test_proviso-registers.el ends here

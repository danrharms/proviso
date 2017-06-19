;;; proviso-core.el --- proviso core functionality
;; Copyright (C) 2017  Dan Harms (dharms)
;; Author: Dan Harms <enniomore@icloud.com>
;; Created: Monday, March 27, 2017
;; Version: 1.0
;; Modified Time-stamp: <2017-06-19 08:30:26 dharms>
;; Modified by: Dan Harms
;; Keywords: proviso projects

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
(require 'f)
(require 'ivy)
(require 'seq)
(require 'tramp)
(require 'load-environment-vars nil t)

(defvar proviso-obarray
  (let ((intern-obarray (make-vector 7 0)))
    intern-obarray)
  "Array of project objects.")
(defvar proviso-path-alist '()
  "Alist of pairs of strings (REGEXP . PROJECT-NAME).
A project is used for a file if the filename matches REGEXP.  In the case
of no matches, the default project is instead used.")
(defvar-local proviso-local-proj nil)
(defvar proviso-curr-proj nil)

(defun proviso-current-project ()
  "Return the current project, or if none, the last used."
  (if proviso-local-proj proviso-local-proj proviso-curr-proj))

(defun proviso-current-project-root ()
  "Return the root directory of the current or last-known project."
  (interactive)
  (cond (proviso-local-proj (proviso-get proviso-local-proj :root-dir))
        (proviso-curr-proj (proviso-get proviso-curr-proj :root-dir))
        (t default-directory)))

(defun proviso-current-project-name ()
  "Return the name of the current project, if any."
  (interactive)
  (let ((proj (proviso-current-project)))
    (when proj
      (proviso-get proj :project-name))))

;; Project Properties:
;;   - External:
;;  :include-files :include-ff-files
;;  :build-subdirs
;;   - Intenal:
;; :root-dir :project-name :inited :initfun
;; :remote-prefix :remote-host :root-stem
;; :registers
;; :tags-alist :tags-dir
;; :compile-cmd :compile-defun

;; hooks
(defvar proviso-hook-on-project-pre-init '()
  "Hooks run just before a project is first initialized.
Hook functions are called with one parameter, the new project.")
(defvar proviso-hook-on-project-init '()
  "Hooks run as a project is first initialized.
Hook functions are called with one parameter, the new project.")
(defvar proviso-hook-on-project-post-init '()
  "Hooks run just after a project is first initialized.
Hook functions are called with one parameter, the new project.")
(defvar proviso-hook-on-project-active '()
  "Hooks run whenever a project becomes active.
Hook functions are called with two parameters: the new project,
and the old one: `lambda(new old)()'.")
(defvar proviso-hook-on-file-opened '()
  "Hooks run whenever a file is opened that belongs to a project.
Hook functions are called with one parameter: the file's major mode.")

(defun proviso-proj-p (proj)
  "Return non-nil if PROJ is a project."
  (intern-soft proj proviso-obarray))

(defvar-local proviso--last-proj-defined nil
  "The most recent project to be defined.")

(defvar proviso--ext "proviso"
  "The extension for project files.")

(defun proviso-define (project &rest plist)
  "Create or replace a project named PROJECT.
Add to it the property list PLIST."
  (let ((p (intern project proviso-obarray)))
    (setplist p plist)
    (setq proviso--last-proj-defined p)))

(defun proviso-define-derived (project parent &rest plist)
  "Create or replace a project named PROJECT.
Its parent is PARENT.  Add to it the property list PLIST."
  (let ((p (intern project proviso-obarray)))
    (setplist p (append (list :parent parent) plist))
    (setq proviso--last-proj-defined p)))

(defun proviso-get-plist (project)
  "Return the plist associated with project PROJECT."
  (symbol-plist (intern-soft project proviso-obarray)))

(defun proviso-put (project property value)
  "Put into PROJECT the PROPERTY with value VALUE."
  (let ((p (intern-soft project proviso-obarray)))
    (if p (put p property value)
      (error "Invalid project %s" project))))

(defun proviso-get (project property &optional inhibit-polymorphism)
  "Get from PROJECT the value associated with PROPERTY.
INHIBIT-POLYMORPHISM, if non-nil, will constrain lookup from
searching in any bases."
  (let ((p (intern-soft project proviso-obarray))
        parent parentname)
    (when p
      (or (get p property)
          (and (not inhibit-polymorphism)
               (setq parentname (get p :parent))
               (setq parent (intern-soft parentname proviso-obarray))
               (proviso-get parent property))))))

(defun proviso-find-path-alist (&optional filename)
  "Scan `proviso-path-alist' for an entry to match FILENAME."
  (assoc-default
   (or filename (buffer-file-name) (buffer-name))
   proviso-path-alist 'string-match))

(defun proviso-name-p (proj)
  "Return non-nil if PROJ names an active project."
  (seq-find (lambda (elt)
              (string= (cdr elt) proj)) proviso-path-alist))

(define-error 'proviso-error "Project error")
(define-error 'proviso-error-non-fatal "Project load stopped" 'proviso-error)
(define-error 'proviso-error-aborted "Project load aborted" 'proviso-error)

(defvar proviso--ignore-load-errors nil
  "Internal variable is non-nil if user desires errors to be skipped.")

(defun proviso--query-error (project err)
  "While loading PROJECT, error ERR has occurred; ask the user what to do."
  (interactive)
  (let ((buf (get-buffer-create "*Proviso Error*")))
    (with-current-buffer buf
      (erase-buffer)
      (toggle-truncate-lines -1)
      (insert "An error occurred while loading project \""
              (propertize (symbol-name project) 'face 'bold)
              "\":\n\n"
              (propertize err 'face '(bold error))
              "\n\nWould you like to continue loading this project?  "
              "Please select:\n\n "
              (propertize "[y]" 'face '(bold warning))
              " Continue loading project, ignoring this error\n "
              (propertize "[!]" 'face '(bold warning))
              " Continue loading project, ignoring this and future errors\n "
              (propertize "[n]" 'face '(bold warning))
              " Stop loading project\n "
              (propertize "[a]" 'face '(bold warning))
              " Abort loading of project, and revert project load\n"
              ))
    (pop-to-buffer buf)
    (let ((choices '(?y ?n ?a ?!))
          (prompt "Please type y, n, ! or a: ")
          ch)
      (while (null ch)
        (setq ch (read-char-choice prompt choices)))
      (quit-window t)
      (cond ((eq ch ?n)
             (signal 'proviso-error-non-fatal err))
            ((eq ch ?a)
             (proviso-hard-reset project)
             (signal 'proviso-error-aborted
                     (format "Aborted (and reset) project \"%s\" (%s)"
                             (symbol-name project) err)))
            ((eq ch ?!)
             (setq proviso--ignore-load-errors t))
            ))
    nil))

(defun proviso--safe-funcall (proj property &rest rem)
  "Call a function from project PROJ stored in its PROPERTY tag.
The function is called with arguments REM, if the function exists
and is bound."
  (let ((func (proviso-get proj property)))
    (and func (or (and (symbolp func)
                       (fboundp func))
                  (functionp func))
         (funcall func (car rem)))))

(defun proviso-soft-reset ()
  "Reset the current project.
This does not otherwise remove any projects from memory."
  (interactive)
  ;; kill-local-variable insufficient due to permanent-local property
  (setq proviso-curr-proj nil)
  (setq proviso-local-proj (default-value 'proviso-local-proj)))

(defun proviso-hard-reset (&optional project)
  "Remove all traces of PROJECT."
  (interactive)
  (proviso--remove-proviso-from-alist project)
  (proviso--remove-proj project)
  (proviso-soft-reset))

(defun proviso--remove-proj (project)
  "Delete the project PROJECT, which can be a symbol or string (name)."
  (unintern project proviso-obarray))

(defun proviso--remove-proviso-from-alist (project)
  "Remove project PROJECT from the internal data structure."
  (setq proviso-path-alist
        (seq-remove
         (lambda (elt)
           ;; string-equal handles a symbol using its print-name
           (string-equal (cdr elt) project))
         proviso-path-alist)))

(defun proviso-find-file-upwards-helper (path file)
  "Helper function to search upward from PATH for FILE."
  (let* ((parent (file-name-directory path))
         files)
    (cond
     ;; parent of ~ is nil, parent of / is itself
     ;; This terminating condition accounts for both
     ((or (null parent) (equal parent (directory-file-name parent)))
      nil)
     ((setq files (directory-files parent t file))
      (car files))                      ;found
     (t (proviso-find-file-upwards-helper
         (directory-file-name parent) file)))))

(defun proviso-find-file-upwards (dir file)
  "Recursively search upward from DIR for FILE.
Return path to file or nil if not found."
  (interactive)
  (proviso-find-file-upwards-helper (or dir default-directory) file))

(defun proviso-find-file-dir-upwards (file)
  "Recursively search upward for FILE.
Return that file's directory or nil if not found."
  (interactive)
  (let ((file (proviso-find-file-upwards nil file)))
    (when file (file-name-directory file))))

(defun proviso--find-root (dir &optional absolute)
  "Search for the project root, starting from DIR and moving up the file tree.
Returns a cons (file, dir) containing the project file and its parent
directory, if found, else nil.  If ABSOLUTE is non-nil, the path, if found,
will be absolute.  Project files can look like any of the following:
    1) .proviso
    2) proj.proviso
    3) .proj.proviso"
  (let (root file)
    (setq root
          (if (functionp 'locate-dominating-file)
              (locate-dominating-file
               dir
               (lambda (parent)
                 (setq file
                       (car (directory-files parent t
                                             (concat "\\sw*\\."
                                                     proviso--ext "$"))))))
            (proviso-find-file-upwards dir
                                       (concat "\\sw*\\."
                                               proviso--ext "$"))))
    (when root
      (if absolute
          (cons file (expand-file-name root))
        (cons file root)))))

(defun proviso--compute-basename-from-file (name)
  "Compute the basename of the project located at NAME.
We first attempt to derive a name from the base of the file.
Otherwise we look at the current directory.  For example, the
following examples would all yield `sample':
    1)  ~/first/second/sample.proviso
    2)  /home/user/third/.sample.proviso
    3)  ~/sample/.proviso"
  (let ((base (file-name-nondirectory name)))
    (if (string-match
         (concat "\\.?\\(.+\\)\\." proviso--ext)
         base)
        (match-string-no-properties 1 base)
      (file-name-nondirectory
       (directory-file-name
        (file-name-directory name))))))

(defun proviso--compute-remote-props (dir)
  "Compute the remote properties associated with DIR.
DIR may be remote."
  (and dir (file-remote-p dir)
       (with-parsed-tramp-file-name dir file
         `( ,file-host ,file-localname
                       ,(tramp-make-tramp-file-name
                         file-method file-user file-host "")))))

(defun proviso--compute-stem (proj)
  "Compute a project PROJ's stem.
This is useful in regexp-matching.  The project's root-dir is
probably a relative path, possibly including a `~' that
represents the user's home directory."
  (replace-regexp-in-string "~/" "" (proviso-get proj :root-dir)))

(defun proviso-eval-string (str)
  "Evaluate the contents of STR."
  (let ((i 0) curr)
    (while (< i (1- (length str)))
      (setq curr (read-from-string str i))
      (eval (car curr))
      (setq i (cdr curr)))))

;;;###autoload
(defun proviso-choose-project ()
  "Allow the user to choose a project among those currently defined."
  (interactive)
  (let (lst)
    (mapatoms (lambda (atom)
                (push (symbol-name atom) lst)) proviso-obarray)
    (if (seq-empty-p lst)
        (error "No projects defined")
      (ivy-read "Project: " lst
                :caller 'proviso-choose-project
                ))))

(defun proviso-load-environment-variables-from-file (proj name)
  "Load environment variables in root dir of PROJ from file NAME.
Nothing is done if no such file exists in the root director of PROJ."
  (interactive "fLoad environment variables from file: ")
  (let* ((remote (proviso-get proj :remote-prefix))
        (root (proviso-get proj :root-dir))
        (file (concat remote root name)))
    (setenv "REPO_ROOT" (directory-file-name root))
    (and (fboundp 'load-environment-variables-from-file)
         (f-exists? file)
         (load-environment-variables-from-file file))))

(provide 'proviso-core)
;;; proviso-core.el ends here

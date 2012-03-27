;;; summered-emacs.el --- Summered for Emacs.

;; Copyright (C) 2012 Arthur Leonard Andersen

;; Author: Arthur Leonard Andersen <leoc.git@gmail.com>
;; URL: http://github.com/leoc/org-helpers
;; Version: 0.1.0

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
;;    org-helpers provide many methods to configure org-mode easily
;;  the GTD way.
;;
;;; Installation:
;;
;;    Just put org-helpers.el in a directory that´s in you load-path
;;  and `(require 'org-helpers)` in your `init.el`.
;;
;;     Afterwards you can use the org-helpers functions to configure
;;   your org-mode to your wishes.
;;
;;; Credits
;;
;;    Most code is based or taken from the wonderful article from
;;  norang. (http://doc.norang.ca/org-mode.html)
;;  Many thanks to Bernt Hansen for a well-founded approach!
;;
;;; Code

(defun oh/agenda-sort (a b)
  "Sorting strategy for agenda items.
Late deadlines first, then scheduled, then non-late deadlines"
  (let (result num-a num-b)
    (cond
     ;; time specific items are already sorted first by org-agenda-sorting-strategy
     ;; non-deadline and non-scheduled items next
     ((oh/agenda-sort-test 'oh/is-not-scheduled-or-deadline a b))
     ;; deadlines for today next
     ((oh/agenda-sort-test 'oh/is-due-deadline a b))
     ;; late deadlines next
     ((oh/agenda-sort-test-num 'oh/is-late-deadline '< a b))
     ;; scheduled items for today next
     ((oh/agenda-sort-test 'oh/is-scheduled-today a b))
     ;; late scheduled items next
     ((oh/agenda-sort-test-num 'oh/is-scheduled-late '> a b))
     ;; pending deadlines last
     ((oh/agenda-sort-test-num 'oh/is-pending-deadline '< a b))
     ;; finally default to unsorted
     (t (setq result nil)))
    result))

(defmacro oh/agenda-sort-test (fn a b)
  "Test for agenda sort"
  `(cond
    ;; if both match leave them unsorted
    ((and (apply ,fn (list ,a))
          (apply ,fn (list ,b)))
     (setq result nil))
    ;; if a matches put a first
    ((apply ,fn (list ,a))
     (setq result -1))
    ;; otherwise if b matches put b first
    ((apply ,fn (list ,b))
     (setq result 1))
    ;; if none match leave them unsorted
    (t nil)))

(defmacro oh/agenda-sort-test-num (fn compfn a b)
  `(cond
    ((apply ,fn (list ,a))
     (setq num-a (string-to-number (match-string 1 ,a)))
     (if (apply ,fn (list ,b))
         (progn
           (setq num-b (string-to-number (match-string 1 ,b)))
           (setq result (if (apply ,compfn (list num-a num-b))
                            -1
                          1)))
       (setq result -1)))
    ((apply ,fn (list ,b))
     (setq result 1))
    (t nil)))

(defun oh/is-not-scheduled-or-deadline (date-str)
  (and (not (oh/is-deadline date-str))
       (not (oh/is-scheduled date-str))))

(defun oh/is-due-deadline (date-str)
  (string-match "Deadline:" date-str))

(defun oh/is-late-deadline (date-str)
  (string-match "In *\\(-.*\\)d\.:" date-str))

(defun oh/is-pending-deadline (date-str)
  (string-match "In \\([^-]*\\)d\.:" date-str))

(defun oh/is-deadline (date-str)
  (or (oh/is-due-deadline date-str)
      (oh/is-late-deadline date-str)
      (oh/is-pending-deadline date-str)))

(defun oh/is-scheduled (date-str)
  (or (oh/is-scheduled-today date-str)
      (oh/is-scheduled-late date-str)))

(defun oh/is-scheduled-today (date-str)
  (string-match "Scheduled:" date-str))

(defun oh/is-scheduled-late (date-str)
  (string-match "Sched\.\\(.*\\)x:" date-str))

(defun oh/set-agenda-restriction-lock (arg)
  "Set restriction lock to current task subtree or file if prefix is specified"
  (interactive "p")
  (let* ((pom (org-get-at-bol 'org-hd-marker))
         (tags (org-with-point-at pom (org-get-tags-at))))
    (let ((restriction-type (if (equal arg 4) 'file 'subtree)))
      (save-restriction
        (cond
         ((equal major-mode 'org-agenda-mode)
          (org-with-point-at pom
            (org-agenda-set-restriction-lock restriction-type)))
         ((and (equal major-mode 'org-mode) (org-before-first-heading-p))
          (org-agenda-set-restriction-lock 'file))
         (t
          (org-with-point-at pom
            (org-agenda-set-restriction-lock restriction-type))))))))


(defun oh/org-todo (arg)
  (interactive "p")
  (if (equal arg 4)
      (save-restriction
        (widen)
        (org-narrow-to-subtree)
        (org-show-todo-tree nil))
    (widen)
    (org-narrow-to-subtree)
    (org-show-todo-tree nil)))

(defun oh/widen ()
  (interactive)
  (widen)
  (org-agenda-remove-restriction-lock))

(defun oh/narrow-to-org-subtree ()
  (widen)
  (org-narrow-to-subtree)
  (save-restriction
    (org-agenda-set-restriction-lock)))

(defun oh/narrow-to-subtree ()
  (interactive)
  (if (equal major-mode 'org-agenda-mode)
      (org-with-point-at (org-get-at-bol 'org-hd-marker)
        (oh/narrow-to-org-subtree))
    (oh/narrow-to-org-subtree)))

(defun oh/narrow-up-one-org-level ()
  (widen)
  (save-excursion
    (outline-up-heading 1 'invisible-ok)
    (oh/narrow-to-org-subtree)))

(defun oh/narrow-up-one-level ()
  (interactive)
  (if (equal major-mode 'org-agenda-mode)
      (org-with-point-at (org-get-at-bol 'org-hd-marker)
        (oh/narrow-up-one-org-level))
    (oh/narrow-up-one-org-level)))

(defun oh/narrow-to-org-project ()
  (widen)
  (save-excursion
    (oh/find-project-task)
    (oh/narrow-to-org-subtree)))

(defun oh/narrow-to-project ()
  (interactive)
;  (if (equal major-mode 'org-agenda-mode)
;      (org-with-point-at (org-get-at-bol 'org-hd-marker)
;        (oh/narrow-to-org-project))
    (oh/narrow-to-org-project));)

(defun oh/hide-other ()
  (interactive)
  (save-excursion
    (org-back-to-heading 'invisible-ok)
    (org-shifttab)
    (org-reveal)
    (org-cycle)))

(defun oh/set-truncate-lines ()
  "Toggle value of truncate-lines and refresh window display."
  (interactive)
  (setq truncate-lines (not truncate-lines))
  ;; now refresh window display (an idiom from simple.el):
  (save-excursion
    (set-window-start (selected-window)
                      (window-start (selected-window)))))

(defun oh/make-org-scratch ()
  (interactive)
  (find-file "/tmp/publish/scratch.org")
  (gnus-make-directory "/tmp/publish"))

(defun oh/switch-to-scratch ()
  (interactive)
  (switch-to-buffer "*scratch*"))

(defun oh/clock-in-to-next (kw)
  "Switch a task from TODO to NEXT when clocking in.
Skips capture tasks, projects, and subprojects.
Switch projects and subprojects from NEXT back to TODO"
  (when (not (and (boundp 'org-capture-mode) org-capture-mode))
    (cond
     ((and (member (org-get-todo-state) (list "TODO"))
           (oh/is-task-p))
      "NEXT")
     ((and (member (org-get-todo-state) (list "NEXT"))
           (oh/is-project-p))
      "TODO"))))

(defun oh/find-project-task ()
  "Move point to the parent (project) task if any"
  (save-restriction
    (widen)
    (let ((parent-task (save-excursion (org-back-to-heading 'invisible-ok) (point))))
      (while (org-up-heading-safe)
        (when (member (nth 2 (org-heading-components)) org-todo-keywords-1)
          (setq parent-task (point))))
      (goto-char parent-task)
      parent-task)))

(defun oh/punch-in (arg)
  "Start continuous clocking and set the default task to the
selected task.  If no task is selected set the Organization task
as the default task."
  (interactive "p")
  (setq oh/keep-clock-running t)
  (if (equal major-mode 'org-agenda-mode)
      ;;
      ;; We're in the agenda
      ;;
      (let* ((marker (org-get-at-bol 'org-hd-marker))
             (tags (org-with-point-at marker (org-get-tags-at))))
        (if (and (eq arg 4) tags)
            (org-agenda-clock-in '(16))
          (oh/clock-in-organization-task-as-default)))
    ;;
    ;; We are not in the agenda
    ;;
    (save-restriction
      (widen)
                                        ; Find the tags on the current task
      (if (and (equal major-mode 'org-mode) (not (org-before-first-heading-p)) (eq arg 4))
          (org-clock-in '(16))
        (oh/clock-in-organization-task-as-default)))))

(defun oh/punch-out ()
  (interactive)
  (setq oh/keep-clock-running nil)
  (when (org-clock-is-active)
    (org-clock-out))
  (org-agenda-remove-restriction-lock))

(defun oh/clock-in-default-task ()
  (save-excursion
    (org-with-point-at org-clock-default-task
      (org-clock-in))))

(defun oh/clock-in-parent-task ()
  "Move point to the parent (project) task if any and clock in"
  (let ((parent-task))
    (save-excursion
      (save-restriction
        (widen)
        (while (and (not parent-task) (org-up-heading-safe))
          (when (member (nth 2 (org-heading-components)) org-todo-keywords-1)
            (setq parent-task (point))))
        (if parent-task
            (org-with-point-at parent-task
              (org-clock-in))
          (when oh/keep-clock-running
            (oh/clock-in-default-task)))))))

(defvar oh/organization-task-id "eb155a82-92b2-4f25-a3c6-0304591af2f9")

(defun oh/clock-in-organization-task-as-default ()
  (interactive)
  (org-with-point-at (org-id-find oh/organization-task-id 'marker)
    (org-clock-in '(16))))

(defun oh/clock-out-maybe ()
  (when (and oh/keep-clock-running
             (not org-clock-clocking-in)
             (marker-buffer org-clock-default-task)
             (not org-clock-resolving-clocks-due-to-idleness))
    (oh/clock-in-parent-task)))

(require 'org-id)
(defun oh/clock-in-task-by-id (id)
  "Clock in a task by id"
  (org-with-point-at (org-id-find id 'marker)
    (org-clock-in nil)))

(defun oh/clock-in-last-task (arg)
  "Clock in the interrupted task if there is one
Skip the default task and get the next one.
A prefix arg forces clock in of the default task."
  (interactive "p")
  (let ((clock-in-to-task
         (cond
          ((eq arg 4) org-clock-default-task)
          ((and (org-clock-is-active)
                (equal org-clock-default-task (cadr org-clock-history)))
           (caddr org-clock-history))
          ((org-clock-is-active) (cadr org-clock-history))
          ((equal org-clock-default-task (car org-clock-history)) (cadr org-clock-history))
          (t (car org-clock-history)))))
    (org-with-point-at clock-in-to-task
      (org-clock-in nil))))

(defun oh/is-project-p ()
  "Any task with a todo keyword subtask"
  (save-restriction
    (widen)
    (let ((has-subtask)
          (subtree-end (save-excursion (org-end-of-subtree t)))
          (is-a-task (member (nth 2 (org-heading-components)) org-todo-keywords-1)))
      (save-excursion
        (forward-line 1)
        (while (and (not has-subtask)
                    (< (point) subtree-end)
                    (re-search-forward "^\*+ " subtree-end t))
          (when (member (org-get-todo-state) org-todo-keywords-1)
            (setq has-subtask t))))
      (and is-a-task has-subtask))))

(defun oh/is-project-subtree-p ()
  "Any task with a todo keyword that is in a project subtree.
Callers of this function already widen the buffer view."
  (let ((task (save-excursion (org-back-to-heading 'invisible-ok)
                              (point))))
    (save-excursion
      (oh/find-project-task)
      (if (equal (point) task)
          nil
        t))))

(defun oh/is-task-p ()
  "Any task with a todo keyword and no subtask"
  (save-restriction
    (widen)
    (let ((has-subtask)
          (subtree-end (save-excursion (org-end-of-subtree t)))
          (is-a-task (member (nth 2 (org-heading-components)) org-todo-keywords-1)))
      (save-excursion
        (forward-line 1)
        (while (and (not has-subtask)
                    (< (point) subtree-end)
                    (re-search-forward "^\*+ " subtree-end t))
          (when (member (org-get-todo-state) org-todo-keywords-1)
            (setq has-subtask t))))
      (and is-a-task (not has-subtask)))))

(defun oh/is-subproject-p ()
  "Any task which is a subtask of another project"
  (let ((is-subproject)
        (is-a-task (member (nth 2 (org-heading-components)) org-todo-keywords-1)))
    (save-excursion
      (while (and (not is-subproject) (org-up-heading-safe))
        (when (member (nth 2 (org-heading-components)) org-todo-keywords-1)
          (setq is-subproject t))))
    (and is-a-task is-subproject)))

(defun oh/list-sublevels-for-projects-indented ()
  "Set org-tags-match-list-sublevels so when restricted to a subtree we list all subtasks.
  This is normally used by skipping functions where this variable is already local to the agenda."
  (if (marker-buffer org-agenda-restrict-begin)
      (setq org-tags-match-list-sublevels 'indented)
    (setq org-tags-match-list-sublevels nil))
  nil)

(defun oh/list-sublevels-for-projects ()
  "Set org-tags-match-list-sublevels so when restricted to a subtree we list all subtasks.
  This is normally used by skipping functions where this variable is already local to the agenda."
  (if (marker-buffer org-agenda-restrict-begin)
      (setq org-tags-match-list-sublevels t)
    (setq org-tags-match-list-sublevels nil))
  nil)

(defun oh/skip-non-stuck-projects ()
  "Skip trees that are not stuck projects"
  (save-restriction
    (widen)
    (let ((next-headline (save-excursion (or (outline-next-heading) (point-max)))))
      (if (oh/is-project-p)
          (let* ((subtree-end (save-excursion (org-end-of-subtree t)))
                 (has-next (save-excursion
                             (forward-line 1)
                             (and (< (point) subtree-end)
                                  (re-search-forward "^\\*+ \\(NEXT\\) " subtree-end t)))))
            (if has-next
                next-headline
              nil)) ; a stuck project, has subtasks but no next task
        next-headline))))

(defun oh/skip-non-stuck-projects-and-habits ()
  "Skip trees that are not stuck projects"
  (save-restriction
    (widen)
    (let ((next-headline (save-excursion (or (outline-next-heading) (point-max)))))
      (if (and (not (org-is-habit-p))
               (oh/is-project-p))
          (let* ((subtree-end (save-excursion (org-end-of-subtree t)))
                 (has-next (save-excursion
                             (forward-line 1)
                             (and (< (point) subtree-end)
                                  (re-search-forward "^\\*+ \\(NEXT\\) " subtree-end t)))))
            (if has-next
                next-headline
              nil)) ; a stuck project, has subtasks but no next task
        next-headline))))

(defun oh/skip-non-projects ()
  "Skip trees that are not projects"
  (oh/list-sublevels-for-projects-indented)
  (if (save-excursion (oh/skip-non-stuck-projects))
      (save-restriction
        (widen)
        (let ((subtree-end (save-excursion (org-end-of-subtree t))))
          (if (oh/is-project-p)
              nil
            subtree-end)))
    (org-end-of-subtree t)))

(defun oh/skip-non-projects-and-habits ()
  "Skip trees that are not projects"
  (oh/list-sublevels-for-projects-indented)
  (if (save-excursion (oh/skip-non-stuck-projects))
      (save-restriction
        (widen)
        (let ((subtree-end (save-excursion (org-end-of-subtree t))))
          (if (and (not (org-is-habit-p))
                   (oh/is-project-p))
              nil
            subtree-end)))
    (org-end-of-subtree t)))

(defun oh/skip-project-trees-and-habits ()
  "Skip trees that are projects"
  (save-restriction
    (widen)
    (let ((subtree-end (save-excursion (org-end-of-subtree t))))
      (cond
       ((oh/is-project-p)
        subtree-end)
       ((org-is-habit-p)
        subtree-end)
       (t
        nil)))))

(defun oh/skip-projects-and-habits-and-single-tasks ()
  "Skip trees that are projects, tasks that are habits, single non-project tasks"
  (save-restriction
    (widen)
    (let ((next-headline (save-excursion (or (outline-next-heading) (point-max)))))
      (cond
       ((org-is-habit-p)
        next-headline)
       ((oh/is-project-p)
        next-headline)
       ((and (oh/is-task-p) (not (oh/is-project-subtree-p)))
        next-headline)
       (t
        nil)))))

(defun oh/skip-projects-and-habits ()
  "Skip trees that are projects, tasks that are habits, single non-project tasks"
  (save-restriction
    (widen)
    (let ((next-headline (save-excursion (or (outline-next-heading) (point-max)))))
      (cond
       ((org-is-habit-p)
        next-headline)
       ((oh/is-project-p)
        next-headline)
       (t
        nil)))))

(defun oh/skip-project-tasks-maybe ()
  "Show tasks related to the current restriction.
When restricted to a project, skip project and sub project tasks, habits, NEXT tasks, and loose tasks.
When not restricted, skip project and sub-project tasks, habits, and project related tasks."
  (save-restriction
    (widen)
    (let* ((subtree-end (save-excursion (org-end-of-subtree t)))
           (next-headline (save-excursion (or (outline-next-heading) (point-max))))
           (limit-to-project (marker-buffer org-agenda-restrict-begin)))
      (cond
       ((oh/is-project-p)
        next-headline)
       ((org-is-habit-p)
        subtree-end)
       ((and (not limit-to-project)
             (oh/is-project-subtree-p))
        subtree-end)
       ((and limit-to-project
             (oh/is-project-subtree-p)
             (member (org-get-todo-state) (list "NEXT")))
        subtree-end)
       (t
        (org-agenda-skip-entry-if 'scheduled 'deadline))))))

(defun oh/skip-projects-and-habits ()
  "Skip trees that are projects and tasks that are habits"
  (save-restriction
    (widen)
    (let ((subtree-end (save-excursion (org-end-of-subtree t))))
      (cond
       ((oh/is-project-p)
        subtree-end)
       ((org-is-habit-p)
        subtree-end)
       (t
        nil)))))

(defun oh/skip-non-subprojects ()
  "Skip trees that are not projects"
  (let ((next-headline (save-excursion (outline-next-heading))))
    (if (oh/is-subproject-p)
        nil
      next-headline)))


(defun oh/summary-todo-checkbox (c-on c-off)
  "Switch entry to DONE when all subentry-checkboxes are done, to TODO otherwise."
  (outline-previous-visible-heading 1)
  (let (org-log-done org-log-states)	; turn off logging
    (org-todo (if (= c-off 0) "DONE" "TODO"))))

(provide 'org-helpers)

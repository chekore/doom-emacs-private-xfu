;;; ui/doom/config.el -*- lexical-binding: t; -*-

;; <https://github.com/hlissner/emacs-doom-theme>
(def-package! doom-themes :load-path "~/.emacs.d/modules/private/doom/local/emacs-doom-themes/"
  :config
  (unless doom-theme
    (setq doom-theme 'doom-one)
    (after! solaire-mode
      (add-hook 'doom-init-theme-hook #'solaire-mode-swap-bg t)))

  ;; Ensure `doom/reload-load-path' reloads common faces
  (defun +doom|reload-theme () (load "doom-themes-common.el" nil t))
  (add-hook 'doom-pre-reload-theme-hook #'+doom|reload-theme)

  ;; improve integration w/ org-mode
  (add-hook 'doom-init-theme-hook #'doom-themes-org-config)

  ;; more Atom-esque file icons for neotree
  (add-hook 'doom-init-theme-hook #'doom-themes-neotree-config)
  (setq doom-neotree-enable-variable-pitch t
        doom-neotree-file-icons 'simple
        doom-neotree-line-spacing 2))


(def-package! solaire-mode
  :hook (after-change-major-mode . turn-on-solaire-mode)
  :config
  (setq solaire-mode-real-buffer-fn #'doom-real-buffer-p)
  ;; Prevent color glitches when reloading either DOOM or the theme
  (add-hook! '(doom-init-theme-hook doom-reload-hook) #'solaire-mode-reset))


(after! hideshow
  (defface +doom-folded-face
    `((((background dark))
       (:inherit font-lock-comment-face :background ,(doom-color 'base0)))
      (((background light))
       (:inherit font-lock-comment-face :background ,(doom-color 'base3))))
    "Face to hightlight `hideshow' overlays."
    :group 'doom)

  ;; Nicer code-folding overlays (with fringe indicators)
  (defun +doom-set-up-overlay (ov)
    (when (eq 'code (overlay-get ov 'hs))
      (when (featurep 'vimish-fold)
        (overlay-put
         ov 'before-string
         (propertize "…" 'display
                     (list vimish-fold-indication-mode
                           'empty-line
                           'vimish-fold-fringe))))
      (overlay-put
       ov 'display (propertize "  [...]  " 'face '+doom-folded-face))))
  (setq hs-set-up-overlay #'+doom-set-up-overlay))


;; NOTE Adjust these bitmaps if you change `doom-fringe-size'
(after! flycheck
  ;; because git-gutter is in the left fringe
  (setq flycheck-indication-mode 'right-fringe)
  ;; A non-descript, left-pointing arrow
  (fringe-helper-define 'flycheck-fringe-bitmap-double-arrow 'center
    "...X...."
    "..XX...."
    ".XXX...."
    "XXXX...."
    ".XXX...."
    "..XX...."
    "...X...."))

;; subtle diff indicators in the fringe
(after! git-gutter-fringe
  ;; places the git gutter outside the margins.
  (setq-default fringes-outside-margins t)
  ;; thin fringe bitmaps
  (fringe-helper-define 'git-gutter-fr:added '(center repeated)
    "XXX.....")
  (fringe-helper-define 'git-gutter-fr:modified '(center repeated)
    "XXX.....")
  (fringe-helper-define 'git-gutter-fr:deleted 'bottom
    "X......."
    "XX......"
    "XXX....."
    "XXXX...."))

(after! colir
  (defun colir--blend-background (start next prevn face object)
    (let ((background-prev (face-background prevn)))
      (progn
        (put-text-property
         start next
         (if background-prev
             (cons `(background-color
                     . ,(colir-blend
                         (colir-color-parse background-prev)
                         (colir-color-parse (face-background face nil t))))
                   prevn)
           (list face prevn))
         object))))
  (defun colir-blend-face-background (start end face &optional object)
    "Append to the face property of the text from START to END the face FACE.
When the text already has a face with a non-plain background,
blend it with the background of FACE.
Optional argument OBJECT is the string or buffer containing the text.
See also `font-lock-append-text-property'."
    (let (next prev prevn)
      (while (/= start end)
        (setq next (next-single-property-change start 'face object end))
        (setq prev (get-text-property start 'face object))
        (setq prevn (if (listp prev)
                        (cl-find-if #'atom prev)
                      prev))
        (cond
         ((or (keywordp (car-safe prev)) (consp (car-safe prev)))
          (put-text-property start next 'face (cons face prev) nil object))
         ((facep prevn)
          (colir--blend-background start next prevn face object))
         (t
          (put-text-property start next 'face face nil object)))
        (setq start next)))))

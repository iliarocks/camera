#lang racket

(require racket/system)
(require racket/gui/base)
(require racket/draw)

(define PADDING 24)
(define PREVIEW_WIDTH 600)
(define PREVIEW_HEIGHT 400)
(define SHUTTER_RADIUS 32)
(define SHUTTER_SIZE (* 2 SHUTTER_RADIUS))
(define SHUTTER_CENTER_X (+ PREVIEW_WIDTH SHUTTER_RADIUS PADDING))
(define SHUTTER_CENTER_Y (/ PREVIEW_HEIGHT 2))
(define SHUTTER_TOP (- (/ PREVIEW_HEIGHT 2) SHUTTER_RADIUS))
(define SHUTTER_LEFT (+ PREVIEW_WIDTH PADDING))

(define-values (preview-process from-preview to-preview preview-errors)
  (subprocess #f #f (current-error-port)
              (find-executable-path "python3")
              "camera-helper.py"))

(printf "Process handle ~a\n" (subprocess? preview-process))
(define image (read-bitmap from-preview))

(define (draw-preview drawing-context)
  (define original-transformation (send drawing-context get-transformation))
  (define scaling (/ PREVIEW_WIDTH (send image get-width)))
  (send drawing-context scale scaling scaling)
  (send drawing-context draw-bitmap image 0 0)
  (send drawing-context set-transformation original-transformation))

(define frame (new frame%
                [label "Camera"]
                [style (list 'no-caption)]
                [width (+ PREVIEW_WIDTH (* 2 SHUTTER_RADIUS) (* 2 PADDING))]
                [height PREVIEW_HEIGHT]))

(define custom-canvas%
  (class canvas%
    (super-new)
    (define/override (on-event event)
      (when
        (and (send event button-down? 'left)
             (<= (sqrt (+ (sqr (- (send event get-y) SHUTTER_CENTER_Y)) 
                          (sqr (- (send event get-x) SHUTTER_CENTER_X))))
                 SHUTTER_RADIUS))
        (println "Shutter")))))


(new custom-canvas%
  [parent frame]
  [paint-callback
   (lambda (canvas drawing-context)
     (send drawing-context set-pen "black" 0 'transparent)
     (send drawing-context set-brush "black" 'solid)
     (send drawing-context draw-rectangle 0 0 (+ PREVIEW_WIDTH SHUTTER_SIZE (* 2 PADDING)) PREVIEW_HEIGHT)
     (send drawing-context set-brush "gray" 'solid)
     (send drawing-context draw-rectangle 0 0 PREVIEW_WIDTH PREVIEW_HEIGHT)
     (send drawing-context set-brush "white" 'solid)
     (send drawing-context draw-ellipse SHUTTER_LEFT SHUTTER_TOP SHUTTER_SIZE SHUTTER_SIZE)
     (draw-preview drawing-context))])

(send frame show #t)

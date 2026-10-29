#lang racket

(require racket/system)
(require racket/gui/base)
(require racket/draw)

(define SCALE 2)
(define PADDING 12)
(define PREVIEW_WIDTH 300)
(define PREVIEW_HEIGHT 200)
(define SHUTTER_RADIUS 16)
(define SHUTTER_SIZE (* 2 SHUTTER_RADIUS))

(define frame (new frame% 
                   [label "Camera"]
                   [style (list 'no-caption)]
                   [width (* (+ PREVIEW_WIDTH (* 2 SHUTTER_RADIUS) (* 2 PADDING)) SCALE)]
                   [height (* PREVIEW_HEIGHT SCALE)]))

(new canvas%
  [parent frame]
  [paint-callback
   (lambda (canvas drawing-context)
     (send drawing-context set-pen "black" 0 'transparent)
     (send drawing-context set-scale SCALE SCALE)
     (send drawing-context set-brush "black" 'solid)
     (send drawing-context draw-rectangle 0 0 (+ PREVIEW_WIDTH SHUTTER_SIZE (* 2 PADDING)) PREVIEW_HEIGHT)
     (send drawing-context set-brush "gray" 'solid)
     (send drawing-context draw-rectangle 0 0 PREVIEW_WIDTH PREVIEW_HEIGHT)
     (send drawing-context set-brush "white" 'solid)
     (send drawing-context draw-ellipse (+ PREVIEW_WIDTH PADDING) (- (/ PREVIEW_HEIGHT 2) SHUTTER_RADIUS) SHUTTER_SIZE SHUTTER_SIZE))])

(send frame show #t)

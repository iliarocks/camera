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

(define-values (camera-process from-camera to-camera camera-errors)
  (subprocess #f #f (current-error-port)
              (find-executable-path "python3")
              "camera-helper.py"))

(define image #f)
(define busy #f)

(define (read-message input)
  (define header (read-bytes 4 input))
  (if (not (eof-object? header))
      (list (read-byte input)
            (read-bytes (integer-bytes->integer header #f #f) input))
      header))

(define (draw-preview drawing-context)
  (when image
    (define original-transformation (send drawing-context get-transformation))
    (define scaling (/ PREVIEW_WIDTH (send image get-width)))
    (send drawing-context scale scaling scaling)
    (send drawing-context draw-bitmap image 0 0)
    (send drawing-context set-transformation original-transformation)))

(define (request-camera-stop)
  (display "stop\n" to-camera)
  (flush-output to-camera))

(define custom-frame%
  (class frame%
    (super-new)
    (define/augment (on-close)
      (request-camera-stop))))

(define frame
  (new custom-frame%
    [label "Camera"]
    [style (list 'no-caption)]
    [width (+ PREVIEW_WIDTH (* 2 SHUTTER_RADIUS) (* 2 PADDING))]
    [height PREVIEW_HEIGHT]))

(define custom-canvas%
  (class canvas%
    (super-new)
    (define/override (on-event event)
      (when
        (and (not busy)
             (send event button-down? 'left)
             (<= (sqrt (+ (sqr (- (send event get-y) SHUTTER_CENTER_Y))
                          (sqr (- (send event get-x) SHUTTER_CENTER_X))))
                 SHUTTER_RADIUS))
        (begin 
          (set! busy #t)
          (send canvas refresh)
          (display "capture\n" to-camera)
          (flush-output to-camera))))))


(define canvas
  (new custom-canvas%
    [parent frame]
    [paint-callback
     (lambda (canvas drawing-context)
       (send drawing-context set-pen "black" 0 'transparent)
       (send drawing-context set-brush "black" 'solid)
       (send drawing-context draw-rectangle 0 0 (+ PREVIEW_WIDTH SHUTTER_SIZE (* 2 PADDING)) PREVIEW_HEIGHT)
       (send drawing-context set-brush "dim gray" 'solid)
       (send drawing-context draw-rectangle 0 0 PREVIEW_WIDTH PREVIEW_HEIGHT)
       (if (not busy)
           (send drawing-context set-brush "white" 'solid)
           (send drawing-context set-brush "dim gray" 'solid))
       (send drawing-context draw-ellipse SHUTTER_LEFT SHUTTER_TOP SHUTTER_SIZE SHUTTER_SIZE)
       (draw-preview drawing-context))]))

(send frame show #t)

(define receiver-worker
  (thread
    (lambda ()
      (define (receive-messages)
        (define received-message (read-message from-camera))
        (unless (eof-object? received-message)
          (define type (first received-message))
          (define payload (second received-message))
          (when (= type 1)
            (queue-callback
              (lambda () 
                (set! busy #f)
                (send canvas refresh))))
          (when (= type 0)
            (define received-image (read-bitmap (open-input-bytes payload)))
            (queue-callback
              (lambda ()
                (set! image received-image)
                (send canvas refresh))))
          (receive-messages)))
      (receive-messages)
      (subprocess-wait camera-process)
      (close-input-port from-camera)
      (close-output-port to-camera)
      (printf "Camera ended (exit ~a)\n"
              (subprocess-status camera-process)))))

(void (yield (thread-dead-evt receiver-worker)))

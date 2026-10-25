#lang racket

(require racket/system)
(require racket/gui/base)

(define-values (camera-process from-camera to-camera camera-errors)
  (subprocess (current-output-port) #f (current-error-port)
              (find-executable-path "rpicam-still")
              "--timeout"
              "0"
              "--keypress"
              "--output"
              "live-test-%04d.jpg"))

(define (request-photo)
  (newline to-camera)
  (flush-output to-camera))

(define (stop-camera)
  (display "x" to-camera)
  (newline to-camera)
  (flush-output to-camera)
  (subprocess-wait camera-process)
  (printf "Exit-status: ~a\n" (subprocess-status camera-process))
  (close-output-port to-camera))

(define custom-frame%
  (class frame%
    (super-new)
    (define/augment (on-close)
      (stop-camera))))
      
(define frame (new custom-frame% [label "Camera"]))
(define message (new message%
                  [parent frame]
                  [label "Ready"]))

(new button%
  [parent frame]
  [label "Capture"]
  [callback (lambda (button event)
              (request-photo)
              (send message set-label "Capture requested"))])

(printf "Process handle? ~a\n" (subprocess? camera-process))

(send frame show #t)

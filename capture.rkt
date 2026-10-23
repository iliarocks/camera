#lang racket

(require racket/system)
(require racket/gui/base)

(define (capture-photo output-path)
  (system* (find-executable-path "rpicam-still") "--nopreview" "--output" output-path))

(define frame (new frame% [label "Camera"]))
(define message (new message% 
                  [parent frame]
                  [label "Ready"]))
(new button% 
  [parent frame]
  [label "Capture"]
  [callback (lambda (button event) 
              (if (capture-photo "capture-gui-test.jpg")
                  (send message set-label "Capture successful")
                  (send message set-label "Capture failed")))])

(send frame show #t)

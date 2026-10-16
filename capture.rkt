#lang racket

(require racket/system)

(define (capture-photo output-path)
  (system* (find-executable-path "rpicam-still") "--nopreview" "--output" output-path))

(capture-photo "racket-text.jpg")

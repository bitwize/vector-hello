(c-declare "#include \"vector_hello_x11.c\"")

(define WINDOW-WIDTH 800)
(define WINDOW-HEIGHT 600)
(define HELLO-INIT -600)
(define HELLO-Y 100)
(define WORLD-INIT 1200)
(define WORLD-Y 300)
(define DEST 150)

(define JIFFY-TIME 0.016) ; seconds
(define *game-state* (cons
		      (cons HELLO-INIT HELLO-Y)
		      (cons WORLD-INIT WORLD-Y)))
(define *clock* 0)
(define *old-clock* 0)
(define *seconds-accumulator* 0)
(define *coord-buffer* (make-s16vector 1024 0))

(define init-window
  (c-lambda (unsigned-int unsigned-int) int "init_window"))

(define close-window
  (c-lambda () void "close_window"))

(define refresh-window!
  (c-lambda () void "refresh_window"))

(define clear-display!
  (c-lambda () void "clear_display"))

(define get-input-events!
  (c-lambda () void "get_input_events"))

(define should-quit
  (c-lambda () int "___return(should_quit);"))

(define (draw-pline! color len coords)
  (if (and (integer? color)
	   (s16vector? coords))
      (let* ((real-len (min (* 2 len) (s16vector-length coords)))
	     (draw-pline-base!
	      (c-lambda (unsigned-int unsigned-int scheme-object) void
			"draw_pline(___arg1, ___arg2, (uint16_t *)___BODY_AS(___arg3, ___tS16VECTOR));")))
	(draw-pline-base! color real-len coords))))

(define (copy-coords-to-buffer! coord-list)
  (let* ((target-vector-len (* (length coord-list) 2))
	 (buffer-len (s16vector-length *coord-buffer*)))
    (if (< buffer-len target-vector-len)
	(set! *coord-buffer* (make-s16vector target-vector-len 0)))
    (let loop ((i 0)
	       (l coord-list))
      (cond
       ((null? l))
       (else
	(s16vector-set! *coord-buffer* i (car (car l)))
	(s16vector-set! *coord-buffer* (+ i 1) (cdr (car l)))
	(loop (+ i 2) (cdr l)))))))

(define (draw-dlist! dlist)
  (for-each
   (lambda (item)
     (copy-coords-to-buffer! (cdr item))
     (draw-pline! (car item) (length (cdr item)) *coord-buffer*))
   dlist))

(define (translate-dlist dl x y)
  (map
   (lambda (item)
     (cons (car item)
	   (map
	    (lambda (coords)
	      (cons
	       (+ (car coords) x)
	       (+ (cdr coords) y)))
	    (cdr item))))
   dl))

(define (hello-loc state)
  (car state))

(define (world-loc state)
  (cdr state))

(define hello-object
  '(
    ;; H
    (1
     (0 . 0)
     (0 . 100))
    (1
     (0 . 50)
     (50 . 50))
    (1
     (50 . 0)
     (50 . 100))
    ;; E
    (2
     (150 . 0)
     (100 . 0)
     (100 . 100)
     (150 . 100))
    (2
     (150 . 50)
     (100 . 50))
    ;; L
    (3
     (200 . 0)
     (200 . 100)
     (250 . 100))
    ;; L
    (4
     (300 . 0)
     (300 . 100)
     (350 . 100))
    ;; O
    (5
     (400 . 0)
     (400 . 100)
     (450 . 100)
     (450 . 0)
     (400 . 0))))

(define world-object
  '(
    ;; W
    (6
     (0 . 0)
     (0 . 100)
     (25 . 75)
     (50 . 100)
     (50 . 0))
    ;; O
    (1
     (100 . 0)
     (100 . 100)
     (150 . 100)
     (150 . 0)
     (100 . 0))
    ;; R
    (2
     (200 . 100)
     (200 . 0)
     (250 . 0)
     (250 . 50)
     (200 . 50)
     (250 . 100))
    ;; L
    (3
     (300 . 0)
     (300 . 100)
     (350 . 100))
    ;; D
    (4
     (400 . 0)
     (450 . 0)
     (450 . 100)
     (400 . 100))
    (4
     (425 . 0)
     (425 . 100))))

(define (get-dlist state)
  (let* ((hloc (hello-loc state))
	 (wloc (world-loc state)))
    (append
     (translate-dlist hello-object (car hloc) (cdr hloc))
     (translate-dlist world-object (car wloc) (cdr wloc)))))

(define (step-one-frame! state)
  (let* ((hloc (hello-loc state))
	 (wloc (world-loc state)))
    (if (< (car hloc) DEST)
	(set-car! hloc (+ (car hloc) 1)))
    (if (> (car wloc) DEST)
	(set-car! wloc (- (car wloc) 1)))))

(define (update-state!)
  (set! *seconds-accumulator*
	(+ *seconds-accumulator* (- *clock* *old-clock*)))
  (let loop ()
    (cond
     ((>= *seconds-accumulator* JIFFY-TIME)
      (step-one-frame! *game-state*)
      (set! *seconds-accumulator* (- *seconds-accumulator* JIFFY-TIME))
      (loop)))))

(define (draw-display!)
  (clear-display!)
  (draw-dlist!
   (get-dlist *game-state*))
  (refresh-window!))

(define (main)
  (set! *clock* (time->seconds (current-time)))
  (set! *old-clock* (time->seconds (current-time)))
  (dynamic-wind
      (lambda ()
	(init-window WINDOW-WIDTH WINDOW-HEIGHT))
      (lambda ()
	(let loop ()
	  (set! *clock* (time->seconds (current-time)))
	  (get-input-events!)
	  (update-state!)
	  (draw-display!)
	  (set! *old-clock* *clock*)
	  (thread-sleep! JIFFY-TIME)
	  (if (zero? (should-quit)) (loop))))
      (lambda ()
	(close-window))))

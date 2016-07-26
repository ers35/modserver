(define (run s)
  (set_status s 200)
  (set_header s "Content-Type" "text/plain; charset=UTF-8")
  (let ((arg (get_arg s "arg")))
    (if (string? arg)
      (rwrite s arg)))
  (rwrite s (get_method s))
  (let ((header (get_header s "User-Agent")))
    (if (string? header)
      (rwrite s header)))
  (rflush s))

;(display run)
;(display (current-module))
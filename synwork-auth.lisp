;;;; synwork-auth.lisp

(in-package #:synwork-auth)

;;; "synwork-auth" goes here. Hacks and glory await!
;;;

(define-route login ("login")
  (list :title "Log in"
		:body (login-form)))

(define-route login/post ("login" :method :post)
  (let ((user (auth-user (hunchentoot:post-parameter "username")
					     (hunchentoot:post-parameter "password"))))
	(if user
	  (log-in (getf user :username)
			  (getf user :password-hash))
	  (redirect 'login))))

(define-route register ("register")
  (list :title "register"
		:body (register-form)))

(define-route register/post ("register" :method :post)
  (let ((user (register-user (hunchentoot:post-parameter "username")
					         (hunchentoot:post-parameter "password"))))
	(if user
	  ;(print (getf user :password-hash))
	  (log-in (getf user :username)
	  		  (getf user :password-hash))
	  (redirect 'register))))

(define-route test ("test")
  (list :title "test"
		:body (test-frame)))

(define-route test/post ("test" :method :post)
  (format nil "My: ~A" (hunchentoot:post-parameters*)))

(define-route decrypt-cookie/post ("decrypt-cookie" :method :post)
  (let* ((auth-info (decrypt-auth-cookie (hunchentoot:post-parameter "cookie")))
		(cookie (hunchentoot:post-parameter "cookie")))
	(if auth-info
	  (let ((myuser (verify-user (second auth-info) (third auth-info))))
		(if myuser
		  (json:encode-json-to-string (make-instance 'guest-info :guest-name (getf myuser :username) :guest-channel (getf myuser :channel)))	 
		  (json:encode-json-to-string (make-instance 'guest-info)))))))
		  ;(format nil "{\"username\":\"~A\",\"channel\":~A}" (getf myuser :username) (getf myuser :channel))
		  ;(format nil "{\"user\":\"none\",\"channel\":00000}"))))))

(define-route logout ("logout")
  (log-out))



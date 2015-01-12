;;;;; template.lisp
;;;
(in-package #:synwork-auth)

(defun login-form ()
  (<:form :action (genurl 'login/post) :method "post"
		  "User Name:" (<:br)
		  (<:input :type "text" :name "username")(<:br)
		  "Password:" (<:br)
		  (<:input :type "password" :name "password")(<:br)
		  (<:input :type "submit" :value "Log in")))

(defun register-form ()
  (<:form :action (genurl 'register/post) :method "post"
		  "User Name:" (<:br)
		  (<:input :type "text" :name "username")(<:br)
		  "Password:" (<:br)
		  (<:input :type "password" :name "password")(<:br)
		  (<:input :type "submit" :value "Register")))

(defun test-frame ()
  "Test some var"
  (let ((auth-info (get-auth-cookie)))
	(if auth-info
	  (<:div (second auth-info))
	  (<:div "None Cookie"))))


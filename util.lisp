;;;;;;;;;; util.lisp
;;;
(in-package #:synwork-auth)

(defvar *authenticate-user-function* nil)
(defvar *register-user-function* nil)
(defvar *redirect-route* nil)

(defclass guest-info ()
  ((guest-name
	 :initarg :guest-name
	 :initform "guest")
   (guest-channel
	 :initarg :guest-channel
	 :initform "cool_channel")))

(defun logged-on-p ()
  (hunchentoot:session-value :username))

(defun logged-info (username)
  (if (logged-on-p)
	(find-user username)))	  

(defun log-in (username password-hash &optional (redirect-route *redirect-route*))
  (hunchentoot:start-session)
  (setf (hunchentoot:session-value :username) username)
  (set-auth-cookie username password-hash)
  (redirect redirect-route))

(defun log-out (&optional (redirect-route *redirect-route*))
  "Clear cookie with auth information"
  (setf (hunchentoot:session-value :username) nil)
  (hunchentoot:set-cookie *cookie-auth-name*)
  (redirect redirect-route))

(defun init-datastore-auth (&key
							(datastore 'synwork-auth.redis-datastore:redis-datastore)
							(datastore-init nil))
  (setf *datastore* (apply #'make-instance datastore datastore-init))
  (init))



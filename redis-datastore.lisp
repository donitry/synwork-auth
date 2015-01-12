;;;;;;;;;;;; redis-datastore.lisp
;;;
(in-package #:synwork-auth.redis-datastore)

(defclass redis-datastore ()
  ((host :initarg :host :initform #(127 0 0 1) :accessor host)
   (port :initarg :port :initform 6379 :accessor port)))

(defmethod datastore-init ((datastore redis-datastore)))

(defun hash-password (password)
  (multiple-value-bind (hash salt)
	(ironclad:pbkdf2-hash-password (babel:string-to-octets password))
	(list :password-hash (ironclad:byte-array-to-hex-string hash)
		  :salt (ironclad:byte-array-to-hex-string salt))))

(defun check-password (password password-hash salt)
  (let ((hash (ironclad:pbkdf2-hash-password
				(babel:string-to-octets password)
				:salt (ironclad:hex-string-to-byte-array salt))))
	(string= (ironclad:byte-array-to-hex-string hash)
			 password-hash)))

(defun serialize-list (list)
  (with-output-to-string (out)
	(print list out)))

(defun deserialize-list (string)
  (let ((read-eval nil))
	(read-from-string string)))

(defun make-key (prefix suffix)
  (format nil "~a:~a" (symbol-name prefix) suffix))

(defmethod datastore-find-user ((datastore redis-datastore) username)
  (with-connection (:host (host datastore)
					:port (port datastore))
	(let ((user-id (red-get (make-key :username username))))
	  (when user-id
		(deserialize-list (red-get (make-key :user user-id)))))))

(defmethod datastore-auth-user ((datastore redis-datastore) username password)
  (let ((user (datastore-find-user datastore username)))
	(when (and user
			   (check-password password
							   (getf user :password)
							   (getf user :salt)))
	  (list :username username :password-hash (getf user :password)))))

(defmethod datastore-verify-user ((datastore redis-datastore) username password-hash)
  (let ((user (datastore-find-user datastore username)))
	(when (and user
			   (string= (getf user :password) password-hash))
	  (list :username username :channel (getf user :channel)))))


(defmethod datastore-register-user ((datastore redis-datastore) username password)
  (with-connection (:host (host datastore)
					:port (port datastore))
	(unless (datastore-find-user datastore username)
	  (let* ((password-salt (hash-password password))
			 (id (red-incr :user-ids))
			 (record (list :id id
						   :username username
						   :password (getf password-salt :password-hash)
						   :salt (getf password-salt :salt)
						   :channel "100001")))
		(red-set (make-key :user id) (serialize-list record))
		(red-set (make-key :username username) id)
		(list :username username :password-hash (getf password-salt :password-hash))))))



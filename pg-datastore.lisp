;;;;;;;;; pg-datastore.lisp
;;;
(in-package #:synwork-auth.pg-datastore)

(defclass pg-datastore ()
  ((connection-spec :initarg :connection-spec
					:accessor connection-spec)))

(defparameter *db-auth*
  (make-instance 'pg-datastore
				 :connection-spec '("synwork" "sexdon" "zxc123.com" "localhost")))

(defclass db-users ()
  ((id :col-type serial :reader user-id)
   (name :col-type string :reader user-name :initarg :name)
   (password :col-type string :reader user-password :initarg :password)
   (salt :col-type string :reader user-salt :initarg :salt))
  (:metaclass dao-class)
  (:keys id))

(defmethod datastore-init ((datastore pg-datastore))
  (with-connection (connection-spec datastore)
	(unless (table-exists-p 'db-users)
	  (execute (dao-table-definition 'db-users)))))

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

(defmethod datastore-find-user ((datastore pg-datastore) username)
  (with-connection (connection-spec datastore)
	(query (:select :* :from 'db-users
					:where (:= 'name username))
		   :plist)))

(defmethod datastore-auth-user ((datastore pg-datastore) username password)
  (let ((user (datastore-find-user datastore username)))
	(when (and user
			   (check-password password (getf user :password)
							   			(getf user :salt)))
	  (list :username username :password-hash (getf user :password)))))

(defmethod datastore-register-user ((datastore pg-datastore) username password)
  (with-connection (connection-spec datastore)
	(unless (datastore-find-user datastore username)
	  (let ((password-salt (hash-password password)))
		(when
		  (save-dao
			(make-instance 'db-users
						   :name username
						   :password (getf password-salt :password-hash)
						   :salt (getf password-salt :salt)))
		  (list :username username :password-hash (getf password-salt :password-hash)))))))

(defmethod datastore-verify-user ((datastore pg-datastore) username password-hash)
  (let ((user (datastore-find-user datastore username)))
	(when (and user
			   (string= (getf user :password) password-hash))
	  (list :username username :channel "10001"))))



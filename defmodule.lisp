;;;; defmodule.lisp

(restas:define-policy datastore
  (:interface-package #:synwork-auth.policy.datastore)
  (:interface-method-template "DATASTORE-~A")
  (:internal-package #:synwork-auth.datastore)

  (define-method init ()
	"initiate the datastore")

  (define-method find-user (username)
	"Find the user by username")

  (define-method auth-user (username password)
	"Check if a user exists and has the suplied password")
  
  (define-method verify-user (username password-hash)
    "Verify user and return channel id")

  (define-method register-user (username password)
	"Register a new user"))

(restas:define-module #:synwork-auth
  (:use #:cl #:restas #:synwork-auth.datastore)
  (:export #:*authenticate-user-function*
		   #:*register-user-function*
		   #:*redirect-route*
		   #:logged-on-p
		   #:logged-info
  		   #:init-datastore-auth))

(defpackage #:synwork-auth.redis-datastore
  (:use #:cl #:redis #:synwork-auth.policy.datastore)
  (:export #:redis-datastore))

(defpackage #:synwork-auth.pg-datastore
  (:use #:cl #:postmodern #:synwork-auth.policy.datastore)
  (:export #:pg-datastore))

(in-package #:synwork-auth)

(defparameter *cookie-auth-name* "userauth")

(defparameter *cookie-cipher-key* (ironclad:ascii-string-to-byte-array "Specify the secure key"))

(defvar *user-auth-cipher*)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; initialization
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defmethod restas:initialize-module-instance ((module (eql #.*package*)) context)
	(restas:context-add-variable 
	  context
      '*user-auth-cipher*
      (ironclad:make-cipher :blowfish 
                            :mode :ecb
                            :key (restas:context-symbol-value context
															  '*cookie-cipher-key*))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;; md5
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun calc-md5-sum (val)
  "Calc sha1 sum of the val (string)"
  (ironclad:byte-array-to-hex-string
    (ironclad:digest-sequence :md5
      (babel:string-to-octets val :encoding :utf-8))))
 	
(defun calc-sha1-sum (val)
  "Calc sha1 sum of the val (string)"
  (ironclad:byte-array-to-hex-string
    (ironclad:digest-sequence :sha1
      (babel:string-to-octets val :encoding :utf-8))))

(defparameter *template-directory*
  (merge-pathnames #P"templates/" synwork-auth-config:*base-directory*))

(defparameter *static-directory*
  (merge-pathnames #P"static/" synwork-auth-config:*base-directory*))

(sexml:with-compiletime-active-layers
  	(sexml:standard-sexml sexml:xml-doctype)
  (sexml:support-dtd
	(merge-pathnames "html5.dtd" (asdf:system-source-directory "sexml"))
	:<))

(mount-module -static- (#:restas.directory-publisher)
	(:url "static")
	(restas.directory-publisher:*directory* *static-directory*))


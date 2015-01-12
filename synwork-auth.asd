(defpackage #:synwork-auth-config (:export #:*base-directory*))
(defparameter synwork-auth-config:*base-directory* 
  (make-pathname :name nil :type nil :defaults *load-truename*))

(asdf:defsystem #:synwork-auth
  :serial t
  :description "Your description here"
  :author "Your name here"
  :license "Your license here"
  :depends-on (:RESTAS :SEXML :IRONCLAD :BABEL
  			   :CL-REDIS :POSTMODERN
  			   :restas-directory-publisher :cl-json)
  :components ((:file "defmodule")
  			   (:file "pg-datastore")
  			   (:file "redis-datastore")
			   (:file "cookie")
			   (:file "util")
			   (:file "template")
               (:file "synwork-auth")))

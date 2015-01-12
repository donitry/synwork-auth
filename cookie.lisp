;;;;;  cookie.lisp
;;;
(in-package #:synwork-auth)

;;;; set-auth-cookie
;;;

(defun pack-auth-cookie (name password &key (version 1) date)
  (format nil "~A|~A|~A|~A" version name password
		  (or date
			  (get-universal-time))))

(defun encrypt-auth-cookie (name password &key (version 1) date)
  (let ((result (ironclad:ascii-string-to-byte-array 
				  (pack-auth-cookie name password :version version
												  :date date))))
	(ironclad:encrypt-in-place *user-auth-cipher* result)
	(ironclad:byte-array-to-hex-string result)))

(defun set-auth-cookie (name password &key (version 1))
  (hunchentoot:set-cookie *cookie-auth-name*
						  :value (encrypt-auth-cookie name password 
								   :version version)
						  :path "/"
						  :expires (+ (get-universal-time) (* 60 60 24 4))
						  :http-only nil))

;;;;; get-auth-cookie
;;;
(defun unpack-auth-cookie (str)
  (split-sequence:split-sequence #\| str))

(defun hex-string-to-byte-array (string &key (start 0) (end nil))
  (declare (type string string))
  (let* ((end (or end (length string)))
		 (length (/ (- end start) 2))
		 (key (make-array length :element-type '(unsigned-byte 8))))
	(declare (type (simple-array (unsigned-byte 8) (*)) key))
	(flet ((char-to-digit (char)
			 (let ((x (position char "0123456789abcdef" :test #'char-equal)))
			   (or x (error "Invalid hex key ~A specified" string)))))
	  (loop for i from 0
			for j from start below end by 2
			do (setf (aref key i)
					 (+ (* (char-to-digit (char string j)) 16)
						(char-to-digit (char string (1+ j)))))
		finally (return key)))))

(defun decrypt-auth-cookie (str)
  (ignore-errors
	(let ((result (hex-string-to-byte-array str)))
	  (ironclad:decrypt-in-place *user-auth-cipher*
								 result)
	  (unpack-auth-cookie (babel:octets-to-string result :encoding :utf-8)))))

(defun get-auth-cookie ()
  (let ((cookie (hunchentoot:cookie-in *cookie-auth-name*)))
	(if cookie
	  (decrypt-auth-cookie cookie))))


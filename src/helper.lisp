(in-package :cl-user)
(defpackage jonathan.helper
  (:use :cl
   :jonathan.encode)
  (:export :write-key
           :write-value
           :write-key-value
           :with-object
           :with-array
           :write-item
           :with-output
           :with-output-to-string*))
(in-package :jonathan.helper)

(defun with-macro-p (list)
  (and (consp list)
       (member (car list) '(with-object with-array))))

(defmacro write-key (key)
  (declare (ignore key)))

(defmacro write-value (value)
  (declare (ignore value)))

(defmacro write-key-value (key value)
  (declare (ignore key value)))

(defmacro with-object (&body body)
  (let ((first (gensym "first")))
    `(let ((,first t))
       (macrolet ((write-key (key)
                    `(progn
                       (if ,',first
                           (setq ,',first nil)
                           (%write-char #\,))
                       (%to-json (princ-to-string ,key))))
                  (write-value (value)
                    `(progn
                       (%write-char #\:)
                       ,(if (with-macro-p value)
                            value
                            `(%to-json ,value))))
                  (write-key-value (key value)
                    `(progn
                       (write-key ,key)
                       (write-value ,value))))
         (%write-char #\{)
         ,@body
         (%write-char #\})))))

(defmacro write-item (item)
  (declare (ignore item)))

(defmacro with-array (&body body)
  (let ((first (gensym "first")))
    `(let ((,first t))
       (macrolet ((write-item (item)
                    `(progn
                       (if ,',first
                           (setq ,',first nil)
                           (%write-char #\,))
                       ,(if (with-macro-p item)
                            item
                            `(%to-json ,item)))))
         (%write-char #\[)
         ,@body
         (%write-char #\])))))

(defmacro with-output ((stream) &body body)
  `(let ((*stream* ,stream))
     ,@body))

(defmacro with-output-to-string* (&body body)
  `(with-output-to-string (stream)
     (with-output (stream)
       ,@body)))

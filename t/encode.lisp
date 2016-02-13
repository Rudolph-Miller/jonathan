(in-package :cl-user)
(defpackage jonathan-test.encode
  (:use :cl
        :prove
        :jonathan))
(in-package :jonathan-test.encode)

(diag "jonathan-test.encode")

(plan 31)

(subtest "with-object"
  (is-print
   (with-object
     (write-key "key1")
     (write-value "value1")
     (write-key-value "key2" "value2"))
   "{\"key1\":\"value1\",\"key2\":\"value2\"}"
   "can handle write-key, write-value and write-key-value.")

  (is-print
   (with-object
     (write-key "key1")
     (write-value
      (with-object
        (write-key "key2")
        (write-value "value"))))
   "{\"key1\":{\"key2\":\"value\"}}"
   "can handle nested macro."))

(subtest "with-array"
  (is-print
   (with-array
     (write-item 1)
     (write-item 2))
   "[1,2]"
   "can handle write-item.")

  (is-print
   (with-array
     (write-item 1)
     (write-item
      (with-array
        (write-item 2)
        (write-item 3))))
     "[1,[2,3]]"
     "can handle nested macro."))

(subtest "with-output"
  (is (with-output-to-string (stream)
        (with-output (stream)
          (with-object
            (write-key-value "key" "value"))))
      "{\"key\":\"value\"}"
      "can write into stream."))

(is (to-json t)
    "true"
    "with T.")

(is (to-json nil)
    "[]"
    "with NIL.")

(is (to-json :false)
    "false"
    "with :false.")

(is (to-json 'rudolph)
    "\"RUDOLPH\""
    "with symbol.")

(is (to-json "Rudolph")
    "\"Rudolph\""
    "with string.")

(is (to-json (format nil "Rudo~alph" #\Newline))
    "\"Rudo\\nlph\""
    "with #\Newline.")

(is (to-json (format nil "Rudo~alph" #\Return))
    "\"Rudo\\rlph\""
    "with #\Return.")

(is (to-json (format nil "Rudo~alph" #\Tab))
    "\"Rudo\\tlph\""
    "with #\Tab.")

(is (to-json (format nil "Rudo~alph" #\"))
    "\"Rudo\\\"lph\""
    "with #\".")

(is (to-json (format nil "Rudo~alph" #\\))
    "\"Rudo\\\\lph\""
    "with #\\.")

(is (to-json "Rüdólph")
    "\"Rüdólph\""
    "with non-ASCII character")

(is (to-json (format nil "Rud~alph" (code-char 0)))
    "\"Rud\\u0000lph\""
    "With Nul character")

(is (to-json (format nil "Rud~alph" (code-char #x91)))
    "\"Rud\\u0091lph\""
    "With control character from C1")

(is (to-json "Rüdólph" :octets t)
    #(34 82 195 188 100 195 179 108 112 104 34)
    "with non-ASCII characters to bytes"
    :test 'equalp)

#-:abcl                                 ; abcl reader has problems with utf-8 non-BMP
(is (to-json "😃" :octets t)
    #(34 240 159 152 131 34)
    "with non-BMP character to bytes"
    :test #'equalp)

#+:abcl
(is (to-json (format nil "~a~a" (code-char #xd83d) (code-char #xde03)) :octets t)
    #(34 240 159 152 131 34)
    "with non-BMP character to bytes"
    :test #'equalp)

(is (to-json '("Rudolph" "Miller"))
    "[\"Rudolph\",\"Miller\"]"
    "with list.")

(is (to-json #("Rudolph" "Miller"))
    "[\"Rudolph\",\"Miller\"]"
    "with vector.")

(let ((hash (make-hash-table)))
  (setf (gethash :|Rudolph| hash) "Miller")
  (is (to-json hash)
      "{\"Rudolph\":\"Miller\"}"
      "with hash-talbe."))

(is (to-json 1)
    "1"
    "with integer.")

(is (to-json -1)
    "-1"
    "with negative.")

(is (to-json (/ 1 10))
    "0.1"
    "with rational.")

(is (to-json 1.1d0)
    "1.10"
    "with float.")

(is (to-json '(:|Rudolph| "Miller"))
    "{\"Rudolph\":\"Miller\"}"
    "with plist.")

(is (to-json '(:|Rudolph| "Miller") :octets t)
    #(123 34 82 117 100 111 108 112 104 34 58 34 77 105 108 108 101 114 34 125)
    :test #'equalp
    ":octet T.")

(is (to-json '((:|Rudolph| . "Miller")) :from :alist)
    "{\"Rudolph\":\"Miller\"}"
    ":from :alist.")

(is (to-json '(:obj (:|Rudolph| . "Miller")) :from :jsown)
    "{\"Rudolph\":\"Miller\"}"
    ":from :jsown.")

(defclass user ()
  ((id :type integer :initarg :id)
   (name :type string :initarg :name)))

(defmethod %to-json ((user user))
  (with-object
    (write-key "id")
    (write-value (slot-value user 'id))
    (write-key-value "name" (slot-value user 'name))))

(is (to-json (make-instance 'user :id 1 :name "Rudolph"))
    "{\"id\":1,\"name\":\"Rudolph\"}"
    "customizable.")

(subtest "%write-utf8-char"
  (macrolet ((test-char (char message)
               `(is (let* ((jonathan.encode:*stream* (fast-io:make-output-buffer))
                           (*octets* t))
                      (%write-utf8-char ,char)
                      (fast-io:finish-output-buffer jonathan.encode:*stream*))
                    (babel:string-to-octets (string ,char))
                    ,message
                    :test #'equalp)))
    (test-char (code-char #x0) "Single byte")
    (test-char (code-char #x80) "Two bytes")
    (test-char (code-char #x800) "Three bytes")
    (test-char (code-char #x10000) "Four bytes")
    (test-char (code-char #x7f) "Largest single byte")
    (test-char (code-char #x7ff) "Largest two byte")
    (test-char (code-char #xffff) "Largest three byte")
    (test-char (code-char #x10ffff) "Highest unicode character")))

(finalize)

#!/usr/bin/sbcl --script

(defparameter base-count 8)

(defun start-walk-keyboard(keyboards cnt)
  "Foreach key(letter) in keyboards."
  (maphash #'(lambda (k v) (starting-point keyboards cnt k)) keyboards))

(defun get-directions()
  '(:n :ne :e :se :s :sw :w :nw))

(defun get-chars-around(keyboards central-char)
  "Get the characters around another character on the keyboard"
  (let ((char-list (list))
	(dir-pairs))
    (dolist (dir (get-directions))
      (setf dir-pairs (get-char-line keyboards 2 central-char dir))
      (if (>= (list-length dir-pairs) 2)
	(pushnew (nth 1 dir-pairs) char-list)))
  char-list))

(defun fold(keyboards cnt first-char)
  "Half the chars to a point, then another half going possibly another direction"
  (let ((half-cnt (/ cnt 2))
	(first-list (list))
	(second-list (list))
	(last-char))
    (dolist (dir1 (get-directions))
      (setf first-list (get-char-line keyboards half-cnt first-char dir1))
      (if (>= (list-length first-list) half-cnt)
	(progn
	  (setf last-char (nth 0 (last first-list)))
	  (dolist (second-first-char (get-chars-around keyboards last-char))
             (dolist (dir2 (get-directions))
	       (setf second-list (get-char-line keyboards half-cnt second-first-char dir2))
	       (if (>= (list-length second-list) half-cnt)
		 (format t "~D ~D~%" first-list second-list)))))))))

(defun pattern(keyboard cnt first-char)
  "X characters. Then a direction from the first, Then X more characters going the same direction, and so on"
  )

(defun starting-point(keyboards cnt first-char)
  "Foreach possile direction. Does it have base-count keys?"
  (fold keyboards cnt first-char)
  ;(pattern keyboards cnt first-char)
  )

(defun get-char-line(keyboards cnt current dir &optional (char-list (list current) char-list-supplied-p))
  "if there is a char to the dir under cnt, get it"
  (if char-list-supplied-p
    (push current (cdr (last char-list))))
  (if (and (getf (gethash current keyboards) dir) (> cnt 1))
    (setf char-list (get-char-line keyboards (- cnt 1) (getf (gethash current keyboards) dir) dir char-list)))
  char-list)

(defun get-next-key(keyboard-matrix row col delta)
  "Get the next key in the matrix with the current row and col and the delta list(row col)"
  (let ((row-next-key (+ row (nth 0 delta)))
        (col-next-key (+ col (nth 1 delta))))
    (if (and (>= row-next-key 0)
             (>= col-next-key 0)
             (nth row-next-key keyboard-matrix)
             (nth col-next-key (nth row-next-key keyboard-matrix)))
      (nth col-next-key (nth row-next-key keyboard-matrix)))))

(defun make-keyboard(keyboard-matrix dir-delta)
  "Convert a keyboard matrix and an direction to offset plist to a hash of directions to characters."
  (let ((row 0) (col 0) (next-key NIL) (keyboard (make-hash-table :test 'equal)))
    (dolist (keyrow keyboard-matrix)
      (dolist (key keyrow)
        (dolist (dir '(:n :ne :e :se :sw :w :nw)) ; foreach direction
          (if (and (getf dir-delta dir) ; if we have an offset for that direction
		   key) ; sticking NIL check here for now
            (progn
              (setf next-key (get-next-key keyboard-matrix row col (getf dir-delta dir)))
              (if next-key
                (setf (getf (gethash key keyboard) dir) next-key)))))
	 (setq col (+ col 1)))
      (setf col 0)
      (setf row (+ row 1)))
    keyboard))

(defun make-keyboards()
  "A hash of chars to keyboard directions to keys. TODO: figure out number pad and its double keys."
  (let ((lc-matrix '(("`" 1 2 3 4 5 6 7 8 9 0 "-" "=")
                     (NIL "q" "w" "e" "r" "t" "y" "u" "i" "o" "p" "[" "]" "\\")
                     (NIL "a" "s" "d" "f" "g" "h" "j" "k" "l" ";" "'")
                     (NIL "z" "x" "c" "v" "b" "n" "m" "," "." "/")))
	(uc-matrix '(("~" "!" "@" "#" "$" "%" "^" "&" "*" "(" ")" "_" "+")
		     (NIL "Q" "W" "E" "R" "T" "Y" "U" "I" "O" "P" "{" "}" "|")
		     (NIL "A" "S" "D" "F" "G" "H" "J" "K" "L" ":")
		     (NIL "Z" "X" "C" "V" "B" "N" "M" "<" ">" "?")))
	(micro-matrix '((1 2 3 4) ; For testing
			("q" "w" "e" "r")
			("a" "s" "d" "f")))
	(main-dir-delta '(:ne (-1 1) :e (0 1) :se (1 0) :sw (1 -1) :w (0 -1) :nw (-1 0)))
	(num-matrix '((NIL "/(1)" "*(1)" "-(1)")
		      ("7(1)" "8(1)" "9(1)" "+(1)" ) ; TODO: big plus key...
		      ("4(1)" "5(1)" "6(1)" "+(2)" )
		      ("1(1)" "2(1)" "3(1)" )
		      ("0(1)" "0(2)" ".(1)" ))) ; TODO: big zero key...
        (num-dir-delta '(:n (-1 0) :ne (-1 1) :e (0 1) :se (1 1) :s (1 0) :sw (1 -1) :w (0 -1) :nw (-1 -1)))
        (keyboards (make-hash-table :test 'equal)))
     (maphash #'(lambda (k v) (setf (gethash k keyboards) v)) (make-keyboard lc-matrix main-dir-delta))
     (maphash #'(lambda (k v) (setf (gethash k keyboards) v)) (make-keyboard uc-matrix main-dir-delta))
     (maphash #'(lambda (k v) (setf (gethash k keyboards) v)) (make-keyboard num-matrix num-dir-delta))
     ;(maphash #'(lambda (k v) (setf (gethash k keyboards) v)) (make-keyboard micro-matrix main-dir-delta))
     keyboards))

(start-walk-keyboard (make-keyboards) base-count)

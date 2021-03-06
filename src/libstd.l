(ir::defmacro ir::rest-args (rest start)
  (ir::return `(ir::block (ir::var ,rest '())
		 (ir::for (ir::var i ,start) (ir::< i (.-length arguments)) (ir::set i (ir::+ i 1))
			  (ir::block (.push ,rest (ir::nth arguments i)))))))

(ir::defmacro defmacro (name args)
  (ir::rest-args body 2)
  (ir::var bodypos (.indexOf args ':rest))
  (ir::if (ir::<= 0 bodypos)
	  (ir::block
	      (ir::return `(defmacro ,name ,(.slice args 0 bodypos)
			     (ir::rest-args ,(ir::nth args (ir::+ bodypos 1)) ,bodypos)
			     ,@body))))
  (ir::return `(ir::defmacro ,name ,args (ir::named-block ,name ,@body))))

(defmacro return	(:rest args) (ir::return `(ir::return ,@args)))
(defmacro def		(:rest args) (return `(ir::var ,@args)))
(defmacro block		(:rest args) (return `(ir::named-block ,@args)))
(defmacro return-from	(:rest args) (return `(ir::return-from ,@args)))
(defmacro typeof	(:rest args) (return `(ir::typeof ,@args)))
(defmacro yield		(:rest args) (return `(ir::yield ,@args)))
(defmacro throw		(:rest args) (return `(ir::throw ,@args)))
(defmacro break		(:rest args) (return `(ir::break ,@args)))
(defmacro continue	(:rest args) (return `(ir::continue ,@args)))
(defmacro member	(:rest args) (return `(ir::in ,@args)))
(defmacro eql		(:rest args) (return `(ir::=== ,@args)))
(defmacro eq		(:rest args) (return `(ir::== ,@args)))
(defmacro not		(:rest args) (return `(ir::! ,@args)))
(defmacro and		(:rest args) (return `(ir::&& ,@args)))
(defmacro or		(:rest args) (return `(ir::|| ,@args)))
(defmacro +		(:rest args) (return `(ir::+ ,@args)))
(defmacro ++		(:rest args) (return `(ir::++ ,@args)))
(defmacro -		(:rest args) (return `(ir::- ,@args)))
(defmacro --		(:rest args) (return `(ir::-- ,@args)))
(defmacro *		(:rest args) (return `(ir::* ,@args)))
(defmacro /		(:rest args) (return `(ir::/ ,@args)))
(defmacro mod		(:rest args) (return `(ir::% ,@args)))
(defmacro >		(:rest args) (return `(ir::> ,@args)))
(defmacro <		(:rest args) (return `(ir::< ,@args)))
(defmacro >=		(:rest args) (return `(ir::>= ,@args)))
(defmacro <=		(:rest args) (return `(ir::<= ,@args)))
(defmacro new		(:rest args) (return `(ir::new ,@args)))
(defmacro nth		(:rest args) (return `(ir::nth ,@args)))
(defmacro set		(:rest args) (return `(ir::set ,@args)))
(defmacro hash		(:rest args) (return `(ir::hash ,@args)))
(defmacro list		(:rest args) (return `(ir::array ,@args)))
(defmacro quote		(:rest args) (return `(ir::quote ,@args)))
(defmacro instanceof	(:rest args) (return `(ir::instanceof ,@args)))

(defmacro if (condition :rest statements)
  (return
    `(ir::if ,condition
	     ,@(.map statements
		     (ir::function (s) (ir::block (return `(ir::block ,s))))))))

(defmacro when (condition :rest statements)
  (return `(ir::if ,condition (ir::block ,@statements))))

(defmacro unless (condition :rest statements)
  (return `(ir::if (not ,condition) (ir::block ,@statements))))

(defmacro lambda (args :rest body)
  (def restpos (.indexOf args ':rest))
  (when (<= 0 restpos)
    (def rest (nth args (+ restpos 1)))
    (set args (.concat (.slice args 0 restpos) (.slice args (+ restpos 2))))
    (return `(lambda ,args
	       (ir::rest-args ,rest (.-length args))
	       ,@body)))
  (def namedpos (.indexOf args ':named))
  (when (<= 0 namedpos)
    (def tag (nth args (+ namedpos 1)))
    (set args (.concat (.slice args 0 namedpos) (.slice args (+ namedpos 2))))
    (return `(lambda ,args (block ,tag ,@body))))
  (return `(ir::function ,args (ir::block ,@body))))

(defmacro defun (name args :rest body)
  (return `(def ,name (lambda (,@args :named ,name) ,@body))))

(defmacro for (condition :rest body)
  (return
    `(ir::for
      (def ,@(nth condition 0))
      ,@(.slice condition 1)
      (ir::block ,@body))))

(defmacro while (condition :rest body)
  (return
    `(ir::while ,condition (ir::block ,@body))))

(defmacro let (defs :rest body)
  (def vars (.map defs (lambda (d) (return (nth d 0)))))
  (def vals (.map defs (lambda (d) (return (nth d 1)))))
  (return `((lambda ,vars ,@body) ,@vals)))

(defmacro cond (:rest statements)
  (if (<= 2 (.-length statements))
      (return
	`(if ,(nth (nth statements 0) 0)
	     (ir::block ,@(.slice (nth statements 0) 1))
	     (cond ,@(.slice statements 1))))
      (return
	`(if ,(nth (nth statements 0) 0)
	     (ir::block ,@(.slice (nth statements 0) 1))))))

(defmacro case (variable :rest statements)
  (let ((f (lambda (s)
	     (if (eql (nth s 0) 'otherwise)
		 (return `(true ,@(.slice s 1)))
		 (return
		   `((or ,@(.map (nth s 0)
				 (lambda (v)
				   (return `(eql ,v ,variable)))))
		     ,@(.slice s 1)))))))
    (return-from case `(cond ,@(.map statements f)))))

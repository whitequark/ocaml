(* my own tests *)

open StdLabels;;

type 'a t = { t : 'a }
;;
class ['b] ilist l = object
  val l = l
  method add x = {< l = x :: l >}
  method fold : 'a. f:('a -> 'b -> 'a) -> init:'a -> 'a =
    List.fold_left l
end
;;
class virtual ['a] vlist = object (_ : 'self)
  method virtual add : 'a -> 'self
  method virtual fold : 'b. f:('b -> 'a -> 'b) -> init:'b -> 'b
end
;;
class ilist2 l = object
  inherit [int] vlist
  val l = l
  method add x = {< l = x :: l >}
  method fold = List.fold_left l
end
;;
class ['a] ilist3 l = object
  inherit ['a] vlist
  val l = l
  method add x = {< l = x :: l >}
  method fold = List.fold_left l
end
;;
class ['a] ilist4 (l : 'a list) = object
  val l = l
  method virtual add : _
  method add x = {< l = x :: l >}
  method virtual fold : 'b. f:('b -> 'a -> 'b) -> init:'b -> 'b
  method fold = List.fold_left l
end
;;
class ['a] ilist5 (l : 'a list) = object (self)
  val l = l
  method add x = {< l = x :: l >}
  method virtual fold : 'b. f:('b -> 'a -> 'b) -> init:'b -> 'b
  method virtual fold2 : 'b. f:('b -> 'a -> 'b) -> init:'b -> 'b
  method fold2 ~f ~init = self#fold ~f ~init:(self#fold ~f ~init)
  method fold = List.fold_left l
end
;;
class ['a] ilist6 l = object (self)
  inherit ['a] vlist
  val l = l
  method add x = {< l = x :: l >}
  method virtual fold2 : 'b. f:('b -> 'a -> 'b) -> init:'b -> 'b
  method fold2 ~f ~init = self#fold ~f ~init:(self#fold ~f ~init)
  method fold = List.fold_left l
end
;;
class virtual ['a] olist = object
  method virtual fold : 'c. f:('a -> 'c -> 'c) -> init:'c -> 'c
end
;;
class ['a] onil = object
  inherit ['a] olist
  method fold ~f ~init = init
end
;;
class ['a] ocons ~hd ~tl = object (_ : 'b)
  inherit ['a] olist
  val hd : 'a = hd
  val tl : 'a olist = tl
  method fold ~f ~init = f hd (tl#fold ~f ~init)
end
;;
class ['a] ostream ~hd ~tl = object (_ : 'b)
  inherit ['a] olist
  val hd : 'a = hd
  val tl : _ #olist = (tl : 'a ostream)
  method fold ~f ~init = f hd (tl#fold ~f ~init)
  method empty = false
end
;;
class ['a] ostream1 ~hd ~tl = object (self : 'b)
  inherit ['a] olist
  val hd = hd
  val tl : 'b = tl
  method hd = hd
  method tl = tl
  method fold ~f ~init =
    self#tl#fold ~f ~init:(f self#hd init)
end
;;

class vari = object
  method virtual m : 'a. ([< `a|`b|`c] as 'a) -> int
  method m = function `a -> 1 | _ -> 0
end
;;
module V =
  struct
    type v = [`a | `b | `c]
    let m : [< v] -> int = function `a -> 1 | _ -> 0
  end
;;
class varj = object
  method virtual m : 'a. ([< V.v] as 'a) -> int
  method m = V.m
end
;;
class point ~x ~y = object
  val x : int = x
  val y : int = y
  method x = x
  method y = y
end
;;
class color_point ~x ~y ~color = object
  inherit point ~x ~y
  val color : string = color
  method color = color
end
;;
class circle (p : #point) ~r = object
  val p = (p :> point)
  val r = r
  method virtual distance : 'a. (#point as 'a) -> float
  method distance p' =
    let dx = p#x - p'#x and dy = p#y - p'#y in
    let d = sqrt (float (dx * dx + dy * dy)) -. float r in
    if d < 0. then 0. else d
end
;;
let p0 = new point ~x:3 ~y:5
let p1 = new point ~x:10 ~y:13
let cp = new color_point ~x:12 ~y:(-5) ~color:"green"
let c = new circle p0 ~r:2
let d = c#distance cp
;;
let f (x : < m : 'a. 'a -> 'a >) = (x : < m : 'b. 'b -> 'b >)
;;
let f (x : < m : 'a. 'a -> 'a list >) = (x : < m : 'b. 'b -> 'c >)
;;

class id = object
  method virtual id : 'a. 'a -> 'a
  method id x = x
end
;;

class type id_spec = object
  method id : 'a -> 'a
end
;;
class id_impl = object (_ : #id_spec)
  method id x = x
end
;;

class a = object
  method m = (new b : id_spec)#id true
end
and b = object (_ : #id_spec)
  method id x = x
end
;;

class ['a] id1 = object
  method virtual id : 'b. 'b -> 'a
  method id x = x
end
;;
class id2 (x : 'a) = object
  method virtual id : 'b. 'b -> 'a
  method id x = x
end
;;
class id3 x = object
  val x = x
  method virtual id : 'a. 'a -> 'a
  method id _ = x
end
;;
class id4 () = object
  val mutable r = None
  method virtual id : 'a. 'a -> 'a
  method id x =
    match r with
      None -> r <- Some x; x
    | Some y -> y
end
;;
class c = object
  method virtual m : 'a 'b. 'a -> 'b -> 'a
  method m x y = x
end
;;

let f1 (f : id) = f#id 1, f#id true
;;
let f2 f = (f : id)#id 1, (f : id)#id true
;;
let f3 f = f#id 1, f#id true
;;
let f4 f = (f : id); f#id 1, f#id true
;;

class c = object
  method virtual m : 'a. (#id as 'a) -> int * bool
  method m (f : #id) = f#id 1, f#id true
end
;;

class id2 = object (_ : 'b)
  method virtual id : 'a. 'a -> 'a
  method id x = x
  method mono (x : int) = x
end
;;
let app = new c #m (new id2)
;;
type 'a foo = 'a foo list
;;

class ['a] bar (x : 'a) = object end
;;
type 'a foo = 'a foo bar
;;

fun x -> (x : < m : 'a. 'a * 'b > as 'b)#m;;
fun x -> (x : < m : 'a. 'b * 'a list> as 'b)#m;;
let f x = (x : < m : 'a. 'b * (< n : 'a; .. > as 'a) > as 'b)#m;;

fun (x : < p : 'a. < m : 'a ; n : 'b ; .. > as 'a > as 'b) -> x#p;;

type sum = T of < id: 'a. 'a -> 'a > ;;
fun (T x) -> x#id;;

type record = { r: < id: 'a. 'a -> 'a > } ;;
fun x -> x.r#id;;
fun {r=x} -> x#id;;

class myself = object (self)
  method self : 'a. 'a -> 'b = fun _ -> self
end;;

class number = object (self : 'self)
  val num = 0
  method num = num
  method succ = {< num = num + 1 >}
  method prev =
    self#switch ~zero:(fun () -> failwith "zero") ~prev:(fun x -> x)
  method switch : 'a. zero:(unit -> 'a) -> prev:('self -> 'a) -> 'a =
    fun ~zero ~prev ->
      if num = 0 then zero () else prev {< num = num - 1 >}
end
;;

let id x = x
;;
class c = object
  method id : 'a. 'a -> 'a = id
end
;;
class c' = object
  inherit c
  method id = id
end
;;
class d = object
  inherit c as c
  val mutable count = 0
  method id x = count <- count+1; x
  method count = count
  method old : 'a. 'a -> 'a = c#id
end
;;
class ['a] olist l = object
  val l = l
  method fold : 'b. f:('a -> 'b -> 'b) -> init:'b -> 'b
      = List.fold_right l
  method cons a = {< l = a :: l >}
end
;;
let sum (l : 'a #olist) = l#fold ~f:(fun x acc -> x+acc) ~init:0
;;
let count (l : 'a #olist) = l#fold ~f:(fun _ acc -> acc+1) ~init:0
;;
let append (l : 'a #olist) (l' : 'b #olist) =
  l#fold ~init:l' ~f:(fun x acc -> acc#cons x)
;;


# Data Handling (Containers/Data Frames/Algorithms)

## A Person Database to play with

Assume, you have some csv file (aka "Excel sheet"), `got.csv`, and you have to do some tasks on it. Sure, you could open Excel ... if you have (or, Libreoffice Calc).

But you could also use Julia.

```julia
julia> using CSV, DataFrames

julia> df = CSV.read("got.csv", DataFrame)
15×5 DataFrame
 Row │ name      surname    age    gender   title               
     │ String15  String15   Int64  String7  String31            
─────┼──────────────────────────────────────────────────────────
   1 │ Eddard    Stark         60  male     Lord of Winterfell
   2 │ Robert    Baratheon     55  male     King
   3 │ Jaime     Lannister     49  male     Chief of Kingsguard
   4 │ Cersei    Lannister     46  female   Queen
   5 │ Daenerys  Targaryen     32  female   Queen
   6 │ Jon       Snow          32  male     Black Guard
   7 │ Sansa     Stark         23  female   Lady
   8 │ Arya      Stark         22  female   Killer
   9 │ Bran      Stark         20  male     Three-eyed Raven
  10 │ Joffrey   Baratheon     27  male     King
  11 │ Tyrion    Lannister     50  male     Consultant
  12 │ Catelyn   Stark         56  female   Lady
  13 │ Jorah     Mormont       58  male     Knight
  14 │ Sandor    Clegane       50  male     Knight
  15 │ Samwell   Tarly         31  male     Consultant
```
Longer or wider tables are represented only in part. This gives already a good overview what the document contains.
```julia
julia> names(df)
5-element Vector{String}:
 "name"
 "surname"
 "age"
 "gender"
 "title"

julia> propertynames(df)
5-element Vector{Symbol}:
 :name
 :surname
 :age
 :gender
 :title

julia> describe(df)
5×7 DataFrame
 Row │ variable  mean     min          median  max               nmissing  eltype   
     │ Symbol    Union…   Any          Union…  Any               Int64     DataType 
─────┼──────────────────────────────────────────────────────────────────────────────
   1 │ name               Arya                 Tyrion                   0  String15
   2 │ surname            Baratheon            Tarly                    0  String15
   3 │ age       40.7333  20           46.0    60                       0  Int64
   4 │ gender             female               male                     0  String7
   5 │ title              Black Guard          Three-eyed Raven         0  String31
```
With this example data set, it's harder to grasp. But the `age` row might give an impression. One gets statistics from that (whatever this means for a list of strings).

Types of the colums can also be obtained using
```julia
julia> eltype.(eachcol(df))
5-element Vector{DataType}:
 String15
 String15
 Int64
 String7
 String31
```

`String31` means a string auto-type of DataFrames, containing up to 31 characters. Users don't need to do anything here. It's an optimization. You can consider them all a `String`.




# Data Handling (Containers/Data Frames/Algorithms)

## A Character Database to play with

```julia
julia> using CSV, DataFrames

julia> df = CSV.read("got.csv", DataFrame);

# 1. Find all characters with surname `Stark`!
julia> filter(:surname => x -> x == "Stark", df)
5×5 DataFrame
 Row │ name      surname   age    gender   title              
     │ String15  String15  Int64  String7  String31           
─────┼────────────────────────────────────────────────────────
   1 │ Eddard    Stark        60  male     Lord of Winterfell
   2 │ Sansa     Stark        23  female   Lady
   3 │ Arya      Stark        22  female   Killer
   4 │ Bran      Stark        20  male     Three-eyed Raven
   5 │ Catelyn   Stark        56  female   Lady

# 2. Find all characters younger or as old as 30 years!
julia> filter(:age => x -> x ≤ 30, df)
4×5 DataFrame
 Row │ name      surname    age    gender   title            
     │ String15  String15   Int64  String7  String31         
─────┼───────────────────────────────────────────────────────
   1 │ Sansa     Stark         23  female   Lady
   2 │ Arya      Stark         22  female   Killer
   3 │ Bran      Stark         20  male     Three-eyed Raven
   4 │ Joffrey   Baratheon     27  male     King

# 3. Find all characters with a first name that starts with letter `J` till `S`!
julia> filter(:name => x -> 'J' ≤ x[1] ≤ 'S', df)
8×5 DataFrame
 Row │ name      surname    age    gender   title               
     │ String15  String15   Int64  String7  String31            
─────┼──────────────────────────────────────────────────────────
   1 │ Robert    Baratheon     55  male     King
   2 │ Jaime     Lannister     49  male     Chief of Kingsguard
   3 │ Jon       Snow          32  male     Black Guard
   4 │ Sansa     Stark         23  female   Lady
   5 │ Joffrey   Baratheon     27  male     King
   6 │ Jorah     Mormont       58  male     Knight
   7 │ Sandor    Clegane       50  male     Knight
   8 │ Samwell   Tarly         31  male     Consultant

# 4. Sort the data by surname!
julia> sort(df,:surname)
15×5 DataFrame
 Row │ name      surname    age    gender   title               
     │ String15  String15   Int64  String7  String31            
─────┼──────────────────────────────────────────────────────────
   1 │ Robert    Baratheon     55  male     King
   2 │ Joffrey   Baratheon     27  male     King
   3 │ Sandor    Clegane       50  male     Knight
   4 │ Jaime     Lannister     49  male     Chief of Kingsguard
   5 │ Cersei    Lannister     46  female   Queen
   6 │ Tyrion    Lannister     50  male     Consultant
   7 │ Jorah     Mormont       58  male     Knight
   8 │ Jon       Snow          32  male     Black Guard
   9 │ Eddard    Stark         60  male     Lord of Winterfell
  10 │ Sansa     Stark         23  female   Lady
  11 │ Arya      Stark         22  female   Killer
  12 │ Bran      Stark         20  male     Three-eyed Raven
  13 │ Catelyn   Stark         56  female   Lady
  14 │ Daenerys  Targaryen     32  female   Queen
  15 │ Samwell   Tarly         31  male     Consultant

# 5. Sort the data by surname, where also the first names are sorted!
julia> sort(sort(df,:name),:surname)
15×5 DataFrame
 Row │ name      surname    age    gender   title               
     │ String15  String15   Int64  String7  String31            
─────┼──────────────────────────────────────────────────────────
   1 │ Joffrey   Baratheon     27  male     King
   2 │ Robert    Baratheon     55  male     King
   3 │ Sandor    Clegane       50  male     Knight
   4 │ Cersei    Lannister     46  female   Queen
   5 │ Jaime     Lannister     49  male     Chief of Kingsguard
   6 │ Tyrion    Lannister     50  male     Consultant
   7 │ Jorah     Mormont       58  male     Knight
   8 │ Jon       Snow          32  male     Black Guard
   9 │ Arya      Stark         22  female   Killer
  10 │ Bran      Stark         20  male     Three-eyed Raven
  11 │ Catelyn   Stark         56  female   Lady
  12 │ Eddard    Stark         60  male     Lord of Winterfell
  13 │ Sansa     Stark         23  female   Lady
  14 │ Daenerys  Targaryen     32  female   Queen
  15 │ Samwell   Tarly         31  male     Consultant

# also possible: df[partialsortperm(1:nrow(df), 1:nrow(df), by = i -> (df.surname[i], df.name[i])), :]


# 6. Find all characters younger than 30, sorted by surname!
julia> sort(filter(:age => x -> x ≤ 30, df), :surname)
4×5 DataFrame
 Row │ name      surname    age    gender   title            
     │ String15  String15   Int64  String7  String31         
─────┼───────────────────────────────────────────────────────
   1 │ Joffrey   Baratheon     27  male     King
   2 │ Sansa     Stark         23  female   Lady
   3 │ Arya      Stark         22  female   Killer
   4 │ Bran      Stark         20  male     Three-eyed Raven

# 7. Find the youngest character!
julia> filter(:age => x -> x == minimum(df.age),df)
1×5 DataFrame
 Row │ name      surname   age    gender   title            
     │ String15  String15  Int64  String7  String31         
─────┼──────────────────────────────────────────────────────
   1 │ Bran      Stark        20  male     Three-eyed Raven
# or, even shorter:
julia> df[argmin(df.age), :]
...     # same result

# 8. Find the 3rd-youngest character!
julia> df[partialsortperm(df.age, 3),:]                             # partialsortperm applies partial sort, and returns a range of indices
DataFrameRow
 Row │ name      surname   age    gender   title    
     │ String15  String15  Int64  String7  String31 
─────┼──────────────────────────────────────────────
   7 │ Sansa     Stark        23  female   Lady

# sort(df, :age)[3, :] would sort the complete list

# 9. Find the three youngest characters! (Without sorting the whole list!)
julia> df[partialsortperm(df.age, 1:3), :]
3×5 DataFrame
 Row │ name      surname   age    gender   title            
     │ String15  String15  Int64  String7  String31         
─────┼──────────────────────────────────────────────────────
   1 │ Bran      Stark        20  male     Three-eyed Raven
   2 │ Arya      Stark        22  female   Killer
   3 │ Sansa     Stark        23  female   Lady

# 10. Create a new column, where for each character a "status" is determined of being "dead" or "alive", depending on `age <= 50` (alive)!
julia> transform!(df, :age => ByRow(x -> x ≤ 50 ? "probably alive" : "probably dead") => :status)
15×6 DataFrame
 Row │ name      surname    age    gender   title                status         
     │ String15  String15   Int64  String7  String31             String         
─────┼──────────────────────────────────────────────────────────────────────────
   1 │ Eddard    Stark         60  male     Lord of Winterfell   probably dead
   2 │ Robert    Baratheon     55  male     King                 probably dead
   3 │ Jaime     Lannister     49  male     Chief of Kingsguard  probably alive
   4 │ Cersei    Lannister     46  female   Queen                probably alive
   5 │ Daenerys  Targaryen     32  female   Queen                probably alive
   6 │ Jon       Snow          32  male     Black Guard          probably alive
   7 │ Sansa     Stark         23  female   Lady                 probably alive
   8 │ Arya      Stark         22  female   Killer               probably alive
   9 │ Bran      Stark         20  male     Three-eyed Raven     probably alive
  10 │ Joffrey   Baratheon     27  male     King                 probably alive
  11 │ Tyrion    Lannister     50  male     Consultant           probably alive
  12 │ Catelyn   Stark         56  female   Lady                 probably dead
  13 │ Jorah     Mormont       58  male     Knight               probably dead
  14 │ Sandor    Clegane       50  male     Knight               probably alive
  15 │ Samwell   Tarly         31  male     Consultant           probably alive

# to remove the column, issue you can do:
# select!(df, Not(:status))
# you can also only remove the data:
# df.status .= nothing

```

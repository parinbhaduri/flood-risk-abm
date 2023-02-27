###To recreate syntethic data into proper file formats
using CSVFiles, DataFrames

#Create CSV for agent data




##Create CSV for Housing Properties
house_prop = DataFrame(SqFeet = zeros(30), Age = zeros(30), Stories = zeros(30), Baths = zeros(30))

for i,row in iterrows(house_prop)
    if p[1] <= 8 
        SqFeet = (500.0 + (p[2]* 120.0)) / 4100.0
        Age = 3.0 / 5.0
        Stories = 2.0 / 5.0
        Baths = 3.0 / 5.0
    elseif  p[1] > 8 && p[1] <= 16
        SqFeet = 2000.0 / 4100.0
        Age = (p[2] / 6.0) / 5.0
        Stories = 2.0/ 5.0
        Baths = 3.0/ 5.0
    elseif  p[1] > 16 && p[1] <= 23
        SqFeet = 2000.0 / 4100.0
        Age = 3.0/ 5.0
        Stories = (p[2] / 6.0) / 5.0
        Baths = 3.0/ 5.0
    else
        SqFeet = 2000.0 / 4100.0
        Age = 3.0/ 5.0
        Stories = 2.0/ 5.0
        Baths = (p[2] / 6.0) / 5.0
    end
end

#Create df from Housing Properties
Count = 0
for row in eachrow(house_prop)
    while Count < 5
        Count += 1
        row.SqFeet = 4
        println(row.SqFeet)
    end
end
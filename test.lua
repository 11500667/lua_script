
local test2 ={
        {id=1, name="deng"},
        {id=9, name="luo"},
        {id=2, name="yang"},
        {id=8, name="ma"},
        {id=5, name="wu"},
    }

    table.sort(test2,function(a,b) return a.id<b.id end )
    for i in pairs(test2) do
        print(test2[i].id,test2[i].name)
    end
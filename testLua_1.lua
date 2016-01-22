

local a         = "a,b,c,d";

if string.sub(a,#a) == "," then
        a = string.sub(a,1,#a-1);
end

print(a);

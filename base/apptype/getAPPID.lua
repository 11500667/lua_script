function getPrime(h, m)
	local val_prime ="";
  for n=h+1,m do
       local isPrime = true;
         local s = math.floor(math.sqrt(n));
         for i=s,2,-1 do
         	local n_i = n%i;
        	if n_i == 0 then
         		isPrime =false;
         	end
         end
         if isPrime==true then
         	 --  break; 
         	 val_prime = val_prime..","..n;

         end
  end
   val_prime = string.sub(val_prime,2,#val_prime);
  return val_prime;
end


function getPrimeByOne(m)
	if m < 2 then
		return 2;
	end 
local isPrime = true;
	while(isPrime)
	do
	  m = m+1;
      local s = math.floor(math.sqrt(m));
      for i=s,2,-1 do
         	local n_i = m%i;
        	if n_i == 0 then

         		isPrime = false;
         		break;
         	end
      end
    end

  return m-1;
end

function dec_prime(n)
  local vals = "";
  local tmp = {2,3,5,7,11,13,17,19,23,29,31,37,41}
  for i =1,#tmp do
    local a = tmp[i];
     if n%a == 0 then
      n=n/a;
       vals = vals..","..a;
     -- ngx.say("a="..a)
      a=1;

    end
  end

	return string.sub(vals,2,#vals)
end


function combine(a,num)
     local vals = "";
     local val = 1;
     local b = {};
     local b_length = #a+1;
     for i=0,b_length do
        if i<num then
          b[i] = "1";
        else
          b[i] = "0"; 
        end
     end
     local point = 0;
     local nextpoint = 0;
     local count = 0;
     local sum = 0;
     local temp = "1";
     while (true) do
        --判断是否全部移位完毕

        for i=b_length-1,b_length-num,-1 do

          if b[i]=="1" then
             sum = sum+1;

          end
        end
        --根据移位生成数据
      
         for i=0,b_length do
          if b[i] =="1" then
             point = i;
             val = val*a[point];
             count=count+1;
             if count == num then
                break;
             end
          end
        end
        
        --往返回值列表添加数据
  --    ngx.say("val="..val);
      vals = vals..","..val;
        --当数组的最后num位全部为1 退出

        if sum == num then
           break;
        end
        
        sum = 0;

        --修改从左往右第一个10变成01
        for i=0,b_length-1 do
           if (b[i]=="1") and (b[i+1]=="0") then
              point = i;
              nextpoint = i+1;
              b[point] = "0";
              b[nextpoint]= "1";
              break;
           end
        end
        --将 i-point个元素的1往前移动 0往后移动
        for i=0,point-1 do
            for j=i,point-1 do
              if b[i]=="0" then
                 temp = b[i];
                 b[i] = b[j+1];
                 b[j+1] = temp;
              end
            end
        end
        val = 1;
        count = 0;
     end

return  string.sub(vals,2,#vals);
end

function getCombineValues(tab_val,search_val)
      local vals="";
      for i=1,#tab_val do
          if i<=2 then
              local  list = Split(combine(tab_val,i),",");
              for j=1,#list do
                  vals = vals ..",".. search_val*list[j];
              end

          end
      end
    --  ngx.say(vals);
return string.sub(vals,2,#vals);
end


function PrimeNumberSet()
    local reverse = {} --以数据为key，数据在set中的位置为value
    local set = {};  
    --一个数组，其中的value就是要管理的数据
    return setmetatable(set,
    {__index = {
          insert = function(set,value)
              if not reverse[value] then
                    table.insert(set,value)
                    reverse[value] = table.getn(set)
              end
          end,

          remove = function(set,value)
              local index = reverse[value]
              if index then
                    reverse[value] = nil
                    local top = table.remove(set) --删除数组中最后一个元素
                    if top ~= value then
                        --若不是要删除的值，则替换它
                        reverse[top] = index
                        set[index] = top
                    end
              end
          end,

          find_value = function(set,value)
              local index = set[value]
             return index;
          end,

          find_key = function(set,value)
              local index = reverse[value]
             return index;
          end,
    }
  })
end

local s = PrimeNumberSet()


local tmp={2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97};
for i =1,#tmp do
  s:insert(tmp[i]);
end

ngx.say("最终结果="..s:find_value(5).."最终结果"..s:find_key(5))


--local  mm =  aa(105);

--ngx.say("mm"..mm)
 --[[
local s = PrimeNumberSet()



local tmp={2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97};
for i =1,#tmp do
  s:insert(tmp[i]);
end
ngx.say("最终结果="..s:find_value(5).."最终结果"..s:find_key(5))
]]
--[[
s:insert("hi0")
s:insert("hi1")

for _,Value in ipairs(s) do
    ngx.say(Value)
end

ngx.say(s:find("hi0"))
s:remove("hi0")
ngx.say(s:find("hi0"))
]]

--local mm = getPrime(1,10);

--local mm = getPrimeByOne(2)


--ngx.say("mm="..mm);
--local a = {};
--a[0] =2;
--a[1] = 5;
--a[2] = 7;
--ngx.log(ngx.ERR,"========="..#a);
--local num = 3;
--local mm = getCombineValues(a,num)

--ngx.say("mm="..mm);




--Split方法
function Split(szFullString, szSeparator)
   local nFindStartIndex = 1
   local nSplitIndex = 1
   local nSplitArray = {}
   while true do
      local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
      if not nFindLastIndex then
         nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
         break
      end
      nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
      nFindStartIndex = nFindLastIndex + string.len(szSeparator)
      nSplitIndex = nSplitIndex + 1
   end
   return nSplitArray
end



v_my_info_type = {
   { type_id = 6  , type_name = "我的上传" },
   { type_id = 7  , type_name = "我的共享" },
   { type_id = 1  , type_name = "我的收藏" },
   { type_id = 2  , type_name = "我推荐的资源" },
   { type_id = 3  , type_name = "推荐给我的资源" },
   { type_id = 4  , type_name = "我的评论" },
   { type_id = 5  , type_name = "我的反馈" },
   { type_id = 10 , type_name = "我参评的资源" },
   { type_id = 0  , type_name = "全部" }
}


table.sort(v_my_info_type,function(a,b) return a.type_id<b.type_id end);


for i,v in ipairs(v_my_info_type) do
   print(v.type_id);
end












local res = ngx.location.capture('/dsideal_yy/resource/test1')
ngx.say(res.body)

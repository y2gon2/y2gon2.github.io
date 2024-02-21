---
layout: post
read_time: true
show_date: true
title:  Shell Script 사용한 시스템 구축 01 (사용자 계정 생성)
date:   2024-02-20 14:32:20 +0900
description: 개발자를 위한 반도체 SW개발 기초 (디바이스 드라이버 개발) 관련 학습 04
img: posts/general/post_general22.jpg
tags: [linux, bash, shell scirpt]
author: Yong gon Yun
---

참고 자료 : [처음 배우는 셸 스크립트 8장 시스템 구축](https://product.kyobobook.co.kr/detail/S000001810353) 

shell script 를 사용하여 사용자 개정을 생성하는 파일을 작성 및 실행


프로세스
1. 사용자 계정과 패스워드 입력
2. 입력 정보가 없으면 에러 메세지를 보여주고, script 종료
3. 여러명의 사용자 계정을 생성할 경우 반복문을 사용하여 순회
4. 각 계정이 이미 사용자 계정에 포함되어 있는지 확인
5. 포함되어있지 않다면, 계정을 생성하고 패스워드 설정
6. 이미 존재하는 계정이라면, 이를 메세지로 보여줌.

### 1. 다수의 사용자 계정 생성

(1) `if [[ -n $1 ]] && [[ -n $2 ]]`
<br>해당 script 실행시 매개 변수로 사용자 계정(`$1`)과 패스워드(`$2`)가 모두 입력 되었는지 확인(`-n` : 비워있지 않아야 함) 한다. `$1` 과 `$2` 모두 외부 입력값이므로 이중 중괄호 `[[]]` 를 사용한다.
<br>

(2) `IFS=' ' read -r -a UserList <<< "$1"` <br>
입력된 매개변수 값을 공백을 기준으로 값을 slice 하여 배열의 형태로 shell script 변수로 저장함.<br>
* IFS (Internal Field Separator) : IFS 는 shell scirpt 에서 사용하는 내부 필드 구분자. 이 변수는 문자열을 분리하여 배열이나 개별 변수로 읽을 때 사용하는 구분자을 정의한다. 기본값은 공백, 탭, 개행 문자.
* `read` : 표준 입력이나 파일로부터 입력을 읽어드림. 이 명령어를 사용하여 변수에 값을 할당할 수 있다. 
* `-r` : `read` 옵션 중 백슬래시(`\`) 가 이스케이프 문자로 처리되지 않고, 그대로 읽어드림.
* `-a` : `read` 명령어에 의히 읽힌 값을 배열로 저장.
* `<<<` (Here String) :  "$1" 로 받은 외부 입력 값을 UserList 변수 값으로 취할 수 있도록 redirection 해줌. 
<br>

(3) `for (( i=0 ; i < ${#UserList[@]}; i++ ))` <br>
배열 `UserList` 의 길이만큼 반복할 수 있도록 설정
<br>

(4) `if [[ $(cat /etc/passwd | grep -w ${UserList[$i]} | wc -l) == 0 ]] `<br>
* `$(cat /etc/passwd` 파일의 내용을 가져와서,
* `UserList[$i]` 의 값과 정확히 (`-w`)일치하는 사용자 계정을 찾고,
* `wc` (word count) 의 라인 수(`-l`) 을 출력,
* 해당 값이 0 아니라면, 동일 계정이 존재한다는 것을 의미함.
<br>

(5) `useradd ${UserList[$i]}` <br>
기존 계정이 존재하지 않는 경우, 해당 값 `${UserList{$i}}` 의 계정을 생성함. 
<br>

(6) `echo "${UserList[$i]}:${Password[$i]}" | chpasswd` <br>
새로 생성한 계정에 대한 패스워드 값을 사용하여 패스워드를 설정
<br>

```bash
#!/bin/bash

# 사용자 계정 및 패스워드가 입력되었는지 확인
if [[ -n $1 ]] && [[ -n $2 ]] #  (1)
then

        IFS=' ' read -r -a UserList <<< "$1" #  (2)
        IFS=' ' read -r -a Password <<< "$2"

        # for 문을 이용하여 사용자 계정 생성
        for (( i=0 ; i < ${#UserList[@]}; i++ )) #  (3)
        do
                # if문을 사용하여 사용자 계정이 있는지 확인
                if [[ $(cat /etc/passwd | grep -w ${UserList[$i]} | wc -l) == 0 ]] #  (4)
                then
                        # 사용자 생성 및 패스워드 설정
                        useradd ${UserList[$i]} #  (5)
                        echo "${UserList[$i]}:${Password[$i]}" | chpasswd #  (6)
                else
                        # 사용자가 있다고 메세지를 보여줌
                        echo "this user ${UserList[$i]} is existing."
                fi
        done

else
        # 사용자가 계정과 패스워드를 입력하라는 메세지를 보여줌
        echo -e 'Please input user id and password. \nUsage: adduser-script.sh "user01 user02" "pw01 pw02"'
fi
```
해당 script 를  `adduser-script.sh` 에 저장하고 아래와 같이 실행

```bash
gon@DESKTOP:~/book/ch08$ sudo bash adduser-script.sh "user1 user2" "1111 2222"
```
여기에서 `sh` 가 아닌 `bash` 명령어를 사용한 이유는, 일부 리눅스 (ex. Ubuntu) shell 이 `bash` 가 아닌 `dash` 에서 실행되는 경우가 있다. 이런 경우, `dash` 에서 지원되지 않는 기능 (ex. redirection `<<<`)을 shell script 내 사용한 경우, 다음과 같은 에러가 발생한다. 

```bash
gon@DESKTOP:~/book/ch08$ sudo sh adduser-script.sh "user1 user2" "1111 2222"
adduser-script.sh: 7: Syntax error: redirection unexpected
```

이를 해결하는 다른 방법으로, 해당 파일의 실행 권한을 아예 변경하고, 직접 실행 시키면 된다.

```bash
gon@DESKTOP:~/book/ch08$ chmod +x adduser-script.sh
gon@DESKTOP:~/book/ch08$ ./adduser-script.sh "user1 user2" "1111 2222"
```

최종적으로, 해당 실행이 정상적으로 동작했는지를 위해 `/etc/passwd` 파일 내용을 확인하면 아래 해당 user 가 추가된 것을 확인할 수 있다. 

```bash
gon@DESKTOP:~/book/ch08$ cat /etc/passwd

...
user1:x:1001:1001::/home/user1:/bin/sh
user2:x:1002:1002::/home/user2:/bin/sh
```

### 2. ssh  를 활용하여 다른 서버에 사용자 계정 생성

```bash
#!/bin/bash

for server in "host01 host02 host03"
do
        # 여러 대의 시스템에 사용자 생성 및 패스워드 설정
        echo $server
        ssh root@$server "useradd $1"  # (1)
        ssh root@$server "echo $2:$1 | chpasswd" 
done
```

(1) `ssh root@$server "useradd $1"`
* `ssh` : SSH protocol 을 사용하여 원격 서버에 접속하가나 원격 서버에서 명령을 실행하기 위한 client 프로그램
* `root@$server` : `사용자명@호스트명` 형식으로 접속할 원격 서버의 최고 관리자 계정을 의미
* `"useradd $1"` : ssh root 계정으로 해당 host 에 접속하여 사용자 계정 추가를 실행


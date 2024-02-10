---
layout: post
read_time: true
show_date: true
title:  Shell Script 기본 문법 01
date:   2024-02-10 08:32:20 +0900
description: 개발자를 위한 반도체 SW개발 기초 (디바이스 드라이버 개발) 관련 학습 01
img: posts/general/post_general19.jpg
tags: [linux, shell scirpt]
author: Yong gon Yun
---

### 1. 간단한 함수를 사용한 script 1

```bash
#!/bin/bash

# 함수 정의: 두 인자를 받아 출력함
add_inner_numbers() {
    echo "첫 번째 숫자: $1"
    echo "두 번째 숫자: $2"
    
    local sum=0
    sum=$(( $1 + $2 ))
    echo "두 수의 합: $sum"
}

# 함수 호출: 5와 10을 인자로 전달
add_inner_numbers 5 10
```

* `#!/bin/bash` 
  - "shebang" (또는 "hashbang") 
  - 해당 script를 실행할 때 사용할 interpreter 의 경로를 진행 
  - 여기서는 Bash shell 을 사용하여 실행되어야 함을 의미

*  `subtract_num() {}`
  - script 함수를 정의할 때, 매개변수는 명시하지 않는다. 함수 내 $1, $2, $3 ... 과 같이 함수 내부에 명시된 value 의 숫자값에 순서대로 매칭되어 입력된다.   

* `sum=$(( $1 + $2 ))`
  - 첫번째 괄호는 $() 로 연산 결과를 값으로 취함을 의미
  - 두번째 괄호는 연산에 대한 괄호
  - 띄어쓰기는 여기서는 결과에 영향을 미치지는 않지만 일반적인 작성 기준을 따름.

<br>
* 실행 결과

```bash
root@DESKTOP:~$ ./example.sh
첫 번째 숫자: 5
두 번째 숫자: 10
두 수의 합: 15
```

### 2. 간단한 함수를 사용한 script 2 (외부 입력)

```bash
#!/bin/bash

#  두수를 빼는  함수 정의
subtract_num() {
        local sub=0
        sub=$(( $2 - $1 ))
        echo "두 수의 차: $sub"
}

# 사용자로부터 두수 입력 받기
read -p "첫번째 수를 입력하세요: " num1
read -p "두번째 수를 입력하세요: " num2

# 함수 호출
subtract_num $num1 $num2
```

* `read -p "첫번째 수를 입력하세요: " num1`
  - `read` 명령어로 표준입력 값을 받을 수 있다. 
  - `-p` 옵션으로 `echo` 명령어를 사용하지 않고 프롬프트 메세지를 보여줄 수 있다.

<br>
* 실행 결과

```bash
root@DESKTOP:~$ ./example.sh
첫번째 수를 입력하세요: 2
두번째 수를 입력하세요: -5
두 수의 차: -7
```

### 3. 간단한 함수를 사용한 script 3 (외부 입력, 조건문)

외부 입력을 함수의 실행과 함께 받도록 아래와 같이 구현할 수 있다. 

```bash
#!/bin/bash

#  두수를 빼는  함수 정의
subtract_num() {
        local sub=0
        sub=$(( $2 - $1 ))
        echo "두 수의 차: $sub"
}

if [ $# -ne 2 ]; then
        echo "사용방법: $0 숫자1 숫자2"
        exit 1
fi

# 함수 호출
subtract_num $1 $2
```

* `if [ $# -ne 2 ]; then ... fi`
  - `[];` 내 조건이 참일 경우, `then ... fi` 내 명령어를 실행
  - `if`, `[];`, `then` 사이에는 띄어쓰기를 반드시 해야 함.

* `$# -ne 2`
  - `$#` 은 script 에 전달된 positional parameter 의 갯수. 위 예제의 경우, `./example.sh 1 2` 와 같이 실행되는데, 이 때 `$#` 값은 2 이다.
  - `-ne` 은 "not equal"  의 약자로, 두 값이 서로 다른지를 비교
  - `2` 는 비교 대상의 값
  - 즉 해당 script 부분은 "입력된 positional parameter 갯수가 2개가 아니라면" 이라는 조건을 정의함.

* `echo "..." exit 1` 
  - 해당 조건일 때, 메세지를 출력하고 에러 상태로 script 를 종료
  - `exit 0` 인 경우, 정상적으로 작업이 성공되고 종료됨을 의미, 0 이 아닌 경우는, 에러나 특정 조건으로 인한 종료를 의미

<br>
* 실행 결과

매개변수를 입력하지 않은 경우

```bash
root@DESKTOP~$ ./example.sh
사용방법: ./example.sh 숫자1 숫자2
```

매개변수 값을 함께 입력한 경우

```bash
root@DESKTOP:~$ ./example.sh 3 3
두 수의 차: 0
```

### 4. 파일 입력 & 반복문을 이용 script

```bash
#!/bin/bash

# 'list' 파일을 읽어와 line 변수에 저장
while read -r line; do
    # 공백으로 구분된 값을 배열로 변환
    IFS=' ' read -ra ADDR <<< "$line"
    # 배열의 각 요소를 반복하여 출력
    for i in "${ADDR[@]}"; do
        echo $i
    done
done < "list"
```

list 파일
```bash
1 2 3 4 5
```

* `while read -r line: do ... done < "list"`
  - `list` 파일로 부터 해당 내용을 줄별로 읽어와서 각 줄의 값을 `line` 변수의 값으로 생성한다. 
  - `-r` 옵션은 `read` 명령어가 `\` 을 이스케이프 문자가 아닌 데이터 원본 그대로 무결성을 유지한채로 값을 가질 수 있도록 조건을 부여한다.

* `IFS=' ' read -ra ADDR <<< "$line"`
  - `IFS` 는 "Internal Field Separator" 의 약자, Bash 에서 단어 경계를 정의하는데 사용되는 환경 변수. 이 구분에서 `IFS` 는 공백문자 `' '` 로 설정되어 단어의 구분을 공백으로 사용하겠다는 의미.
  - `-ra` 에서 `a` 옵션은 입력된 data 를 배열로 변수 `ADDR` 에 저장함을 의미
  - `<<<` 은 here string redirction 을 의미. `here string` 은 문자열 데이터를 명령어의 표준입력으로 직접 전달할 수 있게 해준다. `명령어 <<< "문자열"` 과 같은 형태로, redirection 을 뒤에 오는 문자열 값을 바로 가져와서 사용할 수 있게 해준다. 예를 들어, 
  ```bash
  root@DESKTOP:~$ grep "찾는" <<< "여기에는 찾는 단어가 있을까요?"
  여기에는 찾는 단어가 있을까요?
  ```
  와 같이, 외부 파일 등에서 가져오는 것이 아니라 뒤에 명시된 문자열 값을 바로 redirection 하여 가져와 사용하게 된다. 
  - 따라서 해당 구문을 정리하면,  
    (1). line 변수 값을 문자열로 생성한다.<br>
    (2). (1) 번 값을 redirection 하여 가져오고,<br> 
    (3). `\` 를 별도 처리하지 않고, <br>
    (4). 띄어쓰기(' ') 로 구분하여 생성된 배열 값을<br> 
    (5). 배열 변수 `ADDR` 의 값으로 생성한다.



<br>
* 실행 결과

```bash
root@DESKTOP:~$ ./example.sh
1
2
3
4
5
```

```bash

```

```bash

```
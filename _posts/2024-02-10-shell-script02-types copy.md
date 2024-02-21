---
layout: post
read_time: true
show_date: true
title:  Shell Script 기본 문법 02 (types)
date:   2024-02-10 08:32:20 +0900
description: 개발자를 위한 반도체 SW개발 기초 (디바이스 드라이버 개발) 관련 학습 02
img: posts/general/post_general20.jpg
tags: [linux, bash, shell scirpt]
author: Yong gon Yun
---

Bash Shell Script에서는 다른 프로그래밍 언어들처럼 명시적인 데이터 타입 선언을 사용하지 않는다. Bash는 기본적으로 모든 변수를 문자열로 처리하지만, Bash 스크립트 내에서 다양한 형태의 데이터를 다룰 수 있으며, 이를 위해 특정 명령어나 구문을 사용하여 숫자, 문자열, 배열 등과 같은 다양한 "형태"의 데이터를 다루게 된다. 아래는 Bash에서 사용될 수 있는 주요 "데이터 타입"의 개념과 예시이다.

### 문자열 (String)
Bash에서 가장 기본적이고 자주 사용되는 데이터 타입. 변수에 값을 할당할 때 따옴표를 사용하지 않거나, 단일 따옴표(')나 이중 따옴표(")를 사용하여 문자열을 할당.

```bash
name="John Doe"
greeting='Hello, World!'
```

### 정수(Integer)
Bash에서는 declare -i 명령어를 사용하여 변수를 정수로 선언할 수 있다. 또한, 산술 연산에서 Bash는 변수를 자동으로 정수로 취급

```bash
declare -i number
number=10
echo $((number + 5))  # 15 출력
```

### 배열(Array)
Bash에서 배열은 여러 값을 저장할 수 있는 데이터 구조. 배열은 0부터 시작하는 인덱스를 가지며, ()를 사용하여 배열을 선언.

```bash
arr=(1 2 "hello" "world")
echo ${arr[0]}  # 1 출력
echo ${arr[3]}  # world 출력
```

* Bash 배열과 다른 프로그래밍 언어 배열 (ex. C)과 다른점 <br>

1. index & mata-data <br>
Bash 배열의 구현은 C 배열과 달리 고수준에서 이루어지기 때문에, 원소가 저장된 메모리에 대한 접근 방법 등을 고려할 필요가 없다.  Bash 배열은 각 원소애 대한 index 와 mata-data 를 내부적으로 유지하며, 여기에 원소의 위치, 길이 등이 포함될 수 있다. <br>

2. 동적 할당과 관리<br>
Bash는 필요에 따라 동적으로 메모리를 할당하고, 배열의 원소를 관리한다. 사용자가 배열에 원소를 추가하거나 제거할 때, Bash는 내부적으로 이러한 변경을 처리하고, 배열의 각 원소가 올바르게 접근될 수 있도록 한다.

3. 추상화된 접근 방식<br>
사용자가 배열의 원소에 접근할 때, Bash는 추상화된 인터페이스(예: 인덱스를 사용-한 접근)를 제공한다. 사용자는 인덱스를 통해 간단하게 원소에 접근할 수 있으며, Bash가 원소의 실제 메모리 위치와 경계를 관리한다.<br>

### 연관 배열(Associative Arrays)
ash 4 이상에서는 연관 배열(키-값 쌍을 저장하는 배열)을 사용할 수 있음. declare -A를 사용하여 연관 배열을 선언.

```bash
declare -A fruits
fruits[apple]="red"
fruits[banana]="yellow"
echo ${fruits[apple]}  # red 출력
```

### 부동 소수점(Floating Point Numbers)
Bash 자체는 부동 소수점 수를 직접 지원하지 않는다. 부동 소수점 연산을 수행하려면 bc나 awk와 같은 외부 도구를 사용해야 함.

```bash
result=$(echo "3.5 + 4.2" | bc)
echo $result  # 7.7 출력
```

### 환경 변수(Environment Variables)
환경 변수는 운영 체제의 환경 설정을 포함하는 전역 변수. Bash 스크립트에서는 이러한 환경 변수를 읽고 설정할 수 있다.

```bash
echo $PATH
export MY_VAR="SomeValue"
```


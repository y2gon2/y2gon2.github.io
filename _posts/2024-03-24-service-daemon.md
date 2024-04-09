---
layout: post
read_time: true
show_date: true
title:  IPC 실습 05 - Named Semaphore
date:   2024-03-24 10:32:20 +0900
description: 개발자를 위한 반도체 SW개발 기초 (디바이스 드라이버 개발) 관련 학습 20

img: posts/general/post_general12.jpg
tags: [linux, IPC, daemon, shared systemd, socket]
author: Yong gon Yun
---

<style>
    summary::-webkit-details-marker {
        display: none;
    }
    summary {
        list-style: none;
    }
</style>

<details><summary></summary>
에러방지  에러방지 에러방지  에러방지 에러방지  에러방지 에러방지  에러방지
에러방지  에러방지 에러방지  에러방지 에러방지  에러방지 에러방지  에러방지
에러방지  에러방지 에러방지  에러방지 에러방지  에러방지 에러방지  에러방지
에러방지  에러방지 에러방지  에러방지 에러방지  에러방지 에러방지  에러방지
에러방지  에러방지 에러방지  에러방지 에러방지  에러방지 에러방지  에러방지
에러방지  에러방지 에러방지  에러방지 에러방지  에러방지 에러방지  에러방지
에러방지  에러방지 에러방지  에러방지 에러방지  에러방지 에러방지  에러방지
에러방지  에러방지 에러방지  에러방지 에러방지  에러방지 에러방지  에러방지
에러방지  에러방지 에러방지  에러방지 에러방지  에러방지 에러방지  에러방지
에러방지  에러방지 에러방지  에러방지 에러방지  에러방지 에러방지  에러방지
에러방지  에러방지 에러방지  에러방지 에러방지  에러방지 에러방지  에러방지
에러방지  에러방지 에러방지  에러방지 에러방지  에러방지 에러방지  에러방지
</details>

아래 내용은 개발자를 위한 시스템 반도체 SW개발 기초(디바이스 드라이버 개발) (https://comento.kr/) 강의 내용 중 일부에 해당함.

### 1. Systemd 란?

커널이 가장 처음 띄우는 init 프로세스 (PID : 1)
 - 시스템을 초기화 하여 여려가지 서비스 데몬들을 띄우고 관리함. 예를 들어, 디바이스 노드를 자동을 생성하는 udev 데몬도 systemd 서비스로 구동됨.

 - journalctl 을 사용하여 각 데몬의 로그도 저장 관리함. 

 - 각 서비스 간의 의존성을 자동으로 관리

#### 기본 Systemd 서비스 관리 명령어 

* systemctl status <서비스 이름> : 해당 서비스의 상태 조회
* systemclt enable/disable <서비스 이름> : 해당 서비스 활성화/비활성화
* systemclt start/stop <서비스 이름> : 해당 서비스 시작/종료
* systemclt daemon-reload : 어떤 서비스를 수정하거나 추가했을 때 해당 명령를 통해 변경사항을 적용해줘양 함. 

* systemctl list-unit : 모든 서비스 목록 출력
* systemctl list-sockets : 서비스가 사요아는 소켓의 목록을 출력
* systemctl list-dependencies : 서비스를 tree 구조로 의존성을 표시하여 출력

* journalctl -fn : 모든 systemd 서비스 데몬들의 로그 출력
* journalctl -fn -u <서비스이름>.service : 모든 systemd 서비스 데몬들의 로그 출력

### 2. Daemon 이란?

여러 요청에 따라서 서비스를 제공하기 위해 백그라운드로 길게 떠 있는 프로세스

사용자가 직접 제어하지 않으며 init 시스템 등이 데몬을 관리하게 됨.
* 부모의 PID 는 1 (systemd) 이며 세션 및 그룩 아이디는 본인 자신이어야 함 - daemonize 과정 필요
    - init 프로세스에 입양시킨다고 표현되기도

#### daemon(nochdir, noclose) 

데몬 프로세스를 생성 함수. 

* nochdir   : 0 이면, daemon 함수는 루트 디렉토리(/)로 현재 작업 디렉토리를 변경, 1 이면 현재 디렉토리를 변경하지 않고 진행. 일반적으로 0 의 설정값을 가지며 그 이유는 데몬 프로세스가 파일 시스템을 마운트 해제하는데 방해가 되지 않도록 하기 위함이다.

* noclose   : 0이면, daemon 함수는 표준 입력(stdin), 표준 출력(stdout), 그리고 표준 에러(stderr)를 /dev/null로 리다이렉트. 만약 1이라면, 이러한 파일 디스크립터들을 리다이렉트하지 않음. 일반적으로 1의 값으로 설정되며 그 이유는 데몬 프로세스가 터미널과의 연결을 끊고, 백그라운드에서 조용히 실행되게 하고자함이다.


#### 데몬 생성 과정

1. 프로세스 분기: 부모 프로세스를 종료하고 자식 프로세스를 백그라운드에서 실행하여 세션 리더가 되게 한다.

2. 세션 생성: 새로운 세션을 생성하여 프로세스 그룹 리더가 된다.

3. 작업 디렉토리 변경: 파일 시스템의 마운트 해제를 방지하기 위해 작업 디렉토리를 루트(/)로 변경(nochdir 0  인 경우).

4. 파일 모드 마스크 초기화: 새로 생성되는 파일과 디렉토리의 권한을 제어.

5. 표준 입출력 리다이렉트: 데몬 프로세스가 터미널과의 입출력 연결을 끊음(noclose 1 인 경우). 

### 3. 서비스 데몬 개발

구현하고자 하는 서비스 데몬은  systemd socket 활셩화하는 것이다.

구현 동작

1. systemd 소켓을 열고 listen 상태로 둠.
2. 소켓에 접속 요청이 들어오면, systemd 는 서비스 데몬을 실행
3. 서비스 데몬은 실행되었을 때, accept 부터 처리하게 됨.
4. 서비스 데몬이 더이상 처리할 것이 없으면 종료함.
5. 요청이 들어올 때마다 2~4번 작업을 반복함.

구현 서비스 데몬 관련 내용 (이해가 안감...;;)
* 소켓으로의 접속이 없을 경우는 서비스 데몬을 열지 않아 메모리 절약 가능
* Accept = yse 까지 사용하면 accpet 도 systemd 가 해주나 성능상 이유로 추천되지는 않음.


### 4. 코드 작성

1.1. 루트 파일 시스템의 /usr/lib/systemd/system 밑에 <서비스>.socket 파일 생성

```bash
[Unit]
Description=socket for Comento Example
service

[Socket]
ListenStream=/run/comento.sock

[Install]
WantedBy=sockets.target
```

1.2. systemctl enable <서비스>.socket : 해당 소켓 켜기
* 소켓을 켜게 되면 ls -l /run/comento.sock 파일 생성

2.1 루트파일 시스템의 /usr/lib/systemd/system 밑에 <서비스>.service 파일 생성

```bash
[Unit]
Description=Comento Example service

[Service]
Type=forking
ExecStart=/usr/bin/comento-daemon
StandardOutput=journal
Restart=on-failure
StartLimitIntervalSec=1s
StartLimitBurst=32

[Install]
WantedBy=basic.target
```


---
layout: post
read_time: true
show_date: true
title:  Buildroot 설치 및 Kernel build
date:   2024-02-22 10:32:20 +0900
description: 개발자를 위한 반도체 SW개발 기초 (디바이스 드라이버 개발) 관련 학습 06
img: posts/general/post_general24.jpg
tags: [linux, buildroot, kernel build]
author: Yong gon Yun
---

개발자를 위한 시스템 반도체 SW개발 기초(디바이스 드라이버 개발) - Rootfs 빌드 강의 내용 (https://comento.kr/)


### 1. buildroot  다운로드 및 설치

### 1.1 buildroot  다운로드 

```bash
root@:~$ git clone git://git.buildroot.net/buildroot
```

#### 1.2 qemu 설정

```bash
root@:~$ cd buildroot
root@:~/buildroot$ ls configs  # config 종류 확인
root@:~/buildroot$ make qemu_aarch64_virt_defconfig
root@:~/buildroot$ make menuconfig
```

<center><img src="assets\img\posts\2024-02-22-buildroot-setting01.png" width="600"></center>

다음과 같이 설정을 진행

* system configuration -> init system -> systemd 선택
* kernel -> linux kernel  해제
* target packages -> text editors -> vim -> target packages -> libaries -> Crypto -> openssl support 선택 -> openssl binary 도 선택 
* Filesystem images -> ext2/3/4 -> ext4 -> exact size -> 128M
* host utilities -> 모두 선택 해제 (해제 불가 항목은 그대로 둠) -> 최종 exit -> 저장 

```bash
root@:~/buildroot$ cat /proc/cpuinfo | grep processor | wc -l # cpu 갯수 확인
root@:~/buildroot$ make -j<cpu 수>
```

#### 1.3 에러 처리

다만 해당 실행 시 에러가 발생하였는데 관련 내용은 다음과 같다. 


```bash
root@:~/buildroot$ make -j<cpu 수>
Your PATH contains spaces, TABs, and/or newline (\n) characters.
This doesn't work. Fix you PATH.
make: *** [support/dependencies/dependencies.mk:27: dependencies] Error 1
```

이 에러 메시지는 Linux 시스템의 PATH 환경 변수에 공백, 탭(TABs), 또는 줄바꿈 문자(newline, \n)가 포함되어 있어서 발생한 것이다. make와 같은 빌드 시스템에서는 PATH 환경 변수를 사용하여 필요한 실행 파일들을 찾는다. 만약 PATH에 이러한 특수 문자가 포함되어 있다면, 빌드 프로세스가 제대로 실행 파일들을 찾지 못하게 되어 오류가 발생하게 된다.

```bash
root@:~/buildroot$ echo $PATH
```

이 명령어를 실행하면 PATH에 설정된 디렉토리들이 콜론(:)으로 구분되어 출력된다. 여기서 공백, 탭, 또는 줄바꿈 문자가 있는지 확인해보니 몇 군데 공백이 확인 되었다. 따라서, PATH에서 문제가 되는 문자를 아래와 같이 제거함. 

```bash
root@:~/buildroot$ export PATH=$(echo $PATH | tr -d ' \t\n')
```

`echo $PATH` 로 제거가 되었는지 확인한 이후, 다시 make 실행에 unzip 이 설치되어 있지 않다고 에러가 발생하여 이를 설치하였다. 

```bash
root@:~/buildroot$ sudo apt-get update
root@:~/buildroot$ sudo apt-get install unzip
```

#### 1.4 buildroot 설치

그리고 최종적으로 make 를 실행하여 설치함 (20 여분 소요)

해당 작업을 통해 Buildroot 는 위 설정에 따라 다음의 주요 작업을 진행, embedded system S/W stackt 을 빌드 한다. 

1. 구성 검증: Buildroot는 .config 파일이나 다른 구성 파일에 정의된 설정을 검증한다. 이 설정은 make menuconfig, make xconfig 또는 make nconfig와 같은 명령어를 통해 사전에 사용자에 의해 정의 것들 이다..

2. 툴체인(Toolchain) 빌드 또는 다운로드: 툴체인은 컴파일러, 링커, 라이브러리 등 임베디드 소프트웨어를 컴파일하기 위해 필요한 도구들의 집합이다. Buildroot는 선택된 설정에 따라 적절한 툴체인을 빌드하거나 사전에 빌드된 툴체인을 다운로드한다. 다만 현재의 설정에서 toolchain 빌드는 따로 진행된다.

3. 리눅스 커널 빌드: 사용자가 지정한 버전의 리눅스 커널을 다운로드하고, 필요한 패치를 적용한 후 커널을 크로스 컴파일한다. 역시 현재의 설정에서 커널 빌드는 따로 진행된다.

4. 루트 파일 시스템(Root Filesystem) 구성: Buildroot는 사용자가 선택한 모든 소프트웨어 패키지를 다운로드하고, 이들을 크로스 컴파일하여 루트 파일 시스템을 구성. 이 과정에는 라이브러리, 시스템 유틸리티, 애플리케이션 등이 포함된다.

5. 부트로더(Bootloader) 빌드: 필요한 경우, 선택된 부트로더(예: U-Boot)를 빌드.

6. 이미지 생성: 모든 빌드 과정이 완료되면, Buildroot는 이들을 통합하여 임베디드 시스템을 위한 최종 이미지(예: SD 카드 이미지, NAND 플래시 이미지)를 생성한다. 이 이미지는 실제 하드웨어에서 직접 부팅할 수 있다. 3 번과 마찬가지로 현재 설정에서 해당 과정은 별도로 커널 빌드 때 진행된다.

### 2. Kernel Build 다운로드 및 이미지 생성

#### 2.1 kernel download (https://kernel.org/)

<center><img src="assets\img\posts\2024-02-22-buildroot-setting012.png" width="600"></center>

해당 사이트 git 주소 -> "stable/linux" 검색 해서 나온 kernel/git/stable/linux.git 경로를 git clone 하여 다운 받음.

```bash
root@:~/buildroot$ cd ..
root@:~$ git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/
```
->  linux 디렉토리에 해다 repository 파일 다운로드 완료

#### 2.2 kernel build 에 필요한 라이브러리 설치

```bash
root@:~$ sudo apt-get install bison flex libelf-dev libssl-dev
```

(각 라이브러리 들의 기능에 대한 이해는 부족한 상태임. 추가학습 필요)

1. Bison

 * 용도: bison은 GNU 프로젝트의 구문 분석기 생성기로, 커널 소스 코드 내의 구문을 분석하는 데 사용된다. 커널 빌드 과정에서는 특히 커널의 구성 설정 도구인 kconfig에 의해 사용됨.

2. Flex

 * 용도: flex는 텍스트 스캔을 위한 패턴 매칭을 수행하는 렉서(lexer) 또는 스캐너(scanner) 생성기. lex의 GNU 버전으로, 텍스트 입력 스트림에서 패턴을 인식하고 처리하는 프로그램을 생성한다. bison과 함께 kconfig에 의해 사용되며, 커널의 설정 옵션을 해석하고 처리하는 데 필요.

3. libelf-dev

 * 용도: libelf-dev는 ELF(Executable and Linkable Format) [(참고 자료 : ELF 란?)](https://doitnow-man.tistory.com/entry/ELF-1-ELF-%EB%9E%80) 파일을 다루기 위한 개발 라이브러리. ELF 파일 포맷은 리눅스 시스템에서 실행 파일, 오브젝트 코드, 공유 라이브러리, 코어 덤프 등을 위해 사용. 커널 모듈과 같은 ELF 형식의 바이너리 파일을 생성하고 조작하는 데 사용되므로 커널 모듈을 빌드하고 분석하는 데 필수적.

4. libssl-dev

 * 용도: libssl-dev는 OpenSSL 라이브러리의 개발 버전 패키지. OpenSSL은 네트워크 연결에 대한 암호화 통신을 제공하는 라이브러리로, SSL(Secure Sockets Layer)과 TLS(Transport Layer Security) 프로토콜을 구현한다. 커널에서는 예를 들어, 보안 통신이 필요한 네트워크 기능을 개발할 때 이 라이브러리가 사용될 수 있다.

#### 2.3 buildroot 에 있는 config 복사 및 .config 파일 생성

```bash
root@:~/linux$ cp ../buildroot/board/qemu/aarch64-virt/linux.config arch/arm64/configs/qemu_defconfig
root@:~/linux$ ARCH=arm64 make qemu_defconfig # 반환값으로 .config 생성
```

#### 2.4 kernel build 를 위한 toolchain download (https://developer.arm.com/)

-> Tools and Software -> Compilers and Libraries -> Arm GNU toolchain -> GNU Toolchain releases for A-profile processors -> GNU-A Downloads (https://developer.arm.com/downloads/-/gnu-a) -> AArch64 GNU/Linux target (aarch64-none-linux-gnu) (gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu.tar.xz) 다운로드

-----------------------

(해당 작업을 wsl2 로 설치한 ubuntu 로 진행하는 경우 다운로드 파일은 windows file system) 내부로 들어오게 된다. 이것을 linux 로 복사하기 위해서는 다음과 같이 복사 및 압풀 해제를 진행한다.

```bash
root@:~/linux$ cd ..
root@:~$ cp /mnt/c/Users/<사용자 이름>/Downloads/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu.tar.xz .
```
-----------------------

#### 2.5 toolchain 압축 풀기

```bash
root@:~$  tar xvf gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu.tar.xz
```

#### 2.6 build 진행 (이미지 생성)

```bash
root@:~$ cd linux
root@:~/linux$ ARCH=arm64 CROSS_COMPILE=/home/gon/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu- make -j16
```
<center><img src="assets\img\posts\2024-02-22-buildroot-setting013.png" width="400"></center>

build 가 완료되면 위와 같이  vmlinux 를 생성하고 이것을 가지고 arch/arm64/boot/Image 가 생성된것을 확인할 수 있다. 

### 3. buildroot 이미지 실행

#### 3.1 QEMU 설치

```bash
root@:~$ sudo apt install qemu-system-arm
```

#### 3.2 이미지 실행

```bash
root@:~$ qemu-system-aarch64 \
> -kernel linux/arch/arm64/boot/Image \
> -drive format=raw,file=buildroot/output/images/rootfs.ext4,if=virtio \
> -append "root=/dev/vda console=ttyAMA0 nokaslr" \
> -nographic -M virt -cpu cortex-a72 \
> -m 2G \
> -smp 2
```

<center><img src="assets\img\posts\2024-02-22-buildroot-setting014.png" width="600"></center>

#### 3.3 이미지 종료

터미널 창을 별도로 열어서 kill 명령어로 종료

```bash
kill -9 qemu-system-aarch64
```

또는 qemu 내에서 shutdown 명령어로 종료

```bash
shutdown -h now
```


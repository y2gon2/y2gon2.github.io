---
layout: post
read_time: true
show_date: true
title:  Device Driver 개발 1
date:   2024-02-29 10:32:20 +0900
description: 개발자를 위한 반도체 SW개발 기초 (디바이스 드라이버 개발) 관련 학습 11

img: posts/general/post_general03.jpg
tags: [linux, device driver, device node]
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

### 1. 디바이스 드라이버 종류

디바이스 드라이버는 플랫폼 별 (윈도우 드라이버, 리눅스 드라이버, 맥 OS 드라이버) 등 또는 OS 수준 별(커널 모드 드라이버, 사용자 모드 드라이버) 로 구분되기도 하며, 아래와 같이 하드웨어의 유형과 기능에 따라 장치별 드라이버로 구분되기도 한다. 

1. 블록 장치 드라이버<br>
데이터를 블록이라는 고정된 크기의 단위로 저장하고 검색하는 저장 장치를 관리. 이러한 장치에는 하드 디스크 드라이브(HDD), 솔리드 스테이트 드라이브(SSD), USB 플래시 드라이브 등이 포함되며. 블록 장치 드라이버는 파일 시스템을 지원하여, 사용자와 시스템이 데이터를 효율적으로 저장하고 액세스할 수 있게 한다. (ex. 블록 장치 드라이버는 운영 체제가 디스크의 특정 블록을 읽거나 쓸 수 있도록 하며, 디스크 상의 데이터의 물리적 위치를 추상화.)

2. 문자 장치 드라이버<br>
데이터를 문자 단위로 처리하는 장치, 즉 한 번에 하나의 문자(또는 바이트)를 전송하는 장치를 관리한다. 이에는 키보드, 마우스, 시리얼 포트, 프린터 등이 포함된다. 문자 장치 드라이버는 사용자 입력을 처리하거나 문자 기반의 데이터를 장치로 전송하는 역할을 한다. (ex. 키보드 드라이버는 사용자가 누른 키의 신호를 받아 운영 체제가 이해할 수 있는 입력 데이터로 변환.)

3. 네트워크 드라이버<br>
네트워크 인터페이스 카드(NIC)나 기타 네트워킹 하드웨어 장치를 관리한다. 이 드라이버는 데이터 패킷을 네트워크를 통해 송수신하는 데 필요한 기능을 제공한다. 네트워크 드라이버는 네트워크 프로토콜(예: TCP/IP)과 상호 작용하여 데이터를 올바르게 포맷하고, 주소를 지정하며, 에러 검사를 수행한다. 네트워크 드라이버는 데이터의 안정적인 전송을 보장하기 위해 중요한 역할을 한다.

4. 버스 디바이스 드라이버<br>
컴퓨터 내의 다양한 하드웨어 장치를 연결하는 통신 경로인 버스를 관리한다. 대표적인 예로는 PCI(Peripheral Component Interconnect), USB(Universal Serial Bus), SATA(Serial ATA) 등이 있습니다. 버스 드라이버는 하드웨어 장치 간의 데이터 전송을 조정하고, 장치 간의 호환성을 보장한다. (ex. USB 버스 드라이버는 USB 장치가 컴퓨터에 연결될 때 필요한 전력 관리, 데이터 전송 속도 조정, 연결된 장치의 식별 및 구성을 담당.)

### 2. 디바이스 노드

디바이스 노드(Device Node)는 유닉스 및 유닉스 계열 운영 체제에서 하드웨어 장치를 파일 시스템 내의 파일로 표현하는 방법. 유닉스 계열 시스템은 '모든 것은 파일'이라는 철학을 따르는데, 이는 하드웨어 장치를 포함한 모든 자원을 파일처럼 취급한다는 의미이다. 디바이스 노드를 통해, 사용자와 응용 프로그램은 표준 파일 입출력(IO) 시스템 호출을 사용하여 하드웨어 장치와 통신할 수 있다.

#### 디바이스 노드의 종류 (타입)

* 문자 디바이스(Character Device) : c <br>

* 블록 디바이스(Block Device) : b <br>

  (네트워크 드라이버와 버스 디바이스 드라이버는 노출되지 않고 별도로 관리됨.)

#### 디바이스 노드의 특징 및 사용 방법

* `mknod <파일이름> <타입> <주번호> <부번호>` : 디바이스 노드 파일 생성

* 파일 시스템 내 위치 <br>
디바이스 노드는 주로 /dev 디렉토리에 위치한다. 예를 들어, /dev/sda는 첫 번째 SATA 하드 드라이브를, /dev/tty는 현재 터미널을 나타낸다.

* 특수 파일 <br>
디바이스 노드는 특수 파일로 분류된다. 일반 파일과 달리, 실제 데이터를 디스크에 저장하는 대신, 커널의 하드웨어 장치 드라이버와 통신하는 인터페이스 역할을 한다.

* MAJOR/MINOR 번호 <br>
각 디바이스 노드는 MAJOR 번호와 MINOR 번호를 가진다. 

  MAJOR 번호(0 ~ 511)는 장치 유형(예: 하드 디스크, 시리얼 포트)을 식별한다. 디바이스 드라이버마다 고유하며 커널이 자동으로 할당하기도 한다. 

  MINOR 번호(0 ~ 1048576)는 해당 유형 내의 개별 장치를 구분한다. 즉 디바이스마다 고유하며 디바이스 드라이버가 할당을 관리한다.

  ex. USB 마우스를 여러개 꽂았을 경우 - 디바이스(minor 번호)는 여러개, 디바이스 드라이버(major 번호) 는 하나

* 사용자와 그룹 권한 <br>
디바이스 노드는 파일과 마찬가지로 사용자와 그룹 권한을 가진다. 이를 통해 특정 사용자 또는 그룹만이 장치에 접근하거나 사용할 수 있는 권한을 제어할 수 있다.


### 3. 문자 디바이스 드라이버 등록 실습

#### 3.1 문자 디바이스 드러이버 구현 시스템콜 파일 생성

(이전 post 에서 구현한 `linux/drivers/coment/main.c` 파일을 사용하여 진행)

```bash
user@DESKTOP:~/linux/drivers/comento$ vim main.c
```

```c
#include <linux/module.h>

// (1)
static int comento_device_open(struct inode *inode, struct file *file) {
    int minor = iminor(inode);
    printk(KERN_DEBUG "%s - minor : %d/n", __func__, minor);
    return 0;
} 

// (2)
struct file_operations fops= {
    .open = comento_device_open,
};

static int __init comento_module_init(void) 
{
    printk(KERN_DEBUG "%s\n", __func__);
    int ret = register_chrdev(177, "comento", &fops); // (3)
    return ret;
}

static void __exit comento_module_exit(void) 
{
    unregister_chrdev(177, "comento");
    printk(KERN_DEBUG "%s\n", __func__);
}

module_init(comento_module_init);
module_exit(comento_module_exit);

MODULE_AUTHOR("Hello<hello@comento.com>");
MODULE_DESCRIPTION("Example module");
MODULE_LICENSE("GPL v2");
```

(1) static int comento_device_open(struct inode *inode, struct file *file) {} <br>
리눅스 커널 내에서 디바이스 파일을 열려고 할 때 호출되는 함수. 이 함수는 file_operations 구조체 내에서 .open 포인터에 의해 참조되며, 사용자 공간에서 디바이스 파일(예: /dev/comento)에 대한 open 시스템 콜이 발생할 때 실행된다.
해당 함수는 디바이스 파일이 열릴 때 필요한 초기화나 상태 확인 등의 작업을 수행하기 위애 정의 된다. <br>
`struct file_operations` 의 주요 필드 callback 함수에 대한 정의를 살펴보면 
  ```c
  struct file_operations {
    struct module *owner;
    loff_t (*llseek) (struct file *, loff_t, int);
    ssize_t (*read) (struct file *, char __user *, size_t, loff_t *);
    ssize_t (*write) (struct file *, const char __user *, size_t, loff_t *);
    int (*open) (struct inode *, struct file *);
    int (*release) (struct inode *, struct file *);
    // 다른 필드들...
  };
  ```
이와 같이 open 필드의 경우, inode 포인터와 file 포인터를 인자로 취하는 함수이여야 한다.

* inode <br>
inode는 유닉스 및 유닉스 계열 시스템에서 파일 시스템의 파일이나 디렉터리에 대한 메타데이터를 저장하는 데이터 구조 (구조체 타입) 각 파일이나 디렉터리는 고유한 inode를 가지며, 이 inode에는 파일의 소유자, 파일 모드(권한), 파일 크기, 파일이 저장된 디스크 상의 위치, 생성 및 수정 날짜 등의 정보가 포함된다. <br> 
디바이스 드라이버의 컨텍스트에서 inode 구조체는 디바이스 파일의 메타데이터에 접근하는 데 사용된다. 특히, 디바이스 파일을 나타내는 inode에서 Major 번호와 Minor 번호를 추출하여, 해당 디바이스 파일이 어떤 디바이스를 참조하는지 식별할 수 있다.<br>


(2) file_operations <br>
리눅스 커널 내에서 파일 작업을 위한 callback 함수를 정의하는데 사용되느 구조체. 커널 모듈이나 디바이스 드라이버가 파일 시스템의 파일이나 디바이스 파일에 대한 다양한 작업(예: 열기, 읽기, 쓰기 등)을 수행할 수 있도록 하는 인터페이스를 제공한다. 각 필드는 특정 파일 작업을 위한 함수 포인터를 가리키며, 해당 작업이 호출될 때 실행될 함수를 지정한다. <br><br>
  - .open   : 파일이나 디바이스를 열 때 호출됨
  - .read   : 파일이나 디바이스에서 데이터를 읽을 때 호출됨
  - .write  : 파일이나 디바이스에 데이터를 쓸 때 호출됨
  - .release: 파일이나 디바이스가 닫힐 때 호출됨 (종종 close 작업으로 참조됨).
  - .llseek : 파일 내에서 읽기/쓰기 위치를 변경할 때 호출됨
  - .ioctl  : 장치에 특정 명령을 보낼 때 사용됨 (장치 제어).<br><br>


(3) register_chrdev(major, name, fops)  <br> 
새로운 문자 디바이스 드라이버 등록에 사용되는 API
 - major : 주번호로 사용할 번호를 지정, (0으로 지정시 커널이 자동 할당)
 - name : 디바이스의 이름
 - fops : 디바이스 드라이버가 구현할 file_operations
 - 등록이 성공했다면 0 또는 할당받은 major 번호를 반환, 실패시 음수 반환

<br>
이제 아래와 같이 수정한 소스 파일을 빌드하여 ko dynamic linker 파일 생성한다. 

```bash
user@DESKTOP:~/linux$ ARCH=arm64 CROSS_COMPILE=/home/gon/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu- make
  CALL    scripts/checksyscalls.sh
  CC [M]  drivers/comento/main.o
  LD [M]  drivers/comento/comento.o
  MODPOST Module.symvers
  LD [M]  drivers/comento/comento.ko
```

rootfs 에 마운트 해당 파일을 마우트 이미지에 삽입

```bash
user@DESKTOP:~/linux/$ sudo mount -o loop ../buildroot/output/images/rootfs.ext4 /mnt
user@DESKTOP:~/linux/$ sudo cp drivers/comento/comento.ko /mnt/usr/lib/modules/.
user@DESKTOP:~/linux/$ sync
user@DESKTOP:~/linux/$ sudo umount /mnt
```

QEMU 로 커널 실행

```bash
user@DESKTOP:~/linux/$ cd ..
user@DESKTOP:~$ qemu-system-aarch64 -kernel linux/arch/arm64/boot/Image -drive format=raw,file=buildroot/output/images/rootfs.ext4,if=virtio -append "root=/dev/vda console=ttyAMA0 nokaslr" -nographic -M virt -cpu cortex-a72 -m 2G -smp 2
```

#### 3.2 디바이스 노드 만들기

mknod 명령어로 디바이스 노드를 생성한다. 순서대로 c (문자 디바이스), 177 (기존에 지정한 major 번호) 32 (임의의 minor 번호) 를 입력한다.

```
# cd /dev/
# mknod /dev/comento c 177 43
```

```
# cat /dev/comento
cat: can't open '/dev/comento': No such device or address
```

명령어 수행 결과를 확인했을 때, 아직 디바이스 드라이버가 로드되지 않아 찾지 못한다고 나온다. 따라서 아래와 같이 해당 디바이스 드라이버를 등록 시키고 다시 확인해보면,

#### 3.3 모듈 로드

```
# insmod /usr/lib/modules/comento.ko
# cat /dev/comento
cat: read error: Invalid argument
```

해당 결과와 같이, 드라이버 노드는 찾은 것 같다. 다만 read 대한 구현이 없기 때문에 해당 에러가 발생하였다. 

```
# dmesg
...
comento_module_init
# ls -lah comento
crw-r--r--    1 root     root      177,  43 Feb 29 07:20 comento
```

dmesg 로 init 되었음이 확인 되었으며, (그런데 `comento_device_open` 함수 실행 메세지는 안나왔네 ;;) ls 명령어를 통해 `comento` 파일이 생성 및 major, minor 번호가 정상적으로 부여되었음을 볼 수 있다. 

위 과정에서 모듈로드가 정상적으로 되어야 드라이버 노드가 정상적으로 작동함을 보여주기 위해  mknod 로 디바이스 노드를 생성한 이후 모듈을 로드 했지만, 논리적으로 절차를 생각하면, 우선 디바이스 노드의 binary 값을 매모리에 로드하는 것이 우선으로 시행되는 것이 맞다. 해당 insmod 명령어 수행시 어떤 작업이 수행되는지 정리하면 아래와 같다. 

1. 메모리 로드
insmod 명령어는 디스크 상의 커널 모듈(.ko 파일)을 찾아 메모리로 로드. 이 파일에는 디바이스 드라이버의 실행 가능한 코드가 포함되어 있다.

2. 초기화 및 등록
드라이버 모듈이 메모리로 로드되면, 그 안에 정의된 초기화 함수가 실행된다. 이 초기화 과정에서 드라이버는 자신이 관리할 하드웨어 디바이스를 설정하고, 커널에 필요한 정보(예: 드라이버가 지원하는 연산, 메이저 번호 등)를 등록한다. 이로써 시스템은 해당 드라이버가 존재하고 사용 가능함을 알게 된다.

3. 시스템과의 통합
드라이버가 성공적으로 로드되고 초기화되면, 시스템의 다른 부분들은 해당 드라이버를 통해 연결된 하드웨어 디바이스와 통신할 수 있다. 예를 들어, 사용자 공간의 애플리케이션은 표준 파일 입출력 연산을 사용하여 디바이스 파일(/dev에 위치)을 통해 드라이버와 데이터를 주고받을 수 있다.

이후 mknod 명령어 요청시 로드된 모듈을 가지고 어떤 작업들이 진행되는 정리하면 아래와 같다. 

1. 파일 유형 및 메이저/마이너 번호 지정
사용자는 mknod 명령어를 실행할 때 파일의 경로, 유형(문자 디바이스 또는 블록 디바이스), 메이저 번호, 그리고 마이너 번호를 지정. 이 정보는 생성될 디바이스 파일의 특성을 결정한다.
(예: mknod /dev/example c 240 0은 /dev 디렉토리에 example이라는 이름의 문자 디바이스 파일을 생성하며, 이 파일은 메이저 번호 240과 마이너 번호 0을 가진다.)

2. 디바이스 파일 생성
지정된 정보를 바탕으로 파일 시스템에 디바이스 파일을 생성. 이 파일은 실제 데이터를 저장하지 않고, 대신 특정 디바이스 드라이버와의 통신 경로 역할을 한다. 생성된 파일의 유형(문자 또는 블록), 메이저 번호, 마이너 번호는 커널이 디바이스 드라이버를 어떻게 찾아야 하는지를 결정하는 데 사용된다.

3. 파일 시스템에 메타데이터 등록
생성된 디바이스 파일에 대한 메타데이터가 파일 시스템에 등록. 이 메타데이터에는 파일의 유형, 권한, 소유자, 그룹, 메이저/마이너 번호 등이 포함될 수 있다. 이 정보는 파일 시스템을 통해 파일에 접근하려는 프로세스에 의해 참조된다.

4. 시스템과의 통합
디바이스 파일이 성공적으로 생성되면, 시스템의 다른 부분(예: 사용자 공간의 프로그램)은 이 파일을 통해 커널의 디바이스 드라이버와 통신할 수 있다. 파일에 대한 입출력 연산은 커널에 의해 해당 디바이스 드라이버의 적절한 함수로 라우팅된다.
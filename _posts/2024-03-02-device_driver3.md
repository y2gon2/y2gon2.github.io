---
layout: post
read_time: true
show_date: true
title:  Device Driver 개발 3 (파일 특수 제어 (ioctl) 구현)
date:   2024-03-02 10:32:20 +0900
description: 개발자를 위한 반도체 SW개발 기초 (디바이스 드라이버 개발) 관련 학습 13

img: posts/general/post_general05.jpg
tags: [linux, device driver, device node, ioctl]
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

### 1. 파일 특수 제어 (ioctl) 이란?

ioctl은 리눅스에서 주로 사용되는 시스템 콜 중 하나로, "Input/Output Control"의 약자이다. 단순 읽기/쓰기 외 디바이스 드라이버에 특정 명령을 전달하거나, 드라이버의 상태를 변경하거나, 내부 데이터를 얻기 위해 사용된다. 일반적인 파일 입출력 시스템 콜과는 달리, ioctl을 통해 디바이스 특화 명령을 수행할 수 있기 때문에, 다양한 종류의 하드웨어 디바이스와 상호작용하는 데 매우 유용하다.

unlocked_ioctl 함수 포인터 프로토타입 : <br>
<strong>long (*unlocked_ioctl)(struct file *file, unsigned int cmd, unsigned long arg);</strong>

* struct file *file : <br>
  현재 열린 파일(디바이스)을 나타내는 file 구조체에 대한 포인터. 이 구조체는 파일에 대한 중요한 정보를 담고 있으며, ioctl 호출 시 해당 디바이스 파일에 대한 참조를 제공.

* unsigned int cmd : <br>
  디바이스 드라이버에 전달된 명령. user space에서 ioctl 함수를 호출할 때 지정한 명령 코드가 이 인자로 전달된다. 드라이버는 이 코드를 사용하여 어떤 작업을 수행할지 결정한다. 명령 코드는 보통 드라이버의 헤더 파일에 상수로 정의되어 있다.

  cmd 의 경우 일반적을 _IOR과 _IOW 매크로를 사용해서 정의 한다. 

  - _IO(type, nr): arg 없이 단순한 명령 매크로. type은 (디바이스 고유의) 명령 유형, nr 은 명령의 고유 번호를 의미
  - _IOW(type, nr, size): arg 를 사용해서 user space 에 size 만큼의 데이터를 kernel 에 넘김. 
  - _IOR(type, nr, size): arg 를 사용해서 kernel 내에서 읽고, 해당 data 를 size 크기 만큼 가져옴.

  이를 사용하여 파일 읽기/쓰기와는 다른 디바이스의 상태, 구성, 또는 내부 정보 등을 읽거나 수정할 수 있다.

* unsigned long arg : <br>
  명령에 대한 추가 데이터를 포함할 수 있는 사용자 공간의 포인터 또는 값. 명령의 성격에 따라 이 값은 주소 값일 수도 있고, 직접적인 데이터 값일 수도 있다. 드라이버는 이 값을 통해 필요한 추가 정보를 얻거나 사용자 공간으로 데이터를 전달할 수 있다.

unlocked_ioctl 함수는 성공 시 0 또는 양의 정수를, 실패 시 음의 에러 코드를 반환한다. 이 반환 값은 시스템 콜을 호출한 사용자 공간 프로세스에게 전달된다.

(unlocked_ioctl 대신 ioctl 함수 포인터를 사용하는 이유 중 하나는, unlocked_ioctl이 빅 커널 락(BKL, Big Kernel Lock)을 사용하지 않기 때문이다. 이는 더 나은 성능과 동시성을 제공하며, 현대의 멀티코어 시스템에서 중요한 특징이다. 따라서, 새로운 드라이버를 작성할 때는 unlocked_ioctl을 사용하는 것이 권장된다.)

### 2. 파일 특수 제어 (ioctl) 구현

기존의 main.c 파일에 ioctl 관련 구현 내용을 추가해 준다. 해당 코드는 buffer 내용을 지우는 (clear) 하는 작업을 정의하였다. 

```c
#define COMENTO_MAGIC 'c'  // type ( ioctl 명령을 유일하게 식별하기 위한 문자)
#define COMENTO_IOCTL_CLEAR _IO(COMENTO_MAGIC, 0) // nr: 0 함수 내부 switch 문의 구분 번호

static long comento_device_ioctl(struct file *fp, unsigned int cmd, unsigned long arg) {
    switch(cmd) {
        case COMENTO_IOCTL_CLEAR:
            memset(comento_device_buf, 0, COMENTO_BUF_SIZE);
            break;
        default:
            printk(KERN_DEBUG "%s failed - %d\n", __func__, cmd);
            return -EINVAL; // 정의되지 않은 값이 입력된 경우, "Invalid Argument" 오류 반환
    }
    return 0;
}

//...
static struct file_operations comento_device_fops = {
    // ...

    .unlocked_ioctl = comento_device_ioctl,
};
```

한편, [이전 post - 파일 읽기/ 쓰기](https://y2gon2.github.io/device_driver2.html) 에서는 파일 읽기/쓰기 기능만 사용되므로, 기존의 읽기/쓰기 함수를 사용하여 구현하였다. 그러나 ioctl 은 사용자 정의 명령을 통해 특정 디바이스 드라이버와 상호작용해야 하므로, 이를 별도로 구현해 주어야 한다. 이와 관련하여 해당 내용은 다음과 같다. 

```c
#include <sys/ioctl.h>
#include <linux/limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>

#define COMENTO_DEVICE_NAME "comento" // 디바이스 파일명 
#define COMENTO_MAGIC 'c'

// 디바이스에 대한 ioctl 명령을 정의, _IO 매크로를 사용하여 COMENTO_IOCTL_CLEAR 명령을 생성
// 해당 정의는 앞에 커널 모듈의 소스코드에서 정의한 것과 일치해야 한다.
#define COMENTO_IOCTL_CLEAR _IO(COMENTO_MAGIC, 0) 

int main(int argc, char *argv[]) {
    // open 함수를 사용하여 /dev/comento-device 디바이스 파일을 읽기/쓰기 모드(O_RDWR)로 염
    // 파일 디스크립터는 fd 변수에 저장
    // 파일 열기에 실패한 경우, 오류 메시지를 출력하고 프로그램을 종료
    int fd = open("/dev/" COMENTO_DEVICE_NAME, O_RDWR); 
    if(fd < 0) {
        printf("Failed to open device\n");
        return -1;
    }

    // ioctl(fd, COMENTO_DEVICE_IOCTL_CLEAR, 0) 해당 호출을 통해 
    // 시스템 콜을 통해 커널 공간으로 전달되고, 커널은 등록된 디바이스 드라이버의 ioctl 처리 함수 
    // 'comento_device_ioctl' - case COMENTO_DEVICE_IOCTL_CLEAR 이 실행되게 된다. 
    // 파일 디스크립터는 fd 변수에 저장되며, 파일 열기에 실패한 경우, 
    // 오류 메시지를 출력하고 프로그램을 종료합니다.
    if(ioctl(fd, COMENTO_IOCTL_CLEAR, 0) < 0) {
        printf("Failed to do ioctl command\n");
        return -1;
    }
    return 0;
}
```

### 3. 구현 작업

main.c 을 열어 위 소스 코드 추가

```bash
user@DESKTOP:~/linux$ vim drivers/comento/main.c
```

소스 코드 빌드

```bash
user@DESKTOP:~/linux$ ARCH=arm64 CROSS_COMPILE=/home/gon/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu- make
  CALL    scripts/checksyscalls.sh
  CC [M]  drivers/comento/main.o
  LD [M]  drivers/comento/comento.o
  MODPOST Module.symvers
  LD [M]  drivers/comento/comento.ko
```

빌드된 커널 모듈을 이미지내 삽입

```bash
user@DESKTOP:~/linux$ sudo mount -o loop ../buildroot/output/images/rootfs.ext4 /mnt
user@DESKTOP:~/linux$ sudo cp drivers/comento/comento.ko /mnt/usr/lib/modules/.
```

사용자 프로그램 생성 (위 작성 코드 내용 사용)

```bash
user@DESKTOP:~/linux$ cd ..
user@DESKTOP:~$ vim ioctl.c
```

toolchain 을 사용하여 사용자 프로그램 빌드

```bash
user@DESKTOP:~$ gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-gcc -o ioctl ioctl.c
```

사용자 프로그램 이미지 내 추가

```bash
user@DESKTOP:~$ sudo cp ioctl /mnt/usr/bin
user@DESKTOP:~$ sync
user@DESKTOP:~$ sudo umount /mnt
```

QEMU 실행 

```bash
user@DESKTOP:~$ qemu-system-aarch64 -kernel linux/arch/arm64/boot/Image -drive format=raw,file=buildroot/output/images/rootfs.ext4,if=virtio -append "root=/dev/vda console=ttyAMA0 nokaslr" -nographic -M virt -cpu cortex-a72 -m 2G -smp 2
```

### 4. ioclt 사용

모듈 삽입 및 드라이버 노드 파일 생성

```
# insmod /usr/lib/modules/comento.ko
# cd /dev/
# mkmod /dev/comento c 177 34
# ls -lah comento
crw-r--r--    1 root     root      177,  34 Mar  2 07:12 comento
```

node file buffer 문자열 넣기 및 확인

```
# echo "hello~~!!" > /dev/comento
# cat /dev/comento
hello~~!!
```

사용자 프로그램(ioctl) 을 실행하여 buffer 초기화 (clear) 실행

```
# ioctl
# cat /dev/comento
(출력 내용 없음)
```

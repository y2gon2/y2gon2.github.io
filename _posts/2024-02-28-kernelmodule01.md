---
layout: post
read_time: true
show_date: true
title:  Kernel Module 만들기
date:   2024-02-28 10:32:20 +0900
description: 개발자를 위한 반도체 SW개발 기초 (디바이스 드라이버 개발) 관련 학습 10

img: posts/general/post_general02.jpg
tags: [linux, kernel module]
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

### 1. 관련 설정 추가 및 source code 생성

1.1 드라이버 디렉토리 생성 및 Makefile 에 해당 디렉토리 추가

```bash
user@DESKTOP:~$ cd linux/drivers
user@DESKTOP:~/linux/drivers$ mkdir comento
user@DESKTOP:~/linux/drivers$ vim Makefile
```

```makefile
...
obj-$(CONFIG_DRM_ACCEL)         += accel/
obj-$(CONFIG_CDX_BUS)           += cdx/
obj-$(CONFIG_DPLL)              += dpll/

obj-$(CONFIG_S390)              += s390/
# 추가 내용
oeeebj-y                           += comento/ 
```

1.2 drivers Kconfig 에도 추가될 디렉토리 Kconfig 항목 추가

```bash
user@DESKTOP:~/linux/drivers$ vim Kconfig
```

```makefile
...
source "drivers/cdx/Kconfig"

source "drivers/dpll/Kconfig"

source "drivers/comento/Kconfig"  # 추가 내용

endmenu
```

1.3 해당 디렉토리에 Kconfig 파일 추가

```bash
user@DESKTOP:~/linux/drivers$ cd comento
user@DESKTOP:~/linux/drivers/comento$ vim Kconfig 
```

```makefile
menu "Comento Example Driver"

config COMENTO_EXAMPLE
    tristate "Comento Example Dirver Module"
    help
        This is an example

endmenu
```

* `config COMENTO_EXAMPLE` : .config 파일에서는 CONFIG prefix 를 붙여 `CONFIG_COMENTO_EXAMPLE` 로 사용됨. 


1.4 해당 디렉토리 내 main.c 로 목적파일이 만들어 질 수 있도록 Makefile 추가

```bash
user@DESKTOP:~/linux/drivers/comento$ vim Makefile
```

```makefile
obj-$(CONFIG_COMENTO_EXAMPLE) += comento.o
comento-objs += main.o
```

1.5 linux kernel module 내용을 담은 소스 코드 `main.c` 작성

```bash
user@DESKTOP:~/linux/drivers/comento$ vim main.c
```

```c
#include  <linux/module.h>

static int __init comento_module_init(void) {
    printk(KERN_DEBUG "%s\n",  __func__);
    return 0;
}

static void __exit comento_module_exit(void) {
    printk(KERN_DEBUG "%s\n",  __func__);
}

module_init(comento_module_init);
module_exit(comento_module_exit);

MODULE_AUTHOR("Hello<hello@comento.com>");
MODULE_DESCRIPTION("Example module");
MODULE_LICENSE("GPL v2");
```
#### 모듈 초기화 및 종료 함수

* `__init` 함수 (comento_module_init): 모듈이 커널에 로드될 때 자동으로 실행됨. `__init` 매크로는 이 함수가 초기화 코드에만 사용되며, 초기화 후에는 메모리에서 해제될 수 있음을 커널에 알린다. 이 예에서, printk 함수를 사용하여 커널 로그에 메시지 (`__func__` 매크로는 현재 함수 이름의 문자열을 반환) 를 출력한다. `__init` 은 init 관련 함수임을 표시한 attribute 이다.

* `__exit` 함수 (comento_module_exit): 모듈이 커널에서 제거될 때 실행됨. `__exit` 매크로는 이 함수가 종료 코드에만 사용되며, 모듈이 커널에 계속 로드되어 있는 경우 메모리를 절약하기 위해 해제될 수 있음을 나타낸다. 

* `module_init` 매크로
  - 목적: 커널 모듈이 시스템에 로드될 때 실행될 초기화 함수를 지정
  - 동작: 지정된 초기화 함수는 모듈이 커널에 삽입될 때(insmod 명령어 사용 시) 자동으로 호출된다. 이 함수 내에서는 모듈이 제대로 작동하기 위해 필요한 리소스 할당, 상태 초기화, 디바이스 등록 등의 작업을 수행한다.

* `module_exit` 매크로
  - 목적: 커널 모듈이 시스템에서 제거될 때 실행될 종료 함수를 지정
  - 동작: 지정된 종료 함수는 모듈이 커널에서 제거될 때(rmmod 명령어 사용 시) 자동으로 호출된다. 이 함수 내에서는 모듈의 정상적인 종료를 위해 할당된 리소스의 해제, 등록된 디바이스의 등록 해제 등의 작업을 수행한다.

* `MODULE_AUTHOR`: 모듈의 작성자.

* `MODULE_DESCRIPTION`: 모듈에 대한 간단한 설명.

* `MODULE_LICENSE`: 모듈의 라이선스 유형. "GPL v2"는, 모듈이 GNU General Public License 버전 2에 따라 배포됨을 나타낸다. 이는 모듈이 GPL 호환 코드와 함께 사용되어야 함을 의미한다.

1.6 menuconfig 실행하여 항목 추가되었음을 확인하고 설정 반영

```bash
user@DESKTOP:~/linux/drivers/comento$ cd ..
user@DESKTOP:~/linux/drivers$ cd ..
user@DESKTOP:~/linux$ ARCH=arm64 make menuconfig
```
Device Driver 항목 맨 아래 다음과 같이 추가되었음을 확인할 수 있다. 

<center><img src="assets\img\posts\2024-02-28-kernelmodule011.png" width="600"></center>
<br>
<center><img src="assets\img\posts\2024-02-28-kernelmodule012.png" width="600"></center>

### 2. kernel build

2.1  kernel build

```bash
user@DESKTOP:~/linux$ ARCH=arm64 CROSS_COMPILE=/home/gon/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu- make 
  CALL    scripts/checksyscalls.sh
  CC [M]  drivers/comento/main.o
  LD [M]  drivers/comento/comento.o
  ...
  CC [M]  drivers/comento/comento.mod.o
  LD [M]  drivers/comento/comento.ko
  ...
```

해당 kernel 을 build 하면 위와 같이 사용자가 작성한 `drivers/comento/main.o` 가 gcc 에 의해 빌드되고, 해당 linker script 가 `comento-objs += main.o` 에 명시된 대로 `main.o` 를 모아서 `obj-$(CONFIG_COMENTO_EXAMPLE) += comento.o` 대로 `drivers/comento/comento.o` 을 생성한다.

그리고 `commento.o` 가 모듈관련 목적 파일 `drivers/comento/comento.mod.o` 과 함께 link 되서 linker 가 `drivers/comento/comento.ko` 를 만든다. 

### 3. buildroot 이미지에 해당 ko 파일 추가 및 QEMU 에서 모듈 로드가 정상적으로 되었는지 확인

3.1 buildroot 이미지에 해당 ko 파일 추가

```bash
user@DESKTOP:~/linux$ sudo mount -o loop ../buildroot/output/images/rootfs.ext4 /mnt
user@DESKTOP:~/linux$ sudo mkdir /mnt/usr/lib/modules
user@DESKTOP:~/linux$ sudo cp drivers/comento/comento.ko /mnt/usr/lib/modules
user@DESKTOP:~/linux$ sync
user@DESKTOP:~/linux$ sudo umount /mnt
```

3.2 QEMU 실행

```bash
user@DESKTOP:~/linux$ cd ..
user@DESKTOP:~$ qemu-system-aarch64 -kernel linux/arch/arm64/boot/Image -drive format=raw,file=buildroot/output/images/rootfs.ext4,if=virtio -append "root=/dev/vda console=ttyAMA0 nokaslr" -nographic -M virt -cpu cortex-a72 -m 2G -smp 2
```

3.3 모듈 추가 확인

```
# ls /usr/lib/modules
comento.ko
```

해당 커널에서 삽입한 경로에 보면 `comento.ko` 이 정상적으로 추가되어 있음을 볼 수 있다. 

### 4. moudule load / unload 

4.1 load

```
# insmod /usr/lib/moduels/comento.ko
# dmesg -c
comento_module_init
```
insmod 하여 모듈을 삽입하고 `dmesg` 를 하면, `main.c` 에 작성 했던 `comento_module_init()` 에서 작성한 대로 함수명 (`comento_module_init`) 을 출력하게 된다. 아래와 같이 `lsmod` 명령어로 현재 로드된 모듈들을 볼 수도 있다. 

```
# lsmod
Module                  Size  Used by
comento                12288  0
```

4.2 unload

```
# rmmod comento.ko
# dmesg -c
comento_module_exit
```

`rmmod` 를 통해 지정된 모듈을 제거 한다. 제거하면서 "comento_module_exit" 메세지가 출력되었음을 볼 수 있다.

```
# lsmod
Module                  Size  Used by
```

`lsmod` 로 보면 이제 로드된 모듈이 없음을 확인할 수 있다. 

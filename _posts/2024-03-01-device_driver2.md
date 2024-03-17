---
layout: post
read_time: true
show_date: true
title:  Device Driver 개발 2 (파일 읽기/ 쓰기)
date:   2024-03-01 10:32:20 +0900
description: 개발자를 위한 반도체 SW개발 기초 (디바이스 드라이버 개발) 관련 학습 12

img: posts/general/post_general04.jpg
tags: [linux, device driver, device node, ssize_t()]
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

개발자를 위한 시스템 반도체 SW개발 기초(디바이스 드라이버 개발) (https://comento.kr/)

### 1. 파일 읽기/ 쓰기 구현 

1.1 ssize_t type

리눅스 드라이버에서 `ssize_t` 타입은 일반적으로 데이터의 크기나 양을 나타내는 데 사용되며, 부호 있는 64비트(시스템에 따라 다를 수 있음) 정수를 의미한다. `ssize_t`는 시스템 호출이나 함수들이 실패할 경우 음수 값을 반환할 수 있게 하며, 성공적인 경우에는 양의 값을 반환한다. 이는 주로 파일이나 소켓의 읽기 및 쓰기 연산에서 반환 타입으로 사용된다.

리눅스 커널 모듈에서 파일 또는 장치 드라이버의 읽기 및 쓰기 연산을 구현할 때, read와 write 시스템 호출에 대응하는 함수 포인터를 file_operations 구조체에 설정하고 `ssize_t` 를 반환 타입으로 설정한다.

* ssize_t(*read)(file, buf, len, ppos) : 파일 읽기 함수 callback
* ssize_t(*write)(file, buf, len, ppos) : 파일 쓰기 함수  callback

 - file (`struct file *`) : 읽기/쓰기 연산을 수행할 파일에 대한 포인터. struct file은 열린 파일의 상태를 나타내며, 파일의 현재 위치(offset) 같은 정보를 포함한다. 이 구조체를 통해 커널은 어떤 파일에 대한 작업을 수행하고 있는지 알 수 있다.

  - buf (`char __user *`) : user space 의 버퍼 주소를 가리키는 포인터. 커널은 데이터를 읽어 user mode process 가 접근한 memory 에 전달할 때, `__user`  포인터가 가리키는 위치부터 버퍼 공간을 확보.

  - len (`size_t`) : 버퍼의 크기. '__user' 포인터 위치로부터 해당 크기만큼의 buffer 를 user space 에 확보하여 data 을 옮기 수 있게 한다. 

  - ppos (`loff_t *`) : 파일 내의 현재 위치(offset)를 나타내는 포인터. loff_t 타입은 대용량 파일 지원을 위해 사용되며, 파일의 어느 부분에서 데이터를 읽을지 결정한다. 함수 호출이 성공하면, 이 위치는 읽은 바이트 수만큼 증가한다. 따라서 파일로부터 원하는 부분에 대한 data 를 읽기 위해서 이에 대한 ppos 의  수정/갱신이 필요하다.

  데이터의 이동이 kernel space 와 user space 간 이루짐으로 일반적인 `memcpy` 는 사용할 수 없으며, `copy_from_user` / `copy_to_user` 를 사용하여 데이터 복사를 진행해야 한다. 

1.2 source 코드 작성 및 빌드

기존에 작성한 [Kernel Module 만들기 1 참조](https://y2gon2.github.io/kernelmodule01.html) `main.c` 파일을 읽기/쓰기 함수를 추가한다.

```bash
user@DESKTOP:~/linux$ vim drivers/comento/main.c
```

```c
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/module.h>
#include <linux/spinlock.h>

#define COMENTO_DEVICE_NAME "comento-device"
#define COMENTO_MAJOR_NUMBER 177 
#define COMENTO_BUF_SIZE 16

static DEFINE_RWLOCK(comento_device_rwlock);  // * rwlock 관련
static char comento_device_buf[COMENTO_BUF_SIZE] = {0, }; 
// 이 버퍼는 커널 모듈의 일부로서, 커널 모듈이 로드될 때 커널의 메모리 영역에 할당되고, 
// 모듈이 언로드될 때 해제된다. 


// char __user *buf : __user attribute (생략 가능하지만 가독성/명확성을 위해 사용)
static ssize_t comento_device_read(struct file *fp, char __user *buf, size_t len, loff_t *ppos) {
    ssize_t written_bytes = 0;

    read_lock(&comento_device_rwlock);  // * rwlock : read 용 lock 얻기
    
    // 데이터를 읽거나 쓸 때, 요청된 작업이 디바이스 또는 버퍼의 실제 크기를 넘어서지 않도록 보장
    // 현재는 *ppos 16 을 넘어가면 실제로 읽지 못하는 상태임 (?)
    if(COMENTO_BUF_SIZE <= len + *ppos) {
        len = COMENTO_BUF_SIZE - *ppos;
    }
    
    // 실제로 복사된 bytes = 사용자가 요청한 복사 길이 bytes - 실패하거나 복사되지 않은 bytes 수를 반환
    // copy_to_user(목적지 space, 출발지 pointer, 복사 요청 길이 ) : 출발지 pointer 의 경우 ppos(offset) 고려해야
    written_bytes = len - copy_to_user(buf, comento_device_buf + *ppos, len);
    *ppos += written_bytes; // offset 값 갱신

    read_unlock(&comento_device_rwlock);  // * rwlock : read 완료 후 unlock

    return written_bytes;
}

// const char __user *buf : 쓰기의 경우 kernel 에서 user space data 를 읽기만 한다. 
// kernel 이 해당 주소를 임의로 수정할 필요가 없으므로 const 로 고정시켜 안정성을 높인다.
// const 로 미 선언시 error 또는 warning 발생
static ssize_t comento_device_write(struct file *fp, const char __user *buf, size_t len, loff_t *ppos) {
    int read_bytes = 0;
    write_lock(&comento_device_rwlock); // * rwlock : write 용 lock 얻기
    
    if (COMENTO_BUF_SIZE <= len + *ppos) {
        len = COMENTO_BUF_SIZE - *ppos;
    }
    
    // copy_from_user(목적지 space, 출발지 pointer, 복사 요청 길이 ) 
    read_bytes = len - copy_from_user(comento_device_buf + *ppos, buf, len);
    *ppos += read_bytes; // offset 값 갱신
    
    write_unlock(&comento_device_rwlock);  // * rwlock : write 완료 후 unlock
    return read_bytes;
}


static int comento_device_open(struct inode *inode, struct file *file) {
    int minor = iminor(inode);
    printk(KERN_DEBUG "%s - minor : %d/n", __func__, minor);
    return 0;
}

struct file_operations fops= {
    .open = comento_device_open, 
    // .open 생략시 open 되었다고 가정하고 시스템에서 에러를 발생시키지 않음.
    .read = comento_device_read,
    .write = comento_device_write,
};

static int __init comento_module_init(void)
{
    printk(KERN_DEBUG "%s\n", __func__);
    int ret = register_chrdev(177, "comento", &fops); 
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

### 2. 파일 빌드, 추가, QEMU 실행 

파일 빌드 및 ko 파일 생성

```bash
user@DESKTOP:~/linux$ ARCH=arm64 CROSS_COMPILE=/home/gon/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu- make
  CALL    scripts/checksyscalls.sh
  CC [M]  drivers/comento/main.o
  LD [M]  drivers/comento/comento.o
  MODPOST Module.symvers
  LD [M]  drivers/comento/comento.ko
```

ko 파일 rootfs 이미지에 복사

```bash
user@DESKTOP:~/linux$ sudo mount -o loop ../buildroot/output/images/rootfs.ext4 /mnt
user@DESKTOP:~/linux$ sudo cp drivers/comento/comento.ko /mnt/usr/lib/modules/.
user@DESKTOP:~/linux$ sync
user@DESKTOP:~/linux$ sudo umount /mnt
```

QEMU 실행

```bash
user@DESKTOP:~/linux$ cd ..
user@DESKTOP:~$ qemu-system-aarch64 -kernel linux/arch/arm64/boot/Image -drive format=raw,file=buildroot/output/images/rootfs.ext4,if=virtio -append "root=/dev/vda console=ttyAMA0 nokaslr" -nographic -M virt -cpu cortex-a72 -m 2G -smp 2
```

### 3. 파일 읽기, 쓰기 사용

드라이버 모듈 삽입 및 확인

```
# insmod /usr/lib/modules/comento.ko
# dmesg
...
comento_module_init
# cd /dev
# ls -lah comento
crw-r--r--    1 root     root      177,  34 Mar  1 05:50 comento
```

dev 디렉토리 내 디바이스 노드 생성

```
# mknod /dev/comento c 177 34
```

값 넣어보기

```
# echo "wow" > /dev/comento
# cat /dev/comento
wow
```

추가된 comento 디바이스 노드에 "wow" 문자열을 redirection 하고, 해당 디바이스 노드 내용을 출력하면  redirect 된 값이 그대로 출력됨을 확인할 수 있다. 

이는 앞에서 구현한 소스코드 중 `comento_device_write` 함수가 실행되어, user space 에서 작성한 문자열이 `copy_from_user` 를 사용하여 kernel space memory (`comento_device_buf`)에 쓰기가 되었음을 의미한다. 

cat 명령을 사용하면, 해당 디바이스 노드의 버퍼 공간 내용을 읽어 온다. 즉 앞에서 구현한 `comento_device_read` 함수를 실행하여 `copy_to_user` 로 `comento_device_buf` 에 저장된 문자열을 표준 출력으로 제공하게 되는 것이다. 

### 4. strace 를 사용한 읽기 과정 관찰

strace 를 사용하기 위해 커널을 빠져 나온 이후, 임의 파일을 생성하고 이를 strace 를 사용하여 그 과정을 좀더 로그로 출력했을때, 그 일부 내용은 아래와 같다. 

```bash
user@DESKTOP:~$ touch empty
user@DESKTOP:~$ strace cat empty
...
openat(AT_FDCWD, "empty", O_RDONLY)     = 3
newfstatat(3, "", {st_mode=S_IFREG|0644, st_size=0, ...}, AT_EMPTY_PATH) = 0
fadvise64(3, 0, 0, POSIX_FADV_SEQUENTIAL) = 0
mmap(NULL, 139264, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7f854e8ec000
read(3, "", 131072)                     = 0
munmap(0x7f854e8ec000, 139264)          = 0
close(3)                                = 0
close(1)                                = 0
close(2)                                = 0
exit_group(0)                           = ?
+++ exited with 0 +++
```

openat(AT_FDCWD, "empty", O_RDONLY) = 3<br>
 - openat: 파일이나 디렉토리를 열기 위한 시스템 호출.
 - AT_FDCWD: 현재 작업 디렉토리 (at file descriptor current working directory)
 - "empty": 열고자 하는 파일의 이름
 - O_RDONLY: 읽기 전용 모드로 열라는 옵션
 - 3: openat 시스템 호출의 반환 값. 리눅스와 유닉스 시스템에서 파일은 파일 디스크립터를 통해 관리되며, 이 값은 성공적으로 파일을 열었을 때 시스템이 할당한 파일 디스크립터를 나타낸다. 여기서 3은 열린 파일을 나타내는 파일 디스크립터 번호이다. 일반적으로 0, 1, 2는 각각 표준 입력, 표준 출력, 표준 에러를 위해 예약되어 있으므로, 사용자가 열 수 있는 첫 번째 파일 디스크립터는 3부터 시작한다.

read(3, "", 131072)                     = 0<br>
  - 앞에서 구현한 파일 읽기와 동일한 callback 이 발생함을 확인할 수 있다. 
  파일 디스크립터 3 에 대해 값 "" 을 131072 buffer size 를 가지고 read 함수가 callback 된다.


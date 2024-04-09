---
layout: post
read_time: true
show_date: true
title:  (Windows) CUDA 사용 tensorflow 작업 환경 설정   
date:   2024-04-08 09:32:20 +0900
description: (Windows 10) CUDA 사용 tensorflow 작업 환경 설정   

img: posts/general/post_general13.jpg
tags: [cuda, cudnn, tensorflow]
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

tensflow 기반 딥러닝 학습을 하는데 cpu 기반 작업이 너무 느려서 GPU 를 사용하고자 하였으나 최신 자료는 없는것 같아 이를 다시 정리해 보았다. 다만 윈도우 환경에서 지원되는 CUDA toolkit 버젼은 그리 변화가 있지는 않았다. 

* 사용환경
 - OS: Windows 10  64bits
 - GPU : RTX 3070 
 - GPU driver : Nvidia Graphic Driver 537.13 
 - CUDA Toolkit : 11.2
 - Visual Studio : 2019  
 - cudnn : 8.2.1 (for cuda toolkit 11.x)
 - python : 3.10
 - Anacoda 가상환경 - jupyter notebook
 - tensorflow-gpy : 2.10


2024년 4월 기준, 아래 페이지에서 다음과 같이 윈도우 환경에서 Nvidia GPU 사용 환경 조건을 확인 할 수 있다. 
[링크 : Tensorflow Build from source on Windows ](https://www.tensorflow.org/install/source_windows?hl=en)

<center><img src="assets\img\posts\2024-04-08-tensorflow_gpu_setting.png" width="600"></center>
<br>

#### 1.Nvidia Graphic Driver 설치 확인 및 전체 환경 설정 조건 확인

아래와 같이 우선 cmd 에서  'nvidia-smi'명령어를 실행하여 그래픽 드라이버라 정상적으로 설치되었는지 확인하며, 이 때 'CUDA Version' 을 확인한다. 

<center><img src="assets\img\posts\2024-04-08-tensorflow_gpu_settingnvidiasmi.png" width="600"></center>

만약 본인 GPU CUDA 버전과 Tensorflow 가이드에 명시된 버젼이 맞다면 해당 버젼에 맞게 모든 설정을 조정하면 된다. 그러나 내 경우와 같이 아직 해당 버젼이 지원하지 않는 경우, 낮춰 모든 설정을 적용해야 한다. 내 경우는 CUDA 11.2 로 적용하였다. 

#### 2. CUDA Tookit & cuDNN 설치

아래 링크에서  CUDA Tookit 을 받아 설치한다. 
[CUDA Tookit 11.2 Downlaods](https://developer.nvidia.com/cuda-11.2.0-download-archive) 

상위 버전의 경우, 필요한 경우 함께  visual studio 를 설치지만, 해당 버젼은 별도로 설치 해주어야 한다. 해당 버전에 맞는 visual studio 는 2019 로 아래 링크에서 다운로드 받아 추가 설치해야 한다. 
[Visual Studio 2019 Download](https://visualstudio.microsoft.com/ko/vs/older-downloads/)

그리고 아래 링크에서 본인에게 맞는 버전의 cuDNN 을 다운 받는다. 
[cuDNN download](https://developer.nvidia.com/rdp/cudnn-archive) 

내 경우, 아래 버젼으로 받아 설치하였다. 

<center><img src="assets\img\posts\2024-04-08-tensorflow_gpu_setting_cudnn.png" width="600"></center>

해당 파일을 받아 압축을 풀고 내부 파일들을 모두 복사하여, CUDA Toolkit 이 설치된 폴더 ( C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.2)에 붙여 넣는다. 

#### 3. 환경변수 설정

앞에서 설치한 CUDA Toolkit 이 정상적으로 설치되었는지 확인과 함께 환경 변수 경로를 추가 해준다.
작업표시줄 검색창에서 "환경 변수" 를 검색하여 시스템 환경 변수 편집을 찾아 들어간다. 환경변수 버튼을 눌러서 들어가면 아래와 같이 창이 나오는데 여기에서 시스템 변수로 'CUDA_PATH' 와 'CUDA_PATH_해당버전' 이 포함되어 있어야 한다. 

<center><img src="assets\img\posts\2024-04-08-tensorflow_gpu_setting_env1.png" width="400"></center>

(다음 작업은 필요한지 잘 모르겠다.)
추가로 사용자 변수 - Path 에 아래와 같이 CUDA Toolkit  설치 경로에 bin, include, lib 폴더 경로를 추가한다. 

<center><img src="assets\img\posts\2024-04-08-tensorflow_gpu_setting_env2.png" width="500"></center>

#### 4. 아나콘다 내 가상환경 설정 및 tensorflow-gpu 설치

아나콘다를 최신 버전으로 설치하고, Anaconda Prompt 를 실행한다. 
여기서 가상환경을 추가할 때 phython 버젼을 앞에서 확인한 tensorflow-gpu 지원 버전을 설치한다. 내 경우는 3.10 으로 설치하여 진행하였다.

```bash
conda create -n [가상환경 이름] python=3.10
```

이후 해당 가상환경을 활성화 한다. 

```bash
conda activate [가상환경이름]
```

그리고 tensorflow-gpu 를 홈페이지에서 확인한 버전으로 설치해 준다.

```bash
pip install tensorflow-gpu==2.10
```

기타 필요한 라이브러리들을 설치하고, jupyter notebook 을 실행하기 위한 notebook 을 설치하고 jupyter notebook 을 실행한다.

```bash
pip install notebook
...
jupyter notebook
```

#### 5. jupyter 에서 tensorflow-gpu 정상 작동 확인

jupyter 커널에서 새 notebook 을 실행하여 아래 code 를 입력하여 gpu 가 정상적으로 연결되었는지를 확인한다. 

```bash
from tensorflow.python.client import device_lib
print(device_lib.list_local_devices())
```

코드를 실행하면 아래와 같이 출력되는데, 만약 GPU 연결이 되지 않았다면, CPU 정보만 출력되고, GPU 관련 정보는 출력되지 않는다. 

<center><img src="assets\img\posts\2024-04-08-tensorflow_gpu_setting_ju.png" width="600"></center>

만약 여기에서 CPU 만 잡힌 상태라면, 앞의 과정에서 무언가 잘못되었다는 의미이므로 다시 작업해야 한다. (개인적으로도 해당 설치까지 여러번 반복하였으며, 타 블로그 글에도 수차례 실패했다는 글이 많다.)

최종적으로 성공했다면, 이제 GPU 실행 환경으로 설정하고 사용하면 된다. 우측 상단에 'Python 3(ipkernel)' 로 되어 있다면 클릭해서 본인이 생성한 가상환겅 (ex. b2404) 로 선택하여 사용하면 된다.

<center><img src="assets\img\posts\2024-04-08-tensorflow_gpu_setting_ju1.png" width="600"></center>
---
layout: post
read_time: true
show_date: true
title:  Deep Q-Network + ML-agents 구현
date:   2024-05-03 09:32:20 +0900
description: Deep Q-Network + ML-agents 구현 

img: posts/general/post_general14.jpg
tags: [cuda, pytorch, unity, dqn, ml-agents]
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

* 해당 내용은 다음의 강의 내용을 개인적으로 재학습 하기 위해 작성됨. <br>
  [인프런 - 유니티 머신러닝 에이전트 완전정복 (기초편) | 민규식](https://www.inflearn.com/course/%EC%9C%A0%EB%8B%88%ED%8B%B0-%EB%A8%B8%EC%8B%A0%EB%9F%AC%EB%8B%9D-%EC%97%90%EC%9D%B4%EC%A0%84%ED%8A%B8-%EA%B8%B0%EC%B4%88)

* DQN 알고리즘의 전체 흐름

<center><img src="assets\img\posts\2024-05-03-DQN_ml_agents\0.png" width="600"></center>
[이미지 출처](https://www.inflearn.com/course/%EC%9C%A0%EB%8B%88%ED%8B%B0-%EB%A8%B8%EC%8B%A0%EB%9F%AC%EB%8B%9D-%EC%97%90%EC%9D%B4%EC%A0%84%ED%8A%B8-%EA%B8%B0%EC%B4%88)

### 0. 전체 코드 요약

전체 코드는 다음의 내용으로 구성된다. 

1. 프로그램 기본 설정
   * 필요한 파이썬 라이브러리 가져오기
   * 파라미터 설정
   * 유니티 연결 환경 설정
   * 학습된 모델 저장/불러오기
   * 연산장치 (CPU or GPU) 선택<br><br>


2. Deep Q-Network class 정의
   * Layer 구현 (입/출력, Convolution layer 정의)
   * 신경망 함수<br><br>


3. DQNAgent class 정의
   * Agent 구현 환경 정의(ex. network, optimizer, memory)
   * network 를 통한 action 선택 함수
   * replay memory 에 데이터 추가 함수 
   * network parameter 학습 시키는 함수
   * target_network update 함수
   * 모델 저장 함수
   * tensorboard 기록 함수  <br><br>


4. 프로그램 동작 구현 (main)
   * unity 와 상호 작용이 가능한  UnityEnvironment 인스턴스(env) 생성
   * env 로 부터 관측/target 공간 정보, step 진행 후 정보 및 구동 환경(time scale) 설정
   * 반복문을 통해  run_step + test_step 동안 학습을 진행시킴
     - (run_step 마지막 단계에서 모델을 저장하고 test_mode 로 전환)
     - 전처리: 시각적 관측 정보와 목적지 관측 정보를 전처리하여 state 로 저장
     - agent 를 통해 action 을 결정하고, 해당 action 으로 unity 에서 다음 step 을 진행시킴
     - 진행된 현재 step 정보 가져옴
     - 종료(termination) 확인 및 next_step -> next_state 정보로 전처리 
     - (train mode 일 경우) next_state 를 replay memory 에 저장
     - 충분히 메모리에 state 정보가 차 있다면, 모델 학습으로 손실값을 계산하고, 일정 주기로 target_model 을 update 함.
     - episode 종료 시, 필요한 설정값을 조정하고, tensorboard 에 보상/손실 값을 기록, 필요 조건마다 훈련된 모델 저장 

### 1. 프로그램 기본 설정
#### 1.1 필요한 파이썬 라이브러리 가져오기

```python
import numpy as np
import random
import copy
import datetime
import platform # system (OS) 관련
import torch
import torch.nn.functional as F
from troch.utils.tensorboard import SummaryWriter
from collections import deque
from mlagetns_envs.environment import UnityEnvironment, ActionTuple # (1)
from malagents_envs.side_channel.engine_configuration_channel import EngineConfigurationChannel # (2)
```
(1) 유니티 환경 클래스, 액션을 환경에 전달하기 위한 환경 객체 <br>
(2) 유니티 환경 조건을 조정하기 위한 라이브러리 (ex. 타임 스케일 조절)

#### 1.2 파라미터 설정

```python
state_size = [3*2, 64, 84] # goal-plus RGB + goal-ex RGB => 6 채널 * h * w (아래 이미지 참조)
action_size = 4 # 오른쪽, 왼쪽, 위, 아래

load_model = False # 모델 불러오기 여부
train_mode = True  # 모델 학습 여부 (True : 학습모드, False: 평가모드)

batch_size = 32
mem_maxlen = 10000  # replay memory 최대 크기
discount_factor = 0.9 # 미래에 대한 보상 감가율
learning_rate = 0.00025 # 네트워크 학습률

run_step = 50000 if train_mode else 0 # 학습모드에서 진행할 스텝 수 설정 (평가 모드 = 0)
test_step = 5000         # 평가 모드에서 진행할 스텝 수
train_start_step = 5000  # 학습 시작 전에 리플레이 메모리에 충분한 데이터를 모으기 위해 몇 스텝동안 임의의 행동으로 게임 진행할 것인지 설정
target_update_step = 500 # 타겟 네트워크를 몇 스텝 주기로 업데이트 할지 설정

print_interval = 10     # 학습 진행 상황을 텐서보드에 기록할 주기
save_interval = 100     # 학습 모델을 저장할 에피스드 주기 설정

epsilon_eval = 0.05     # 평가모드의 eps 값
epsilon_init = 1.0 if train_mode else epsilon_eval # eps 초기값
epsilon_min = 0.1       # 학습구간에서의 eps 최소값
explore_step = run_step * 0.8 # eps 이 감소되는 구간
eplsilon_data = (epsilon_init - epsilon_min) / explore_step if train_mode else 0.05
                        # 한스텝당 감소하는 eps 변화량

# 다음의 파라미터 값들은 실제 데이터를 가리키는 인덱스, 즉 enum 과 유사한 개념으로 사용됨.
VISUAL_OBS = 0  # 시각적 관측 데이터. 에이전트가 이미지 형태로 관측하는 정보를 가리키는 인덱스 
GOAL_OBS = 1    # 목적지 관측 데이터. 에이전트가 목표를 달성하는데 필요한 정포를 가리키는 인덱스
VECTOR_OBS = 2  # 수치적 관측 인덱스. 에이전트가 벡터 형태로 관측하는 정보를 가리키는 인덱스
OBS = VISUAL_OBS # DQN 에서는 시각적 관측 인덱스를 사용
```

* state_size = [3*2, 64, 84] 관련 이미지 

<center><img src="assets\img\posts\2024-05-03-DQN_ml_agents\1.png" width="600"></center>
[이미지 출처](https://www.inflearn.com/course/%EC%9C%A0%EB%8B%88%ED%8B%B0-%EB%A8%B8%EC%8B%A0%EB%9F%AC%EB%8B%9D-%EC%97%90%EC%9D%B4%EC%A0%84%ED%8A%B8-%EA%B8%B0%EC%B4%88)

* epsilon-greedy 를 적용한 학습에서 각 파라미터들의 사용 그래프
<center><img src="assets\img\posts\2024-05-03-DQN_ml_agents\2.png" width="600"></center>
[이미지 출처](https://www.inflearn.com/course/%EC%9C%A0%EB%8B%88%ED%8B%B0-%EB%A8%B8%EC%8B%A0%EB%9F%AC%EB%8B%9D-%EC%97%90%EC%9D%B4%EC%A0%84%ED%8A%B8-%EA%B8%B0%EC%B4%88)


#### 1.3 유니티 연결 환경 설정

```python
game = "GridWorld"          # 환경 빌드명 
os_name = platform.system() # 현재 사용 OS
if os_name == 'Windows':
    env_name = f"../envs/{game}_{os_name}/{game}" # 불러올 유니티 환경 경로
elif os_name == 'Darwin': # Mac OS
    env_name = f"../envs/{game}_{os_name}"

```

#### 1.4 학습된 모델 저장/불러오기

```python
date_time = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
save_path = f"./saved_models/{game}/DQN/{date_time}" # 모델 파일일 저장될 경로
load_path = f"./saved_models/{game}/DQN/20240503201212" # 불러올 모델 파일 경로
```

#### 1.5 연산장치 (CPU or GPU) 선택

```python
device = torch.device("cuda" if torch.cuda.is_available() else "cpu") # 연산 장치 (CPU or GPU)
```

### 2. Deep Q-Network class 정의

```python
class DQN(torch.nn.Module):
    # 2.1 Layer 구현 (입/출력, Convolution layer 정의)
    def __init__(self, **kwargs):
        super(DQN, self).__init__(**kwargs)
        self.conv1 = torch.nn.Conv2d(
            in_channels=state_size[0], out_channels=32, kernel_size=8, stride=4
            )
        dim1 = ((state_size[1] - 8)//4 + 1, (state_size[2] - 8)//4 + 1)
        
        self.conv2 = torch.nn.Conv2d(
            in_channels=32, out_channels=64, kernel_size=4, stride=2
            )
        dim2 = ((dim1[0] - 4)//2 + 1, (dim1[1] - 4)//2 + 1)
        
        self.conv3 = torch.nn.Conv2d(
            in_channels=64, out_channels=64, kernel_size=3, stride=1
            )
        dim3 = ((dim2[0] - 3)//1 + 1, (dim2[1] - 3)//1 + 1)

        self.flat = torch.nn.Flatten() # 전체 텐서를 1차원을 변환
        self.fc1 = torch.nn.Linear(64*dim3[0]*dim3[1], 512) # 완전 연결 레이어를 만들어 주기 위함. 
        self.q = torch.nn.Linear(512, action_size)

    # 2.2 신경망 함수
    def forward(self, x):
        x = x.permute(0, 3, 1, 2) # 데이터 차원 순서  변환 input : unity data (H, W, Ch) -> pytorch data (Ch, H, W)
        x = F.relu(self.conv1(x))
        x = F.relu(self.conv2(x))
        x = F.relu(self.conv3(x))
        x = self.flat(x)
        x = F.relu(self.fc1(x))
        return self.q(x)

```
#### 2.1 Layer 구현 (입/출력, Convolution layer 정의)

ML-Agents 를 사용하여 unity 부터 상태 정보를 받을 때, agent 에 설정된 카메라를 통한 이미지를 받아 사용하거나, 해당 환경에서의 좌표값 (vector) 값을 사용할 수 있다. 해당 모델에서는 이미지를 사용하여 처리할 것이므로, 이미지 처리에 적합한 convolution layer 를 사용하여 처리하는 것으로 구현되었다. 

 * convolution layer + flattent layer + linear layer 의 연결 이미지
<center><img src="assets\img\posts\2024-05-03-DQN_ml_agents\3.png" width="600"></center>
[이미지 출처](https://www.inflearn.com/course/%EC%9C%A0%EB%8B%88%ED%8B%B0-%EB%A8%B8%EC%8B%A0%EB%9F%AC%EB%8B%9D-%EC%97%90%EC%9D%B4%EC%A0%84%ED%8A%B8-%EA%B8%B0%EC%B4%88)

#### 2.2 신경망 함수

일반적으로 PyTorch 에서 신경망 모델 구현 클래스는 torch.nn.Module 을 상속받아 사용한다. 해당 부모 class 에 `__call__` 메서드 상 정의에 의해 해당 class 명으로 요청 (ex. `DQN()`)시 `forward` 메서드가 실행 요청된다.  

 * 구현된 신경망 모델 개념도

<center><img src="assets\img\posts\2024-05-03-DQN_ml_agents\4.png" width="600"></center>
[이미지 출처](https://www.inflearn.com/course/%EC%9C%A0%EB%8B%88%ED%8B%B0-%EB%A8%B8%EC%8B%A0%EB%9F%AC%EB%8B%9D-%EC%97%90%EC%9D%B4%EC%A0%84%ED%8A%B8-%EA%B8%B0%EC%B4%88)


### 3. DQNAgent class 정의

```python
class DQNAgent:
    # 3.1 Agent 구현 환경 정의(ex. network, optimizer, memory)
    def __init__(self):
        self.network = DQN().to(device)
        self.target_network = copy.deepcopy(self.network)
        self.optimizer = torch.optim.Adam(self.network.parameters(), lr=learning_rate)
        self.memory = deque(maxlen=mem_maxlen)
        self.epsilon = epsilon_init
        self.writer = SummaryWriter(save_path)

        if load_model == True: 
            print(f"... Load Model from {load_path}/ckpt")
            checkpoint = torch.load(load_path+'/ckpt', map_location=device) 
            self.network.load_state_dict(checkpoint["network"])
            self.target_network.load_state_dict(checkpoint["network"])
            self.optimizer.load_state_dict(checkpoint["optimizer"])

    # 3.2 network 를 통한 action 선택 함수
    def get_action(self, state, training=True):

        self.network.train(training) 
        epsilon = self.epsilon if training else epsilon_eval

        if epsilon > random.random():
            action = np.random.randint(0, action_size, size=(state.shape[0], 1)) 
        else:
            q = self.network(torch.FloatTensor(state).to(device))
            action = torch.argmax(q, axis=-1, keepdim=True).data.cpu().numpy() 
        return action
        
    # 3.3 replay memory 에 데이터 추가 함수
    def append_sample(self, state, action, reward, next_state, done):
        self.memory.append((state, action, reward, next_state, done))

    # 3.4 network parameter 학습 시키는 함수
    def train_model(self):
        batch = random.sample(self.memory, batch_size)
        state = np.stack([b[0] for b  in batch], axis=0)
        action = np.stack([b[1] for b  in batch], axis=0)
        reward = np.stack([b[2] for b  in batch], axis=0)
        next_state = np.stack([b[3] for b  in batch], axis=0)
        done = np.stack([b[4] for b  in batch], axis=0)

        state, action, reward, next_state, done = map(
            lambda x: torch.FloatTensor(x).to(device), [state, action, reward, next_state, done]
        )

        eye = torch.eye(action_size).to(device)
        one_hot_action = eye[action.view(-1).long()] 

        q = (self.network(state) * one_hot_action).sum(1, keepdims=True)

        with torch.no_grad():
            next_q = self.target_network(next_state)
            target_q = reward + next_q.max(1, keepdims=True).values * ((1 - done) * discount_factor)

        loss = F.smooth_l1_loss(q, target_q)
 
        self.optimizer.zero_grad()  
        loss.backward()             
        self.optimizer.step()      
        self.epsilon = max(epsilon_min, self.epsilon - eplsilon_data)

        return loss.item()
    
    # 3.5 target_network update 함수
    def update_target(self):
        self.target_network.load_state_dict(self.network.state_dict())

    # 모델 저장 함수
    def save_model(self):
        print(f"... Save Model to {save_path}/ckpt ...")
        torch.save({
            "network" : self.network.state_dict(),   
            "optimizer" : self.optimizer.state_dict(),
        }, save_path+'/ckpt')

    # tesorboard 기록 
    def write_summary(self, score, loss, epsilon, step):
        self.writer.add_scalar("run/score", score, step)
        self.writer.add_scalar("model/loss", loss, step)
        self.writer.add_scalar("model/epsilon", epsilon, step)
```

#### 3.1 Agent 구현 환경 정의(ex. network, optimizer, memory)

```python
    def __init__(self):
        self.network = DQN().to(device) # (1)
        self.target_network = copy.deepcopy(self.network) # (2)
        self.optimizer = torch.optim.Adam(self.network.parameters(), lr=learning_rate)
        self.memory = deque(maxlen=mem_maxlen) # (3)
        self.epsilon = epsilon_init # (4)
        self.writer = SummaryWriter(save_path)

        if load_model == True: # (5)
            print(f"... Load Model from {load_path}/ckpt")
            checkpoint = torch.load(load_path+'/ckpt', map_location=device) 
            self.network.load_state_dict(checkpoint["network"])
            self.target_network.load_state_dict(checkpoint["network"])
            self.optimizer.load_state_dict(checkpoint["optimizer"])
```

(1) self.network = DQN().to(device)<br>
    훈련에 사용할 network 를 DQN 인스턴스를 생성하여 연산 device 메모리에 넣는다. 

(2) self.target_network = copy.deepcopy(self.network)<br>
    초기 Target_network 설정은 훈련용과 동일하게 설정되므로 그대로 깊은 복사하여 사용

(3) self.memory = deque(maxlen=mem_maxlen) <br>
    replay memory 로 사용될 자료 구조는 FIFO 구조인 deque 를 사용

(4) self.epsilon = epsilon_init<br>
    초기 설정 epsilon 값으로 사용되며, 훈련이 반복되면서 앞에서 언급된 그래프의 형태와 같이 epsilon 값을 작게 하여 무작위 요소를 점차 줄여 나간다. 

(5) if load_model == True:<br>
    만약 기존에 저장된 model 을 사용하고자 할 경우, 해당 조건문 실행으로 기존 모델을 가져와서 실행

#### 3.2 network 를 통한 action 선택 함수

```python
    def get_action(self, state, training=True):

        self.network.train(training) 
        epsilon = self.epsilon if training else epsilon_eval

        if epsilon > random.random():
            action = np.random.randint(0, action_size, size=(state.shape[0], 1)) 
        else:
            q = self.network(torch.FloatTensor(state).to(device))
            action = torch.argmax(q, axis=-1, keepdim=True).data.cpu().numpy() 
        return action
```

다음과 같이 epsilon-greedy 방법을 사용하여 무작위 값 또는 가장 큰 q값을 가진 idx 행동을 선택 

<center><img src="assets\img\posts\2024-05-03-DQN_ml_agents\5.png" width="400"></center>
[이미지 출처](https://www.inflearn.com/course/%EC%9C%A0%EB%8B%88%ED%8B%B0-%EB%A8%B8%EC%8B%A0%EB%9F%AC%EB%8B%9D-%EC%97%90%EC%9D%B4%EC%A0%84%ED%8A%B8-%EA%B8%B0%EC%B4%88)


#### 3.3 replay memory 에 데이터 추가 함수

```python
    def append_sample(self, state, action, reward, next_state, done):
        self.memory.append((state, action, reward, next_state, done))
```

replay momory 에 각 상태 값들을 추가


#### 3.4 network parameter 학습 시키는 함수

```python
def train_model(self):
        batch = random.sample(self.memory, batch_size) # (1)
        state = np.stack([b[0] for b  in batch], axis=0) # (2)
        action = np.stack([b[1] for b  in batch], axis=0)
        reward = np.stack([b[2] for b  in batch], axis=0)
        next_state = np.stack([b[3] for b  in batch], axis=0)
        done = np.stack([b[4] for b  in batch], axis=0)

        state, action, reward, next_state, done = map(
            lambda x: torch.FloatTensor(x).to(device), [state, action, reward, next_state, done]
        ) # (3)

        eye = torch.eye(action_size).to(device) # (4)
        one_hot_action = eye[action.view(-1).long()] # (5) 

        q = (self.network(state) * one_hot_action).sum(1, keepdims=True) # (6)

        with torch.no_grad(): # (7)
            next_q = self.target_network(next_state) # (8)
            target_q = reward + next_q.max(1, keepdims=True).values * ((1 - done) * discount_factor) #(9)

        loss = F.smooth_l1_loss(q, target_q) # (10)

        # model update
        self.optimizer.zero_grad()  # 기울기 초기화
        loss.backward()             # 역전파를 통해 gradient 계산
        self.optimizer.step()       # model parameter update
        # eps 감소 (훈련이 진행됨에 따라 무작위 적용 확률를 차츰 줄여나감)
        self.epsilon = max(epsilon_min, self.epsilon - eplsilon_data) 

        return loss.item()
```

(1) batch = random.sample(self.memory, batch_size)<br>
replay memory 에 저장된 값들 중 임의의 값을 가져옴으로써, 가져오는 데이터들 간 상관 관계가 존재하지 않게되어, 과적합 또는 선형 근사가 발생하는것을 방지 한다. 

아래 이미지는 하나의 episode 또는 근방에서 훈련된 step 간 동일 색으로 표현하였다. 그림과 같이 근방의 step 끼리 학습을 진행하면 전체 데이터에 대한 근사 함수가 아닌 각각에 근접한 step 에 대한 함수로 각각 근사되게 된다. 

<center><img src="assets\img\posts\2024-05-03-DQN_ml_agents\6.png" width="480"></center>
[이미지 출처](https://www.inflearn.com/course/%EC%9C%A0%EB%8B%88%ED%8B%B0-%EB%A8%B8%EC%8B%A0%EB%9F%AC%EB%8B%9D-%EC%97%90%EC%9D%B4%EC%A0%84%ED%8A%B8-%EA%B8%B0%EC%B4%88)

따라서 해당 문제를 막기 위해 한번에 학습되는 step 들을 무작위 분포에서 추출해야 아래와 같이 전체에 대한 근사함수를 얻을 수 있게 된다. 

<center><img src="assets\img\posts\2024-05-03-DQN_ml_agents\7.png" width="220"></center>
[이미지 출처](https://www.inflearn.com/course/%EC%9C%A0%EB%8B%88%ED%8B%B0-%EB%A8%B8%EC%8B%A0%EB%9F%AC%EB%8B%9D-%EC%97%90%EC%9D%B4%EC%A0%84%ED%8A%B8-%EA%B8%B0%EC%B4%88)

(2) state = np.stack([b[0] for b  in batch], axis=0) <br>
추출된 batch 값에서 state, action, reward, next_state, done 값들을 각각의 array 값으로 추출한다. 

(3) state, action, reward, next_state, done = map(
            lambda x: torch.FloatTensor(x).to(device), [state, action, reward, next_state, done]
        ) <br>

각 상태값들의 array 값들을 실수형 tensor 로 타입 변환 후, device 메모리에 추가

(4) eye = torch.eye(action_size).to(device) <br>

주 대각선 값 1, 나머지 요소는 0인 2차원 배열 (4 * 4 (action_size))을 생성하여 device 메모리에 추가

(5) one_hot_action = eye[action.view(-1).long()] <br>

action [0, 2, 3, 2, 1, 1, ...] (0~3) 의 값 * 32 np array 에서 각각의 원소를 long 형 (int64) one_hot type * 32 형 으로 변경 한다. 
즉 [0, 2, 3, 2, 1, 1, ...]  -> [[1, 0, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1], [0, 0, 0, 1], ....]

(6) q = (self.network(state) * one_hot_action).sum(1, keepdims=True)<br>

현재 상태에 대한 모델 q값 * one_hot_action = 선택된 action 에 대한 Q(x) 값 이외 값은 0 으로 변환하여 각 q값 ([32.334, 0, 0, 0]) 과 같은 형태에서 ([[\32.334]]) 로변환하여 q에 저장한다. (즉, one_hot data 에서 0 인 부분은 모두 제거 한다.)

(7) with torch.no_grad(): <br>

loss 를 계산하기 위해서 target 값이 필요하지만, target 값에 대한 제어는 별도로 이루어지므로 target 값을 얻는 과정이 network 에 영향을 주어서는 안되므로 with  문 내부에서 torch.no_grad() (gradient 추적이 되지 않는) 상태에서 값을 얻는다.

(8) next_q = self.target_network(next_state) <br>

next_q : target network 을 이용하요 다음상태 s' 에대한 q 값들을 예측함.

(9) target_q = reward + next_q.max(1, keepdims=True).values * ((1 - done) * discount_factor) <br>

* .max(1, keepdims=True).values : (0 차원: batch , 1 차원, action) 에서 action 차원의 최대값을 가져옴
* (1 - done) : done == False 이면 1 True 이면 해당 값은 0 이 됨. 
* discount_factor : 감가율을 곱함. 

<center><img src="assets\img\posts\2024-05-03-DQN_ml_agents\10.png" width="370"></center>

즉 벨만 방정식 최적 q 를 얻는 공식  target_q = 보상값 + 감가율(다음 상태에서의 최대 Q(x)값) 을 구함 + 혹시 끝난 상태인 경우 0으로 만들어 주는 수식을 결합한 상태

(10) loss = F.smooth_l1_loss(q, target_q) <br>

Huber loss 계산 

<center><img src="assets\img\posts\2024-05-03-DQN_ml_agents\8.png" width="220"></center>

<center><img src="assets\img\posts\2024-05-03-DQN_ml_agents\9.png" width="280"></center>
[이미지 출처](https://www.inflearn.com/course/%EC%9C%A0%EB%8B%88%ED%8B%B0-%EB%A8%B8%EC%8B%A0%EB%9F%AC%EB%8B%9D-%EC%97%90%EC%9D%B4%EC%A0%84%ED%8A%B8-%EA%B8%B0%EC%B4%88)


#### 3.5 target_network update 함수

```python
    def update_target(self):
        self.target_network.load_state_dict(self.network.state_dict())
```

* self.network.state_dict() : 일반 (훈련) 네트워크를 가져옴
* self.target_network.load_state_dict() : 가져운 일반 네트워크를 target 네트워크로 저장

### 4. 프로그램 동작 구현 (main)

아래 도식의 동작을 구현

<center><img src="assets\img\posts\2024-05-03-DQN_ml_agents\11.png" width="600"></center>
[이미지 출처](https://www.inflearn.com/course/%EC%9C%A0%EB%8B%88%ED%8B%B0-%EB%A8%B8%EC%8B%A0%EB%9F%AC%EB%8B%9D-%EC%97%90%EC%9D%B4%EC%A0%84%ED%8A%B8-%EA%B8%B0%EC%B4%88)

```python
if __name__ == '__main__':
    # 4.1 unity 와 상호 작용이 가능한 UnityEnvironment 인스턴스(env) 생성
    engine_configuration_channel = EngineConfigurationChannel()
    env = UnityEnbironment(
        file_name=env_name, side_channels=[engine_configuration_channel]
    )
    env.reset()

    # 4.2 env 로 부터 관측/target 공간 정보, step 진행 후 정보 및 구동 환경(time scale) 설정
    behavior_name = list(env.behavior_specs.keys())[0]
    spec = env.behavior_specs[behavior_name]

    engine_configuration_channel.set_configuration_parameters(time_scale=12.0)
    dec, term = env.get_steps(behavior_name) 
    agent = DQNAgent()

    losses, scores, episode, score = [], [], 0, 0
    
    # 4.3 반복문을 통해 run_step + test_step 동안 학습을 진행시킴
    for step in range(run_step + test_step):
        # 4.3.1 (run_step 마지막 단계에서 모델을 저장하고 test_mode 로 전환)
        if step == run_step:
            if train_mode:
                agent.save_model()
            print("TEST START")
            train_mode = False
            engine_configuration_channel.set_configuration_parameters(time_scale=1.0) 

        # 4.3.2 전처리: 시각적 관측 정보와 목적지 관측 정보를 전처리하여 state 로 저장
        preprocess = lambda obs, goal: np.concatenate((obs*goal[0][0], obs*goal[0][1]), axis=-1)        
        
        state = preprocess(dec.obs[OBS], dec.obs[GOAL_OBS])

        # 4.3.3 agent 를 통해 action 을 결정하고, 해당 action 으로 unity 에서 다음 step 을 진행시킴
        action = agent.get_action(state, train_mode) 
        real_action = action + 1 
        action_tuple = ActionTuple() 
        action_tuple.add_discrete(real_action) 
        env.set_actions(behavior_name, action_tuple) 
        env.step() 

        # 4.3.4 진행된 현재 step 정보 가져옴
        dec, term = env.get_steps(behavior_name) 

        # 4.3.5 종료(termination) 확인 및 next_step -> next_state 정보로 전처리
        done = len(term.agent_id) > 0 
        reward = term.reward if done else dec.reward
        next_state = preprocess(term.obs[OBS], term.obs[GOAL_OBS]) if done \
            else preprocess(dec.obs[OBS], dec.obs[GOAL_OBS])
        score += reward[0] 

        # 4.3.6 (train mode 일 경우) next_state 를 replay memory 에 저장
        if train_mode:
            agent.append_sample(state[0], action[0], reward, next_state[0], [done])

        # 4.3.7 충분히 메모리에 state 정보가 차 있다면, 모델 학습으로 손실값을 계산하고, 일정 주기로 target_model 을 update 함.
        if train_mode and step > max(batch_size, train_start_step): 
            loss = agent.train_model()
            losses.append(loss)

            if step % target_update_step == 0:
                agent.update_target()

        # 4.3.8 episode 종료 시, 필요한 설정값을 조정하고, tensorboard 에 보상/손실 값을 기록, 필요 조건마다 훈련된 모델 저장
        if done:
            episode += 1
            scores.append(score)
            score = 0 

            if episode % print_interval == 0:
                mean_score = np.mean(scores)
                mean_loss = np.mean(losses)
                agent.write_summary(mean_score, mean_loss, agent.epsilon, step)
                losses, scores = [], []

                print(f"{episode} Episode / Step: {step} / Score: {mean_score:.2f} /" + \
                      f"Loss: {mean_loss:.4f} / Epsilon: {agent.epsilon:.4f}")            
            
            if train_mode and episode % save_interval == 0:
                agent.save_model()

    env.close()
```

#### 4.1 unity 와 상호 작용이 가능한 UnityEnvironment 인스턴스(env) 생성

```python
    engine_configuration_channel = EngineConfigurationChannel()
    env = UnityEnvironment(
        file_name=env_name, side_channels=[engine_configuration_channel]
    )
    env.reset()
```

env (UnityEnvironment 인스턴스)의 역할 및 기능

1. 유니티와의 인터페이스: UnityEnvironment는 유니티 엔진과 파이썬 코드 간의 주요 인터페이스. 이 인스턴스를 통해 유니티 게임 환경을 시작, 중지 및 관리할 수 있다.

2. 데이터 교환: 유니티 게임 환경에서 생성된 데이터(에이전트의 관측값, 보상 등)를 파이썬으로 전송하고, 파이썬에서 생성한 행동 지시를 유니티로 보내는 역할

3. 환경 제어: side_channels을 통해 유니티 환경의 세부적인 설정을 조정할 수 있다. 이를 통해 학습 중 시뮬레이션의 속도를 조절, 테스트 중에는 보다 정밀한 테스트를 수행 가능

* file_name=env_name : 유니티 게임 환경의  실행 파일 경로를 지정
* side_channels=[engine_configuration_channel] : 유니티 환경의 timescale, 해상도, 그래픽 품질 등을 수정할 때 사용

#### 4.2 env 로 부터 관측/target 공간 정보, step 진행 후 정보 및 구동 환경(time scale) 설정 (유니티 브레인 설정)

```python
    # 유니티 브레인 설정
    behavior_name = list(env.behavior_specs.keys())[0]
    # env.behavior_specs : 모든 behavior 정보 (예: 관측 공간의 크기, 행동의 유형 및 크기 등)를 가지고 있음. 
    # 해당 프로젝트에서는 behavior_sepc 중  behavior_name 만 있으면 된다. 해당 spec 은 첫번쩨 요소 이므로 [0] 의 값만 가져온다.
    
    spec = env.behavior_specs[behavior_name]
    # behavior_name 에 대한 spec 을 가져오며 관련 정보는 아래와 같다. 
    # 1. 관측 공간(Obervation Space) : 에이전트가 환경에서 관측할 수 있는 데이터의 형태와 크기를 설명
    #                                  카메라 이미지, 속도계의 값, 위치 좌표 등
    #
    # 2. 행동 공간(Action Space) : 에이전트가 취할 수 있는 행동의 유형과 범위
    #                             에이전트가 조종할 수 있는 방향, 속도 조절, 점프 등의 행동

    engine_configuration_channel.set_configuration_parameters(time_scale=12.0) # 시간 12 배속 (빠르게) 설정
    dec, term = env.get_steps(behavior_name) # behavior_name 으로 부터  step 정보를 얻음
    # dec : decision step - decision request step 정보
    # term : termination step - 에피소드 종료 스텝 정보

    # DQNAgent 클래스를 agent 객체 생성
    agent = DQNAgent()

    # c.0 학습을 진행하기 위해 필요한 정보 초기화
    losses, scores, episode, score = [], [], 0, 0
```

#### 4.3 반복문을 통해 run_step + test_step 동안 학습을 진행시킴

#### 4.3.1 (run_step 마지막 단계에서 모델을 저장하고 test_mode 로 전환)

```python
  for step in range(run_step + test_step):
    # run_step : 학습 모드 step
    # test_step: 테스트모드 step

        # test step 진행 코드
        if step == run_step:
            if train_mode:
                agent.save_model()
            print("TEST START")
            train_mode = False
            engine_configuration_channel.set_configuration_parameters(time_scale=1.0)  # test_step 은 정속으로 수행

```

#### 4.3.2 전처리: 시각적 관측 정보와 목적지 관측 정보를 전처리하여 state 로 저장

```python
        #  전처리 : 시각적 관측 정보와 목적지 관측 정보를 전처리하여 state 에 저장
        preprocess = lambda obs, goal: np.concatenate((obs*goal[0][0], obs*goal[0][1]), axis=-1)        
        # a. obs*goal[0][0] : agent 관즉 이미지 * goal[0][0] (goal_plus 이면 1, goal_ex 이면 0)
        # b. obs*goal[0][1] : agent 관측 이미지 * goal[0][1] (goal_plus 이면 0, goal_ex 이면 1)
        # 위 값을 concatenate
        #  ->  6 채널 중  goal_plus 의 경우 전반부 3 채널에 대해 값이 채워지고, 나머지 3채널에 대한 값은 모두 0 으로 처리
        #  ->  6 채널 중  goal_ex   의 경우 후반부 3 채널에 대해 값이 채워지고, 나머지 3채널에 대한 값은 모두 0 으로 처리
        
        state = preprocess(dec.obs[OBS], dec.obs[GOAL_OBS])
        # dec.obs : 지정된 behavior_name 을 가진 모든 agent 에 대한 모든 관측을 포함하는 튜플
        # dec.obs[0] (OBS = 0 시각적 관측 idx) : 로 시각적 관측 정보를 얻을 수 있음.
        # dec.obs[1] (GOAL_OBS = 1 (시각적) 목적지 관측 idx) : 로 목적지의 시각적 정보를 얻음.
        # dec.obs[GOAL_OBS] 에서  goal_plus : [[1., 0]] / goal_ex: [[0., 1.]]

```

#### 4.3.3 agent 를 통해 action 을 결정하고, 해당 action 으로 unity 에서 다음 step 을 진행시킴

```python
        action = agent.get_action(state, train_mode) # get_action 을 통해 현재 state 의 eps-greedy 행동 선택
        real_action = action + 1 # unity 에서 0 은 정지 action 을 의미하게 되므로 , 0 ~3  -> 1 ~ 4 로 +1
        action_tuple = ActionTuple() 
        action_tuple.add_discrete(real_action) # 신경망을 통해 결정된 action 값을 동작 값으로 저장 
        env.set_actions(behavior_name, action_tuple) # action 을 unity 환경에 전달
        env.step() # unity 에서 시뮬레이션 step 진행
```

#### 4.3.4 진행된 현재 step 정보 가져옴

```python
        dec, term = env.get_steps(behavior_name) # 진행한 현재 스텝 정보 가져오기
```

#### 4.3.5 종료(termination) 확인 및 next_step -> next_state 정보로 전처리

```python
        done = len(term.agent_id) > 0 # 현재 시뮬레이션은 agent 가 1개 이므로 termination agent_id 가 존재하면  종료되었음을 바로 확인 가능 
        reward = term.reward if done else dec.reward
        next_state = preprocess(term.obs[OBS], term.obs[GOAL_OBS]) if done \
            else preprocess(dec.obs[OBS], dec.obs[GOAL_OBS])
        score += reward[0] # step 보상 누적
```

#### 4.3.6 (train mode 일 경우) next_state 를 replay memory 에 저장

```python
        # replay memory 에  data 저장 (학습 모드)
        if train_mode:
            agent.append_sample(state[0], action[0], reward, next_state[0], [done])
```

#### 4.3.7 충분히 메모리에 state 정보가 차 있다면, 모델 학습으로 손실값을 계산하고, 일정 주기로 target_model 을 update 함.
```python
        if train_mode and step > max(batch_size, train_start_step): # 충분한 학습 데이터가 모였다면 (최소 batch_size 이상)
            # 학습수행
            loss = agent.train_model()
            losses.append(loss)

            # 타겟 네트워크 업데이트 (특정 수의 step 타이밍 마다)
            if step % target_update_step == 0:
                agent.update_target()

```

#### 4.3.8 episode 종료 시, 필요한 설정값을 조정하고, tensorboard 에 보상/손실 값을 기록, 필요 조건마다 훈련된 모델 저장

```python
        # episode 완료 시,
        if done:
            episode += 1
            scores.append(score)
            score = 0 # 초기화

            # 게임 진행 상황 출력 및 텐서 보드에 보상과 손실 함수 값 기록
            if episode % print_interval == 0:
                mean_score = np.mean(scores)
                mean_loss = np.mean(losses)
                agent.write_summary(mean_score, mean_loss, agent.epsilon, step)
                losses, scores = [], []

                print(f"{episode} Episode / Step: {step} / Score: {mean_score:.2f} /" + \
                      f"Loss: {mean_loss:.4f} / Epsilon: {agent.epsilon:.4f}")            
            

                
            # 네트워크 모델 저장
            if train_mode and episode % save_interval == 0:
                agent.save_model()
                
    env.close()
```

### 최종 전체 코드 

```python
import numpy as np
import random
import copy
import datetime
import platform # system (OS) 관련
import torch
import torch.nn.functional as F
from torch.utils.tensorboard import SummaryWriter
from collections import deque
from mlagents_envs.environment import UnityEnvironment, ActionTuple 
from mlagents_envs.side_channel.engine_configuration_channel import EngineConfigurationChannel 

state_size = [3*2, 64, 84] 
action_size = 4 

load_model = False 
train_mode = True  

batch_size = 32
mem_maxlen = 10000  
discount_factor = 0.9
learning_rate = 0.00025 

run_step = 50000 if train_mode else 0 
test_step = 5000       
train_start_step = 5000 
target_update_step = 500 

print_interval = 10     
save_interval = 100     

epsilon_eval = 0.05    
epsilon_init = 1.0 if train_mode else epsilon_eval 
epsilon_min = 0.1      
explore_step = run_step * 0.8 
eplsilon_data = (epsilon_init - epsilon_min) / explore_step if train_mode else 0.05

VISUAL_OBS = 0  
GOAL_OBS = 1   
VECTOR_OBS = 2  
OBS = VISUAL_OBS 

game = "GridWorld"          
os_name = platform.system() 
if os_name == 'Windows':
    env_name = f"../envs/{game}_{os_name}/{game}" 
elif os_name == 'Darwin': 
    env_name = f"../envs/{game}_{os_name}"

date_time = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
save_path = f"./saved_models/{game}/DQN/{date_time}" 
load_path = f"./saved_models/{game}/DQN/20240503201212" 

device = torch.device("cuda" if torch.cuda.is_available() else "cpu") 

class DQN(torch.nn.Module):
    def __init__(self, **kwargs):
        super(DQN, self).__init__(**kwargs)
        self.conv1 = torch.nn.Conv2d(
            in_channels=state_size[0], out_channels=32, kernel_size=8, stride=4
            )
        dim1 = ((state_size[1] - 8)//4 + 1, (state_size[2] - 8)//4 + 1)
        
        self.conv2 = torch.nn.Conv2d(
            in_channels=32, out_channels=64, kernel_size=4, stride=2
            )
        dim2 = ((dim1[0] - 4)//2 + 1, (dim1[1] - 4)//2 + 1)
        
        self.conv3 = torch.nn.Conv2d(
            in_channels=64, out_channels=64, kernel_size=3, stride=1
            )
        dim3 = ((dim2[0] - 3)//1 + 1, (dim2[1] - 3)//1 + 1)

        self.flat = torch.nn.Flatten() 
        self.fc1 = torch.nn.Linear(64*dim3[0]*dim3[1], 512)
        self.q = torch.nn.Linear(512, action_size)

    def forward(self, x):
        x = x.permute(0, 3, 1, 2) 
        x = F.relu(self.conv1(x))
        x = F.relu(self.conv2(x))
        x = F.relu(self.conv3(x))
        x = self.flat(x)
        x = F.relu(self.fc1(x))
        return self.q(x)

class DQNAgent:
    def __init__(self):
        self.network = DQN().to(device)
        self.target_network = copy.deepcopy(self.network)
        self.optimizer = torch.optim.Adam(self.network.parameters(), lr=learning_rate)
        self.memory = deque(maxlen=mem_maxlen)
        self.epsilon = epsilon_init
        self.writer = SummaryWriter(save_path)

        if load_model == True: 
            print(f"... Load Model from {load_path}/ckpt")
            checkpoint = torch.load(load_path+'/ckpt', map_location=device) 
            self.network.load_state_dict(checkpoint["network"])
            self.target_network.load_state_dict(checkpoint["network"])
            self.optimizer.load_state_dict(checkpoint["optimizer"])

    def get_action(self, state, training=True):

        self.network.train(training) 
        epsilon = self.epsilon if training else epsilon_eval

        if epsilon > random.random():
            action = np.random.randint(0, action_size, size=(state.shape[0], 1)) 
        else:
            q = self.network(torch.FloatTensor(state).to(device))
            action = torch.argmax(q, axis=-1, keepdim=True).data.cpu().numpy() 
        return action
        
    def append_sample(self, state, action, reward, next_state, done):
        self.memory.append((state, action, reward, next_state, done))

    def train_model(self):
        batch = random.sample(self.memory, batch_size)
        state = np.stack([b[0] for b  in batch], axis=0)
        action = np.stack([b[1] for b  in batch], axis=0)
        reward = np.stack([b[2] for b  in batch], axis=0)
        next_state = np.stack([b[3] for b  in batch], axis=0)
        done = np.stack([b[4] for b  in batch], axis=0)

        state, action, reward, next_state, done = map(
            lambda x: torch.FloatTensor(x).to(device), [state, action, reward, next_state, done]
        )

        eye = torch.eye(action_size).to(device)
        one_hot_action = eye[action.view(-1).long()] 

        q = (self.network(state) * one_hot_action).sum(1, keepdims=True)

        with torch.no_grad():
            next_q = self.target_network(next_state)
            target_q = reward + next_q.max(1, keepdims=True).values * ((1 - done) * discount_factor)

        loss = F.smooth_l1_loss(q, target_q)
 
        self.optimizer.zero_grad()  
        loss.backward()             
        self.optimizer.step()      
        self.epsilon = max(epsilon_min, self.epsilon - eplsilon_data)

        return loss.item()
    
    def update_target(self):
        self.target_network.load_state_dict(self.network.state_dict())

    def save_model(self):
        print(f"... Save Model to {save_path}/ckpt ...")
        torch.save({
            "network" : self.network.state_dict(),   
            "optimizer" : self.optimizer.state_dict(),
        }, save_path+'/ckpt')

    def write_summary(self, score, loss, epsilon, step):
        self.writer.add_scalar("run/score", score, step)
        self.writer.add_scalar("model/loss", loss, step)
        self.writer.add_scalar("model/epsilon", epsilon, step)

if __name__ == '__main__':
    engine_configuration_channel = EngineConfigurationChannel()
    env = UnityEnbironment(
        file_name=env_name, side_channels=[engine_configuration_channel]
    )
    env.reset()


    behavior_name = list(env.behavior_specs.keys())[0]
    spec = env.behavior_specs[behavior_name]

    engine_configuration_channel.set_configuration_parameters(time_scale=12.0)
    dec, term = env.get_steps(behavior_name) 
    agent = DQNAgent()

    losses, scores, episode, score = [], [], 0, 0
    
    for step in range(run_step + test_step):
        if step == run_step:
            if train_mode:
                agent.save_model()
            print("TEST START")
            train_mode = False
            engine_configuration_channel.set_configuration_parameters(time_scale=1.0) 

        preprocess = lambda obs, goal: np.concatenate((obs*goal[0][0], obs*goal[0][1]), axis=-1)        
        
        state = preprocess(dec.obs[OBS], dec.obs[GOAL_OBS])

        action = agent.get_action(state, train_mode) 
        real_action = action + 1 
        action_tuple = ActionTuple() 
        action_tuple.add_discrete(real_action) 
        env.set_actions(behavior_name, action_tuple) 
        env.step() 

        dec, term = env.get_steps(behavior_name) 
        done = len(term.agent_id) > 0 
        reward = term.reward if done else dec.reward
        next_state = preprocess(term.obs[OBS], term.obs[GOAL_OBS]) if done \
            else preprocess(dec.obs[OBS], dec.obs[GOAL_OBS])
        score += reward[0] 

        if train_mode:
            agent.append_sample(state[0], action[0], reward, next_state[0], [done])

        if train_mode and step > max(batch_size, train_start_step): 
            loss = agent.train_model()
            losses.append(loss)

            if step % target_update_step == 0:
                agent.update_target()

        if done:
            episode += 1
            scores.append(score)
            score = 0 

            if episode % print_interval == 0:
                mean_score = np.mean(scores)
                mean_loss = np.mean(losses)
                agent.write_summary(mean_score, mean_loss, agent.epsilon, step)
                losses, scores = [], []

                print(f"{episode} Episode / Step: {step} / Score: {mean_score:.2f} /" + \
                      f"Loss: {mean_loss:.4f} / Epsilon: {agent.epsilon:.4f}")            
            
            if train_mode and episode % save_interval == 0:
                agent.save_model()

    env.close()
```


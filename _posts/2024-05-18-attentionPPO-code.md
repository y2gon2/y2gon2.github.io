---
layout: post
read_time: true
show_date: true
title:  ML-agents - AttentionPPO code
date:   2024-05-18 09:32:20 +0900
description: ML-agents - AttentionPPO code

img: posts/general/post_general20.jpg
tags: [transformer, attention, embedding, ppo, ml-agents]
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

* 해당 내용은 다음의 강의 및 책 내용을 개인적으로 재학습 하기 위해 작성됨. <br>
  [인프런 - 유니티 머신러닝 에이전트 완전정복 (응용편) ](https://www.inflearn.com/course/%EC%9C%A0%EB%8B%88%ED%8B%B0-%EB%A8%B8%EC%8B%A0%EB%9F%AC%EB%8B%9D-%EC%97%90%EC%9D%B4%EC%A0%84%ED%8A%B8-%EC%9D%91%EC%9A%A9/dashboard)<br>

### 1. code 개요

이전에 작성된 ML-Agents PPO code [link](https://y2gon2.github.io/PPO2_code.html) 에서 network input data (state) 의 종류의 구분 없이 넣어 주었다. 그러나 해당 코드에서는 Agent 속도 값과 ray 에 의해 관측된 일정 거리 안에 존재하는 물체 (공 or 벽) 에 대해서 다르게 처리한 이후, 이를 통합 PPO 알고리즘을 처리한다. 특히  ray 관측 정보의 경우, trasformer encoding layer 를 사용하여 주목해야 하는 물체에 집중도를 높여 attention output 을 얻는다. 이후, 핻아 정보를 합한 PPO network 를 통해 다음 행동을 결정하도록 구성되었다. 

​<center><img src="assets\img\posts\2024-05-18-attentionPPO-code\1.png" width="600"></center>

아울러 기존 PPO code 에서 변경된 부분 위주로 설명을 추가하였으며, 동일한 부분은 ML-Agents PPO code [link](https://y2gon2.github.io/PPO2_code.html) 참고


### 2. (추가 또는 수정) 파라미터

```python
vel_state_size = 2  # agent 속도 (x, z)
ray_chan_size = 40  # ray 최대 개수 
ray_feat_size = 4   # ray 1개당 정보 크기 (감지된 물체의 x, z 좌표, x, z 속도)
action_size = 5

RAY_OBS = 0         # 환경으로부터 Observation 벡터에서 Ray 정보가 담긴 index
VEL_OBS = 1         # 환경으로부터 Observation 벡터에서 Agent 의 속도 정보가 담긴 index

# attention parameters

# Transformer Encoder Layer 에서 사용할 입력 피쳐 (attention incodingd 입력 ebedding 크기)
# feedforward model  피쳐 크기로도 사용
embed_size = 32     

# Transformer Encoder Layer 에서 MultiHeadAttention  모델의 Head 갯수
num_heads = 4
```

### 3. AttentionActorCritic Class

```python
class AttentionActorCritic(torch.nn.Module):
    def __init__(self, **kwargs):
        super(AttentionActorCritic, self).__init__(**kwargs)
        self.attn_in = torch.nn.Linear(ray_feat_size, embed_size)
        self.attn_layer = torch.nn.TransformerEncoderLayer(
            d_model=embed_size, 
            nhead=num_heads, 
            batch_first=True,
            dim_feedforward=embed_size, 
            dropout=0
        )
        self.attn_out = torch.nn.Linear(ray_chan_size * embed_size, 128)

        self.e = torch.nn.Linear(vel_state_size, 128)
        self.d1 = torch.nn.Linear(256, 128)
        self.d2 = torch.nn.Linear(128, 128)
        self.pi = torch.nn.Linear(128, action_size)
        self.v = torch.nn.Linear(128, 1)

    def forward(self, state):
        ray, vel = torch.split(state, ray_chan_size * ray_feat_size, dim=1) # (1)

        b = ray.shape[0] 
        ray = ray.reshape(b * ray_chan_size, ray_feat_size) # (2)
        attn_in = self.attn_in(ray).reshape(b, ray_chan_size, embed_size) # (3)
        attn_out = self.attn_layer(attn_in) # (4)

        ray_embed = F.relu(self.attn_out(attn_out.reshape(b, -1))) # (5)
        vel_embed = F.relu(self.e(vel)) # (6)

        x = torch.cat((vel_embed, ray_embed), dim=1) # (7)
        x = F.relu(self.d1(x)) # (8)
        x = F.relu(self.d2(x)) # (9)

        return F.softmax(self.pi(x), dim=-1), self.v(x) # (10)
```
​<center><img src="assets\img\posts\2024-05-18-attentionPPO-code\2.png" width="750"></center>
  [이미지 출처](https://www.inflearn.com/course/%EC%9C%A0%EB%8B%88%ED%8B%B0-%EB%A8%B8%EC%8B%A0%EB%9F%AC%EB%8B%9D-%EC%97%90%EC%9D%B4%EC%A0%84%ED%8A%B8-%EC%9D%91%EC%9A%A9/dashboard)


### 4. (추가 또는 수정) AttentionPPOAgent Class

해당 클래스의 경우, network class 명칭을 제외하고 PPO 코드와 동일 [link](https://y2gon2.github.io/PPO2_code.html)


### 5. (추가 또는 수정) main

```python
# ---------//--------
 for step in range(run_step + test_step):
        if step == run_step:
            if train_mode:
                agent.save_model()
            print("TEST START")
            train_mode = False
            engine_configuration_channel.set_configuration_parameters(time_scale=1.0)

        preprocess = lambda ray, vel: np.concatenate((ray.reshape(-1, ray_chan_size * ray_feat_size), vel), axis=1) # (1)
        state = preprocess(dec.obs[RAY_OBS], dec.obs[VEL_OBS])
        action = agent.get_action(state, train_mode)
        action_tuple = ActionTuple()
        action_tuple.add_discrete(action)
        env.set_actions(behavior_name, action_tuple)
        env.step()

        # 환경으로부터 얻는 정보
        dec, term = env.get_steps(behavior_name)
        done = [False] * num_worker
        next_state = preprocess(dec.obs[RAY_OBS], dec.obs[VEL_OBS])
        reward = dec.reward

        if len(term):
            next_term_state = preprocess(term.obs[RAY_OBS], term.obs[VEL_OBS])

        for id in term.agent_id:
            _id = list(term.agent_id).index(id)
            done[id] = True
            next_state[id] = next_term_state[_id]
            reward[id] = term.reward[_id]

        score += reward[0]
# ---------//--------
```

(1) state, next_state 를 유니티로부터 받아왔을 때, 기존 PPO 에서는 모든 observation 요소 들을 동일하게 network 에 입력값으로 사용되었으나, Attention-PPO 에서는 ray 정보와 (agent) vel 정보를 명시적으로 받아서 network 에 입력되는 형태로 정리 해주어야 한다. 따라서, 전처리 과정으로 해당 data 를 받아 순서대로 concatenate 처리 해준다. 

아울러 이와 관련된 부분을 추가 수정해준다. 

### 6. 전체 코드

```python
import numpy as np
import datetime
import platform
import torch
import torch.nn.functional as F
from torch.utils.tensorboard import SummaryWriter
from mlagents_envs.environment import UnityEnvironment, ActionTuple
from mlagents_envs.side_channel.engine_configuration_channel\
                             import EngineConfigurationChannel
from mlagents_envs.side_channel.environment_parameters_channel\
                             import EnvironmentParametersChannel

vel_state_size = 2  # agent 속도 (x, z)
ray_chan_size = 40  # ray 최대 개수 
ray_feat_size = 4   # ray 1개당 정보 크기 (감지된 물체의 x, z 좌표, x, z 속도)
action_size = 5

RAY_OBS = 0         # 환경으로부터 Observation 벡터에서 Ray 정보가 담긴 index
VEL_OBS = 1         # 환경으로부터 Observation 벡터에서 Agent 의 속도 정보가 담긴 index

# attention parameters

# Transformer Encoder Layer 에서 사용할 입력 피쳐 (attention incodingd 입력 ebedding 크기)
# feedforward model  피쳐 크기로도 사용
embed_size = 32     

# Transformer Encoder Layer 에서 MultiHeadAttention  모델의 Head 갯수
num_heads = 4

load_model = False
train_mode = True

discount_factor = 0.99
learning_rate = 3e-4
n_step = 512
batch_size = 512
n_epoch = 3
_lambda = 0.95
epsilon = 0.2

run_step = 2000000 if train_mode else 0
test_step = 100000

print_interval = 10
save_interval = 100

# 닷지 환경 설정
env_static_config = {"ballSpeed": 4, "ballRandom": 0.2, "agentSpeed": 3}
env_dynamic_config = {"boardRadius": {"min": 6, "max": 8, "seed": 77},
                      "ballNums": {"min": 10, "max": 15, "seed": 77}}

# 유니티 환경 경로
game = "Dodge_Attention"
os_name = platform.system()
if os_name == 'Windows':
    env_name = f"../Env/{game}/{game}"
elif os_name == 'Darwin':
    env_name = f"../envs/{game}_{os_name}"

# 모델 저장 및 불러오기 경로
date_time = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
save_path = f"./saved_models/{game}/AttentionPPO/{date_time}"
load_path = f"./saved_models/{game}/AttentionPPO/20230728125435"

# 연산 장치 
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# AttentionActorCritic 클래스 -> Attention을 사용하는 ActorCritic Network 정의 
class AttentionActorCritic(torch.nn.Module):
    def __init__(self, **kwargs):
        super(AttentionActorCritic, self).__init__(**kwargs)
        self.attn_in = torch.nn.Linear(ray_feat_size, embed_size)
        self.attn_layer = torch.nn.TransformerEncoderLayer(
            d_model=embed_size, 
            nhead=num_heads, 
            batch_first=True,
            dim_feedforward=embed_size, 
            dropout=0
        )
        self.attn_out = torch.nn.Linear(ray_chan_size * embed_size, 128)

        self.e = torch.nn.Linear(vel_state_size, 128)
        self.d1 = torch.nn.Linear(256, 128)
        self.d2 = torch.nn.Linear(128, 128)
        self.pi = torch.nn.Linear(128, action_size)
        self.v = torch.nn.Linear(128, 1)

    def forward(self, state):
        ray, vel = torch.split(state, ray_chan_size * ray_feat_size, dim=1)

        b = ray.shape[0]
        ray = ray.reshape(b * ray_chan_size, ray_feat_size)
        attn_in = self.attn_in(ray).reshape(b, ray_chan_size, embed_size)
        attn_out = self.attn_layer(attn_in)

        ray_embed = F.relu(self.attn_out(attn_out.reshape(b, -1)))
        vel_embed = F.relu(self.e(vel))

        x = torch.cat((vel_embed, ray_embed), dim=1)
        x = F.relu(self.d1(x))
        x = F.relu(self.d2(x))

        return F.softmax(self.pi(x), dim=-1), self.v(x)
    
# AttentionPPOAgent 클래스 -> AttentionPPOAgent 알고리즘을 위한 다양한 함수 정의
class AttentionPPOAgent:
    def __init__(self):
        self.network = AttentionActorCritic().to(device)
        self.optimizer = torch.optim.Adam(self.network.parameters(), lr=learning_rate)
        self.memory = list()
        self.writer = SummaryWriter(save_path)

        if load_model == True:
            print(f"... Load Model from {load_path}/ckpt ...")
            checkpoint = torch.load(load_path+'/ckpt', map_location=device)
            self.network.load_state_dict(checkpoint["network"])
            self.optimizer.load_state_dict(checkpoint["optimizer"])

    # 정책을 통해 행동 결정
    def get_action(self, state, training=True):
        # 네트워크 모드 설정
        self.network.train(training)

        # 네트워크 연산에 따라 행동 결정
        pi, _ = self.network(torch.FloatTensor(state).to(device))
        action = torch.multinomial(pi, num_samples=1).cpu().numpy()
        
        return action
    
    # 리플레이 메모리에 데이터 추가 (상태, 행동, 보상, 다음 상태, 게임 종료 여부)
    def append_sample(self, state, action, reward, next_state, done):
        self.memory.append((state, action, reward, next_state, done))

    # 학습 수행
    def train_model(self):
        self.network.train()

        state = np.stack([m[0] for m in self.memory], axis=0)
        action = np.stack([m[1] for m in self.memory], axis=0)
        reward = np.stack([m[2] for m in self.memory], axis=0)
        next_state = np.stack([m[3] for m in self.memory], axis=0)
        done = np.stack([m[4] for m in self.memory], axis=0)
        self.memory.clear()

        state, action, reward, next_state, done = map(
            lambda x: torch.FloatTensor(x).to(device),
            [state, action, reward, next_state, done]
        )

        # prob_old, adv, ret 계산
        with torch.no_grad():
            pi_old, value = self.network(state)
            prob_old = pi_old.gather(1, action.long())

            _, next_value = self.network(next_state)
            delta = reward + (1 - done) * discount_factor * next_value - value
            adv = delta.clone()
            adv, done = map(
                lambda x: x.view(n_step, -1).transpose(0, 1).contiguous(),
                [adv, done]
            )

            # GAE 수행
            for t in reversed(range(n_step - 1)):
                adv[:, t] += (1 - done[:, t]) * discount_factor * _lambda * adv[:, t + 1]
            
            adv = adv.transpose(0, 1).contiguous().view(-1, 1)

            ret = adv + value

        # 학습 이터레이션 시장
        actor_losses, critic_losses = [], []
        idxs = np.arange(len(reward))

        for _ in range(n_epoch):
            np.random.shuffle(idxs)
            
            for offset in range(0, len(reward), batch_size):
                idx = idxs[offset : offset + batch_size]

                _state, _action, _ret, _adv, _prob_old = map(
                    lambda x: x[idx], 
                    [state, action, ret, adv, prob_old]
                )

                pi, value = self.network(_state)
                prob = pi.gather(1, _action.long())

                # 정책 신경망 손실 함수 계산
                ratio = prob / (_prob_old + 1e-7) # probability ratio
                surr1 = ratio * _adv
                surr2 = torch.clamp(ratio, min=1-epsilon, max=1+epsilon) * _adv
                actor_loss = -torch.min(surr1, surr2).mean()

                # 가치 신경망 손실함수 계산
                critic_loss = F.mse_loss(value, _ret).mean()

                total_loss = actor_loss + critic_loss

                self.optimizer.zero_grad()
                total_loss.backward()
                self.optimizer.step()

                actor_losses.append(actor_loss.item())
                critic_losses.append(critic_loss.item())

        return np.mean(actor_losses), np.mean(critic_losses)
    
    # 네트워크 모델 저장
    def save_model(self):
        print(f"... Save Model to {save_path}/ckpt ...")
        torch.save({
            "network" : self.network.state_dict(),
            "optimizer" : self.optimizer.state_dict(),
        }, save_path+'/ckpt')

    # 학습 기록 
    def write_summary(self, score, actor_loss, critic_loss, step):
        self.writer.add_scalar("run/score", score, step)
        self.writer.add_scalar("model/actor_loss", actor_loss, step)
        self.writer.add_scalar("model/critic_loss", critic_loss, step)

if __name__ == '__main__':
    # 유니티 환경 경로 설정(file_name)
    engine_configuration_channel = EngineConfigurationChannel()
    environment_parameters_channel = EnvironmentParametersChannel()
    env = UnityEnvironment(
        file_name=env_name,
        side_channels=[engine_configuration_channel, environment_parameters_channel]
    )

    env.reset()

    # 유니티 behavior 설정
    behavior_name = list(env.behavior_specs.keys())[0]
    spec = env.behavior_specs[behavior_name]
    engine_configuration_channel.set_configuration_parameters(time_scale=12.0)

    for key, value in env_static_config.items():
        environment_parameters_channel.set_float_parameter(key, value)
    
    for key, value in env_dynamic_config.items():
        environment_parameters_channel.set_uniform_sampler_parameters(
                              key, value["min"], value["max"], value["seed"])

    dec, term = env.get_steps(behavior_name)
    num_worker = len(dec)

    # AttentioPPOAgent class 를 agent 로 정의
    agent = AttentionPPOAgent()
    actor_losses, critic_losses, scores, episode, score = [], [], [], 0, 0
    for step in range(run_step + test_step):
        if step == run_step:
            if train_mode:
                agent.save_model()
            print("TEST START")
            train_mode = False
            engine_configuration_channel.set_configuration_parameters(time_scale=1.0)

        preprocess = lambda ray, vel: np.concatenate((ray.reshape(-1, ray_chan_size * ray_feat_size), vel), axis=1)
        state = preprocess(dec.obs[RAY_OBS], dec.obs[VEL_OBS])
        action = agent.get_action(state, train_mode)
        action_tuple = ActionTuple()
        action_tuple.add_discrete(action)
        env.set_actions(behavior_name, action_tuple)
        env.step()

        # 환경으로부터 얻는 정보
        dec, term = env.get_steps(behavior_name)
        done = [False] * num_worker
        next_state = preprocess(dec.obs[RAY_OBS], dec.obs[VEL_OBS])
        reward = dec.reward

        if len(term):
            next_term_state = preprocess(term.obs[RAY_OBS], term.obs[VEL_OBS])

        for id in term.agent_id:
            _id = list(term.agent_id).index(id)
            done[id] = True
            next_state[id] = next_term_state[_id]
            reward[id] = term.reward[_id]

        score += reward[0]

        if train_mode:
            for id in range(num_worker):
                agent.append_sample(state[id], action[id], [reward[id]], next_state[id], [done[id]])

            # 학습 수행
            if (step + 1) % n_step == 0:
                actor_loss, critic_loss = agent.train_model()
                actor_losses.append(actor_loss)
                critic_losses.append(critic_loss)
        
        if done[0]:
            episode += 1
            scores.append(score)
            score = 0

            # 게임 진행 상황 출력 및 텐서 보드에 보상과 손실함수 값 기록 
            if episode % print_interval == 0:
                mean_score = np.mean(scores)
                mean_actor_loss = np.mean(actor_losses) if len(actor_losses) > 0 else 0
                mean_critic_loss = np.mean(critic_losses)  if len(critic_losses) > 0 else 0
                agent.write_summary(mean_score, mean_actor_loss, mean_critic_loss, step)
                actor_losses, critic_losses, scores = [], [], []

                print(f"{episode} Episode / Step: {step} / Score: {mean_score:.2f} / " +\
                      f"Actor loss: {mean_actor_loss:.2f} / Critic loss: {mean_critic_loss:.4f}" )

            # 네트워크 모델 저장 
            if train_mode and episode % save_interval == 0:
                agent.save_model()
    env.close()

```
---
layout: post
read_time: true
show_date: true
title:  Trasformer - Attention 모델 학습
date:   2024-05-17 09:32:20 +0900
description: Trasformer - Attention 모델 학습

img: posts/general/post_general19.jpg
tags: [transformer, attention, incoding, decoding, embedding]
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

<Transformer - Attention is All you Need> 의 논문에 나온 Transformer 에 대해 학습 내용을 정리

해당 논문은 언어를 다른나라의 언어로 번역하는 작업을 Transformer-Attention 알고리즘을 적용하여 기존보다 효율적으로 언어를 변환할 수 있음을 보여준다. Transformer  구조도는 아래와 같으며 해당 구조에 각 요소와 process 를 분석한다. 
​<center><img src="assets\img\posts\2024-05-17-transformer\1.png" width="400"></center>

* 해당 내용은 다음의 책 내용을 개인적으로 재학습 하기 위해 작성됨. <br>
  [자연어 처리 바이블 -ChatGPT 핵심기술-](https://product.kyobobook.co.kr/detail/S000001952238)

### 1.  (Word) Embedding

입력된 정보(단어)들을 컴퓨터가 연산으로 처리할 수 있도록 vector 공간의 특정 값으로 매핑 시킨다. 매핑된 정보들은 임이의 vector 값을 가지거나 어떤 학습을 통해 아래와 같이, 연관성이 높은 단어들 간에 가까운 공간내 존재하도록 값을 할당 받을 수 있다. 
​<center><img src="assets\img\posts\2024-05-17-transformer\2.png" width="600"></center>
  [이미지 출처](https://medium.com/@hari4om/word-embedding-d816f643140)

### 2. Positional Embedding

언어를 처리할 때, 문장에서 각 단어의 위치는 중요한 의미를 가진다. 그런다. word embedding 에는 해당 정보가 존재하지 않으므로, 문장 구조(각 단어의 위치와 시퀀스 내 다른 단어간의 위치 차이에 대한 정보) 를 가진 positional encoding 을 추가하여 순서의 의미를 포함한 embedding 으로 변환해준다. 
​<center><img src="assets\img\posts\2024-05-17-transformer\3.png" width="500"></center>
  [이미지 출처](https://product.kyobobook.co.kr/detail/S000001952238)

### 3. Incoder

입력 정보는 앞에서와 같이 Embedding 작업, Positional Encoding 추가 작업을 거친 후 Incoder 로 진입하게 된다. 여기서 Multi-Head Attention 과정을 거치게 되는데, Mulit-Head Attention 은 여러개의 독립적인  Self-Attion 으로 구성되어 있다. 따라서 우선 Self-Attion 에서 진행되는 작업을 우선 살펴본다.

#### 3.1 Self-Attention

#### 3.1.1 Query 벡터, Key 벡터, Value 벡터를 생성

해당 과정에서 우선 입력된 Embedding 벡터로부터 Query 벡터, Key 벡터, Value 벡터를 생성한다. 
​<center><img src="assets\img\posts\2024-05-17-transformer\4.png" width="500"></center>
  [이미지 출처](https://product.kyobobook.co.kr/detail/S000001952238)

* Query 벡터 (Q) : 현재 처리하고 있는 입력 요소에 대한 벡터로, 다른 모든 요소들과의 관계를 평가하는 데 사용. 즉, 해당 단어가 다른 모든 Key 벡터들과의 상호작용을 통해 어느 정도 연관성이나 중요도를 가지는지를 평가하는 것을 의미. (이를 은유적으로 "질문 (Query)" 로 표현함)

* Key 벡터 (K) : 비교 대상 (연결될 다음 단어)이 되는 각 입력 요소에 대응하는 벡터로, Query와 비교(내적연산) 된다. Key 벡터는 Query가 어떤 요소에 집중(다음 단어로 선택)해야 할지 결정하는 데 도움을 준다.

* Value 벡터 (V) : 각 입력 요소의 실제 정보를 담고 있는 벡터로, attention 가중치가 적용된 후, 이 값들이 합쳐져 최종적으로 출력될 정보를 형성.

각각의 가중치 행렬 W<sup>Q</sup>, W<sup>K</sup>, W<sup>V</sup> 일반적으로 각각 독립젹으로 학습되며, gradient 하강법을 사용하여 최적화 된다. 

#### 3.1.2 점수 계산

현재 처리 중인 단어와 해당 단어가 포함된 문장 내 모든 다른 단어들에 대해서 점수를 계산한다. 이 점수는 현재 단어를 encode 할 때, 다른 단어들에 대해서 얼마나 집중을 해야 할지를 결정한다. 
​<center><img src="assets\img\posts\2024-05-17-transformer\5.png" width="140"></center>
  [이미지 출처](https://product.kyobobook.co.kr/detail/S000001952238)

현재 단어의 Query 벡터와 다른 단어들의 Key 벡터들 간에 각각 내적으로 계산된다. 해당 값의 크기를 조절(scale & Mask) 하고, softmax 계산을 통과시켜 모든 점수들을 양수로 만들고 그 합을 1 로 만들어 준다. 이 점수는 현재 위치의 단어의 encoding 에 있어서 얼마나 각 단어들의 표현이 들어갈 것인지를 결정한다. 

예를 들어, I am a student. (영어) 을 넣고, 현재 I 라는 단어의 위치를 encoding 하고 있다면, 현재 위치에 위치할 단어로 I (동일 단어) 가 가장 높은 점수를 가지게 되겠지만, 가끔은 현재 단어에 관련이 있는 다른 단어에 대한 정보가 들어가는 것이 필요할 수 있다(? 이해가 잘 안됨.)

#### 3.1.3 weighted value 합 & 최종 출력 벡터 형성

1. 가중합 (weighted sum) : 앞의 과정에서 얻은 점수(attention weights - 가중치)를 vector 에 value 벡터를 곱한다. 이 과정에서 각단어의 value 가 가중치에 의해 그 값이 (가중치가 높다면), 그 값이 거의 그대로 유지되거나, (가중치가 낮다면) 값이 매우 작아지게된다. 가중합 과정을 거치면 value 가 매우 작아진 단어들은 최종 결과에 거의 기여하지 못하고, 중요도(결과값)가 높은 단어들에 집중할 수 있게 된다. (정보의 필터링) 

2. 모든 weighted value 벡터들을 요소별로 합산한다. 즉, 같은 위치에 있는 요소들끼리 더한다. 이렇게 합산된 결과는 하나의 벡터가 되며, 이 벡터가 그 위치에서의 self-attention layer의 최종 출력이 된다. 

여기까지 3.1.2 & 3.1.3 의 과정을 Scaled Dot=Product Attention 이라고 하며, 그 작업을 정리하면 아래와 같다. 
​<center><img src="assets\img\posts\2024-05-17-transformer\6.png" width="180"></center>
  [이미지 출처](https://product.kyobobook.co.kr/detail/S000001952238)

#### 3.2 Multi Head Attention

논문에서는 성능 개선을 위해  encoder/decoder 마다 위와 같이 구조의 Attention Head 를  8개씩 갖도록 한다. 각 Head 는 다른 representation 공간을 가진다. 즉, 각 단어에 대해 scale dot product attention 을 여러번 병렬적으로 수행함을 의미한다. 해당 작동 과정을 정리하면 아래와 같다. 

1. 분할(Divide): 입력 벡터(예: 단어 임베딩)는 먼저 여러 개의 ‘head’로 분할된다. 각 head에서는 독립적인 attention 연산이 수행되며, 이는 각기 다른 query, key, value 벡터의 세트를 사용.

2. 병렬 처리(Parallel Processing): 각 head는 독립적으로 scale dot product attention을 수행한다. 이는 각 head가 입력 데이터의 서로 다른 부분집합 또는 다른 관점에서의 정보를 처리하게 함으로써, 모델이 다양한 특성을 동시에 고려할 수 있도록 한다.

3. Attention 연산: 각 head에서는 독립적으로 query 벡터와 key 벡터의 내적을 통해 점수를 계산하고, 이 점수에 softmax를 적용하여 attention 가중치를 얻는다. 이 가중치는 각 head의 value 벡터와 곱해져 weighted value 벡터를 생성한다.

4. 결합(Concatenate): 각 head에서 생성된 weighted value 벡터들은 다시 하나의 벡터로 결합된다. 이 결합 과정은 각 head가 추출한 정보를 통합하여 전체적인 문맥을 형성한다.

5. 선형 변환(Linear Transformation): 결합된 벡터는 추가적인 선형 변환을 거쳐 최종 출력 벡터를 형성한다. 이 변환은 모든 head에서 얻은 정보를 최적화하고 특정 작업에 맞게 조정하는 역할을 한다.
​<center><img src="assets\img\posts\2024-05-17-transformer\7.png" width="250"></center>

#### 3.3 잔차 연결 (Residual connection)
​<center><img src="assets\img\posts\2024-05-17-transformer\8.png" width="130"></center>
​<center><img src="assets\img\posts\2024-05-17-transformer\9.png" width="480"></center>
  [이미지 출처](https://velog.io/@glad415/Transformer-7.-%EC%9E%94%EC%B0%A8%EC%97%B0%EA%B2%B0%EA%B3%BC-%EC%B8%B5-%EC%A0%95%EA%B7%9C%ED%99%94-by-WikiDocs)

위와 같이 해당 위치의 단어 encoding 벡터 (x: 서브층 입력)에 multi haed attention 연산의 결과를 더함. 각 레이어의 입력과 출력을 직접 연결하여, 깊은 네트워크에서도 학습이 원활하게 진행되도록 돕는다. 그 결과, 네트워크가 더 깊어져도 정보가 손실되는 것을 방지할 수 있다.  

#### 3.4 층 정규화 (Layer normalization)

잔차 연결로 학습 내용을 누적시킨 x 에 대해서 요소의 평균과 분산을 계산하여 데이터를 정규화한다. 이는 훈련 과정을 안정화하고, 다른 스케일의 특징들이 네트워크에 의해 고르게 학습될 수 있도록 한다. 이 정규화는 벡터의 각 차원에 걸쳐 진행된다.

#### 3.5 Feed Forward Networks (전방 전달 네트워크)

이 부분은 각 위치의 인코딩된 벡터 z를 독립적으로 동일한 신경망(Feed Forward Neural Network)에 통과시킨다. 이 네트워크는 일반적으로 두 개의 선형 변환과 그 사이에 하나의 비선형 활성화 함수(예: ReLU)로 구성된다.

* 첫 번째 선형 변환: 입력 벡터를 더 높은 차원으로 매핑.
* 활성화 함수: 비선형성을 도입하여 모델이 더 복잡한 패턴을 학습할 수 있도록 함.
* 두 번째 선형 변환: 다시 원래 차원으로 매핑.

Feed Forward 네트워크는 각 위치에서 독립적으로 작동하므로, 서로 다른 위치의 데이터가 서로 영향을 미치지 않는다. 이것은 Transformer가 문맥에 따라 각 단어의 표현을 개별적으로 조정할 수 있게 한다.

Feed Forward Networks (전방 전달 네트워크) 의 목적

1. 비선형 처리 능력 추가: Transformer의 self-attention 메커니즘은 기본적으로 선형적인 처리를 수행한다. 비선형 활성화 함수를 포함하는 Feed Forward Network를 통해 모델에 비선형성을 도입함으로써, 모델이 더 복잡하고 추상적인 패턴과 관계를 학습할 수 있게 된다. 이는 모델이 더 높은 수준의 언어 이해와 처리 능력을 갖추도록 돕는다.

2. 향상된 표현력: 각 입력 포지션에 대해 동일한 Feed Forward Network를 적용함으로써, 인코더는 각 단어 혹은 토큰의 표현을 더욱 풍부하게 만들 수 있다. 이 과정은 입력 벡터를 더 높은 차원으로 확장시키고, 다시 원래의 차원으로 줄이는 과정을 통해 각 토큰의 특징을 더욱 세밀하게 조정한다.

3. 독립적인 위치 처리: Transformer의 Feed Forward Network는 각 포지션에서 독립적으로 작동한다. 이는 모델이 문장의 각 부분을 독립적으로 평가하고 조정할 수 있도록 하며, 이는 특히 병렬 처리에서 큰 장점을 제공한다. 각 위치의 데이터 처리가 다른 위치의 데이터에 영향을 받지 않기 때문에, 전체적인 계산 효율성이 높아짐.

4. 문맥적 통합 강화: 비록 Feed Forward Network는 위치별로 독립적으로 작동하지만, self-attention 단계에서 이미 계산된 문맥적 정보를 토대로 각 토큰의 표현을 더욱 개선하고 정제합니다. 이는 전체 문장의 의미를 더 잘 파악하고, 각 단어나 토큰이 전체 문맥에서 어떻게 기능하는지 더 정확하게 반영할 수 있게 합니다.

이러한 과정을 통해, Transformer는 각 입력 데이터의 특성을 개선하고, 더 정교한 언어 처리를 수행할 수 있는 강력한 툴을 제공합니다. Feed Forward Networks는 Transformer의 구조적 핵심 요소 중 하나로, 모델의 전반적인 성능과 표현력을 크게 향상시키는 역할을 합니다.

#### 3.6 Add & Normalize (추가 및 정규화)

Feed Forward Networks 입력과 출력에 대해 다시 잔차 연결 & 정규화 과정을 진행한다.

### 4. Decoder
​<center><img src="assets\img\posts\2024-05-17-transformer\11.png" width="400"></center>
#### 4.1 Masked Multi-Head Attention

Masking 의 작동 방식

ransformer 디코더의 self-attention 계층에서 각 토큰은 자신과 그 이전의 모든 토큰에 대해서만 attention 계산을 수행할 수 있다. 이는 softmax 함수를 적용하기 전에 특정 위치의 attention 점수를 아주 작은 값(예를 들어, -무한대와 같은)으로 설정함으로써 해당 위치의 점수는 0에 가까운 값이 되어, 결국 해당 위치의 토큰은 계산에서 제외됨.
​<center><img src="assets\img\posts\2024-05-17-transformer\10.png" width="450"></center>
  [이미지 출처](https://paul-hyun.github.io/transformer-02/)


Masking의 목적

디코더가 아직 생성하지 않은 출력 토큰들에 대한 정보를 참조하지 못하게 하는 것. 즉, 디코더가 각 단계에서 예측을 수행할 때 오직 그 단계 이전까지의 출력들만 고려하도록 보장.

#### 4.2 입력 data 랙 Multi-Head Attention

Query Vector : Decoder 내 이전 단계의 Masked Mulit-Head Attention 결과를 사용
Key & Value Vector : Incoder 프로세스 결과 사용

### 5. Linear Layer & Softmax

여러 개의 decoder 를 거치고 난 후에는 확률을 요소로 가진 벡터 하나가 남게 된다. 어떻게 이 하나의 벡터를 단어로 바꿀 수 있을까? 

Linear layer 는 fully-connected 신경망으로 decoder 가 마지막으로 출력한 벡터를 그보다 훨씬 큰 사이즈의 벡터인 logits 벡터에 투영 시킨다. logit 벡터의 크기는 모델이 선택할수 있는 어휘의 크기와 같다. 즉 Decoder 의 결과를 신경망 layer 로 넣어서 현재 위치(step)에서 전체 어휘들 중 선택 가능 점수를 계산하게 된다. 

해당 점수는 softmax 를 적용하여 확률분포로 변환되고, 최종적으로 가장 높은 확률의 단어가 선택된다. 
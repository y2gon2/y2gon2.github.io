---
layout: post
read_time: true
show_date: true
title:  Lazy Collection 과 Stream library
date:   2024-01-07 10:32:20 +0900
description: Lazy Collection 과 Stream library
img: posts/general/post_general11.jpg
tags: [elixir, lazy collection, elixir stream]
author: Yong gon Yun
github:  y2gon2/exercism/blob/main/document
---
<h3>Lazy Collection</h3>
<p>Lazy Colleciton 은 Elixir와 같은 함수형 프로그래밍 언어에서 중요한 개념 중 하나로 데이터가 실제로 필요할 때까지 그 처리를 연기하는 방식으로 작동한다. 이 방식은 특히 대용량 데이터를 다룰 때 메모리 사용을 최소화하고 성능을 향상시킬 수 있다.</p>

```elixir
stream = Stream.map(1..10000, &(&1 * &1))
```

<p>이 코드는 1부터 10,000까지의 숫자 각각에 대해 제곱을 하는 스트림을 생성한다. 그러나 실제 제곱 연산은 스트림을 열거하는 시점, 예를 들어 Enum.to_list(stream)을 호출할 때까지 수행되지 않는다.</p>

<p><strong>특징</strong></p>
<ul>
<li>비동기 처리: lazy collection은 데이터의 전체 집합을 메모리에 한 번에 로드하지 않는다. 대신, 요소들은 필요할 때, 즉 실제로 열거(enumerate)하거나 접근할 때 처리된다.</li><br>
<li>효율성: lazy collection은 메모리 사용을 최적화한다. 큰 데이터셋을 한 번에 처리하는 대신, 작은 조각으로 나누어 필요한 부분만 처리한다. 이는 특히 파일 읽기, 외부 API 호출, 대규모 계산과 같은 상황에서 유용하다.</li><br>
<li>Function Chaining: lazy collection은 여러 함수를 연결(chaining)하여 복잡한 데이터 처리 파이프라인을 구축할 수 있다. 각 함수는 이전 함수의 출력을 입력으로 받아 처리한다.(아래 보충 설명 참조)</li><br>
<li>Stream Module: Elixir에서 lazy collection을 구현하는 데 사용되는 주요 모듈은 Stream이다. Stream 모듈은 다양한 지연 처리 함수를 제공한다. 예를 들어, <code>Stream.map/2</code>은 컬렉션의 각 요소에 주어진 함수를 적용하지만, 실제 계산은 스트림을 열거할 때까지 연기된다.</li>
</ul>

<h3>즉시 연산 vs 지연 연산</h3>
<p>아래 두 예제의 경우, 반환값은 동일하지만, 아래와 같이 다른 기능적 특징을 가진다.</p>

```elixir
Stream.map(1..10000, &(&1 * &1))
```
<ul>
<li>지연 연산: Stream.map은 연산을 즉시 수행하지 않고, 각 요소에 대한 연산을 정의하는 스트림을 반환한다. 이 스트림은 실제로 열거되기 전까지는 어떤 연산도 수행하지 않는다.</li><br>
<li>메모리 효율성: 큰 데이터셋을 처리할 때 Stream.map은 모든 요소를 한 번에 메모리에 로드하지 않는다. 대신, 스트림을 열거할 때 각 요소를 개별적으로 처리한다. 이는 대규모 데이터셋을 다룰 때 메모리 사용을 최소화한다.</li><br>
<li>적용 예: 위 code 에서 <code>Enum.to_list(stream)</code> 또는 다른 Enum 함수를 사용하여 스트림을 열거할 때까지 실제 연산이 연기된다.</li>
</ul>

```elixir
Enum.map(1..10000, &(&1 * &1))
```
<ul>
<li>즉시 연산: Enum.map은 함수가 호출되는 즉시 모든 요소에 대해 연산을 수행한다. 연산 결과는 즉시 계산되고 반환된다.</li><br>
<li>메모리 사용: 이 방식은 연산을 수행한 전체 결과를 메모리에 저장한다. 큰 데이터셋을 처리할 경우, 이는 상당한 양의 메모리를 사용할 수 있다.</li><br>
<li>적용 예: 연산 결과가 즉시 필요하고 데이터셋이 메모리에 들어갈 수 있을 정도로 작을 때 유용.</li>
</ul>

<center>*****</center>
<h3>Function Chaining 상태에서의 Lazy Collection</h3>
<p>앞에서 관련 장점을 설명했으나, 다양한 함수를 연속적으로 사용하는 function chaining 에서 항상 해당 장점이 발휘되는 것은 아니다.</p>
<p>예를 들면,</p>

```elixir
1..10000
|> Enum.map(&(&1 * 2))
|> Stream.filter(&(&1 < 100))
|> Enum.to_list()
```

<p>의 처리 과정을 보면,</p>

<ol>
<li>chaining 과정에서 Stream 모듈의 함수 뒤에 Enum 모듈의 함수가 오면, 스트림에 대한 모든 연산이 Enum 함수 호출 시점에 즉시 수행된다. 이는 Enum 함수가 실제 데이터를 필요로 하기 때문이다.</li><br>
<li>반대로, Enum 함수 다음에 Stream 함수가 오면, Enum 함수는 즉시 실행되고, 그 결과는 Stream 함수에 의해 다시 지연 처리된다.</li><br>
<li>이 경우, Enum.map은 즉시 모든 요소에 대해 연산을 수행한다. 이어서 <code>Stream.filter</code>는 지연 처리 스트림을 생성하지만, 최종적으로 <code>Enum.to_list</code>에 의해 이 스트림이 즉시 열거되어 모든 데이터 처리가 완료된다.</li>
</ol>

<p>결론적으로, 예제에서 <code>Stream.filter(&(&1 < 100))</code>는 결국 체인의 마지막에 있는 <code>Enum.to_list()</code> 함수 때문에 즉시 연산 처리된다.</p>
<p>chaining된 함수들 중 하나라도 즉시 연산을 수행하는 Enum 모듈의 함수를 포함하고 있고, 이것이 체인의 마지막에 위치한다면, 체인의 모든 연산은 결국 즉시 수행된다. 이는 Enum 모듈의 함수가 실제 데이터를 필요로 하기 때문에, 지연된 연산들도 강제로 실행되어 결과를 산출한다.</p>
<center>*****</center>
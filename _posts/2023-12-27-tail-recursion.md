---
layout: post
read_time: true
show_date: true
title:  tail recursion 
date:   2023-12-27 15:32:20 +0900
description: tail recursion  
img: posts/general/post_general09.jpg
tags: [tail recursion, elixir]
author: Yong gon Yun
github:  y2gon2/exercism/tree/main/document
---
<h3>일반 재귀 (Regular Recursion) 예제</h3>

```elixir
defmodule RegularRecursion do
  def sum([]), do: 0
  def sum([head | tail]), do: head + sum(tail)
end
```
<p>이 예제에서 `sum/1` 함수는 리스트의 첫 번째 요소를 취하고, 나머지 리스트에 대해 재귀적으로 `sum/1`을 호출한 다음, 결과에 첫 번째 요소를 더한다. 여기서 중요한 점은 재귀 호출 후에 추가 작업(더하기)이 수행된다는 것.</p>

<h3>꼬리 재귀 (Tail Recursion) 예제</h3>


<p>다음 예제에서 `sum/2` 보조 함수는 누적된 합계를 유지하면서 재귀적으로 호출된다. 각 재귀 호출은 누적된 합계에 현재 요소를 더한 값과 함께 호출되며, 이는 꼬리 호출 최적화를 가능하게 한다.</p>

```elixir
defmodule TailRecursion do
  def sum(list), do: sum(list, 0)

  defp sum([], total), do: total
  defp sum([head | tail], total) do
    sum(tail, head + total)
  end
end
```

<h3>차이점</h3>
<ul>
<li>일반 재귀에서는 각 재귀 호출 후에 추가적인 계산 필요(예: head + sum(tail)).</li>
<li>꼬리 재귀에서는 재귀 호출이 함수의 마지막 연산이며, 추가 계산이 없음(예: sum(tail, head + total)).</li>
<li>일반 재귀는 호출 스택에 각 호출의 컨텍스트를 저장해야 하므로 메모리 사용이 더 많고, 깊은 재귀에서 스택 오버플로우를 일으킬 수 있다. 반면, 꼬리 재귀는 최적화를 통해 이러한 문제를 피할 수 있으며, 깊은 재귀 호출에서도 효율적으로 작동한다.</li>
</ul>

<h3>(Regular) Recursion vs Tail Recursion - 성능 & stack 사용 비교 </h3>
<h4>꼬리 재귀 (Tail Recursion)</h4>
<p>Elixir에서 꼬리 재귀는 <strong>꼬리 호출 최적화(Tail-Call Optimization, TCO)</strong>라는 기술을 통해 최적화된다. 꼬리 재귀 함수에서는 재귀 호출이 함수의 마지막 작업으로, Elixir 컴파일러가 현재의 스택 프레임을 재사용할 수 있게 한다. 이러한 최적화는 새로운 스택 프레임을 추가하는 대신 현재의 프레임을 재사용함으로써 메모리 사용량을 최소화한다. 대규모 작업이나 대량의 데이터 처리에 특히 메모리 효율이 좋으며, 스택 오버플로우 위험을 피할 수 있다.</p>

<h4>일반 재귀 (Regular Recursion)</h4>
<p>반면, Elixir에서 일반 재귀는 각 함수 호출마다 새로운 스택 프레임을 추가한다. 이는 특히 깊은 재귀 또는 큰 리스트를 다룰 때 메모리 사용량을 증가시킬 수 있으며, 각 재귀 호출이 자체 스택 프레임을 요구하기 때문에 성능 문제나 극단적인 경우 스택 오버플로우를 일으킬 수 있다.</p>

<h4>성능적 영향</h4>
<p>일반적으로 꼬리 재귀는 Elixir에서 더 빠르고 메모리 효율적이며, 특히 리스트 축소나 대규모 데이터 처리에 유리하다. 하지만 모든 경우에 꼬리 재귀가 우월한 것은 아니다. 특정 상황, 특히 함수가 리스트를 축소하지 않고 단순히 매핑하는 경우, 일반 재귀가 더 효율적일 수 있다. 예를 들어, 리스트의 숫자를 두 배로 하는 함수는 일반 재귀를 사용하는 것이 더 빠를 수 있다.</p>

<h3>다른 언어의 logic 처리 (iteration) 과 Tail Recursion 비교</h3>
<p>Elixir에서 꼬리 재귀를 사용하는 것이 다른 언어에서의 일반적인 반복문(iteration)을 사용하는 것과 유사한 수준의 성능과 메모리 사용을 제공할 수 있다. 꼬리 재귀의 주요 장점 중 하나는 꼬리 호출 최적화(tail-call optimization, TCO)로 인해 메모리 사용이 최소화된다는 것. 이 최적화는 재귀 호출 시 새로운 스택 프레임을 생성하는 대신 현재 스택 프레임을 재사용하게 해, 깊은 재귀 호출에서도 스택 오버플로우 위험을 줄여준다.</p>

<h3>꼬리 재귀와 반복문의 성능 비교</h3>
<ul>
<li>메모리 사용량: 꼬리 재귀를 사용하는 Elixir 함수는 일반 반복문을 사용하는 다른 언어의 함수들과 유사하게, 낮은 메모리 사용량을 가질 수 있다. 각 재귀 호출이 새로운 스택 프레임을 추가하지 않기 때문에, 깊은 재귀 수준에서도 메모리 사용량이 제한적이다. </li><br>
<li>성능: 꼬리 재귀 최적화 덕분에 Elixir의 꼬리 재귀 함수는 일반 반복문을 사용하는 함수들과 비슷한 성능을 낼 수 있다. 반복문은 일반적으로 CPU 사이클을 덜 사용하고, 반복 로직이 명시적이기 때문에 일부 경우에서 더 효율적일 수 있다. 하지만 꼬리 재귀는 이러한 성능 차이를 상당 부분 줄일 수 있다.</li>
</ul>
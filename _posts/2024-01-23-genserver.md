---
layout: post
read_time: true
show_date: true
title:  @impl attribute
date:   2024-01-23 15:32:20 +0900
description: @impl attribute
img: posts/general/post_general14.jpg
tags: [elixir, impl, attribute]
author: Yong gon Yun
---

<p>elixir code 를 작성할 때, behaviour 나 macro 의 callback 의 구현체를 정의하는 구조는 일반 함수와 동일하다. 이를 구별하기 위해 <code>@impl true</code>를 사용하는 것이 좋다. 사용하지 않을 경우, 작업에 문제가 발생하지는 않으나 IDE 나 complier 가 아래 내용의 warning 이 나타날 수 있다.</p>

```
module attribute @impl was not set for function init/1 callback (specified in GenServer). This either means you forgot to add the "@impl true" annotation before the definition or that you are accidentally overriding this callback
```
<p>아울러 해당 attribute 를 사용했을 때의 장점은 다음과 같다.</p>

<ol>
  <li>명확성: <code>@impl true</code>는 해당 함수가 특정 행위(behaviour)의 callback 함수임을 명확히 함. 따라서 가독성이 높아질 수 있음.</li>
  <li>컴파일러 검증: <code>@impl true</code>를 사용하면 Elixir compiler가 해당 함수가 실제로 지정된 행위의 callback 함수인지를 검증함으로 써, 잘못된 callback 함수일 경우, compile 단계에서 이를 감지할 수 있어짐</li>
  <li>문서화: <code>@impl true</code>를 사용하면 ExDoc과 같은 문서화 도구에서 해당 함수가 콜백 함수임을 자동으로 식별하여 문서화할 수 있음.</li>
  <li>유지보수 용이성: 코드의 유지보수를 담당하는 다른 개발자들에게 해당 함수의 역할과 중요성을 쉽게 전달할 수 있음.</li> 
</ol>

<p><strong>예시</strong></p>

```elixir
defmodule ImplAttribute do
  use GenServer
  ... ...
  @impl true
  def init(list) do
    {:ok, list}
  end

  @impl true
  def handle_call(:view, _from, list) do
    {:reply, list, list}
  end
  ... ...
end
```
<p>만약 callback 이 아닌 일반 함수에 해당 attribute 를 사용할 경우 다음과 같은 warning 이 발생한다.</p>

```elixir
defmodule ImplAttribute do
  use GenServer
  ... ...
  @impl true
  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  @impl true
  def view(pid) do
    GenServer.call(pid, :view)
  end
  ... ...
end
```

```
got "@impl true" for function add/2 but no behaviour specifies such callback. The known callbacks are: ... ...
```
<h3>그렇다면 다른 @impl attribute 는?</h3>

<p><code>@impl Module</code>: 여기서 Module은 특정 행위를 나타내는 모듈. 이 형식은 함수가 특정 행위의 일부임을 더 명시적으로 나타내는 데 사용된다. 예를 들어, <code>@impl GenServer</code>는 해당 함수가 <code>GenServer 행위의 callback임을 나타낸다.</p>

```elixir
defmodule MyGenServer do
  use GenServer

  # Client API

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def add(pid, value) do
    GenServer.cast(pid, {:add, value})
  end

  # Server Callbacks

  @impl GenServer
  def init(args) do
    {:ok, args}
  end

  @impl GenServer
  def handle_cast({:add, value}, state) do
    new_state = state + value
    {:noreply, new_state}
  end
end
```

<p><code>@impl GenServer</code> attribute는 <code>init/1</code> 및 <code>handle_cast/2</code> 함수가 <code>GenServer</code>의 callback임을 명시</p>
---
layout: post
read_time: true
show_date: true
title:  Elixir GenServer
date:   2024-01-23 10:32:20 +0900
description: Elixir GenServer
img: posts/general/post_general13.jpg
tags: [elixir, genserver, pubsub]
author: Yong gon Yun
---

<p>Elixir의 <code>GenServer</code>는 OTP(Open Telecom Platform) behaviour 중 하나로, 서버 프로세스를 구현하기 위한 추상화를 제공한다. GenServer는 클라이언트-서버 관계에서 서버 부분을 담당하며, 상태를 유지하고, 요청을 동기적 또는 비동기적으로 처리할 수 있다. 이는 Elixir/Erlang 시스템에서 병렬처리와 상태 관리를 용이하게 하는 강력한 도구이다.</p>

<p><code>GenServer</code> 의 다양한 macro callback 중 주요한 것을을 사용하여 통신 moudule 을 구현하고자 한다. 해당 module 의 구조는 다음과 같다.</p>

<center>
  <img src="assets\img\posts\genserver.png" width="500" height>
</center>

<p>module 내 구성은 크게 client 와 server 구현 부분으로 구분 된다. client 는 경우, 해당 module 이 실행되는 application 자체 또는 일부 process 에서 실행될 code 이며, 해당 code 를 통해 server process 를 생성, 동기/비동기 작업 요청 및 응답, 종료 등의 작업을 정의한다.</p>
<p>server 부분의 경우, client 작업 요청에 대응하는 작업에 대한 code 를 정의한다. 위에 언급된 <code>GenServer</code> callback 들의 경우, 모두 <code>GenServer</code> behaviour의 구현체이다.</p>
<p>client-server 에 각 callback 들에 대해 간단하게 설명하면 다음과 같다.</p>

<ol>
  <li>Server 생성
    <ul>
      <li><code>start_link/3</code>: 새로운 GenServer 프로세스를 시작하고 연결</li>
      <li><code>init/1</code>: <code>start_link/3</code> 요청에 의해 GenServer가 시작될 때 호출되며, 초기 상태를 설정</li>
    </ul>
  </li>
  <li>비동기 요청/응답
    <ul>
      <li><code>cast/2</code>: 비동기적 통신에 사용. client 는 server 에 메시지를 보내고 즉시 반환됨. 이 메소드는 서버의 <code>handle_cast/2</code> callback을 trigger.</li>
      <li><code>handle_cast/2</code>: 비동기적 요청을 처리. 클라이언트는 응답을 기다리지 않음.</li>
    </ul>
  </li>
  <li>동기 요청/응답
    <ul>
      <li>call/3<code></code>: 동기적 통신에 사용. client는 server에 요청을 보내고, server가 응답할 때까지 기다리며, server의 <code>handle_call/3</code>s callback을 trigger.</li>
      <li><code>handle_call/3</code>: 동기적 요청을 처리하고 그 결과를 clientd에게 응답.</li>
    </ul>
  </li>
  <li>Server 종료
    <ul>
      <li><code>stop/3</code>: <code>GenServer</code> 프로세스를 안전하게 종료하기 위해 사용. 이 함수는 종료 이유(ex.  'normal', 'shutdown', 'kill' 등)와 타임아웃(default : 5 sec)을 지정할 수 있으며, 서버의 <code>terminate/2</code>  callback을 trigger.</li>
      <li><code>terminate/2</code>: server가 종료되기 전에 호출되는 callback <code>GenServer</code> 프로세스가 정상적으로 종료될 때 호출되며, 종료 전에 필요한 정리 작업(ex.종료되기 전에 상태를 저장하거나 열려 있는 리소스를 닫는 등의 작업 등)을 수행할 수 있습니다.</li>
    </ul>
  </li>
</ol>

<p><strong>예제 코드</strong></p>

```elixir
  defmodule ShopingList do
  use GenServer

  #  ------ client API --------

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def add(pid, item) do
    GenServer.cast(pid, item)
  end

  def view(pid) do
    GenServer.call(pid, :view)
  end

  def remove(pid, item) do
    GenServer.cast(pid, {:remove, item})
  end

  def stop(pid) do
    GenServer.stop(pid, :normal, :infinity)
  end

  # ----- server callback -----

  def init(list) do
    {:ok, list}
  end

  def handle_cast({:remove, item}, list) do
    updated_list = Enum.reject(list, fn(i) -> i == item end)
    {:noreply, updated_list}
  end

  def handle_cast(item, list) do
    updated_list = [item|list]
    {:noreply, updated_list}
  end

  def handle_call(:view, _from, list) do
    {:reply, list, list}
  end

  def terminate(_reason, list) do
    IO.puts("This Server is termniated.")
    IO.inspect(list)
  end
end
```

<p><strong>실행 결과</strong></p>

```
iex(1)> {:ok, pid} = ShoppingList.start_link()
{:ok, #PID<0.422.0>}
```
<p><code>ShoppingList.start_link()</code> 를 통해 server process 를 생성한다. server 측 <code>init(list)</code> 함수 callback 이 실행되어 server process 를 초기화 하고 그 결과 및 pid 를 client 에게 반환한다.</p>

```
iex(2)> ShoppingList.add(pid, "eggs") 
:ok
iex(3)> ShoppingList.add(pid, "milk") 
:ok
iex(4)> ShoppingList.add(pid, "cheese") 
:ok
iex(5)> ShoppingList.view(pid) 
["cheese", "milk", "eggs"]
```

<p><code>ShoppingList.add(pid, "eggs")</code> 등의 함수를 통해 server process 비동기 작업을 요청한다. <code>:ok</code> 응답은 server 작업의 완료와 관계없이 반환된다. <code>handle_cast(item, list)</code>가 작업을 하여 server 자체 list 에 client 가 보낸 메세지를 list 에 추가한다.</p>
<p><code>ShoppingList.view(pid)</code> 를 통해 동기화된 작업을 요청한다. 해당 요청으로 <code>handle_call(:view, _from, list)</code> callback 이 trigger 된다. 해당 callback 반환값 튜플<code>{:reply, list, list}</code>의 각 요소는 다음의 의미를 가진다.</p>
<ol>
  <li><code>:reply</code>: client 에게 동기적으로 응답을 보내야 함을 의미</li>
  <li><code>list</code>: client 에게 보낼 실제 응답 data</li>
  <li><code>list</code>: 해당 callback 작업 이후 server 가 가질 data</li>
</ol>

```
iex(6)> ShoppingList.remove(pid, "cheese") 
:ok
iex(7)> ShoppingList.view(pid)
["milk", "eggs"]
```

<p><code>ShoppingList.remove(pid, "cheese")</code> 의 경우 앞에서 사용한  <code>ShoppingList.add(pid, "eggs")</code> 와 동일하게 비동기 작업을 요청하지만 함수 다형성(polymorphism) 을 적용하여 별도로 정의된 <code>handle_cast({:remove, item}, list)</code> callback 을 trigger 한다.</p>

```
iex(8)> ShoppingList.stop(pid) 
This Server is termniated.
["milk", "eggs"]
:ok
```

<p>server process 을 종료 요청을 보내고 triggering 된 <code>terminate(_reason, list)</code> 작업을 진행하고 해당 process 는 종료된다.</p>

<h3><code>Phoenix PubSub</code> 과 <code>GenServer</code></h3>

<p> <code>Phoenix PubSub</code>은 내부적으로 <code>GenServer</code>를 사용하여 구축된다. <code>Phoenix PubSub</code>은 Elixir 어플리케이션 내에서 프로세스 간의 메시징을 쉽게 구현할 수 있도록 해주는 시스템입니다. 이는 주로 Phoenix framework 내에서 실시간 웹 기능을 구현하는 데 사용되며, 웹소켓을 통해 client-server 간의 메시지를 효율적으로 교환할 수 있게 해준다. 그 주요 역할은 다음과 같다.</p>

<ul>
  <li>상태 관리: 각 PubSub 서버는 구독 정보와 같은 상태를 유지 관리.</li>
  <li>메시지 처리: 발행된 메시지는 <code>GenServer</code> 프로세스를 통해 구독자들에게 전달.</li>
  <li>동기화 및 제어: <code>GenServer</code> callback을 통해 메시지 전송 및 구독 관리를 제어.</li>
</ul>

<br>
[참고 문헌 - ElixirCasts - #12: Intro to GenServer](https://elixircasts.io/intro-to-genserver)
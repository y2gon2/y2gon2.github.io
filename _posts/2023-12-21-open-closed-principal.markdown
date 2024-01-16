---
layout: post
read_time: true
show_date: true
title:  Open-Closed Principle (OCP)
date:   2023-12-21 10:32:20 +0900
description: Open-Closed Principle (OCP)
img: "posts/general/post_general08.jpg"
tags: [elixir, polymorphism, Open-Closed Principle, overloading, behaviour]
author: Yong gon Yun
github:  y2gon2/exercism/tree/main/document
mathjax: yes
---


Elixir에서 <strong>오픈-클로즈드 원칙(Open-Closed Principle, OCP)</strong>은 소프트웨어 엔지니어링의 SOLID 원칙 중 하나로, <strong>클래스, 모듈, 함수 등이 확장에는 열려 있으나, 수정에는 닫혀 있어야 한다</strong>는 개념. 이 원칙의 목적은 기존의 코드를 변경하지 않으면서도 시스템의 기능을 확장할 수 있게 하는 것이다.

Elixir는 함수형 언어이며, 모듈과 함수를 사용하여 이 원칙을 적용할 수 있다. Elixir에서 OCP를 적용하는 몇 가지 방법은 다음과 같다:

1. <strong>다형성(Polymorphism)을 사용하는 방법</strong><br>
Elixir에서는 프로토콜(Protocol)을 사용하여 다형성을 구현할 수 있다. 프로토콜은 서로 다른 데이터 타입에 대해 동일한 인터페이스를 제공하며, 새로운 타입을 추가할 때 기존 코드를 변경하지 않고도 기능을 확장할 수 있다.<br><br>
아래 예제와 같이 `great/1` 의 경우, 모두 동일한 parameter 갯수를 갖지만 각각 type 이 다르므로 각각 함수 요청을 구분하여, 해당 함수가 실행되도록 한다.

  ```elixir
  defmodule PolymorphismExample do
    # 인자가 맵이고 키 :name을 가진 경우
    def greet(%{name: name}), do: "Hello, #{name}!" 

    # 인자가 문자열일 경우
    def greet(name) when is_binary(name), do: "Hello, #{name}!" 

    # 위의 경우에 모두 해당하지 않을 때
    def greet(_), do: "Hello, there!" 
  end
  ```

2. <strong>함수 오버로딩</strong><br>
함수 오버로딩을 통해 같은 이름의 함수에 대해 다양한 패턴을 정의할 수 있다. 이를 통해 새로운 경우를 처리하기 위해 기존 함수를 수정하는 대신 새로운 함수 정의를 추가할 수 있다.
<br><br>
다음의 경우, parameter 갯수가 다름에 따라 각 함수는 구분되어진다.

```elixir
defmodule OverloadingExample do
  def sum(a, b), do: a + b # 두 개의 인자를 받는 함수
  def sum(list) when is_list(list), do: Enum.sum(list) # 리스트를 인자로 받는 함수
end
```
3. **행위(Behaviour)를 정의하는 방법**<br>
   Elixir에서는 행위(behaviour)를 정의하여 모듈이 특정 콜백을 구현하도록 할 수 있다. **(아직 이해가 부족하므로 추가 학습 필요)** 이를 통해 동일한 인터페이스를 가진 다양한 구현을 제공할 수 있으며, 새로운 구현을 추가해도 기존 모듈을 수정할 필요가 없다.

  - Behaviour 에 대하여
    Elixir 는 함수형 언어이므로 JAVA, 나 Python 과 같은 객체에 대한 개념이 존재 하지 않으므로, 상속 또한 존재하지 않는다. 그러나 약간 유사하게 동일한 함수 signiture 를 정의하여, 이를 필요한 상황에 맞춰 callback 함수를 구현할 수 있는 기능이 있으며, 이것이 곧 behaviour 이다. (OOP 에서 부모 객체 'animal' 에서 울음소리에 대한 함수를 구현하고, 자식 객체 'cat', 'dog' 에서 각각 함수를 상속 받아 내용을 다르게 구현하는 것과 유사한 기능을 사용할 수 있음.)
    <br><br>
    아래의 예제를 보면, 
    ```elixir
    defmodule Worker do
      @callback work(data :: any) :: String.t()
    end
    defmodule FileWorker do
      @behaviour Worker
      def work(data) do
        "Processing file: #{data}"
      end
    end
    defmodule DatabaseWorker do
      @behaviour Worker
      def work(data) do
        "Processing database entry: #{data}"
      end
    end
    ```
    `Worker` module 에서  `work/1` callback 함수를 정의한다. 이 때, 함수명, parameter & return type 에 대해서만 정의한다.<br><br>
    그리고 함수의 내용은 다른 module 에서 해당 함수를 필요할 때,  `@behaviour Worker` 로  callback 을 정의 하고, 함수를 구현하여 사용하므로, 각 module 에서 필요한 logic 을 맞추어 사용할 수 있다. <br> 
    [공식 문서 behaviour 설명](https://elixirschool.com/ko/lessons/advanced/behaviours) 


4. <strong>컨피규레이션을 통한 확장(추후학습 예정)</strong><br>
시스템을 구성하는 요소들을 컨피규레이션을 통해 정의하고, 새로운 구성 요소를 추가하여 기능을 확장할 수 있다.<strong>(아직 이해가 부족하므로 추가 학습 필요)</strong> 이 방법은 기존 시스템의 코드를 변경하지 않고도 새로운 기능을 추가할 수 있게 한다.


결론적으로 오픈-클로즈드 원칙을 적용하면, 시스템의 유지보수성과 확장성이 향상되며, 기존 코드의 안정성을 유지하면서 새로운 기능을 추가할 수 있습니다.
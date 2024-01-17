---
layout: post
read_time: true
show_date: true
title:  Elixir - intance 생성
date:   2023-12-29 13:32:20 +0900
description: Elixir - intance 생성
img: posts/general/post_general06.jpg
tags: [elixir, instance, struct]
author: Yong gon Yun
github:  y2gon2/pento1/tree/main/document
---
<p>Elixir 문범에서 struct 에 대한 instace를 생성하는 방법은 아래와 같이 두가지가 존재한다. (ChatGPT 가 설명한 그 용도의 차이점에 대해서.. 아직 잘 모르겠다. 내눈에는 그냥 동일한 용도로 사용되는 것 처럼 보인다. ;;)</p>

<h3><code>__MODULE__</code> 사용</h3>
<ul>
<li>사용법: <code>%__MODULE__{}</code> 구문은 주로 모듈 내부에서 해당 모듈의 구조체 인스턴스를 생성할 때 사용. 이 경우, 모듈 내부에서 직접 <code>%__MODULE__{field1: value1, field2: value2}</code>와 같이 구조체 인스턴스를 생성할 수 있다.</li><br>
<li>예시: 모듈 내부에서 <code>def new()</code> 함수를 정의하고, 이 함수 안에서 <code>%__MODULE__{}</code>를 사용하여 인스턴스를 생성할 수 있다.</li>
</ul>

<h3><code>def new(field \\ []), do: __struct__(field)</code> 정의</h3>
<ul>
<li>사용법: 이 방법은 모듈 외부에서 인스턴스를 생성할 때 사용합니다. 여기서 new 함수는 외부에서 호출할 수 있는 공개 인터페이스를 제공하고, <code>__struct__</code> 호출을 통해 내부적으로 구조체 인스턴스를 생성한다.</li><br>
<li>예시: 다른 모듈에서 <code>ModuleName.new(field_values)</code>를 호출하여 구조체 인스턴스를 생성할 수 있다. 여기서 field_values는 인스턴스의 필드를 초기화하기 위해 사용됨.</li>
</ul>

<h3>결론</h3>
<p>두 방식 모두 Elixir에서 구조체 인스턴스를 생성하는 방법. <code>__MODULE__</code> 방식은 주로 모듈 내부에서 사용되며, <code>def new(field \\ []), do: __struct__(field)</code> 방식은 모듈 외부에서 구조체 인스턴스를 생성할 때 사용되는 공개 함수를 제공한다. 두 경우 모두, <code>모듈명.new(field 값)</code>과 같은 형태로 호출하여 인스턴스를 생성할 수 있다.</p>


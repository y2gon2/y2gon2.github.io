---
layout: post
read_time: true
show_date: true
title:  slot attribute 사용 
date:   2024-01-01 10:32:20 +0900
description: slot attribute 사용 
img: posts/general/post_general07.jpg
tags: [phoenix, liveview, slop]
author: Yong gon Yun
github:  y2gon2/pento1/tree/main/document
---
<p>Phoenix LiveView 에서 동적인 component 를 삽입 하고자 하는 경우, 해당  component attribute 로 `slot` 을 정의하고 이를 사용해 주어야 한다. </p>

<h3>사용 방법</h3>

```elixir
slot :블록명, required: true
def 컴포넌트명(assigns) do
	~H"""
	<동적으로 구현할 컴포넌트 태그>
		<>..사용자 구현...<>
		<%= render_slot(@블록명) %>
	</동적으로 구현할 컴포넌트 태그>
	"""
end
```

<h3> Slot 정의</h3>
<ul>
<li><code>slot :블록명</code> : 컴포넌트 내부에 동적으로 콘텐츠를 삽입할 수 있는 블록명이라는 이름의 슬롯을 정의.</li>
<li><code>required: true</code>:  이 슬롯이 반드시 제공되어야 함을 의미. 이 컴포넌트를 사용할 때는 블록명 슬롯에 대한 내용을 제공해야 한다.</li>
</ul>


<h3>컴포넌트 정의</h3>
<ul>
<li><code>def 컴포넌트명(assigns) do ... end</code> : 컴포넌트를 정의하는 함수. 이 함수 내에서 HTML 태그와 Elixir의 템플릿 언어를 사용하여 컴포넌트의 구조를 정의한다.</li>
</ul>


<h3>동적 콘텐츠의 삽입 위치</h3>
<ul>
<li><code><%= render_slot(@블록명) %></code> : 구문은 정의된 블록명 슬롯에 전달된 콘텐츠를 해당 위치에 렌더링.이 위치는 <code>"동적으로 구현할 컴포넌트 태그"</code> 내부로 이 태그 안에서 블록명 슬롯에 제공된 콘텐츠가 렌더링됨.</li>
</ul>


<h3>사용자 구현</h3>
<ul>
<li>사용자는 이 컴포넌트를 사용할 때 블록명 슬롯에 원하는 콘텐츠를 제공할 수 있다. 이 콘텐츠는 다양한 HTML 요소, 다른 LiveView 컴포넌트, 또는 동적인 데이터를 포함할 수 있다.</li>
</ul>


<h3>실제 코드 예시</h3>

```elixir
attr :view_box, :string
slot :inner_block, required: true
def canvas(assigns) do
  ~H"""
  <svg viewBox={ @view_box }>
    <defs>
      <%!-- 위에 정의된 point component 사용하여 정사각형 생성 --%>
      <rect id="point" width="10" height="10" />
    </defs>
    <%= render_slot(@inner_block) %>
  </svg>
  """
end
```
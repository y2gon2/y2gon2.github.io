---
layout: post
read_time: true
show_date: true
title:  (App 개발 02) root.html.heex 과 app.html.heex 에 대해
date:   2024-01-25 08:32:20 +0900
description: Phoenix LiveView 에서 기본 <head> 설정 및 공통으로 rendering 될 요소를 넣을 수 있는 root.html.heex 과 app.html.heex 에 대해 각각의 용도를 확인하고 이를 수정 사용하는 작업 방법 확인함
img: posts/general/post_general16.jpg
tags: [phoenix, liveview, root.html.heex, app.html.heex, applciation_개발1]
author: Yong gon Yun
---

현재 Phoenix LiveView application 작업을 진행하면서, 아래와 같이 page 최상단에 메뉴바를 띄우고자 한다. 

<center><img src="assets\img\posts\header.png" width="500"></center>

다만 `/` 과 `/games` url 에 대해서는 메뉴바가 있고, `/games/:id` url 에 대해서는 메뉴바가 없도록 구성하고 싶다. 해당 작업을 진행하면 `root.html.heex` 와 `app.html.heex` 파일을 수정하고, 수정된 파일을 어떻게하면 적절하게 이용할 수 있을지 위에서의 고민을 토대로 각 파일에 대해 알아본다. 

### root.html.heex 역할

이 파일은 전체 Phoenix 애플리케이션의 최상위 레이아웃을 정의하며, 다른 템플릿들은 이 안에 삽입되어 최종 HTML 문서를 형성한다. 일반적으로 전체 애플리케이션에 걸쳐 공통적으로 사용되는 HTML 요소를 포함한다.(`<head>` 태그 내의 meta data, stylesheet link, javascript 파일 등)

`router.ex` 에서 `pipeline :browser` 를 통해 주입되며, 모든 정적 html와 LiveView는 이 파일의 구조 안에서 렌더링된다. 

만약 `root1.html.heex` 파일에서 해당 메뉴바를 구현하고, `root2.html.heex` 에는 메뉴바를 구현하지 않고, 이렇게 두 개의 파일을 만들어서 `pipeline :browser1` , `pipeline :browser2` 를 각각 정의하여 이를 각각 필요한 url 에 맞게 사용하고자 시도하였으나, 이런 경우, 동일한 매개변수를 가지는 `live_session` macro 가 두번 정의되어야 한다. 이는 다음의 에러가 발생시킨다. 

```bash
** (RuntimeError) attempting to redefine live_session :require_authenticated_user.
live_session routes must be declared in a single named block.
```

따라서 동일한 `scope` macro 에서 정의되어야 하는 url page 에 대해서는 동일한 `root.html.heex` 가 적용되어야 한다. 

### app.html.heex 역할

`app.html.heex`는 `root.html.heex` 내에 삽입되는, 특정 부분의 레이아웃을 정의하는 파일로, 주로 애플리케이션의 주요 컨텐츠를 포함하며, 특정 페이지나 섹션에 대한 레이아웃을 정의하는 데 사용된다. 예를 들어, header, footer, sidebar 등 페이지의 주요 부분을 구성할 수 있으며, 페이지 별로 다른 내용을 표시하는데 사용된다. 

따라서 url 별로 header 적용 여부를 다르게 하고 싶다면 `app.html.heex` 파일을 각각 만들어서 각 page mdoule 에서 다른 template 을 가져오면 된다. 

### 구현

기존에 작성한 header 는 `root.html.heex` 에 있었다. 그래서 해당 code 를 `app.html.heex` 로 이동시키고, header 가 없은 `app_no_header.html.heex` 를 추가 생성하였다. 

그리고 `app_no_header.html.heex` 을 liveview 에서 가져올 수 있도록 `my_pjt_web.ex` 에 callback 함수를 추가해주었다. 

```elixir
defmodule MyPjt1Web do
  ...
  # 기존 app.html.heex 를 layout 로 사용하는 함수
  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {MyPjt1Web.Layouts, :app}

      unquote(html_helpers())
    end
  end

  # 추가된 함수. app_no_header.html.heex 를 layout 로 사용
  def live_view_no_header do
    quote do
      use Phoenix.LiveView,
        layout: {MyPjt1Web.Layouts, :app_no_header}

      unquote(html_helpers())
    end
  end
  ...
end
```

다음으로 각 url 대한 module 에서 `use` macro 를 사용하여 앞에서 정의한 callback 을 맞게 가져옴

```elixir
defmodule MyPjt1Web.GameLive.Index do
  use MyPjt1Web, :live_view
  ...
end
```

```elixir
defmodule MyPjt1Web.GameLive.Show do
  use MyPjt1Web, :live_view_no_header
  ...
end
```

마지막으로 남은 것은 `get "/", PageController, :home` 에서 가져오는 module 만 처리해주면 된다. 그런데, 분명 `my_pjt1_web`module `controller` callback 에 `layout: {MyPjt1Web.Layouts, :app}` 이 정의되어 있음에도 불구하고, application 실행시 `app.html.heex` 의 header 가 표시되어지지 않았다. 그래서 어쩔수 없이 `home.html.heex` 에 동일한 header 를 추가하여 
자체적으로 header 를 rendering 하도록 구현하였다. 
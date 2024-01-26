---
layout: post
read_time: true
show_date: true
title:  Account context - users table 에 nickname 항목 추가
date:   2024-01-25 08:32:20 +0900
description: 계정 정보에서 nickname 정보가 필요함에 따라, 이를 기존에 생성한 users table 에 추가하고, 계정 생성 시, nickname 을 입력하도록 함. 
img: posts/general/post_general17.jpg
tags: [phoenix, liveview, migration, table_항목_추가, schema, changeset/2]
author: Yong gon Yun
---

Phoenix LiveView Authrization 설정을 위해 lon in 기능을 활성화에 필요한 계정 생성 작업이 필요하다. 이 때, `mix phx.gen.auth Accounts User users` command 를 통해 사용자 email, password 정보를 저장하고 이를 사용하여 authrization, session 괸리를 위한 service code, template, token 저장 table 까지 모두 알아서 생성해 준다. 

매우 편리한 기능이지만, 해당 command 로 추가 정보를 저장/관리하는 기능을 함께 생성할 수는 없음을 확인하였다. 대신 추가 migration 생성 및 필요한 요소를 관련 code 에 직접 추가하여 사용 가능하였다. 

현재 작업하고 있는 application 에서 사용자 정보를 노출 시킬 때, email 보다 nickname 으로 보여지는 것이 좋다고 판단되어 이를 추가하고 실제 application 에 반영하는 작업을 정리해 보았다. 

### 1. migration 생성 및 실행

다음의 command 를 실행하여 migration script 파일을 생성

```bash
mix ecto.gen.migration add_nickname_to_users
```

이를 실행하면 `priv/repo/migrations/(생성일시)_add_nickname__to_users.exs` 파일이 생성된다. 해당 파일에서 `nickname` column 을 추가할 code 를 작성한다. 

```elixir
defmodule MyPjt1.Repo.Migrations.AddNicknameToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :nickname, :string
    end
  end
end
```

해당 파일을 아래의 command 로 실행하고, database 에 변경 사항이 반영되었는지 확인한다. 

```bash
mix ecto.migrate
```

### 2. `User` module 에서 schema 및 `changeset/2` 수정

아래와 같이 `Usher` module 에서 `schema` 에 field 를 추가시켜 준다. 

```elixir
  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :naive_datetime
    field :nickname, :string  # field 추가

    timestamps(type: :utc_datetime)
  end
```

그러나, field 를 추가하고, 계정 등록 module (`user_registration_live.ex`) 에서 nickname 입력을 구현하여도 실제로 저장이 되지 않는다. 그 이유는 nickname 정보까지 모두 입력 후 저장 버튼을 누를 때, 입력 값의 유효성 검증이 우선 진행되며, 검증을 통과된 경우, db 에 저장 및 authorization 작업이 진행되게 된다. 

그런데, 관련 유효성 검증 작업, 즉 `changeset/2` code 를 확인하면

```elixir
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_email(opts)
    |> validate_password(opts)
  end
```

여기에서 `cast(attrs, [:email, :password])` 함수는 매개변수로 입력된 key 들 (`:email, :password`) 에 대한 value 값이 변경되었을 때, 해당 항목에 대한 `changeset` 을 반환하는 함수이다. 즉 해당 항목에 `:nickname` 을 추가해 주어야 함께 `changeset` 으로 변환되어, 유효성을 검증하고, 다음 작업을 진행할 수 있게 된다. (`:nickname`에 대한 vaildation 은 필요하지 않아서 추가하지 않았음.) 

```elixir
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :nickname]) # :nickname 추가
    |> validate_email(opts)
    |> validate_password(opts)
  end
```

### 3. 계정 생성 시 nickname 추가 화면 구현

`user_registration_live.ex` `render/2` 내 아래와 같이 nickname 항목을 추가하면 최종적으로 계정 생성시 nickname 정보까지 입력해야 조건을 만들어 줄 수 있다. 

```elixir
...
  <.simple_form ... >
    ...
    <.input field={@form[:email]} type="email" label="Email" required />
    <.input field={@form[:password]} type="password" label="Password" required />
    <.input field={@form[:nickname]} label="Nickname" required />
    ...
  </.simple_form>
...
```
<center><img src="assets\img\posts\nickname_form.png" width="500"></center>
<br>
<center><strong>users table</strong></center>
<center><img src="assets\img\posts\nickname_db.png" width="700"></center>
<br>
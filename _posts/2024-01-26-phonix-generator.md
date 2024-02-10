---
layout: post
read_time: true
show_date: true
title:  Phoenix Live Generator
date:   2024-01-26 08:32:20 +0900
description: Phoenix Live Generator 는 주어진 resource 에 대한 기본적인 CRUD code 생성을 도와주는 utility 이다. 이에 대해 알아보자.  
img: posts/general/post_general18.jpg
tags: [phoenix, generator]
author: Yong gon Yun
---

(아래 내용은 [programming-phoenix-liveview_B10.0 - chapter 3 Generators: Contexts and Schemas](https://pragprog.com/titles/liveview/programming-phoenix-liveview/) 를 정리한 것임을 밝힙니다.) 


### Phoenix Live Generator 란?

Phoenix Live Generator 는 주어진 resource 에 대한 기본적인 CRUD code 생성을 도와주는 utility 로 다음 작업에 대한 설정을 자동을 생성해준다. 

* backend  : schema, context 
* frontend : routs, LiveView, templates

다만 위에서 표현한 'code 생성' 의 의미는 elixir 에서는 조금 다른 의미를 포함하고 있다. 이는 Generator 가 자체적으로 새로운 code 을 생성 해준다기보다, 이미 정의된 macro 를 사용하여 'code 를 생성하는 code' 를 실행시킴으로써, 최종적으로 사용자가 정의한 code 를 얻을 수 있게 되는 것을 의미한다. 

결과적으로 Generator 를 사용하여, 작성자의 반복적 작업을 줄여 줌으로써, 작성자는 각 부분의 logic 및 공통적이지 않은 부분의 작업에 집중할 수 있도록 도와준다. 

### Phoenix Live Generator 기본 구조

간단한 예제로 상품에 대한 정보를 DB 에 저장하고, 상품 리스트를 화면에 보여주는 view 를 가진 application 을 개발한다고 가정해보면, 해당 application 의 구조를 아래와 같이 그려볼 수 있다. 

<center><img src="assets\img\posts\2024-01-26-product_diagram.png" width="300"></center>

* frontend: web 에서 `/product` GET 요청이 있을 때, 상품 리스트를 보여주는 tempalte 이 rendering 됨. 
* backend : phoenix application 에서 live view 는 전체적으로 context 에 관리되며, core part 인 schema 를 감싸고 있다. 즉, context 는 frontend 및 DB 와 상호작용을 담당한다. 

### Phoenix Live Generator 의 실행

기본 원리와 개념 이해를 위해, 아래 command 를 실행하여, Generator 를 실행시킨다. 

```bash
mix phx.gen.live Catalog Product products name:string \
description:string unit_price:float sku:integer:unique
```

그러면 자동으로 관련 migration, schema 를 포함한 context, template 파일들이 생성되며, command 속성값들의 의미는 다음과 같다.

* Catalog : boundary layer 인 context
* Product : applcation core 인 schema
* prodcuts: DB table
* name:string description:string unit_price:float sku:integer:unique : schema fields & DB table colums

### Generated Core 의 이해

Generated Core (ex. Product) 는,

* 항상 동일한 입력에 대해 동일한 출력을 제공하는 순수함수이여야 한다. 
* database 를 관리하며 상호작용 한다. 즉 database table 생성, data 관리/유지 작업, transaction 과 query 준비 작업을 담당한다.

이와 관련된 파일들을 살펴보면 다음과 같다. 

#### The Product Migration

database table 을 정의한 migration 파일을 `pento/priv/repo/migrations/20230728120332_create_products.exs`와 같이 생성되어 진다. 해당 code 를 살펴보면 아래와 같이 command 에서 명시한 table 이름, column 명, data type 이 생성되어 있다. 

```elixir
defmodule Pento.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string
      add :description, :string
      add :unit_price, :float
      add :sku, :integer

      timestamps()
    end

    create unique_index(:products, [:sku])
  end
end
```

그리고 아래 command 실행을 통해 DB 에 해당 table 이 생성됨을 확인할 수 있다. 

```bash
mix ecto.migrate
```

#### The Product Schema

아래 `lib/pento/catalog/product.ex` 생성된 파일 `schema` macro 구현부를 통해 Elixir 구조체와 databalse `products` table record 간 변환할 수 있게 해준다. 

```elixir
defmodule Pento.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset
  
  schema "products" do
    field :description, :string
    field :name, :string
    field :sku, :integer
    field :unit_price, :float
  timestamps()
end
```

관련 작업을 수행해주는 함수의 경우, macro 에 의해 자동 생성되며, 그 목록은 아래와 같다.

```bash
iex> alias Pento.Catalog.Product
iex> exports Product
__changeset__/0 __schema__/1 __schema__/2 __struct__/0
__struct__/1 changeset/2

```

이중 `schema` 함수가 elixir 구조체를 생성해서 database table record 와 엮는 작업을 담당한다.

해당 구조체 생성은 `struct/1` 로 생성하며, 이를 CLI 상태에서 실행하여, 직접 그 결과를 확인할 수 있다. 

```bash
iex> Product.__struct__(name: "Exploding Ninja Cows")
%Pento.Catalog.Product{
  __meta__: #Ecto.Schema.Metadata<:built, "products">,
  description: nil,
  id: nil,
  inserted_at: nil,
  name: "Exploding Ninja Cows",
  sku: nil,
  unit_price: nil,
  updated_at: nil
}
```

여기에서 `id`, `inserted_at`, `updated_at` field 의 경우, 자동 생성되는 field 로 record 관리에 필요한 data (ex. `id` 의 경우, 각 record 고유값으로 식별자 역할) 들을 저장한다. 

`changeest` 의 경우, 기존에 정리된 내용 참고. ([changeset/2 in Ecto Library](https://y2gon2.github.io/changeset.html))

### Generated Boundary 의 이해

boundary 영역에 대한 code 을 Context 라고 하며, 외부에서 입력된 data 를 sanitizing, validating 해서 변환된 data 를 cord 영역으로 넘겨주는 작업을 담당하며 이를 정리하면 아래와 같다. 

* Access External Services : 외부 서비스에 대한 단일 접근 지점을 제공. application 에서 필요한 외부 data 나 기능을 통합하고, 이러한 서비스들과 상호 작용을 중앙에서 관리하게 해줌.
* Abstract Away Tedious Details : 반복적이거나 복잡한 작업등ㄹ을 숨김(추상화) 함으로써, 개발자가 보다 중요한 logic 에 집중할 수 있도록 함. 예를 들어, data formating 이나 네트워크 통신과 같은 작업을 사전에 처리
* Handle uncertainty : {:ok, result} 또는 {:error, message} 와 같은 형태로 그 결과를 반환함으로써, 성공 또는 실패를 명확하게 함. 이를 통해, 오류 처리 및 예외 상황을 보다 효율적으로 처리할 수 있음.
* Present a single, common API : 하나의 database table 관련 service 들에 대해 단일 접근점을 제공하여 application 내 다양한 기능들을 일관된 방식으로 사용할 수 있게 해주며, 이를 통해 application 의 사용성과 유지보수서을 향상시킴.

#### 외부 service 로부터의 접근의 예

database 의 접근은 applciation 입장에서 외부 service 에 대한 접근에 해당한다. 관련 Repo 작업은 `Ecto` library 함수를 사용하게 되며, 따라서 `Ecto` code 도 core 와 boundary 부분으로 나누어지게 된다. 

* Ecto core : query build & transaction 준비 작업 (외부 환경에 영향 없이 입력값과 내부 logic 에만 영향을 받아 결과가 항상 확정적이고 예측가능, ex. `changeset`)
* Ecto boundary : `Ecto.Repo` 작업의 경우, 외부 상황 (ex. DB server 연결 상태)에 따라 그 결과가 바뀔 수 있으므로, boundary 에 해당 
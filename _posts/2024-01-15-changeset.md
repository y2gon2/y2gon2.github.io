---
layout: post
read_time: true
show_date: true
title:  changeset/2 in Ecto Library
date:   2024-01-15 10:32:20 +0900
description: changeset/2 in Ecto Library
img: posts/general/post_general12.jpg
tags: [ecto, changeset/2]
author: Yong gon Yun
---
<p>Phoenix LiveView 에서 DB 처리 작업은 Ecto library 를 사용하여 작업이 진행된다. 이와 관련하여, Ecto 의 기능과 구성요소에 대해 알아보고, 여기에서 <code>changeset/2</code> 함수에 대해 좀더 알아 본다. </p>

<h3>Ecto 란?</h3>
<p>Phoenix LiveView 에서 사용하는 Ecto library 는 Elixir 언어를 위한 database wrapper 이다. 주로 Elixir web-framewor 인 Phoenix 와 함께 사용되며, 데이터베이스 상호작용을 효율적으로 만들어 준다.</p>

<p><strong>구성요소</strong></p>

<ol>
  <li>
    <p>Repo (Repository)</p>
    <ul>
      <li>데이터베이스와의 모든 상호작용(CRUD)을 처리</li>
      <li>데이터베이스에 query를 보내고 결과를 반환 받음</li>
      <li>여러 Repo 를 지원 할 수 있어, 다양한 데이터베이스와 동시에 작업 가능</li>
    </ul>
  </li>
    <li>
    <p>Schema</p>
    <ul>
      <li>데이터베이스 table 과 Elixir 구조체 간 mapping 을 정의</li>
      <li>각 field 는 Elixir data type 으로 선언됨</li>
      <li>schema 는 data 유효성 검사와 제약 조건도 함께 정의함</li>
    </ul>
  </li>
    <li>
    <p>Changeset</p>
    <ul>
      <li>data 를 삽입하거나 업데이트하기 전에 데이터를 검증하고 변환하는 역할</li>
      <li>유효성 검사, 제약 조건 확인, filtering, 형식 변환 등을 처리</li>
    </ul>
  </li>
    <li>
    <p>Query</p>
    <ul>
      <li>Elixir 의 구문을 사용하여 database query 를 생성 또는 사용자 정의 query 구현 가능하도록 함</li>
      <li>query 는 Ecto.Query module 을 사용하여 작성됨</li>
      <li>query 는 compile 타임에 생성되므로, 효율적인 성능을 발휘함</li>
    </ul>
  </li>
</ol>

<p><strong>Ecto 의 특징</strong></p>
<ul>
  <li>Database Adapter : PostgreSQL, MySQL, SQLite 등 다양한 데이터베이스를 지원</li>
  <li>Migration : 데이터베이스 schema 변경을 위한 migration 을 쉽게 관리</li>
  <li>Transaction: 데이터베이스 transaction을 통해 데이터 일관성을 보장</li>
  <li>Multi-Tenancy : 필요한 경우, 동일한 app 내에서 여러 데이터베이스를 다룰 수 있음</li>
</ul>

<h3>changset/2</h3>

<p><strong><code>changset/2</code>의 역할</strong></p>
<ul>
  <li><code>cast/3</code>를 사용하여 비 구조체 type 의 user data 를 구조체 형태로 변환하여 Ecto 데이터베이스 schema 와 안전한 상태로 mapping 될 수 있도록 변환</li>
  <li>관련 feild 값을 capture 하여 데이터베이스에 저장된 값과 비교, 변경 여부를 확인</li>
  <li>현재 작업 중이 값이 유효한지를 검증한다. 변경된 값이 query 를 통해 데이터베이스에 값이 저장 또는 수정되기 전에, 유효성 (field type, 길이, 값의 범위, 존재 여부 등) 을 확인하여 잘못된 형식 또는 잘못된 값이 아닌지를 먼저 판단한다. 해당 과정은 각 field 에 대해 항상 동일한 규칙과 조건을 적용한다. (consistent rule)</li>
  <li>유효성 확인의 결과로 <code>:ok</code> 또는 <code>:error</code> 상태를 반환하여 context 가 query 작업을 진행할지 여부에 대한 state 를 제공한다.</li>
</ul>

<p><strong>예제 code</strong></p>

```elixir
def changeset(product, attrs) do
  product
  |> cast(attrs, [:name, :description, :unit_price, :sku])
  |> validate_required([:name, :description, :unit_price, :sku])
  |> unique_constraint(:sku)
  |> validate_number(:unit_price, greater_than: 0.0)
end
```
<ol>
  <li><code>cast/3</code> 를 통해 attr key-values 중 <code>product</code> 구조체의 field (<code>[:name, :description, :unit_price, :sku]</code>) 에 해당하는 값이 있는지 확인하고 해당하는 값을 <code>product</code> 구조체로 변환</li>
  <li><code>validate/2</code>, <code>unique_constraint/2</code>, <code>validate_number/2</code> 함수들을 통해 유효성 검사를 진행</li>
  <li>최종으로 해당 값이 존재하고, 유효성에 문제가 없으면 <code>:ok</code> 아니면 <code>:error</code> 상태를 반환한다.</li>
  <li></li>
</ol>

 * [참고 문헌 - programming-phoenix-liveview_B10.0](https://pragprog.com/titles/liveview/programming-phoenix-liveview/)
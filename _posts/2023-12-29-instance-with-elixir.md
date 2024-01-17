---
layout: post
read_time: true
show_date: true
title:  struct - instance 에 대해 (Elixir vs OOP languages)
date:   2023-12-29 10:32:20 +0900
description: struct - instance 에 대해 (Elixir vs OOP languages)
img: posts/general/post_general05.jpg
tags: [oop, instance, struct, phoenix, liveview, elixir]
author: Yong gon Yun
github:  y2gon2/pento1/tree/main/document
---
<p>elixir 에서의 구조체는 상속, 다형성 등이 지원되지 않고 한번 정의되면 구조체 내부 field 값을 변경할 수 없는, 내부에 field 가 존재하는 사용자 정의 type 이며, 해당 구조체 type 에 실제 data 를 가지게 하고 이를 변수 매칭 시킨것이 elixir instance 이다. </p>

<h3>유사점</h3>
<ol>
<li>데이터 캡슐화: Elixir의 구조체와 Java나 Python의 인스턴스 모두 데이터를 캡슐화. 여러 데이터를 하나의 구조로 묶어 관리할 수 있다.</li><br>
<li>필드 정의: 두 언어에서는 자료구조에 필드(데이터 요소)를 정의할 수 있으며, 이러한 필드는 각각의 자료구조에 속한 정보를 나타냄.</li><br>
<li>타입 안정성: Elixir의 구조체와 Java의 객체는 둘 다 특정 타입에 속하는 데이터를 담는데, 이는 데이터 타입에 대한 안정성과 예측 가능성을 제공.</li>
</ol>

<h3>차이점</h3>
<ol>
<li>불변성(Immutability) vs 가변성(Mutability): Elixir의 구조체는 불변성을 가짐. 한 번 생성되면 그 상태를 변경할 수 없음. 반면, Java나 Python의 객체는 가변적이며, 객체의 상태(필드 값 등)를 변경할 수 있음.</li><br>
<li>함수형 vs 객체지향: Elixir는 함수형 프로그래밍 패러다임을 따르기 때문에, 데이터와 함수가 분리되어 있음. 구조체는 단지 데이터를 담는 용도로 사용되며, 모든 작업은 순수 함수를 통해 처리됨. 반면, Java나 Python에서는 객체가 데이터와 그 데이터를 조작하는 메소드를 모두 포함.</li><br>
<li>상속과 다형성: Java나 Python에서는 클래스 상속과 다형성이 중요한 특징으로 객체는 부모 클래스의 속성과 메소드를 상속받을 수 있으며, 인터페이스나 추상 클래스를 통해 다형성을 구현할 수 있음. 반면, Elixir의 구조체는 이런 상속 메커니즘이나 다형성을 지원하지 않음.</li><br>
<li>메소드와 함수: Java나 Python에서 객체는 자신의 메소드를 가지고 있으며, 이를 통해 객체의 상태를 변경하거나 정보를 얻을 수 있음. Elixir에서는 모든 작업이 함수를 통해 이루어지며, 이 함수들은 구조체의 데이터에 대한 연산을 수행하지만, 구조체 내부에 정의되지 않음.</li>
</ol>

<h3>결론</h3>
<p>Elixir의 구조체는 Java나 Python의 객체와 유사하게 데이터를 캡슐화하는 역할을 하지만, 불변성, 함수형 패러다임, 상속 및 다형성 부재, 메소드와 함수의 차이라는 측면에서 분명한 차이점이 있다. 이러한 차이점들은 Elixir가 가진 함수형 프로그래밍의 특징을 반영한다.</p>


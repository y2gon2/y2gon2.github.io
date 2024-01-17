---
layout: post
read_time: true
show_date: true
title:  Elixir 의 Map, Struct 등은 왜 immutable data types 인가?
date:   2024-01-03 10:32:20 +0900
description: Elixir 의 immutable data types (Map, Struct)
img: posts/general/post_general10.jpg
tags: [elixir, map, struct, immutable data type]
author: Yong gon Yun
github:  y2gon2/exercism/blob/main/document
---
<p>Elixir 에서 Map 은 immutable type 이다. 따라서 <code>Map.delete/2</code>, <code>Map.put/3</code>, <code>Map.update/4</code> 등과 같은 함수는 실제로 기존 map data 를 수정하는 것이 아니라, 수정되된 값으로 새로운 map data 를 만들고 이것을 재할당 하는 것이다.</p>
<p>Struct 의 경우도, 한번 생성된 instance 의 내부 field 값을 변경하고자 하는 경우, 이는 수정이 아닌, 새로운 data 생성 및 이를 재할당 하는 것이다. 그런데 list, map 과 같이 많은 데이터를 포함하고 있는 경우, 그중 하나의 값이 바뀔 때마다 매번 모든 부분에 대한 재할당을 진행한다면, 메모리 사용이나 성능상 단점이 매 커보인다.</p>
<p>그렇다면, immutable data type 으로 처리할 때 어떤 이점이 있을 수 있으며, 예상되는 문제점은 어떻게 해결할까?</p>

<ul>
<li>구조적 공유(Structural Sharing): 변경 불가능한 데이터 구조에서는 종종 구조적 공유 작업이 필요하다. 즉, 새로운 맵을 생성할 때 전체 구조를 복사하는 대신, 변경되지 않은 부분은 기존 구조를 재사용하여 필요한 메모리 양과 복사 작업이 크게 줄인다. (결국 immutable data type 이라도 매번 모든 data 에 대한 memory 할당 및 쓰기 작업이 진행되지는 않는다.)</li><br>
<li>예측 가능성과 안정성: 데이터의 불변성은 함수의 부작용을 줄여준다. 이는 프로그램의 동작을 예측하기 쉽게 만들고, 디버깅과 유지보수를 용이하게 한다. </li><br>
<li>병렬 처리: 데이터가 변경 불가능하면 여러 스레드나 프로세스에서 동시에 데이터에 접근해도 안전하므로, 병렬 처리와 동시성 프로그래밍에서 큰 이점을 제공한다.</li><br>
<li>최적화: 현대의 가비지 컬렉션(GC) 시스템은 변경 불가능한 데이터 구조를 효율적으로 처리할 수 있도록 설계되어 있다. 따라서 새로운 구조를 생성하는 오버헤드는 종종 생각보다 작다.</li>
</ul>


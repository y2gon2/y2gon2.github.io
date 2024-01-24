---
layout: post
read_time: true
show_date: true
title:  Phoenix LiveView 에서 사용자 정의 JS code 사용 방법
date:   2024-01-24 08:32:20 +0900
description: Phoenix LiveView 에서 사용자 정의 JS code 구현 및 적용을 위한 Node.js 설정 및 render/1 에 적용하는 과정
img: posts/general/post_general15.jpg
tags: [phoenix, liveview, custom javascript, node.js]
author: Yong gon Yun
---

<p>Phoenix LiveView 를 사용하여 아래와 같이 버튼 클릭시 번갈아가며 버튼의 배경색과 내용이 바뀌는 toggle button 을 사용하고자 하였다. 그런데 기존의 Phoenix LiveView 제공 html tag 및 css 로 이를 생성할 수 없었으며, 따라서 자체적으로 JS 를 작성하여 기존 button 에 적용해야 하는 상황이다. 해당 과정에서 필요한 설정 및 <code>render/1</code>에 적용하기까지의 과정을 정리하고자 한다. </p>

<center>
  <img src="assets\img\posts\toggle_button.png" width="300">
</center>

<h3>1. Node module 설치 및 관련 package 설치</h3>

<p>(1) <code>package.json</code> 생성</p>

```bash
cd assets
npm init
```

<p>만약 <code>package.json</code> 파일이 없다면, 새로 생성해야 한다. 이를 위해 <code>npm init</code> 명령어를 실행하여 새로운 <code>package.json</code> 파일을 생성할 수 있다. 이 과정에서 프로젝트에 대한 기본 정보를 입력해야 한다.</p>

<p>(2) <code>npm init</code> 작업을 위한 기본 정보 입력
</p>
<p><code>npm init</code> 을 실행하면 프로젝트 이름, 버전, 설명, 진입점(주로 index.js), 테스트 명령어, 저장소, 키워드, 라이선스 등을 입력을 요청 받는다. 입력을 완료하면 <code>package.json</code> 이 생성되며, 여기서 해당 내용 등을 수정, 추가할 수 있다. 해당 script 은 다음과 같다.</p>

```json
{
  "name": "***",
  "version": "1.0.0",
  "description": "phoenix liveview project",
  "main": "tailwind.config.js",
  "author": "***",
  "license": "ISC",
  "repository": {
    "type": "git",
    "url": "git+https://github.com/***/***.git"
  },
  "keywords": [
    "phoenix"
  ],
  "bugs": {
    "url": "https://github.com/***/***/issues"
  },
  "homepage": "https://github.com/***/***#readme"
}
```

<p>(3) Webpack 설치 전 설정 추가</p>

<p><code>package.json</code> <code>scripts</code> 섹션에 <code>deploy</code> 스크립트를 추가해야 웹팩을 사용하여 build 할 수 있다. script 섹션 설정을 포함한  다음 코드를 <code>package.json</code> 에 추가한다.</p>

```json
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1",
    "deploy": "webpack --mode production"
  }
```

<p>Webpack 을 설치할 때, 진입점이 필요하다. <code>assets/src</code> 위치에 <code>index.js</code> 파일을 생성하고 프로젝트에 필요한 기본 JavaScript 코드나 모듈 가져오기(import)를 추가한다.</p>

```
// 예시: assets/src/index.js
import "phoenix_html";
// 다른 필요한 JavaScript 코드나 모듈 import
```

<p>(4) Webpack 설정 config 파일 추가</p>

<p><code>assets</code> 디렉토리 내에 <code>webpack.config.js</code>을 생성하고 진입점(entry point)으로 <code>index.js</code> 을 설정해준다. 그 밖에 output, loader 등을 포함하여 다음과 같이 생성한다.</p>

```
const path = require('path');

module.exports = {
  // 진입점 설정
  entry: './js/app.js', // 이 경로는 프로젝트에 맞게 조정해야 합니다

  // 출력 설정
  output: {
    path: path.resolve(__dirname, '../priv/static/assets'), // 출력 디렉토리
    filename: 'app.js', // 출력 파일명
  },

  // 모듈 설정
  module: {
    rules: [
      {
        test: /\.js$/, // .js 파일에 대한 처리
        exclude: /node_modules/, // node_modules 디렉토리 제외
        use: {
          loader: 'babel-loader', // Babel 로더 사용
          options: {
            presets: ['@babel/preset-env'], // Babel 프리셋 설정
          },
        },
      },
      // 추가적인 로더 설정(예: CSS, 이미지 파일 등)
    ],
  },
};
```


<h3>2. Node 모듈 설치 및 Node.js 의존성 설정</h3>

<p>(1) Node 모듈 설치</p>
<p><code>assets</code> 디렉토리로 이동하여 <code>npm install</code>을 실행한다. 이 명령어는 <code>package.json</code>에 정의된 모든 Node 의존성을 설치한다. Phoenix 프로젝트의 경우,<code>phoenix</code>, <code>phoenix_html</code>, <code>phoenix_live_view</code> 패키지들은 자동으로 <code>package.json</code>에 추가되어 있어야 한다.</p>

```bash
cd assets
npm install
```

<p>(2) Node.js 필수 Package 설치</p>

<p>- Webpack<br> assets (HTML, CSS, JavaScript 파일, 이미지, 폰트 등 웹 애플리케이션을 구성하는 모든 정적 파일들) 을 bundling (여러 개의 파일을 하나 또는 소수의 파일로 결합하는 과정. 이를 통해 네트워크 요청 최소화, application 최적화, 의존성 관리의 이점이 있음) 하기 위해 필요</p>

```bash
npm install webpack webpack-cli --save-dev
```

<p>- Babel<br> JavaScript 코드를 변환하기 위한 컴파일러. ES6 이상의 코드를 이전 버전의 JavaScript로 변환하는데 사용.</p>

```bash
npm install @babel/core @babel/preset-env babel-loader --save-dev
```

<p>- CSS 관련 package<br>CSS를 처리하기 위해 필요한 패키지들</p>

```bash
npm install css-loader style-loader mini-css-extract-plugin --save-dev
```

<p>- Tailwind CSS</p>

```bash
npm install tailwindcss postcss autoprefixer --save-dev
```

<p>(3) Node.js Package 중 Phoenix LiveView 관련 설치</p>

<p><code>phoenix</code>, <code>phoenix_live_view</code>, <code>phoenix_html</code> package 를 설치하기 전, <code>assets/js/app.js</code> 다음 코드가 없다면 추가해준다.(phoenix_live_view 0.20.1 기준 기본적으로 추가되어 있음.)</p>

```
import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
```

<p><code>assets</code> 디렉토리에서 해당 package 를 추가해준다.</p>

```
npm install --save phoenix phoenix_html phoenix_live_view
```
<p>제대로 설치되었다면, 앞에서 설치한 Node.js Package 디렉토리가 <code>assets/node_modules</code>에 생성된다.</p>

<h3>3. JavaScript 파일 작성</h3>
<p>앞의 과정에서 사용자 정의 JavaScript 를 사용할 수 있도록 관련 설정을 완료하였으므로, 이제 프로젝트의 <code>assets/js</code> 디렉토리 안에 사용자 정의 JavaScript 파일을 생성 (ex. <code>assets/js/custom.js</code>) 한다.</p>

```
export function toggleButton(btn) {
  btn.classList.toggle('bg-blue-500');
  btn.classList.toggle('bg-gray-600');

  if (btn.innerText === 'READY !!') {
    btn.innerText = 'WAIT  ......  ';
  } else {
    btn.innerText = 'READY !!';
  }
}
```

<h3>4. Phoenix 프로젝트에 JavaScript 통합</h3>
<p>(1) <code>app.js</code>에서 사용자 정의 <code>custom.js</code> 가져오기.</p>

<p><code>assets/js/app.js</code> 파일을 열고, 만들어진 <code>custom.js</code> 을 가져올 수 있도록 import 해준다.</p>

```
// assets/js/app.js
import { toggleButton } from "./custom";
window.toggleButton = toggleButton;
```

<p>이렇게 하면 <code>customFunction</code>을 전역 변수로 설정하여, HTML에서 접근할 수 있게 된다.</p>

<p>(2) Webpack build</p>
<p>지금까지의 변경사항을 적용하기 위해 <code>assets</code> 디렉토리에서 <code>npm run deploy</code>를 실행하여 JavaScript 파일을 빌드한다.</p>

<h3>5. LiveView에서 JavaScript 사용</h3>
<p>(1) LiveView 템플릿에 스크립트 적용</p>
<p>LiveView의 <code>render/1</code> 함수에서 해당 JavaScript 함수를 사용하는 HTML을 반환</p>

```elixir
def render(assigns) do
  ~L"""
  ... ...
    <button 
      type="button" 
      onclick="window.toggleButton(this)"
      class="text-white bg-blue-500 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2">
        READY !!
    </button>    
  ... ...  
  """
end
```

<h3>결론</h3>
<center>
  <img src="assets\img\posts\toggle_button.png" width="300">
</center>

<p>위 작업이 정상적으로 완료되었다면 의도한대로 사용자 정의 toggle button 이 동작하는 것을 확인 할 수 있다. </p>



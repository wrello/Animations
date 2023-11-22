"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[556],{3905:(e,t,n)=>{n.d(t,{Zo:()=>p,kt:()=>d});var a=n(67294);function i(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function r(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(e);t&&(a=a.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,a)}return n}function l(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?r(Object(n),!0).forEach((function(t){i(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):r(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function o(e,t){if(null==e)return{};var n,a,i=function(e,t){if(null==e)return{};var n,a,i={},r=Object.keys(e);for(a=0;a<r.length;a++)n=r[a],t.indexOf(n)>=0||(i[n]=e[n]);return i}(e,t);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);for(a=0;a<r.length;a++)n=r[a],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(i[n]=e[n])}return i}var u=a.createContext({}),s=function(e){var t=a.useContext(u),n=t;return e&&(n="function"==typeof e?e(t):l(l({},t),e)),n},p=function(e){var t=s(e.components);return a.createElement(u.Provider,{value:t},e.children)},m="mdxType",c={inlineCode:"code",wrapper:function(e){var t=e.children;return a.createElement(a.Fragment,{},t)}},k=a.forwardRef((function(e,t){var n=e.components,i=e.mdxType,r=e.originalType,u=e.parentName,p=o(e,["components","mdxType","originalType","parentName"]),m=s(n),k=i,d=m["".concat(u,".").concat(k)]||m[k]||c[k]||r;return n?a.createElement(d,l(l({ref:t},p),{},{components:n})):a.createElement(d,l({ref:t},p))}));function d(e,t){var n=arguments,i=t&&t.mdxType;if("string"==typeof e||i){var r=n.length,l=new Array(r);l[0]=k;var o={};for(var u in t)hasOwnProperty.call(t,u)&&(o[u]=t[u]);o.originalType=e,o[m]="string"==typeof e?e:i,l[1]=o;for(var s=2;s<r;s++)l[s]=n[s];return a.createElement.apply(null,l)}return a.createElement.apply(null,n)}k.displayName="MDXCreateElement"},26437:(e,t,n)=>{n.r(t),n.d(t,{contentTitle:()=>l,default:()=>m,frontMatter:()=>r,metadata:()=>o,toc:()=>u});var a=n(87462),i=(n(67294),n(3905));const r={},l=void 0,o={type:"mdx",permalink:"/Animations/CHANGELOG",source:"@site/pages/CHANGELOG.md",description:"v1.0.3",frontMatter:{}},u=[{value:"v1.0.3",id:"v103",level:2},{value:"v1.0.2",id:"v102",level:2},{value:"v1.0.1",id:"v101",level:2},{value:"v1.0.0",id:"v100",level:2}],s={toc:u},p="wrapper";function m(e){let{components:t,...n}=e;return(0,i.kt)(p,(0,a.Z)({},s,n,{components:t,mdxType:"MDXLayout"}),(0,i.kt)("h2",{id:"v103"},"v1.0.3"),(0,i.kt)("blockquote",null,(0,i.kt)("h6",{parentName:"blockquote",id:"11222023"},"11/22/2023")),(0,i.kt)("hr",null),(0,i.kt)("ul",null,(0,i.kt)("li",{parentName:"ul"},(0,i.kt)("p",{parentName:"li"},"Enhancements"),(0,i.kt)("ul",{parentName:"li"},(0,i.kt)("li",{parentName:"ul"},(0,i.kt)("a",{parentName:"li",href:"/api/AnimationsClient#LoadTracks"},(0,i.kt)("inlineCode",{parentName:"a"},"Animations:LoadTracks()")),' now automatically gives the rig an attribute "AnimationsRigType" set to the given ',(0,i.kt)("a",{parentName:"li",href:"/api/AnimationIds#rigType"},(0,i.kt)("inlineCode",{parentName:"a"},"rigType")),' (which is "Player" when the client calls it). ',(0,i.kt)("a",{parentName:"li",href:"https://github.com/wrello/Animations/issues/9"},"Issue #9")),(0,i.kt)("li",{parentName:"ul"},"Explained a convenient feature when using ",(0,i.kt)("a",{parentName:"li",href:"/api/AnimationsClient#SetTrackAlias"},(0,i.kt)("inlineCode",{parentName:"a"},"Animations:SetTrackAlias()"))," in the documentation of the function."))),(0,i.kt)("li",{parentName:"ul"},(0,i.kt)("p",{parentName:"li"},"Fixes"),(0,i.kt)("ul",{parentName:"li"},(0,i.kt)("li",{parentName:"ul"},"Fixed ",(0,i.kt)("a",{parentName:"li",href:"/api/AnimationsClient#GetTrackFromAlias"},(0,i.kt)("inlineCode",{parentName:"a"},"Animations:GetTrackFromAlias()"))," not working. ",(0,i.kt)("a",{parentName:"li",href:"https://github.com/wrello/Animations/issues/10"},"Issue #10")),(0,i.kt)("li",{parentName:"ul"},"Fixed ",(0,i.kt)("inlineCode",{parentName:"li"},"Util.ChildFromPath")," bug that caused errors when the ",(0,i.kt)("inlineCode",{parentName:"li"},"parent")," became nil during the recursion. ",(0,i.kt)("a",{parentName:"li",href:"https://github.com/wrello/Animations/issues/7"},"Issue #7"))))),(0,i.kt)("h2",{id:"v102"},"v1.0.2"),(0,i.kt)("blockquote",null,(0,i.kt)("h6",{parentName:"blockquote",id:"8312023"},"8/31/2023")),(0,i.kt)("hr",null),(0,i.kt)("ul",null,(0,i.kt)("li",{parentName:"ul"},(0,i.kt)("p",{parentName:"li"},"Enhancements"),(0,i.kt)("ul",{parentName:"li"},(0,i.kt)("li",{parentName:"ul"},"Added assertions to check ",(0,i.kt)("inlineCode",{parentName:"li"},"AnimationsClient")," and ",(0,i.kt)("inlineCode",{parentName:"li"},"AnimationsServer")," are being required on the client and server respectively. ",(0,i.kt)("a",{parentName:"li",href:"https://github.com/wrello/Animations/issues/4"},"Issue #4")))),(0,i.kt)("li",{parentName:"ul"},(0,i.kt)("p",{parentName:"li"},"Fixes"),(0,i.kt)("ul",{parentName:"li"},(0,i.kt)("li",{parentName:"ul"},"Fixed subsequent ",(0,i.kt)("inlineCode",{parentName:"li"},"Animations:AwaitLoaded()")," calls getting discarded. ",(0,i.kt)("a",{parentName:"li",href:"https://github.com/wrello/Animations/issues/5"},"Issue #5")),(0,i.kt)("li",{parentName:"ul"},"Fixed documentation. ",(0,i.kt)("a",{parentName:"li",href:"https://github.com/wrello/Animations/issues/3"},"Issue #3")),(0,i.kt)("li",{parentName:"ul"},"Fixed documentation. ",(0,i.kt)("a",{parentName:"li",href:"https://github.com/wrello/Animations/issues/2"},"Issue #2")),(0,i.kt)("li",{parentName:"ul"},"Removed an unecessary ",(0,i.kt)("inlineCode",{parentName:"li"},":"),". ",(0,i.kt)("a",{parentName:"li",href:"https://github.com/wrello/Animations/issues/1"},"Issue #1"))))),(0,i.kt)("h2",{id:"v101"},"v1.0.1"),(0,i.kt)("blockquote",null,(0,i.kt)("h6",{parentName:"blockquote",id:"832023"},"8/3/2023")),(0,i.kt)("hr",null),(0,i.kt)("ul",null,(0,i.kt)("li",{parentName:"ul"},"Fixes",(0,i.kt)("ul",{parentName:"li"},(0,i.kt)("li",{parentName:"ul"},"Fixed Animation:Init() error when called without optional ",(0,i.kt)("inlineCode",{parentName:"li"},"initOptions"),".")))),(0,i.kt)("h2",{id:"v100"},"v1.0.0"),(0,i.kt)("blockquote",null,(0,i.kt)("h6",{parentName:"blockquote",id:"832023-1"},"8/3/2023")),(0,i.kt)("hr",null),(0,i.kt)("ul",null,(0,i.kt)("li",{parentName:"ul"},"Initial release")))}m.isMDXComponent=!0}}]);
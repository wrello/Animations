"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[801],{3905:(e,n,t)=>{t.d(n,{Zo:()=>d,kt:()=>h});var i=t(67294);function a(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function r(e,n){var t=Object.keys(e);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);n&&(i=i.filter((function(n){return Object.getOwnPropertyDescriptor(e,n).enumerable}))),t.push.apply(t,i)}return t}function o(e){for(var n=1;n<arguments.length;n++){var t=null!=arguments[n]?arguments[n]:{};n%2?r(Object(t),!0).forEach((function(n){a(e,n,t[n])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(t)):r(Object(t)).forEach((function(n){Object.defineProperty(e,n,Object.getOwnPropertyDescriptor(t,n))}))}return e}function l(e,n){if(null==e)return{};var t,i,a=function(e,n){if(null==e)return{};var t,i,a={},r=Object.keys(e);for(i=0;i<r.length;i++)t=r[i],n.indexOf(t)>=0||(a[t]=e[t]);return a}(e,n);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);for(i=0;i<r.length;i++)t=r[i],n.indexOf(t)>=0||Object.prototype.propertyIsEnumerable.call(e,t)&&(a[t]=e[t])}return a}var p=i.createContext({}),m=function(e){var n=i.useContext(p),t=n;return e&&(t="function"==typeof e?e(n):o(o({},n),e)),t},d=function(e){var n=m(e.components);return i.createElement(p.Provider,{value:n},e.children)},s="mdxType",u={inlineCode:"code",wrapper:function(e){var n=e.children;return i.createElement(i.Fragment,{},n)}},c=i.forwardRef((function(e,n){var t=e.components,a=e.mdxType,r=e.originalType,p=e.parentName,d=l(e,["components","mdxType","originalType","parentName"]),s=m(t),c=a,h=s["".concat(p,".").concat(c)]||s[c]||u[c]||r;return t?i.createElement(h,o(o({ref:n},d),{},{components:t})):i.createElement(h,o({ref:n},d))}));function h(e,n){var t=arguments,a=n&&n.mdxType;if("string"==typeof e||a){var r=t.length,o=new Array(r);o[0]=c;var l={};for(var p in n)hasOwnProperty.call(n,p)&&(l[p]=n[p]);l.originalType=e,l[s]="string"==typeof e?e:a,o[1]=l;for(var m=2;m<r;m++)o[m]=t[m];return i.createElement.apply(null,o)}return i.createElement.apply(null,t)}c.displayName="MDXCreateElement"},83904:(e,n,t)=>{t.r(n),t.d(n,{assets:()=>p,contentTitle:()=>o,default:()=>u,frontMatter:()=>r,metadata:()=>l,toc:()=>m});var i=t(87462),a=(t(67294),t(3905));const r={sidebar_position:3},o="Animation Profiles",l={unversionedId:"animation-profiles",id:"animation-profiles",title:"Animation Profiles",description:"---",source:"@site/docs/animation-profiles.md",sourceDirName:".",slug:"/animation-profiles",permalink:"/Animations/docs/animation-profiles",draft:!1,editUrl:"https://github.com/wrello/Animations/edit/master/docs/animation-profiles.md",tags:[],version:"current",sidebarPosition:3,frontMatter:{sidebar_position:3},sidebar:"defaultSidebar",previous:{title:"Basic Usage",permalink:"/Animations/docs/basic-usage"},next:{title:"Animated Objects",permalink:"/Animations/docs/animated-objects"}},p={},m=[{value:"Animation Profiles Setup",id:"animation-profiles-setup",level:2}],d={toc:m},s="wrapper";function u(e){let{components:n,...r}=e;return(0,a.kt)(s,(0,i.Z)({},d,r,{components:n,mdxType:"MDXLayout"}),(0,a.kt)("h1",{id:"animation-profiles"},"Animation Profiles"),(0,a.kt)("hr",null),(0,a.kt)("h2",{id:"animation-profiles-setup"},"Animation Profiles Setup"),(0,a.kt)("p",null,"First create a module inside of the ",(0,a.kt)("inlineCode",{parentName:"p"},"Animations.Deps.AnimationProfiles")," folder. It's name will be the name of the animation profile:"),(0,a.kt)("p",null,(0,a.kt)("img",{alt:"tutorial-1",src:t(97911).Z,width:"314",height:"178"})),(0,a.kt)("p",null,"The animation profile (what the ",(0,a.kt)("inlineCode",{parentName:"p"},"Zombie")," module returns) is just a ",(0,a.kt)("a",{parentName:"p",href:"http://localhost:3000/Animations/api/AnimationsServer#humanoidRigTypeToCustomRBXAnimationIds"},(0,a.kt)("inlineCode",{parentName:"a"},"humanoidRigTypeToCustomRBXAnimationIds"))," table, as seen below:"),(0,a.kt)("pre",null,(0,a.kt)("code",{parentName:"pre",className:"language-lua"},"-- Inside of `Animations.Deps.AnimationProfiles.Zombie`\nreturn {\n    [Enum.HumanoidRigType.R15] = {\n        run = 616163682,\n        walk = 616168032,\n        jump = 616161997,\n        idle = {\n            Animation1 = 616158929,\n            Animation2 = 616160636\n        },\n        fall = 616157476,\n        swim = 616165109,\n        swimIdle = 616166655,\n        climb = 616156119\n    }\n}\n")),(0,a.kt)("admonition",{type:"info"},(0,a.kt)("p",{parentName:"admonition"},"These animations will only work for an ",(0,a.kt)("inlineCode",{parentName:"p"},"R15")," character. Animation ids found here: ",(0,a.kt)("a",{parentName:"p",href:"https://create.roblox.com/docs/animation/using#catalog-animations"},"https://create.roblox.com/docs/animation/using#catalog-animations"))),(0,a.kt)("p",null,"Now you can use the ",(0,a.kt)("inlineCode",{parentName:"p"},"Zombie")," animation profile. Example:"),(0,a.kt)("pre",null,(0,a.kt)("code",{parentName:"pre",className:"language-lua"},'-- In a LocalScript in StarterPlayerScripts\nlocal Animations = require(game.ReplicatedStorage.Animations.Package.AnimationsClient)\n\nAnimations:Init()\n\nAnimations:ApplyAnimationProfile("Zombie") -- We now have zombie animations instead of the default roblox ones.\n')))}u.isMDXComponent=!0},97911:(e,n,t)=>{t.d(n,{Z:()=>i});const i="data:image/png;base64,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"}}]);
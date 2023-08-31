"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[160],{3905:(e,n,a)=>{a.d(n,{Zo:()=>p,kt:()=>y});var t=a(67294);function r(e,n,a){return n in e?Object.defineProperty(e,n,{value:a,enumerable:!0,configurable:!0,writable:!0}):e[n]=a,e}function i(e,n){var a=Object.keys(e);if(Object.getOwnPropertySymbols){var t=Object.getOwnPropertySymbols(e);n&&(t=t.filter((function(n){return Object.getOwnPropertyDescriptor(e,n).enumerable}))),a.push.apply(a,t)}return a}function o(e){for(var n=1;n<arguments.length;n++){var a=null!=arguments[n]?arguments[n]:{};n%2?i(Object(a),!0).forEach((function(n){r(e,n,a[n])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(a)):i(Object(a)).forEach((function(n){Object.defineProperty(e,n,Object.getOwnPropertyDescriptor(a,n))}))}return e}function l(e,n){if(null==e)return{};var a,t,r=function(e,n){if(null==e)return{};var a,t,r={},i=Object.keys(e);for(t=0;t<i.length;t++)a=i[t],n.indexOf(a)>=0||(r[a]=e[a]);return r}(e,n);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(t=0;t<i.length;t++)a=i[t],n.indexOf(a)>=0||Object.prototype.propertyIsEnumerable.call(e,a)&&(r[a]=e[a])}return r}var s=t.createContext({}),c=function(e){var n=t.useContext(s),a=n;return e&&(a="function"==typeof e?e(n):o(o({},n),e)),a},p=function(e){var n=c(e.components);return t.createElement(s.Provider,{value:n},e.children)},d="mdxType",u={inlineCode:"code",wrapper:function(e){var n=e.children;return t.createElement(t.Fragment,{},n)}},m=t.forwardRef((function(e,n){var a=e.components,r=e.mdxType,i=e.originalType,s=e.parentName,p=l(e,["components","mdxType","originalType","parentName"]),d=c(a),m=r,y=d["".concat(s,".").concat(m)]||d[m]||u[m]||i;return a?t.createElement(y,o(o({ref:n},p),{},{components:a})):t.createElement(y,o({ref:n},p))}));function y(e,n){var a=arguments,r=n&&n.mdxType;if("string"==typeof e||r){var i=a.length,o=new Array(i);o[0]=m;var l={};for(var s in n)hasOwnProperty.call(n,s)&&(l[s]=n[s]);l.originalType=e,l[d]="string"==typeof e?e:r,o[1]=l;for(var c=2;c<i;c++)o[c]=a[c];return t.createElement.apply(null,o)}return t.createElement.apply(null,a)}m.displayName="MDXCreateElement"},94537:(e,n,a)=>{a.r(n),a.d(n,{assets:()=>s,contentTitle:()=>o,default:()=>u,frontMatter:()=>i,metadata:()=>l,toc:()=>c});var t=a(87462),r=(a(67294),a(3905));const i={},o="Basic Usage",l={unversionedId:"basic-usage",id:"basic-usage",title:"Basic Usage",description:"---",source:"@site/docs/basic-usage.md",sourceDirName:".",slug:"/basic-usage",permalink:"/Animations/docs/basic-usage",draft:!1,editUrl:"https://github.com/wrello/Animations/edit/master/docs/basic-usage.md",tags:[],version:"current",frontMatter:{},sidebar:"defaultSidebar",previous:{title:"Install",permalink:"/Animations/docs/intro"}},s={},c=[],p={toc:c},d="wrapper";function u(e){let{components:n,...a}=e;return(0,r.kt)(d,(0,t.Z)({},p,a,{components:n,mdxType:"MDXLayout"}),(0,r.kt)("h1",{id:"basic-usage"},"Basic Usage"),(0,r.kt)("hr",null),(0,r.kt)("h1",{id:"animationids"},"AnimationIds"),(0,r.kt)("p",null,"Configure your ",(0,r.kt)("a",{parentName:"p",href:"/api/AnimationIds"},(0,r.kt)("inlineCode",{parentName:"a"},"AnimationIds"))," module:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},'-- In ReplicatedStorage.Animations.Deps.AnimationIds\nlocal ninjaJumpR15AnimationId = 656117878\n\nlocal AnimationIds = {\n    Player = { -- Rig type of "Player" (required for any animations that will run on player characters)\n        Jump = ninjaJumpR15AnimationId -- Path of "Jump"\n    }\n}\n')),(0,r.kt)("h1",{id:"animationsserver"},"AnimationsServer"),(0,r.kt)("p",null,"Playing the animation when it gets auto loaded on a player character:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},'-- In a ServerScript\nlocal Players = game:GetService("Players")\n\nlocal Animations = require(game.ReplicatedStorage.Animations.Package.AnimationsServer)\n\nAnimations:Init({\n    AutoLoadPlayerTracks = true, -- Defaults to false\n    TimeToLoadPrints = true -- Defaults to false (on the server)\n})\n\nlocal function onPlayerAdded(player)\n    Animations:AwaitLoaded(player)\n\n    print("Finished loading animations for", player.Name)\n\n    while true do\n        print("Playing ninja jump animation for", player.Name)\n        Animations:PlayTrack(player, "Jump")\n\n        task.wait(3)\n    end\nend\n\nfor _, player in ipairs(Players:GetPlayers()) do\n    task.spawn(onPlayerAdded, player)\nend\n\nPlayers.PlayerAdded:Connect(onPlayerAdded)\n')),(0,r.kt)("h1",{id:"animationsclient"},"AnimationsClient"),(0,r.kt)("p",null,"Playing the animation when it gets auto loaded on the client:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-lua"},'-- In a LocalScript\nlocal Animations = require(game.ReplicatedStorage.Animations.Package.AnimationsClient)\n\nAnimations:Init({\n    AutoLoadPlayerTracks = true, -- Defaults to false\n    TimeToLoadPrints = true -- Defaults to true (on the client)\n})\n\nlocal player = game.Players.LocalPlayer\n\nlocal function onCharacterAdded(player)\n    Animations:AwaitLoaded()\n\n    print("Finished loading client animations")\n\n    while true do\n        print("Playing ninja jump client animation")\n        Animations:PlayTrack("Jump")\n\n        task.wait(3)\n    end\nend\n\nif player.Character then\n    onCharacterAdded(player.Character)\nend\n\nplayer.CharacterAdded:Connect(onCharacterAdded)\n')))}u.isMDXComponent=!0}}]);
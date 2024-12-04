# promptd-mux

minimal macOS menubar client for OpenAI chat completions

## features

- streaming responses via URLSession.bytes
- keychain secure storage (com.menubargpt.api)
- markdown rendering with syntax highlighting  
- 50 message session persistence
- supports gpt-4o, gpt-4o-mini, o1-mini

## setup

```bash
git clone https://github.com/Ilakiancs/promptd-mux.git
cd promptd-mux
open MenubarGPT.xcodeproj
# cmd+r to build
```

add openai api key in settings → test & save

## usage

`cmd+enter` to send  
click menubar icon for 420x520 window

```

## technical

- swiftui + combine reactive patterns
- app sandbox with network.client entitlement
- no logging in release builds
- automatic retry with exponential backoff

## made by "ilakiancs" 

## license

mit

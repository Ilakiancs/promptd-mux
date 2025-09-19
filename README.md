# promptd-mux

minimal macOS menubar client for OpenAI chat completions

## features

- streaming responses via URLSession.bytes
- keychain secure storage (com.menubargpt.api)
- markdown rendering with syntax highlighting  
- 50 message session persistence
- supports gpt-4o, gpt-4o-mini, o1-mini

## requirements

- macOS 13.0+ (Ventura)
- Xcode 15.0+
- OpenAI API key

## setup

```bash
git clone https://github.com/Ilakiancs/promptd-mux.git
cd promptd-mux

# build main target only (recommended)
./build-main.sh

# or build via xcode
open MenubarGPT.xcodeproj
# cmd+r to build
```

add openai api key in settings → test & save

## usage

`cmd+enter` to send  
click menubar icon for the icon window



<a href="https://next.ossinsight.io/widgets/official/analyze-repo-loc-per-month?repo_id=41986369" target="_blank" style="display: block" align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://next.ossinsight.io/widgets/official/analyze-repo-loc-per-month/thumbnail.png?repo_id=41986369&image_size=auto&color_scheme=dark" width="721" height="auto">
    <img alt="Lines of Code Changes of pingcap/tidb" src="https://next.ossinsight.io/widgets/official/analyze-repo-loc-per-month/thumbnail.png?repo_id=41986369&image_size=auto&color_scheme=light" width="721" height="auto">
  </picture>
</a>

<!-- Made with [OSS Insight](https://ossinsight.io/) -->



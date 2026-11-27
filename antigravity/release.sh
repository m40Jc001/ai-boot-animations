#!/bin/zsh
# 维护者用：打包 Mac 通用版 build/AntigravityBootAnimation.zip 和 Windows 版 build/AntigravityBootAnimation-Windows.zip，供上传到 GitHub Releases
# 用法：./release.sh                 只打包
#       ./release.sh gemini-v1.0.0   打包并用 gh 发布这个版本
set -e
cd "${0:A:h}"
./build.sh
OUT=build/release/AntigravityBootAnimation
rm -rf build/release build/AntigravityBootAnimation.zip; mkdir -p "$OUT"
ditto build/AntigravityBootAnimation.app "$OUT/AntigravityBootAnimation.app"
cp install.sh uninstall.sh ../LICENSE CREDITS.md "$OUT/"
cp assets/LICENSE.md "$OUT/ASSETS-LICENSE.md"
ditto -c -k --norsrc --noextattr --keepParent "$OUT" build/AntigravityBootAnimation.zip
echo "压缩包：build/AntigravityBootAnimation.zip（$(du -h build/AntigravityBootAnimation.zip | cut -f1)）"

# Windows 版：源码 + 脚本 + H.264 视频（很多 Windows 播不了 HEVC），用户电脑上用系统自带编译器现场编译
WOUT=build/release/AntigravityBootAnimation-Windows
rm -f build/AntigravityBootAnimation-Windows.zip; mkdir -p "$WOUT/assets"
cp -R windows/src windows/build.ps1 windows/install.ps1 windows/uninstall.ps1 "$WOUT/"
cp windows/assets/LibreBodoni-Italic.ttf windows/assets/LibreBodoni-OFL.txt "$WOUT/assets/"
cp ../LICENSE CREDITS.md "$WOUT/"; cp assets/LICENSE.md "$WOUT/ASSETS-LICENSE.md"
ffmpeg -v error -y -i assets/intro.mp4 -c:v libx264 -preset slow -crf 20 -pix_fmt yuv420p -movflags +faststart -c:a aac -b:a 160k "$WOUT/assets/intro.mp4"
ffmpeg -v error -y -i assets/loop.mp4 -c:v libx264 -preset slow -crf 20 -pix_fmt yuv420p -movflags +faststart -an "$WOUT/assets/loop.mp4"
# 循环段连放两遍编成一个文件：Windows 版靠两半画面相同做「重叠交接」，接缝不闪（要比 loop.mp4 后生成，程序按修改时间判断用哪个）
ffmpeg -v error -y -stream_loop 1 -i assets/loop.mp4 -c:v libx264 -preset slow -crf 20 -pix_fmt yuv420p -movflags +faststart -an "$WOUT/assets/loop-x2.mp4"
ditto -c -k --norsrc --noextattr --keepParent "$WOUT" build/AntigravityBootAnimation-Windows.zip
echo "压缩包：build/AntigravityBootAnimation-Windows.zip（$(du -h build/AntigravityBootAnimation-Windows.zip | cut -f1)）"

# 和 Claude 版共用一个仓库，所以：版本号用 gemini- 开头，并且标成「不是最新」，
# 免得抢走 Claude 版一行安装要用的 releases/latest。发完记得把 web-install.sh 和 windows/web-install.ps1 里的 TAG 改成新版本号。
if [[ -n "$1" ]]; then
  [[ "$1" == gemini-* ]] || { echo "版本号要以 gemini- 开头，例如 gemini-v1.0.0"; exit 1; }
  gh release create "$1" build/AntigravityBootAnimation.zip build/AntigravityBootAnimation-Windows.zip --latest=false --title "Gemini 开机动画 $1" \
    --notes "${NOTES:-Antigravity 开机动画（Gemini 双剑少女），macOS 13+（Apple 芯片 / Intel）与 Windows 10/11。一行命令安装见 antigravity/README.md。}"
fi

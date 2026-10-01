#!/bin/bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
version=${VERSION:-1.0.0}
out="$root/build"
app="$out/Deskflow Globe.app"
mkdir -p "$app/Contents/MacOS" "$out/module-cache"
for arch in arm64 x86_64; do
  xcrun swiftc -swift-version 5 -O -target "$arch-apple-macos13.0" \
    -module-cache-path "$out/module-cache" \
    "$root/src/FnGesture.swift" "$root/src/main.swift" -o "$out/DeskflowGlobe-$arch" \
    -framework AppKit -framework Carbon -framework CoreGraphics
done
xcrun lipo -create "$out/DeskflowGlobe-arm64" "$out/DeskflowGlobe-x86_64" \
  -output "$app/Contents/MacOS/DeskflowGlobe"
/usr/bin/plutil -create xml1 "$app/Contents/Info.plist"
for pair in 'CFBundleIdentifier io.github.audit0.deskflowglobe' \
  'CFBundleName Deskflow Globe' 'CFBundleExecutable DeskflowGlobe' \
  'CFBundlePackageType APPL' "CFBundleVersion $version" \
  "CFBundleShortVersionString $version" 'LSMinimumSystemVersion 13.0'; do
  key=${pair%% *}; value=${pair#* }
  /usr/bin/plutil -insert "$key" -string "$value" "$app/Contents/Info.plist"
done
/usr/bin/plutil -insert LSUIElement -bool true "$app/Contents/Info.plist"
/usr/bin/plutil -insert NSHighResolutionCapable -bool true "$app/Contents/Info.plist"
/usr/bin/xattr -cr "$app"
/usr/bin/codesign --force --sign - "$app"
/usr/bin/codesign --verify --strict "$app"
architectures=$(xcrun lipo -archs "$app/Contents/MacOS/DeskflowGlobe")
for expected in arm64 x86_64; do
  case " $architectures " in
    *" $expected "*) ;;
    *) echo "Missing architecture: $expected" >&2; exit 1 ;;
  esac
done
package="$out/Deskflow-Globe-$version-macos-universal"
mkdir -p "$package"
/usr/bin/ditto --norsrc "$app" "$package/Deskflow Globe.app"
cp "$root/scripts/install.sh" "$package/Install.command"
cp "$root/scripts/uninstall.sh" "$package/Uninstall.command"
cp "$root/scripts/launcher.sh" "$package/launcher.sh"
cp "$root/README.md" "$root/LICENSE" "$package/"
chmod +x "$package/Install.command" "$package/Uninstall.command"
/usr/bin/xattr -cr "$package"
/usr/bin/codesign --verify --strict "$package/Deskflow Globe.app"
/usr/bin/ditto --norsrc -c -k --keepParent "$package" "$package.zip"
(cd "$out" && /usr/bin/shasum -a 256 "$(basename "$package.zip")" > SHA256SUMS)
printf '%s\n' "$package.zip"

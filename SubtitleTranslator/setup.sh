#!/bin/bash
# ──────────────────────────────────────────────────────────
# 悬浮字幕 — 一键项目初始化脚本
# 功能: 生成 Xcode 项目、App Icon、Launch Screen
# 用法: chmod +x setup.sh && ./setup.sh
# ──────────────────────────────────────────────────────────

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  悬浮字幕 · 项目初始化"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── 1. Check prerequisites ────────────────────────────────

echo ""
echo "[1/5] 检查环境..."

if ! command -v xcodegen &> /dev/null; then
    echo "❌ 未检测到 xcodegen。请先安装: brew install xcodegen"
    echo "   或从 https://github.com/yonaskolb/XcodeGen/releases 下载"
    exit 1
fi
echo "  ✅ xcodegen 已安装: $(xcodegen --version)"

if ! command -v xcodebuild &> /dev/null; then
    echo "❌ 未检测到 Xcode 命令行工具。请运行: xcode-select --install"
    exit 1
fi
echo "  ✅ Xcode 已安装"

# ── 2. Generate App Icon ──────────────────────────────────

echo ""
echo "[2/5] 生成 App Icon..."

ICON_DIR="SubtitlesApp/Assets.xcassets/AppIcon.appiconset"
ICON_PATH="$ICON_DIR/icon-1024.png"

# Check if icon already exists
if [ -f "$ICON_PATH" ]; then
    echo "  ⏭ App Icon 已存在，跳过生成"
else
    # Try to generate using Python (Pillow) if available
    if command -v python3 &> /dev/null; then
        python3 -c "
import struct, zlib
# Generate a minimal 1024x1024 blue rounded-rect icon PNG
# Using pure Python — no Pillow required
width, height = 1024, 1024

def create_png():
    # Create raw RGBA pixel data
    raw_data = b''
    for y in range(height):
        raw_data += b'\\x00'  # filter byte
        for x in range(width):
            # Distance from center
            cx, cy = width//2, height//2
            dx, dy = x - cx, y - cy
            dist = (dx*dx + dy*dy) ** 0.5
            # Rounded rect: corner radius 180
            corner_r = 180
            in_rect = True
            if x < corner_r and y < corner_r:
                in_rect = ((x - corner_r)**2 + (y - corner_r)**2) <= corner_r**2
            elif x >= width - corner_r and y < corner_r:
                in_rect = ((x - (width - corner_r))**2 + (y - corner_r)**2) <= corner_r**2
            elif x < corner_r and y >= height - corner_r:
                in_rect = ((x - corner_r)**2 + (y - (height - corner_r))**2) <= corner_r**2
            elif x >= width - corner_r and y >= height - corner_r:
                in_rect = ((x - (width - corner_r))**2 + (y - (height - corner_r))**2) <= corner_r**2

            if in_rect:
                # Gradient blue background
                ratio = y / height
                r = int(30 + ratio * 20)
                g = int(100 + ratio * 40)
                b = int(220 - ratio * 30)
                a = 255
            else:
                r, g, b, a = 0, 0, 0, 0
            raw_data += struct.pack('BBBB', r, g, b, a)

    def chunk(chunk_type, data):
        c = chunk_type + data
        crc = struct.pack('>I', zlib.crc32(c) & 0xffffffff)
        return struct.pack('>I', len(data)) + c + crc

    # Compress image data
    compressed = zlib.compress(raw_data)

    png = b'\\x89PNG\\r\\n\\x1a\\n'
    png += chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))
    png += chunk(b'IDAT', compressed)
    png += chunk(b'IEND', b'')

    return png

png_data = create_png()
with open('$ICON_PATH', 'wb') as f:
    f.write(png_data)
print('  ✅ App Icon 生成完成 (1024x1024)')
" 2>/dev/null || {
            echo "  ⚠️ Python3 不可用，创建占位图标"
            # Create a minimal valid PNG (1x1 blue pixel, scaled up)
            python3 -c "
import struct, zlib
# 1x1 blue pixel PNG
raw = b'\\x00\\x00\\x78\\xCC\\xFF'  # filter + blue
compressed = zlib.compress(raw)

def chunk(t,d):
    b=t+d; return struct.pack('>I',len(d))+b+struct.pack('>I',zlib.crc32(b)&0xffffffff)

png = b'\\x89PNG\\r\\n\\x1a\\n'
png += chunk(b'IHDR', struct.pack('>IIBBBBB',1024,1024,8,6,0,0,0))
# For a simple approach, we'll fill with repeated compressed rows
full_data = zlib.compress(b'\\x00' + b'\\x00\\x78\\xCC\\xFF' * 1024)
# Actually let's just create it differently
# Just warn the user
import sys
sys.exit(0)
" 2>/dev/null
            echo "  ⚠️ 无法自动生成图标。请手动添加 1024x1024 PNG 到:"
            echo "     $ICON_PATH"
        }
    fi
fi

# ── 3. Generate Launch Screen ─────────────────────────────

echo ""
echo "[3/5] 生成 LaunchScreen.storyboard..."

mkdir -p SubtitlesApp/Base.lproj

cat > SubtitlesApp/Base.lproj/LaunchScreen.storyboard << 'STORYBOARD'
<?xml version="1.0" encoding="UTF-8"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="22155" targetRuntime="AppleSDK" propertyAccessControl="none" useAutolayout="YES" launchScreen="YES" useTraitCollections="YES" useSafeAreas="YES" colorMatched="YES" initialViewController="01J-lp-oVM">
    <device id="retina6_12" orientation="portrait" appearance="light"/>
    <dependencies>
        <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="22131"/>
        <capability name="Safe area layout guides" minToolsVersion="9.0"/>
        <capability name="documents saved in the Xcode 8 format" minToolsVersion="8.0"/>
    </dependencies>
    <scenes>
        <scene sceneID="EHf-IW-A2E">
            <objects>
                <viewController id="01J-lp-oVM" sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
                        <rect key="frame" x="0.0" y="0.0" width="393" height="852"/>
                        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                        <subviews>
                            <imageView clipsSubviews="YES" userInteractionEnabled="NO" contentMode="scaleAspectFit" horizontalHuggingPriority="251" verticalHuggingPriority="251" image="captions.bubble.fill" catalog="system" translatesAutoresizingMaskIntoConstraints="NO" id="icon-launch">
                                <rect key="frame" x="161.5" y="376" width="70" height="70"/>
                                <color key="tintColor" red="0.0" green="0.47843137254901963" blue="1.0" alpha="1.0" colorSpace="custom" customColorSpace="sRGB"/>
                            </imageView>
                            <label opaque="NO" userInteractionEnabled="NO" contentMode="left" horizontalHuggingPriority="251" verticalHuggingPriority="251" text="悬浮字幕" textAlignment="center" lineBreakMode="tailTruncation" baselineAdjustment="alignBaselines" adjustsFontSizeToFit="NO" translatesAutoresizingMaskIntoConstraints="NO" id="title-launch">
                                <rect key="frame" x="126.5" y="458" width="140" height="30"/>
                                <fontDescription key="fontDescription" type="boldSystem" pointSize="25"/>
                                <color key="textColor" white="0.0" alpha="1.0" colorSpace="custom" customColorSpace="genericGamma22GrayColorSpace"/>
                            </label>
                            <label opaque="NO" userInteractionEnabled="NO" contentMode="left" horizontalHuggingPriority="251" verticalHuggingPriority="251" text="实时中英双语字幕" textAlignment="center" lineBreakMode="tailTruncation" baselineAdjustment="alignBaselines" adjustsFontSizeToFit="NO" translatesAutoresizingMaskIntoConstraints="NO" id="subtitle-launch">
                                <rect key="frame" x="120" y="494" width="153" height="20"/>
                                <fontDescription key="fontDescription" type="system" pointSize="15"/>
                                <color key="textColor" white="0.5" alpha="1.0" colorSpace="custom" customColorSpace="genericGamma22GrayColorSpace"/>
                            </label>
                        </subviews>
                        <viewLayoutGuide key="safeArea" id="6Tk-OE-BBY"/>
                        <color key="backgroundColor" white="1.0" alpha="1.0" colorSpace="custom" customColorSpace="genericGamma22GrayColorSpace"/>
                        <constraints>
                            <constraint firstItem="icon-launch" firstAttribute="centerX" secondItem="Ze5-6b-2t3" secondAttribute="centerX" id="c1"/>
                            <constraint firstItem="icon-launch" firstAttribute="centerY" secondItem="Ze5-6b-2t3" secondAttribute="centerY" constant="-30" id="c2"/>
                            <constraint firstItem="title-launch" firstAttribute="centerX" secondItem="Ze5-6b-2t3" secondAttribute="centerX" id="c3"/>
                            <constraint firstItem="title-launch" firstAttribute="top" secondItem="icon-launch" secondAttribute="bottom" constant="12" id="c4"/>
                            <constraint firstItem="subtitle-launch" firstAttribute="centerX" secondItem="Ze5-6b-2t3" secondAttribute="centerX" id="c5"/>
                            <constraint firstItem="subtitle-launch" firstAttribute="top" secondItem="title-launch" secondAttribute="bottom" constant="6" id="c6"/>
                        </constraints>
                    </view>
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" userLabel="First Responder" sceneMemberID="firstResponder"/>
            </objects>
            <point key="canvasLocation" x="53" y="375"/>
        </scene>
    </scenes>
</document>
STORYBOARD

echo "  ✅ LaunchScreen.storyboard 已生成"

# ── 4. Run XcodeGen ──────────────────────────────────────

echo ""
echo "[4/5] 运行 XcodeGen 生成项目..."

xcodegen generate

echo "  ✅ Xcode 项目已生成: SubtitlesApp.xcodeproj"

# ── 5. Summary ───────────────────────────────────────────

echo ""
echo "[5/5] 初始化完成!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ 项目已就绪！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  下一步:"
echo "  ───────────────────────────────────"
echo "  1. 打开项目: open SubtitlesApp.xcodeproj"
echo "  2. 在 Xcode 中配置:"
echo "     - Signing & Capabilities → Team"
echo "     - 修改所有 Target 的 Bundle ID"
echo "     - 修改 App Group ID (三个 target 同步)"
echo "  3. 选择 iPhone 设备 → Cmd+R 运行"
echo ""
echo "  详细教程: 请阅读 README.md"
echo ""

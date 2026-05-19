import Foundation

// ──────────────────────────────────────────────────────────
// 悬浮字幕 App — Launch Screen Storyboard Generator
// This script is called at build time to create a minimal
// LaunchScreen.storyboard. We create it programmatically
// because we avoid XIB/Storyboard complexity in source control.
// ──────────────────────────────────────────────────────────

let storyboardContent = """
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
                                <color key="textColor" red="0.0" green="0.0" blue="0.0" alpha="1.0" colorSpace="custom" customColorSpace="sRGB"/>
                            </label>
                            <label opaque="NO" userInteractionEnabled="NO" contentMode="left" horizontalHuggingPriority="251" verticalHuggingPriority="251" text="实时中英双语字幕" textAlignment="center" lineBreakMode="tailTruncation" baselineAdjustment="alignBaselines" adjustsFontSizeToFit="NO" translatesAutoresizingMaskIntoConstraints="NO" id="subtitle-launch">
                                <rect key="frame" x="120" y="494" width="153" height="20"/>
                                <fontDescription key="fontDescription" type="system" pointSize="15"/>
                                <color key="textColor" red="0.501960814" green="0.501960814" blue="0.501960814" alpha="1.0" colorSpace="custom" customColorSpace="sRGB"/>
                            </label>
                        </subviews>
                        <viewLayoutGuide key="safeArea" id="6Tk-OE-BBY"/>
                        <color key="backgroundColor" red="1.0" green="1.0" blue="1.0" alpha="1.0" colorSpace="custom" customColorSpace="sRGB"/>
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
"""

let outputDir = FileManager.default.currentDirectoryPath + "/SubtitlesApp/Base.lproj"
let outputPath = outputDir + "/LaunchScreen.storyboard"

do {
    try FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
    try storyboardContent.write(toFile: outputPath, atomically: true, encoding: .utf8)
    print("[OK] LaunchScreen.storyboard generated at \(outputPath)")
} catch {
    print("[ERROR] Failed to write LaunchScreen.storyboard: \(error)")
}

{ lib, ... }:
let
  identity = import ../local/identity.nix;

  # システム設定 > キーボード > 修飾キー と同じ保存先を書く。
  # 値は (usagePage << 32) | usage で、page 0x07 が Keyboard。
  hid = usage: 30064771072 + usage; # 0x7_0000_0000

  keyUsages = {
    capsLock = hid 57; # 0x39
    leftControl = hid 224; # 0xE0
    leftShift = hid 225; # 0xE1
    leftOption = hid 226; # 0xE2
    leftCommand = hid 227; # 0xE3
    rightControl = hid 228; # 0xE4
    rightShift = hid 229; # 0xE5
    rightOption = hid 230; # 0xE6
    rightCommand = hid 231; # 0xE7
    none = 1095216660483; # 0xFF_0000_0003 (割り当てなし)
  };

  toMapping =
    from: to:
    let
      src = keyUsages.${from} or (throw "unknown modifier key: ${from}");
      dst = keyUsages.${to} or (throw "unknown modifier key: ${to}");
    in
    {
      HIDKeyboardModifierMappingSrc = src;
      HIDKeyboardModifierMappingDst = dst;
    };

  # `defaults import` はキー単位の置換なので、配列に書かない割り当ては
  # macOS 既定へ戻る。変えたいものだけでなく維持したいものも列挙する。
  toKeyboardEntry =
    keyboardId: remaps:
    lib.nameValuePair "com.apple.keyboard.modifiermapping.${keyboardId}" (
      lib.mapAttrsToList toMapping remaps
    );
in
{
  # 修飾キーの割り当てはキーボード機器ごとに保存され、キー名に機器 ID
  # (`<vendorId>-<productId>-<?>`、内蔵キーボードは 0-0-0) が入る。
  # 機器 ID も望ましい割り当ても機械によって違うため、データは
  # nix/local/identity.nix が持ち、ここは書き込み方だけを持つ。
  targets.darwin.currentHostDefaults.NSGlobalDomain = lib.listToAttrs (
    lib.mapAttrsToList toKeyboardEntry identity.keyboardModifiers
  );
}

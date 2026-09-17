{
  # ログインユーザー名（cmd: whoami）。
  username = "your-username";

  # darwinConfigurations / homeConfigurations のキー名（cmd: hostname -s）。
  hostname = "your-hostname";

  # Apple Silicon: aarch64-darwin / Intel Mac: x86_64-darwin。
  # cmd: uname -m（arm64ならaarch64-darwin / x86_64ならx86_64-darwin）。
  system = "aarch64-darwin";

  # 修飾キーの再割り当て。キーボード機器ごとに保存されるため機械固有。
  # 機器 ID は `<vendorId>-<productId>-<?>` で、内蔵キーボードは 0-0-0。
  #   確認: defaults -currentHost read -g | grep modifiermapping
  #   接続中の ID: ioreg -c AppleHIDKeyboardEventDriverV2 -r -l | grep -E 'VendorID"|ProductID"'
  # 書かない割り当ては macOS 既定へ戻るため、維持したいものも列挙する。
  # 使える名前: capsLock, leftControl, leftShift, leftOption, leftCommand,
  #             rightControl, rightShift, rightOption, rightCommand, none
  # 再割り当てしないなら空の attrset を置く。
  keyboardModifiers = {
    # "0-0-0" = {
    #   leftCommand = "leftControl";
    #   leftControl = "leftCommand";
    #   capsLock = "rightCommand";
    # };
  };
}
